terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Use existing VPC & subnets (default VPC is fine)
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Amazon Linux 2 AMI (x86_64)
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security groups
resource "aws_security_group" "alb_sg" {
  name        = "${var.name}-alb-sg"
  description = "ALB SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "app_sg" {
  name        = "${var.name}-app-sg"
  description = "App SG"
  vpc_id      = var.vpc_id

  # Only ALB can reach instances on 80
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Target group (HTTP)
resource "aws_lb_target_group" "tg" {
  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ALB
resource "aws_lb" "alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids
}

# Listener (HTTP → forward to TG)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# User data (instance-aware page)
locals {
  user_data = <<-EOT
    #!/bin/bash -xe
    yum update -y
    yum install -y httpd
    systemctl enable --now httpd
    cat >/var/www/html/index.html <<'HTML'
    <h1>Welcome to Scalable Web App</h1>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
    <p>AZ: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
    HTML
  EOT
}

# Launch Template
resource "aws_launch_template" "lt" {
  name_prefix            = "${var.name}-lt-"
  image_id               = data.aws_ami.al2.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data              = base64encode(local.user_data)
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                      = "${var.name}-asg"
  vpc_zone_identifier       = var.subnet_ids
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  target_group_arns         = [aws_lb_target_group.tg.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = { "Name" = "${var.name}-app" }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      instance_warmup        = 60
      min_healthy_percentage = 90
    }
    triggers = ["launch_template"]
  }
}

# Target tracking scaling (CPU 50%)
resource "aws_autoscaling_policy" "cpu_target_50" {
  name                   = "${var.name}-cpu50"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}
