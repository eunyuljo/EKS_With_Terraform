### init 

    Terraform 바이너리 파일에는 기본 기능은 포함되어잇지만 공급자에 대한 코드는 포함되어있지 않다.
    init 명령어는 테라폼 코드를 스캔하고, 어느 공급자가 필요한지를 확인하고 필요한 코드를 다운로드하도록 한다.
    기본적으로 공급자 코드는 테라폼의 .terraform 폴더에 다운로드된다.
    ( init 명령어는 멱등성을 제공한다. )
    
### Provider

    https://registry.terraform.io/browse/providers
    