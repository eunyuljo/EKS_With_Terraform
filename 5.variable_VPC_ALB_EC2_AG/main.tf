# VPC 생성
resource "aws_vpc" "example" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# IGW 생성
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# IGW 용 Routing Table 
resource "aws_route" "internet_gateway" {
  route_table_id         = aws_vpc.example.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.example.id
}

# public subnet 
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = var.public_subnet_cidr_block_1
  availability_zone       = var.public_subnet_az_1
  map_public_ip_on_launch = true
  
  tags = {
    Name = var.public_subnet_name_1
  }
}

# public subnet 2
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = var.public_subnet_cidr_block_2
  availability_zone       = var.public_subnet_az_2
  map_public_ip_on_launch = true
  
  tags = {
    Name = var.public_subnet_name_2
  }
}

# EC2, AutoScaling - User_Data 생성
variable "user_data_script" {
  type = string
  default = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
    yum install -y httpd mariadb-server
    sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf
    echo "Hello, World" > /root/test.txt
    systemctl start httpd
    systemctl enable httpd
    echo "Hello, World" > /var/www/html/index.html
  EOF
}

# EC2 생성
resource "aws_instance" "example" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id              = aws_subnet.public1.id
  user_data              = var.user_data_script

  tags = {
    Name = var.instance_name
  }
}

# EC2 보안그룹
resource "aws_security_group" "instance" {
  name = var.instance_security_group_name
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = var.instance_ingress_port
    to_port     = var.instance_ingress_port
    protocol    = var.instance_ingress_protocol
    cidr_blocks = var.instance_ingress_cidr_blocks
  }

  egress {
    from_port   = var.instance_egress_from_port
    to_port     = var.instance_egress_to_port
    protocol    = var.instance_egress_protocol
    cidr_blocks = var.instance_egress_cidr_blocks
  }
}

# ALB용 보안 그룹
resource "aws_security_group" "alb" {
  name = var.alb_security_group_name
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = var.alb_ingress_from_port
    to_port     = var.alb_ingress_to_port
    protocol    = var.alb_ingress_protocol
    cidr_blocks = var.alb_ingress_cidr_blocks
  }

  egress {
    from_port   = var.alb_egress_from_port
    to_port     = var.alb_egress_to_port
    protocol    = var.alb_egress_protocol
    cidr_blocks = var.alb_egress_cidr_blocks
  }
}

# ALB 생성
resource "aws_lb" "example" {
  name               = var.alb_name
  internal           = var.alb_internal
  load_balancer_type = var.alb_type
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.alb_subnets
  tags = {
    Name = var.alb_name
  }
}

# TargetGroup 생성

resource "aws_lb_target_group" "example" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = aws_vpc.example.id

  health_check {
    path                = var.target_group_health_check_path
    interval            = var.target_group_health_check_interval
    timeout             = var.target_group_health_check_timeout
    healthy_threshold   = var.target_group_health_check_healthy_threshold
    unhealthy_threshold = var.target_group_health_check_unhealthy_threshold
    port                = var.target_group_health_check_port
  }

  tags = {
    Name = var.target_group_name
  }
}

# ALB Listner 생성

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = var.listener_default_action_type
    target_group_arn = aws_lb_target_group.example.arn
  }
}

# ALB AG 생성

resource "aws_autoscaling_group" "example" {
  name                 = var.asg_name
  max_size             = var.asg_max_size
  min_size             = var.asg_min_size
  desired_capacity     = var.asg_desired_capacity
  health_check_type    = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period
  vpc_zone_identifier  = var.asg_vpc_zone_identifiers
  launch_configuration = aws_launch_configuration.example.name
  
  tag {
    key                 = var.asg_tag_key
    value               = var.asg_tag_value
    propagate_at_launch = var.asg_tag_propagate_at_launch
  }
}

# Configuration 설정

resource "aws_launch_configuration" "example" {
  name          = var.launch_configuration_name
  image_id      = var.launch_configuration_image_id
  instance_type = var.launch_configuration_instance_type

  security_groups = [aws_security_group.instance.id]
  user_data     = var.user_data_script
}

# EC2 TargetGroup 등록

resource "aws_lb_target_group_attachment" "ec2_target" {
  count            = aws_autoscaling_group.example.desired_capacity
  target_group_arn = aws_lb_target_group.example.arn
  target_id        = aws_instance.example.*.id  
  port             = var.target_group_port
}

# ASG EC2 TargetGroup 등록

resource "aws_autoscaling_attachment" "asg_attachment_target" {
  autoscaling_group_name = aws_autoscaling_group.example.id
  lb_target_group_arn    = aws_lb_target_group.example.id
}