resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow public HTTP to the application load balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = var.alb_ingress_cidr
  from_port         = var.alb_listener_port
  ip_protocol       = "tcp"
  to_port           = var.alb_listener_port
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Allow SSH access to the bastion host"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-bastion-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = var.ssh_ingress_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Allow ALB traffic to application instances"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_host_port
  ip_protocol                  = "tcp"
  to_port                      = var.app_host_port
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_bastion" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Allow app to Redis and Sentinel, and Redis peer replication"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-redis-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_app" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.redis_port
  ip_protocol                  = "tcp"
  to_port                      = var.redis_port
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_peers" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_security_group.redis.id
  from_port                    = var.redis_port
  ip_protocol                  = "tcp"
  to_port                      = var.redis_port
}

resource "aws_vpc_security_group_ingress_rule" "sentinel_from_app" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.redis_sentinel_port
  ip_protocol                  = "tcp"
  to_port                      = var.redis_sentinel_port
}

resource "aws_vpc_security_group_ingress_rule" "sentinel_from_peers" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_security_group.redis.id
  from_port                    = var.redis_sentinel_port
  ip_protocol                  = "tcp"
  to_port                      = var.redis_sentinel_port
}

resource "aws_vpc_security_group_ingress_rule" "redis_ssh_from_bastion" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "redis_all" {
  security_group_id = aws_security_group.redis.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
