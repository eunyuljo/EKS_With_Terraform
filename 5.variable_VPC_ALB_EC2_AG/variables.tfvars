# variables.tfvars

# VPC 변수
vpc_cidr_block = "10.0.0.0/16"
vpc_name = "terraform-vpc"

# Public Subnet 1 변수
public_subnet_cidr_block_1 = "10.0.1.0/24"
public_subnet_az_1 = "ap-northeast-2a"
public_subnet_name_1 = "public1-subnet"

# Public Subnet 2 변수
public_subnet_cidr_block_2 = "10.0.2.0/24"
public_subnet_az_2 = "ap-northeast-2c"
public_subnet_name_2 = "public2-subnet"

# EC2 인스턴스 변수
instance_ami = "ami-04599ab1182cd7961"
instance_type = "t2.micro"
instance_name = "terraform-example-instance"
instance_security_group_name = "terraform-example-instance"
instance_ingress_port = 8080
instance_ingress_protocol = "tcp"
instance_ingress_cidr_blocks = ["0.0.0.0/0"]
instance_egress_from_port = 0
instance_egress_to_port = 0
instance_egress_protocol = "-1"
instance_egress_cidr_blocks = ["0.0.0.0/0"]

# ALB 변수
alb_name = "example-alb"
alb_internal = false
alb_type = "application"
alb_subnets = [aws_subnet.public1.id, aws_subnet.public2.id]
alb_security_group_name = "terraform-example-alb"
alb_ingress_from_port = 80
alb_ingress_to_port = 80
alb_ingress_protocol = "tcp"
alb_ingress_cidr_blocks = ["0.0.0.0/0"]
alb_egress_from_port = 0
alb_egress_to_port = 0
alb_egress_protocol = "-1"
alb_egress_cidr_blocks = ["0.0.0.0/0"]

# Target Group 변수
target_group_name = "example-target-group"
target_group_port = 8080
target_group_protocol = "HTTP"
target_group_health_check_path = "/"
target_group_health_check_interval = 30
target_group_health_check_timeout = 5
target_group_health_check_healthy_threshold = 2
target_group_health_check_unhealthy_threshold = 2
target_group_health_check_port = "traffic-port"

# Listener 변수
listener_port = 80
listener_protocol = "HTTP"
listener_default_action_type = "forward"

# ASG 변수
asg_name = "example-autoscaling-group"
asg_max_size = 3
asg_min_size = 1
asg_desired_capacity = 2
asg_health_check_type = "ELB"
asg_health_check_grace_period = 300
asg_vpc_zone_identifiers = [aws_subnet.public1.id, aws_subnet.public2.id]
asg_tag_key = "Name"
asg_tag_value = "terraform-example-instance"
asg_tag_propagate_at_launch = true

# Launch Configuration 변수
launch_configuration_name = "example-launch-configuration"
launch_configuration_image_id = "ami-04599ab1182cd7961"
launch_configuration_instance_type = "t2.micro"