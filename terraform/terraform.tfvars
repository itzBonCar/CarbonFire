region        = "us-east-1"
state_bucket  = "carbonfire-terraform-state-bucket-unique"
project_name  = "carbonfire"
key_name      = "canbor-kp"
ubuntu_ami_id = "ami-0b6d9d3d33ba97d99"

tags = {
  Environment = "demo"
  ManagedBy   = "terraform"
}
