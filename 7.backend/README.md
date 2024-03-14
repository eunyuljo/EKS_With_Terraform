---

# 테라폼 상태관리

테라폼을 실행할 때마다 생성한 인프라에 대한 정보를 기록해야한다.

이 구성 파일은 테라폼 리소스가 실제로 어떻게 매핑되는지를 JSON 형태로 포함되어있다.



    provider "aws" {
    region = "ap-northeast-2"
    shared_credentials_file = "$HOME/.aws/credentials"
    profile = "eyjo"
    }

    resource "aws_instance" "example" {
        ami = "ami-00d806d1ddaa94d5f"
        instance_type = "t2.micro"
    }
    
이 형태로 작성하고 apply 하여 인프라에 반영하게 되면아래와 같이 저장된다.

    {
      "version": 4,
      "terraform_version": "1.2.2",
      "serial": 1,
      "lineage": "3a1a7b4c-b1a6-931e-c901-e6943740b846",
      "outputs": {},
      "resources": [
        {
          "mode": "managed",
          "type": "aws_instance",
          "name": "example",
          "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
          "instances": [
            {
              "schema_version": 1,
              "attributes": {
                "ami": "ami-00d806d1ddaa94d5f",
                "arn": "arn:aws:ec2:ap-northeast-2:797364105022:instance/i-034101e6a5044ba13",
                "associate_public_ip_address": true,
                "availability_zone": "ap-northeast-2c",
                "capacity_reservation_specification": [
                  {
                    "capacity_reservation_preference": "open",
                    "capacity_reservation_target": []
                  }
                ],
                "cpu_core_count": 1,
                "cpu_threads_per_core": 1,
                "credit_specification": [
                  {
                    "cpu_credits": "standard"
                  }
                ],
                "disable_api_termination": false,
                "ebs_block_device": [],
                "ebs_optimized": false,
                "enclave_options": [
                  {
                    "enabled": false
                  }
                ],
                "ephemeral_block_device": [],
                "get_password_data": false,
                "hibernation": false,
                "host_id": null,
                "iam_instance_profile": "",
                "id": "i-034101e6a5044ba13",
                "instance_initiated_shutdown_behavior": "stop",
                "instance_state": "running",
                "instance_type": "t2.micro",
                "ipv6_address_count": 0,
                "ipv6_addresses": [],
                "key_name": "",
                "launch_template": [],
                "maintenance_options": [
                  {
                    "auto_recovery": "default"
                  }
                ],
                "metadata_options": [
                  {
                    "http_endpoint": "enabled",
                    "http_put_response_hop_limit": 1,
                    "http_tokens": "optional",
                    "instance_metadata_tags": "disabled"
                  }
                ],
                "monitoring": false,
                "network_interface": [],
                "outpost_arn": "",
                "password_data": "",
                "placement_group": "",
                "placement_partition_number": null,
                "primary_network_interface_id": "eni-06798128e006e9138",
                "private_dns": "ip-172-31-28-136.ap-northeast-2.compute.internal",
                "private_ip": "172.31.28.136",
                "public_dns": "ec2-54-180-119-237.ap-northeast-2.compute.amazonaws.com",
                "public_ip": "54.180.119.237",
                "root_block_device": [
                  {
                    "delete_on_termination": true,
                    "device_name": "/dev/sda1",
                    "encrypted": false,
                    "iops": 100,
                    "kms_key_id": "",
                    "tags": {},
                    "throughput": 0,
                    "volume_id": "vol-0b40829bfc2ceb94f",
                    "volume_size": 8,
                    "volume_type": "gp2"
                  }
                ],
                "secondary_private_ips": [],
                "security_groups": [
                  "default"
                ],
                "source_dest_check": true,
                "subnet_id": "subnet-0abd66fc2f30aba3d",
                "tags": null,
                "tags_all": {},
                "tenancy": "default",
                "timeouts": null,
                "user_data": null,
                "user_data_base64": null,
                "user_data_replace_on_change": false,
                "volume_tags": null,
                "vpc_security_group_ids": [
                  "sg-086424629ece025cc"
                ]
              },
              "sensitive_attributes": [],
              "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjo2MDAwMDAwMDAwMDAsImRlbGV0ZSI6MTIwMDAwMDAwMDAwMCwidXBkYXRlIjo2MDAwMDAwMDAwMDB9LCJzY2hlbWFfdmVyc2lvbiI6IjEifQ=="
            }
          ]
        }
      ]
    }
    
이 JSON 형식을 통해 타입이 aws_instance 이고 이름이 example인 리소스가  i-034101e6a5044ba13 인스턴스 ID를 갖고 있음을 기록한다.
이 기록을 통해 테라폼을 실행할 때마다 이 상태 파일을 가져와서 테라폼 구성을 비교하여 어느 변경 사항을 적용해야 하는지 결정하는 것이다.


---

■ tfstate 관리

단일 terraform.tfstate 을 작성하는 경우, 팀 단위로 사용할 경우 문제가 발생할 수 있다.


1. 상태파일을 저장하는 공유 스토리지 

    테라폼을 사용하여 인프라를 업데이트하려면 각 팀원이 동일한 테라폼 상태 파일에 액세스해야 한다.
    ( 상태 파일을 공유 위치에 저장해야 한다. ) 

2. 상태 파일 잠금

    상태 데이터가 공유되자마자 잠금 이슈가 있다.
    잠금 기능이 없다면 충돌을 일으키며, race condition 에 처하면 데이터가 손실될 가능성이 있다.

3. 상태 파일 격리

    인프라를 변경할 때는 다른 환경을 격리하는 것이 가장 좋다.
    테스트 또는 스테이징 환경을 변경할 때 실수로 프로덕션 환경이 중단되는 경우가 없을지 확인해야 한다.


■ tfstate의 버전 

팀원이 파일에 공통으로 액세스할 수 있게 하는 가장 일반적인 방법은 파일을 깃과 같은 버전 관리 시스템 두는 것이다.
그러나, 테라폼 상태 파일을 버전 관리 시스템에 둘 경우 다음과 같은 문제가 있을 수 있다.

1. 수동 오류 

    테라폼을 실행하기 전에 최신 변경 사항을 가져오거나 실행하고 나서 푸시하는 것을 잊기 쉽다.
    팀의 누군가가 이전 버전의 상태 파일로 실행하려고 할 경우 실수로 이전 버전으로 롤백하거나 
    이전에 배포된 인프라를 복제하는 문제가  있을 수 있다.

2. 잠금

    대부분 버전 관리 시스템은 여러 명의 팀 구성원이 동시에 하나의 상태 파일에 terraform apply 명령을 
    실행하지 못하게 하는 잠금 기능을 제공하지 않는다.

3. 시크릿

    테라폼 상태 파일은 모두 평문으로 저장되는데 특정 데이터가 중요한 데이터라면 문제가 발생할 수 있다.
    aws_db_instance 리소스를 사용하여 데이터베이스에 대한 접속 정보가 있는 경우가 있다.
    
■ 원격 백엔드 대상 선정 ( S3 ) 


S3를 활용하면 다음과 같은 장점이 있다.
            
    1. 관리형 서비스
    2. 내부성과 가용성 보장
    3. 암호화 지원 
    4. 아마존 DynamoDB 를 통한 잠금 기능 지원
    5. 버전 관리 지원, 상태 저장 및 롤백 
    6. 저렴한 비용