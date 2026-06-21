variable "project_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = map(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "alb_listener_port" {
  type = number
}

variable "app_host_port" {
  type = number
}

variable "app_health_check_path" {
  type = string
}
