
variable "cidr_block" {
  description = "VPC의 CIDR 블록"
  type        = string
}

variable "name" {
  description = "VPC의 이름"
  type        = string
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