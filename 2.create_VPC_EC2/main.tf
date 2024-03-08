provider "aws" {
    region = "ap-northeast-2"
}

# prj
variable "project_name" { default = "example" } 
variable "environment" { default = "dev" }
variable "key_name" { default = "terraform" }

# VPC
variable "cidr_vpc"        { default = "10.0.0.0/16"}
variable "cidr_public1"    { default = "10.0.0.0/24" }
variable "cidr_public2"    { default = "10.0.1.0/24" }
variable "cidr_public3"    { default = "10.0.2.0/24" }
variable "cidr_public4"    { default = "10.0.3.0/24" }
variable "cidr_private1"   { default = "10.0.11.0/24" }
variable "cidr_private2"   { default = "10.0.12.0/24" }
variable "cidr_private3"   { default = "10.0.13.0/24" }
variable "cidr_private4"   { default = "10.0.14.0/24" }

# Bastion
variable "bastion_ami"           { default = "ami-04599ab1182cd7961" }
variable "bastion_instance_type" { default = "t3.micro" }
variable "bastion_key_name"      { default = "terraform" }
variable "bastion_volume_size"   { default = 8 }

# Private EC2
variable "Private_EC2_ami"           { default = "ami-04599ab1182cd7961" }
variable "Private_EC2_instance_type" { default = "t3.micro" }
variable "Private_EC2_key_name"      { default = "terraform" }
variable "Private_EC2_volume_size"   { default = 8 }


data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "systems_manager" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "cloudwatch_agent" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

# IAM Role
## bastion
resource "aws_iam_role" "bastion" {
  name               = "${var.project_name}-${var.environment}-bastion-iamrole"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = data.aws_iam_policy.systems_manager.arn
}

resource "aws_iam_role_policy_attachment" "bastion_cloudwatch" {
  role       = aws_iam_role.bastion.name
  policy_arn = data.aws_iam_policy.cloudwatch_agent.arn
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project_name}-${var.environment}-bastion-instanceprofile"
  role = aws_iam_role.bastion.name
}

## private_ec2
resource "aws_iam_role" "private_ec2" {
  name               = "${var.project_name}-${var.environment}-private_ec2-iamrole"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "private_ec2_ssm" {
  role       = aws_iam_role.private_ec2.name
  policy_arn = data.aws_iam_policy.systems_manager.arn
}

resource "aws_iam_role_policy_attachment" "private_ec2_cloudwatch" {
  role       = aws_iam_role.private_ec2.name
  policy_arn = data.aws_iam_policy.cloudwatch_agent.arn
}

resource "aws_iam_instance_profile" "private_ec2" {
  name = "${var.project_name}-${var.environment}-private_ec2-instanceprofile"
  role = aws_iam_role.private_ec2.name
}


# Key Pair 생성
resource "tls_private_key" "test_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "test_keypair" {
  key_name   = "test-keypair.pem"
  public_key = tls_private_key.test_key.public_key_openssh
} 

resource "local_file" "test_local" {
  filename        = "./keypair/test-keypair.pem"
  content         = tls_private_key.test_key.private_key_pem
  file_permission = "0600"
}



# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.cidr_vpc}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public1.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.project_name}-${var.environment}-natgw1"
  }
}

resource "aws_eip" "nat_gateway" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.project_name}-${var.environment}-natgw1-eip"
  }
}


# Default route table
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    Name = "${var.project_name}-${var.environment}-default-rtb"
  }
}

# Default security group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment}-default-sg"
  }
}

# Default network access list
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id

  tags = {
    Name = "${var.project_name}-${var.environment}-default-nacl"
  }
}

# Subnet
## public1-subnet
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-2a"
  cidr_block              = "${var.cidr_public1}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public1-subnet"
  }
}

## public2-subnet
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-2c"
  cidr_block              = "${var.cidr_public2}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public2-subnet"
  }
}

## public3-subnet
resource "aws_subnet" "public3" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-2a"
  cidr_block              = "${var.cidr_public3}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-public3-subnet"
  }
}

## public4-subnet
resource "aws_subnet" "public4" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-2c"
  cidr_block              = "${var.cidr_public4}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-public4-subnet"
  }
}

