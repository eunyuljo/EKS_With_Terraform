provider "aws" {
    region = var.region
}

# VPC 모듈 정의
module "network" {
  source = "./modules/network"

  # 모듈에 필요한 입력 변수 설정
  cidr_block = var.cidr_block
  name       = var.name
  public_subnet_cidr_block_1 = var.public_subnet_cidr_block_1
  public_subnet_cidr_block_2 = var.public_subnet_cidr_block_2
  public_subnet_az_1 = var.public_subnet_az_1
  public_subnet_az_2 = var.public_subnet_az_2
}


module "instance" {
    source = "./modules/instance"
    vpc_id                  = module.network.example.vpc_id
    instance_ami            = var.instance_ami
    instance_type           = var.instance_type
    instance_name           = var.instance_name
    instance_security_group_name = var.instance_security_group_name
    instance_ingress_port   = var.instance_ingress_port
    instance_ingress_protocol = var.instance_ingress_protocol
    instance_ingress_cidr_blocks = var.instance_ingress_cidr_blocks
    instance_egress_from_port = var.instance_egress_from_port
    instance_egress_to_port   = var.instance_egress_to_port
    instance_egress_protocol = var.instance_egress_protocol
    instance_egress_cidr_blocks = var.instance_egress_cidr_blocks
}