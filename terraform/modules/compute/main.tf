resource "aws_instance" "bastion" {
  ami                         = var.ubuntu_ami_id
  instance_type               = var.bastion_instance_type
  key_name                    = var.key_name
  subnet_id                   = values(var.public_subnet_ids)[0]
  vpc_security_group_ids      = [var.bastion_security_group_id]
  associate_public_ip_address = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-bastion"
    Role = "bastion"
  })
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = var.ubuntu_ami_id
  instance_type = var.app_instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_security_group_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-app"
      Role = "app"
    })
  }

  tags = var.common_tags
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-app-asg"
  max_size            = var.app_asg_max
  min_size            = var.app_asg_min
  desired_capacity    = var.app_asg_desired
  vpc_zone_identifier = values(var.app_subnet_ids)
  target_group_arns   = [var.app_target_group_arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }
}

# Redis instances: 1 master + 2 replicas
resource "aws_instance" "redis" {
  count                       = 3
  ami                         = var.ubuntu_ami_id
  instance_type               = var.redis_instance_type
  key_name                    = var.key_name
  subnet_id                   = values(var.middleware_subnet_ids)[count.index % length(var.middleware_subnet_ids)]
  vpc_security_group_ids      = [var.redis_security_group_id]
  associate_public_ip_address = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-redis-${count.index + 1}"
    Role = "redis"
    RedisRole = count.index == 0 ? "master" : "replica"
  })
}
