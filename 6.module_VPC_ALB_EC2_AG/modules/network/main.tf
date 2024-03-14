# networking/networking.tf

# AWS VPC 리소스 정의
resource "aws_vpc" "example" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# 인터넷 게이트웨이용 라우팅 테이블 정의
resource "aws_route" "internet_gateway" {
  route_table_id         = aws_vpc.example.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.example.id
}

# public 서브넷 1
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = var.public_subnet_cidr_block_1
  availability_zone       = var.public_subnet_az_1
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public1-subnet"
  }
}

# public 서브넷 2
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = var.public_subnet_cidr_block_2
  availability_zone       = var.public_subnet_az_2
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public2-subnet"
  }
}


