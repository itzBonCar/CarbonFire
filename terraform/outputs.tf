output "alb_dns" {
  value = module.alb.alb_dns
}

output "app_asg" {
  value = module.compute.app_asg_name
}

output "redis_asg" {
  value = module.compute.redis_asg_name
}

output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}

output "terraform_state_bucket" {
  value = var.state_bucket
}
