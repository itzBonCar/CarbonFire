variable "project_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "alb_ingress_cidr" {
  type = string
}

variable "alb_listener_port" {
  type = number
}

variable "app_host_port" {
  type = number
}

variable "redis_port" {
  type = number
}

variable "redis_sentinel_port" {
  type = number
}

variable "ssh_ingress_cidr" {
  type = string
}
