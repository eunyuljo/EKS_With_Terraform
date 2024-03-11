provider "aws" {
    region = "ap-northeast-2"
}

# ## 0. EC2 Default 
resource "aws_instance" "example" {
    ami = "ami-04599ab1182cd7961"
    instance_type = "t2.micro"
}


# ## 1. Tag 
# resource "aws_instance" "example" {
#     ami = "ami-04599ab1182cd7961"
#     instance_type = "t2.micro"
#     tags = { 
#         Name = "terraform-example"
#         User = "eyjo@mz.co.kr"
#     }
#     root_block_device {
#     volume_size = "10"
#     volume_type = "gp2"
#     delete_on_termination = true
#     tags = {Name = "terraform-example"}
#     }
# }


# ## 2. ebs_block_device 추가
# resource "aws_instance" "example" {
#     ami = "ami-04599ab1182cd7961"
#     instance_type = "t2.micro"
#     tags = { 
#         Name = "terraform-example"
#         User = "eyjo@mz.co.kr"
#     }
#     root_block_device {
#     volume_size = "10"
#     volume_type = "gp2"
#     delete_on_termination = true
#     tags = {Name = "terraform-example"}
#     }
#     ebs_block_device {
#     device_name = "/dev/sdf"   # 마운트될 장치 이름
#     volume_type = "gp2"
#     volume_size = 20            # 볼륨 크기 (GB)
#     delete_on_termination = true
#     }
# }


# ## 3. ebs_block_device 
# resource "aws_instance" "example" {
#     ami = "ami-04599ab1182cd7961"
#     instance_type = "t2.micro"
#     tags = { 
#         Name = "terraform-example"
#         User = "eyjo@mz.co.kr"
#     }
    
#     root_block_device {
#     volume_size = "10"
#     volume_type = "gp2"
#     delete_on_termination = true
#     tags = {Name = "terraform-example"}
#     }
    
#     ebs_block_device {
#     device_name = "/dev/sdf"   # 마운트될 장치 이름
#     volume_type = "gp2"
#     volume_size = 20            # 볼륨 크기 (GB)
#     # volume_size = 30            # 볼륨 크기 (GB)
#     delete_on_termination = true
#     }
# }

# ## 4. aws_ebs_volume 별도 리소스로 관리 - attachment
# resource "aws_instance" "example" {
#     ami = "ami-04599ab1182cd7961"
#     instance_type = "t2.micro"
#     tags = { 
#         Name = "terraform-example"
#         User = "eyjo@mz.co.kr"
#     }
#     root_block_device {
#     volume_size = "10"
#     volume_type = "gp2"
#     delete_on_termination = true
#     tags = {Name = "terraform-example"}
#     }
# }
# resource "aws_ebs_volume" "additional_volume" {
#   availability_zone = aws_instance.example.availability_zone
#   #size              = 20 
#   size              = 30
#   type              = "gp2"
# }
# resource "aws_volume_attachment" "additional_attachment" {
#   device_name = "/dev/sdf"
#   instance_id = aws_instance.example.id
#   volume_id   = aws_ebs_volume.additional_volume.id
# }
