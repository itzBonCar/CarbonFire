output "app_asg_name" {
  value = aws_autoscaling_group.app.name
}

output "redis_asg_name" {
  value = aws_autoscaling_group.redis.name
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
