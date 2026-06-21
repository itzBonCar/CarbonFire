provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ubuntu_ami_owner]

  filter {
    name   = "name"
    values = [var.ubuntu_ami_name_filter]
  }
}

locals {
  common_tags = merge(var.tags, {
    Project = var.project_name
  })

  public_subnets = {
    for idx, cidr in var.public_subnets : tostring(idx) => {
      cidr = cidr
      az   = data.aws_availability_zones.available.names[idx]
      name = "${var.project_name}-public-${idx + 1}"
    }
  }

  app_subnets = {
    for idx, cidr in var.app_subnets : tostring(idx) => {
      cidr = cidr
      az   = data.aws_availability_zones.available.names[idx]
      name = "${var.project_name}-app-${idx + 1}"
    }
  }

  middleware_subnets = {
    for idx, cidr in var.middleware_subnets : tostring(idx) => {
      cidr = cidr
      az   = data.aws_availability_zones.available.names[idx]
      name = "${var.project_name}-middleware-${idx + 1}"
    }
  }
}

module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  common_tags        = local.common_tags
  vpc_cidr           = var.vpc_cidr
  public_subnets     = local.public_subnets
  app_subnets        = local.app_subnets
  middleware_subnets = local.middleware_subnets
}

module "security" {
  source = "./modules/security"

  project_name        = var.project_name
  common_tags         = local.common_tags
  vpc_id              = module.network.vpc_id
  alb_ingress_cidr    = var.alb_ingress_cidr
  alb_listener_port   = var.alb_listener_port
  app_host_port       = var.app_host_port
  redis_port          = var.redis_port
  redis_sentinel_port = var.redis_sentinel_port
  ssh_ingress_cidr    = var.ssh_ingress_cidr
}

module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  common_tags           = local.common_tags
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  alb_listener_port     = var.alb_listener_port
  app_host_port         = var.app_host_port
  app_health_check_path = var.app_health_check_path
}

module "compute" {
  source = "./modules/compute"

  project_name              = var.project_name
  common_tags               = local.common_tags
  ubuntu_ami_id             = var.ubuntu_ami_id != "" ? var.ubuntu_ami_id : data.aws_ami.ubuntu.id
  key_name                  = var.key_name
  bastion_instance_type     = var.bastion_instance_type
  public_subnet_ids         = module.network.public_subnet_ids
  bastion_security_group_id = module.security.bastion_security_group_id
  app_instance_type         = var.app_instance_type
  app_asg_min               = var.app_asg_min
  app_asg_max               = var.app_asg_max
  app_asg_desired           = var.app_asg_desired
  app_subnet_ids            = module.network.app_subnet_ids
  app_security_group_id     = module.security.app_security_group_id
  app_target_group_arn      = module.alb.app_target_group_arn
  redis_instance_type       = var.redis_instance_type
  redis_asg_min             = var.redis_asg_min
  redis_asg_max             = var.redis_asg_max
  redis_asg_desired         = var.redis_asg_desired
  middleware_subnet_ids     = module.network.middleware_subnet_ids
  redis_security_group_id   = module.security.redis_security_group_id
}
