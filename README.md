# Deploying a Scalable Web App on AWS with Terraform  

This project demonstrates how to deploy a **highly available, self-healing, and scalable web application** on AWS using **Terraform**.  

The setup provisions:  
- **EC2 instances** running Apache, serving instance metadata (ID + AZ)  
- **Application Load Balancer (ALB)** for distributing traffic across multiple instances  
- **Auto Scaling Group (ASG)** for fault tolerance and elasticity  
- **Terraform IaC** for reproducible infrastructure deployment  

---

## Architecture Overview  
```
Users ─► ALB ─► Target Group ─► Auto Scaling Group ─► EC2 Instances
                  │
                  └─► Health Checks (replace unhealthy instances)
```

---

## Prerequisites  
- AWS Account  
- AWS CLI installed & configured  
```bash
aws --version
aws configure list
```  
- Terraform installed  
```bash
terraform -version
```  

---

## Project Structure  
```
scalable-webapp-aws/
├── providers.tf
├── variables.tf
├── terraform.tfvars
├── security_groups.tf
├── launch_template.tf
├── alb.tf
├── asg.tf
├── outputs.tf
└── README.md
```

---

## Terraform Files  

- **providers.tf** → sets AWS as the provider  
- **variables.tf** → defines reusable inputs (region, instance type, scaling limits)  
- **security_groups.tf** → configures ALB + EC2 firewall rules  
- **launch_template.tf** → installs Apache & serves Instance ID + AZ via user_data  
- **alb.tf** → provisions Application Load Balancer, Target Group, Listener  
- **asg.tf** → creates Auto Scaling Group + CPU scaling policy  
- **outputs.tf** → prints ALB DNS name & ASG name  

---

## Deployment Steps  

1. **Initialize Terraform**  
```bash
terraform init
```

2. **Validate configuration**  
```bash
terraform validate
```

3. **Preview plan**  
```bash
terraform plan
```

4. **Apply to deploy resources**  
```bash
terraform apply -auto-approve
```

5. **Get ALB DNS name**  
```bash
terraform output -raw alb_dns_name
```

6. **Test in browser**  
Visit `http://<alb-dns>` → should show Instance ID + AZ.  

---

## Demo Proof  

- **Load Balancing** → Refresh browser, see requests served by different EC2s.  
- **Auto-Healing** → Terminate one EC2, ASG launches replacement.  
- **Auto Scaling** → Stress test with ApacheBench:  
```bash
ab -n 5000 -c 200 http://<alb-dns>/
```

---

## Cleanup  
Destroy all resources to avoid charges:  
```bash
terraform destroy -auto-approve
```

---

## Key Takeaways  
- **High Availability** → ALB spreads traffic across AZs  
- **Self-Healing** → ASG replaces failed instances  
- **Elasticity** → ASG scales up/down based on CPU load  
- **Infrastructure as Code** → Reproducible, consistent deployments  

---

## Next Steps  
- Add **HTTPS (TLS via ACM)**  
- Replace Apache with a **Dockerized app**  
- Add **CloudWatch alarms & dashboards**  

---

Built with **Terraform + AWS** as part of my DevOps & Cloud journey.  
