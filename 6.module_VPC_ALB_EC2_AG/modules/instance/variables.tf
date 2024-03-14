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

variable "vpc_id" {
    type        = string
}

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