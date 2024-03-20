region = "ap-northeast-2"


##### network #####

cidr_block = "10.0.0.0/16"
name       = "my-vpc"

public_subnet_cidr_block_1 = "10.0.1.0/24"
public_subnet_cidr_block_2 = "10.0.2.0/24"
public_subnet_az_1 = "ap-northeast-2a"
public_subnet_az_2 = "ap-northeast-2c"



##### instance ######


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
