provider "aws" {
    region = "ap-northeast-2"
}

resource "aws_instance" "exmaple" {
    ami = "ami-04599ab1182cd7961"
    instance_type = "t2.micro"
    iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name
}


# 1.신뢰정책 생성
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 2.ssm 권한 확인
data "aws_iam_policy" "systems_manager" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 3.역할 생성
resource "aws_iam_role" "ssm_for_ec2" {
  name               = "ec2_ssmanager"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# 4. 역할에 systems_manager 권한 attach

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ssm_for_ec2.name
  policy_arn = data.aws_iam_policy.systems_manager.arn
}

# 5. 인스턴스 프로파일 설정 추가
resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "ec2_ssm"
  role = aws_iam_role.ssm_for_ec2.name
}

# 6. 인스턴스에 인스턴스 프로파일 연결

# provider "aws" {
#     region = "ap-northeast-2"
# }

# resource "aws_instance" "exmaple" {
#     ami = "ami-04599ab1182cd7961"
#     instance_type = "t2.micro"
#     -> ( 추가 ) iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name
# }