## private1-subnet
resource "aws_subnet" "private1" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-2a"
  cidr_block              = "${var.cidr_private1}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private1-subnet"
  }
}

## private2-subnet
resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-2c"
  cidr_block              = "${var.cidr_private2}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private2-subnet"
  }
}

## private3-subnet
resource "aws_subnet" "private3" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-2a"
  cidr_block              = "${var.cidr_private3}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private3-subnet"
  }
}

## private4-subnet
resource "aws_subnet" "private4" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-2c"
  cidr_block              = "${var.cidr_private4}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private4-subnet"
  }
}


# Route table
## public1~2
resource "aws_route_table" "public1" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment}-public1-rtb"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public1.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public1.id
}

resource "aws_route" "public1" {
  route_table_id         = aws_route_table.public1.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

## public3~4
resource "aws_route_table" "public3" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment}-public3-rtb"
  }
}

resource "aws_route_table_association" "public3" {
  subnet_id      = aws_subnet.public3.id
  route_table_id = aws_route_table.public3.id
}

resource "aws_route_table_association" "public4" {
  subnet_id      = aws_subnet.public4.id
  route_table_id = aws_route_table.public3.id
}

resource "aws_route" "public3" {
  route_table_id         = aws_route_table.public3.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

## private1~2
resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private1-rtb"
  }
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route" "private1" {
  route_table_id         = aws_route_table.private1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

## private3~4
resource "aws_route_table" "private3" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private3-rtb"
  }
}

resource "aws_route_table_association" "private3" {
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.private3.id
}

resource "aws_route_table_association" "private4" {
  subnet_id      = aws_subnet.private4.id
  route_table_id = aws_route_table.private3.id
}

# NACL
## public1~2
resource "aws_network_acl" "public1" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-nacl"
  }
}

## public3~4
resource "aws_network_acl" "public3" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.public3.id, aws_subnet.public4.id]

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public3-nacl"
  }
}

## private1~2
resource "aws_network_acl" "private1" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private1-nacl"
  }
}

## private3~4
resource "aws_network_acl" "private3" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.private3.id, aws_subnet.private4.id]

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private3-nacl"
  }
}

# Security Group
# Bastion EC2 SG
resource "aws_security_group" "bastion_ec2"{
    name        = "${var.project_name}-${var.environment}-bastion-sg"
    description = "for bastion ec2"
    vpc_id      = aws_vpc.vpc.id

    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
  }
}

# Private EC2 SG
resource "aws_security_group" "private_ec2"{
    name        = "${var.project_name}-${var.environment}-private-sg"
    description = "for private ec2"
    vpc_id      = aws_vpc.vpc.id

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-sg"
  }
}

resource "aws_security_group_rule" "private_ec2" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_ec2.id
  security_group_id        = aws_security_group.private_ec2.id
}

# EC2
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"
  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-eip"
  }
}

resource "aws_instance" "bastion" {
  ami = "${var.bastion_ami}"
  instance_type = "${var.bastion_instance_type}"
  vpc_security_group_ids = [aws_security_group.bastion_ec2.id]
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  subnet_id = aws_subnet.public1.id
  key_name = aws_key_pair.test_keypair.key_name
  disable_api_termination = true
  root_block_device {
    volume_size = "${var.bastion_volume_size}"
    volume_type = "gp3"
    delete_on_termination = true
    tags = {
      Name = "${var.project_name}-${var.environment}-bastion-ec2"
    }
  }
  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-ec2"
  }
}

# EC2
resource "aws_instance" "private-ec2" {
  ami = "${var.Private_EC2_ami}"
  instance_type = "${var.Private_EC2_instance_type}"
  vpc_security_group_ids = [aws_security_group.private_ec2.id]
  iam_instance_profile = aws_iam_instance_profile.private_ec2.name
  subnet_id = aws_subnet.private1.id
  associate_public_ip_address = false
  key_name = aws_key_pair.test_keypair.key_name
  disable_api_termination = true
  root_block_device {
    volume_size = "${var.Private_EC2_volume_size}"
    volume_type = "gp3"
    delete_on_termination = true
    tags = {
      Name = "${var.project_name}-${var.environment}-private-ec2"
    }
  }
  tags = {
    Name = "${var.project_name}-${var.environment}-private-ec2"
  }
}

