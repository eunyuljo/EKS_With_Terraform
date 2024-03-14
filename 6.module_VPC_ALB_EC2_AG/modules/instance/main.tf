# EC2, AutoScaling - User_Data 생성


# EC2 생성
resource "aws_instance" "example" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id              = aws_subnet.public1.id
  #user_data              = var.user_data_script

  tags = {
    Name = var.instance_name
  }
}

# EC2 보안그룹
resource "aws_security_group" "instance" {
  name = var.instance_security_group_name
  vpc_id = var.

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