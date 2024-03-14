#### VPC ####

variable "region" {
  type        = string
  description = "Region"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "name" {
  type        = string
  description = "Name tag for the VPC"
}

variable "public_subnet_cidr_block_1" {
  description = "Public 서브넷 1의 CIDR 블록"
  type        = string
}

variable "public_subnet_cidr_block_2" {
  description = "Public 서브넷 2의 CIDR 블록"
  type        = string
}

variable "public_subnet_az_1" {
  description = "Public 서브넷 1의 가용 영역"
  type        = string
}

variable "public_subnet_az_2" {
  description = "Public 서브넷 2의 가용 영역"
  type        = string
}


##### instance ######


variable "instance_ami" {
  type        = string
  description = "AMI ID for the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the EC2 instance"
}

variable "instance_name" {
  type        = string
  description = "Name tag for the EC2 instance"
}

variable "instance_security_group_name" {
  type        = string
  description = "Name for the security group of the EC2 instance"
}

variable "instance_ingress_port" {
  type        = number
  description = "Ingress port for the security group of the EC2 instance"
}

variable "instance_ingress_protocol" {
  type        = string
  description = "Ingress protocol for the security group of the EC2 instance"
}

variable "instance_ingress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks for the ingress rule of the security group of the EC2 instance"
}

variable "instance_egress_from_port" {
  type        = number
  description = "Egress from port for the security group of the EC2 instance"
}

variable "instance_egress_to_port" {
  type        = number
  description = "Egress to port for the security group of the EC2 instance"
}

variable "instance_egress_protocol" {
  type        = string
  description = "Egress protocol for the security group of the EC2 instance"
}

variable "instance_egress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks for the egress rule of the security group of the EC2 instance"
}

