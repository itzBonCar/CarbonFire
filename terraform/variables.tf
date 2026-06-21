variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "carbonfire"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "app_subnets" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "middleware_subnets" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "state_bucket" {
  description = "S3 bucket used for Terraform state."
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key pair name used for SSH through the bastion host."
  type        = string
  default     = "canbor-kp"
}

variable "ubuntu_ami_owner" {
  type    = string
  default = "099720109477"
}

variable "ubuntu_ami_name_filter" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "ubuntu_ami_id" {
  description = "Optional: explicit AMI id to use (overrides name filter when set)."
  type        = string
  default     = ""
}

variable "alb_ingress_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "alb_listener_port" {
  type    = number
  default = 80
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to SSH to the bastion host. Restrict this to your public IP for real use."
  type        = string
  default     = "0.0.0.0/0"
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_asg_min" {
  type    = number
  default = 2
}

variable "app_asg_max" {
  type    = number
  default = 3
}

variable "app_asg_desired" {
  type    = number
  default = 2
}

variable "app_host_port" {
  type    = number
  default = 80
}

variable "app_health_check_path" {
  type    = string
  default = "/health"
}

variable "redis_instance_type" {
  type    = string
  default = "t3.small"
}

variable "redis_asg_min" {
  type    = number
  default = 3
}

variable "redis_asg_max" {
  type    = number
  default = 3
}

variable "redis_asg_desired" {
  type    = number
  default = 3
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "redis_sentinel_port" {
  type    = number
  default = 26379
}

variable "tags" {
  type    = map(string)
  default = {}
}
