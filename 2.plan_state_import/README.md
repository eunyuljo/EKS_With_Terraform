
## 목표

1. 문법에 대한 간단한 이해와 테라폼 특성을 확인해본다.

    - 순차적으로 필요한 기능을 활성화 시켜본다.
 
    
2. 리소스에 대한 속성 이해와 Plan 결과 확인해본다.
 
    - apply 동작 전 plan 동작 수행을 체크한다.
    
    
3. terraform state와 terraform import 를 실습해본다.
    
    - 생성된 인스턴스에 추가로 붙은 EBS 의 볼륨을 수정해본다.
    
    - terraform import aws_instance.example < instance-id > 
        - terraform state rm aws_instance.example
    
    - 공식문서 내용을 참고해보자
		https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#ebs-ephemeral-and-root-block-devices