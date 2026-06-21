variable "project_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
}

variable "app_subnets" {
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
}

variable "middleware_subnets" {
  type = map(object({
    cidr = string
    az   = string
    name = string
  }))
}
