variable "project_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "ubuntu_ami_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "bastion_instance_type" {
  type = string
}

variable "public_subnet_ids" {
  type = map(string)
}

variable "bastion_security_group_id" {
  type = string
}

variable "app_instance_type" {
  type = string
}

variable "app_asg_min" {
  type = number
}

variable "app_asg_max" {
  type = number
}

variable "app_asg_desired" {
  type = number
}

variable "app_subnet_ids" {
  type = map(string)
}

variable "app_security_group_id" {
  type = string
}

variable "app_target_group_arn" {
  type = string
}

variable "redis_instance_type" {
  type = string
}

variable "redis_asg_min" {
  type = number
}

variable "redis_asg_max" {
  type = number
}

variable "redis_asg_desired" {
  type = number
}

variable "middleware_subnet_ids" {
  type = map(string)
}

variable "redis_security_group_id" {
  type = string
}
