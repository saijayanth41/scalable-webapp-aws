variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "scalable-webapp"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "At least 2 subnets in different AZs"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 4
}

variable "health_check_path" {
  type    = string
  default = "/"
}
