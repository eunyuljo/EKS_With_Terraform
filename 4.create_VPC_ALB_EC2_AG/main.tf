
# VPC 생성
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-vpc"
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
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public1-subnet"
  }
}

# public subnet 2
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public2-subnet"
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
  ami                    = "ami-04599ab1182cd7961"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id              = aws_subnet.public1.id
  user_data              = var.user_data_script

  tags = {
    Name = "terraform-example"
  }
}

# EC2 보안그룹
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# outbound 필요한 경우 반드시 명세
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB용 보안 그룹
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # outbound 필요한 경우 반드시 명세
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB 생성
resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
  tags = {
    Name = "terraform-example-alb"
  }
}

# TargetGroup 생성

resource "aws_lb_target_group" "example" {
  name     = "example-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.example.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    port                = "traffic-port"
  }

  tags = {
    Name = "terraform-example-target-group"
  }
}

# ALB Listner 생성

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

# ALB AG 생성

resource "aws_autoscaling_group" "example" {
  name                 = "example-autoscaling-group"
  max_size             = 3
  min_size             = 1
  desired_capacity     = 2
  health_check_type    = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier  = [aws_subnet.public1.id, aws_subnet.public2.id]
  launch_configuration = aws_launch_configuration.example.name
  
  tag {
    key                 = "Name"
    value               = "terraform-example-instance"
    propagate_at_launch = true
  }
}

# Configuration 설정

resource "aws_launch_configuration" "example" {
  name          = "example-launch-configuration"
  image_id      = "ami-04599ab1182cd7961"
  instance_type = "t2.micro"

  security_groups = [aws_security_group.instance.id]
  user_data     = var.user_data_script
  
  }
  
# EC2 TargetGroup 등록

resource "aws_lb_target_group_attachment" "ec2_target" {
  count            = aws_autoscaling_group.example.desired_capacity
  target_group_arn = aws_lb_target_group.example.arn
  target_id        = aws_instance.example.id  
  port             = 8080
}

# ASG EC2 TargetGroup 등록

resource "aws_autoscaling_attachment" "asg_attachment_target" {
  autoscaling_group_name = aws_autoscaling_group.example.id
  lb_target_group_arn    = aws_lb_target_group.example.id
}