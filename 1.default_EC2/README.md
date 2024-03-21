### init 

    Terraform 바이너리 파일에는 기본 기능은 포함되어 있지만 공급자에 대한 코드는 포함되어있지 않다.
    init 명령어는 테라폼 코드를 스캔하고, 어느 공급자가 필요한지를 확인하고 필요한 코드를 다운로드하도록 한다.
    기본적으로 공급자 코드는 테라폼의 .terraform 폴더에 다운로드된다.
    -init 명령어는 멱등성을 제공한다.
    -init 단계에서 각 provider version을 제한할 수 있다.
    
    
### .terraform.lock.hcl 파일 

    Terraform은 terraform init 명령을 실행할 때마다 종속성 잠금 파일을 자동으로 생성하거나 업데이트한다.
    terraform 프로젝트 내에서 일관성과 안정성을 유지하는 데 중요한 역할을 한다.
    
    참고: https://www.techielass.com/should-terraform-lock-hcl-be-included-in-the-gitignore-file/
    
### Provider

    https://registry.terraform.io/browse/providers
    
- 프로바이더 버전에 대한 이해
    
- 업그레이드 관련 주의 사항
    
    주의 사항 : 

    적절한 버전 제약 조건을 사용해서 인프라 변경이 발생할 수 있는 요건을 최소화 -> 종속성 잠금 파일을 이용해서 구성이 일관되게 적용되도록 한다.
    AWS 공급자의 최신 버전 ( >= ) 연산자를 사용하는 경우 구성과 호환되는 최소 공급자 버전을 지정한다.

    $ terraform init -upgrade
    
- CF, Route 53과 같이 특정 리전과 글로벌 영역의 리소스를 다루는 경우에 대해서 provider 적용 시 방안

