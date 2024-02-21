{"changed":true,"filter":false,"title":"main.tf","tooltip":"/terraform-aws-eks/examples/complete/main.tf","value":"provider \"aws\" {\n  region = local.region\n}\n\nprovider \"kubernetes\" {\n  host                   = module.eks.cluster_endpoint\n  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)\n\n  exec {\n    api_version = \"client.authentication.k8s.io/v1beta1\"\n    command     = \"aws\"\n    # This requires the awscli to be installed locally where Terraform is executed\n    args = [\"eks\", \"get-token\", \"--cluster-name\", module.eks.cluster_name]\n  }\n}\n\ndata \"aws_availability_zones\" \"available\" {}\ndata \"aws_caller_identity\" \"current\" {}\n\nlocals {\n  name   = \"terraform-${replace(basename(path.cwd), \"_\", \"-\")}\"\n  region = \"ap-northeast-2\"\n\n  vpc_cidr = \"10.0.0.0/16\"\n  azs      = slice(data.aws_availability_zones.available.names, 0, 3)\n\n  tags = {\n    Example    = local.name\n    GithubRepo = \"terraform-aws-eks\"\n    GithubOrg  = \"terraform-aws-modules\"\n  }\n}\n\n################################################################################\n# EKS Module\n################################################################################\n\nmodule \"eks\" {\n  source = \"../..\"\n\n  cluster_name                   = local.name\n  cluster_endpoint_public_access = true\n\n  cluster_addons = {\n    coredns = {\n      preserve    = true\n      most_recent = true\n\n      timeouts = {\n        create = \"25m\"\n        delete = \"10m\"\n      }\n    }\n    kube-proxy = {\n      most_recent = true\n    }\n    vpc-cni = {\n      most_recent = true\n    }\n  }\n\n  # External encryption key\n  create_kms_key = false\n  cluster_encryption_config = {\n    resources        = [\"secrets\"]\n    provider_key_arn = module.kms.key_arn\n  }\n\n  iam_role_additional_policies = {\n    additional = aws_iam_policy.additional.arn\n  }\n\n  vpc_id                   = module.vpc.vpc_id\n  subnet_ids               = module.vpc.private_subnets\n  control_plane_subnet_ids = module.vpc.intra_subnets\n\n  # Extend cluster security group rules\n  cluster_security_group_additional_rules = {\n    ingress_nodes_ephemeral_ports_tcp = {\n      description                = \"Nodes on ephemeral ports\"\n      protocol                   = \"tcp\"\n      from_port                  = 1025\n      to_port                    = 65535\n      type                       = \"ingress\"\n      source_node_security_group = true\n    }\n    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319\n    ingress_source_security_group_id = {\n      description              = \"Ingress from another computed security group\"\n      protocol                 = \"tcp\"\n      from_port                = 22\n      to_port                  = 22\n      type                     = \"ingress\"\n      source_security_group_id = aws_security_group.additional.id\n    }\n  }\n\n  # Extend node-to-node security group rules\n  node_security_group_additional_rules = {\n    ingress_self_all = {\n      description = \"Node to node all ports/protocols\"\n      protocol    = \"-1\"\n      from_port   = 0\n      to_port     = 0\n      type        = \"ingress\"\n      self        = true\n    }\n    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319\n    ingress_source_security_group_id = {\n      description              = \"Ingress from another computed security group\"\n      protocol                 = \"tcp\"\n      from_port                = 22\n      to_port                  = 22\n      type                     = \"ingress\"\n      source_security_group_id = aws_security_group.additional.id\n    }\n  }\n\n  # Self Managed Node Group(s)\n  self_managed_node_group_defaults = {\n    vpc_security_group_ids = [aws_security_group.additional.id]\n    iam_role_additional_policies = {\n      additional = aws_iam_policy.additional.arn\n    }\n\n    instance_refresh = {\n      strategy = \"Rolling\"\n      preferences = {\n        min_healthy_percentage = 66\n      }\n    }\n  }\n\n  self_managed_node_groups = {\n    spot = {\n      instance_type = \"m5.large\"\n      instance_market_options = {\n        market_type = \"spot\"\n      }\n\n      pre_bootstrap_user_data = <<-EOT\n        echo \"foo\"\n        export FOO=bar\n      EOT\n\n      bootstrap_extra_args = \"--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'\"\n\n      post_bootstrap_user_data = <<-EOT\n        cd /tmp\n        sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm\n        sudo systemctl enable amazon-ssm-agent\n        sudo systemctl start amazon-ssm-agent\n      EOT\n    }\n  }\n\n  # EKS Managed Node Group(s)\n  eks_managed_node_group_defaults = {\n    ami_type       = \"AL2_x86_64\"\n    instance_types = [\"m6i.large\", \"m5.large\", \"m5n.large\", \"m5zn.large\"]\n\n    attach_cluster_primary_security_group = true\n    vpc_security_group_ids                = [aws_security_group.additional.id]\n    iam_role_additional_policies = {\n      additional = aws_iam_policy.additional.arn\n    }\n  }\n\n  eks_managed_node_groups = {\n    blue = {}\n    green = {\n      min_size     = 1\n      max_size     = 10\n      desired_size = 1\n\n      instance_types = [\"t3.large\"]\n      capacity_type  = \"SPOT\"\n      labels = {\n        Environment = \"test\"\n        GithubRepo  = \"terraform-aws-eks\"\n        GithubOrg   = \"terraform-aws-modules\"\n      }\n\n      taints = {\n        dedicated = {\n          key    = \"dedicated\"\n          value  = \"gpuGroup\"\n          effect = \"NO_SCHEDULE\"\n        }\n      }\n\n      block_device_mappings = {\n        xvda = {\n          device_name = \"/dev/xvda\"\n          ebs = {\n            volume_size           = 100\n            volume_type           = \"gp3\"\n            iops                  = 3000\n            throughput            = 150\n            delete_on_termination = true\n          }\n        }\n      }\n\n      update_config = {\n        max_unavailable_percentage = 33 # or set `max_unavailable`\n      }\n\n      tags = {\n        ExtraTag = \"example\"\n      }\n    }\n  }\n\n  # Fargate Profile(s)\n  fargate_profiles = {\n    default = {\n      name = \"default\"\n      selectors = [\n        {\n          namespace = \"kube-system\"\n          labels = {\n            k8s-app = \"kube-dns\"\n          }\n        },\n        {\n          namespace = \"default\"\n        }\n      ]\n\n      tags = {\n        Owner = \"test\"\n      }\n\n      timeouts = {\n        create = \"20m\"\n        delete = \"20m\"\n      }\n    }\n  }\n\n  # Create a new cluster where both an identity provider and Fargate profile is created\n  # will result in conflicts since only one can take place at a time\n  # # OIDC Identity provider\n  # cluster_identity_providers = {\n  #   sts = {\n  #     client_id = \"sts.amazonaws.com\"\n  #   }\n  # }\n\n  # aws-auth configmap\n  manage_aws_auth_configmap = true\n\n  aws_auth_node_iam_role_arns_non_windows = [\n    module.eks_managed_node_group.iam_role_arn,\n    module.self_managed_node_group.iam_role_arn,\n  ]\n  aws_auth_fargate_profile_pod_execution_role_arns = [\n    module.fargate_profile.fargate_profile_pod_execution_role_arn\n  ]\n\n  aws_auth_roles = [\n    {\n      rolearn  = module.eks_managed_node_group.iam_role_arn\n      username = \"system:node:{{EC2PrivateDNSName}}\"\n      groups = [\n        \"system:bootstrappers\",\n        \"system:nodes\",\n      ]\n    },\n    {\n      rolearn  = module.self_managed_node_group.iam_role_arn\n      username = \"system:node:{{EC2PrivateDNSName}}\"\n      groups = [\n        \"system:bootstrappers\",\n        \"system:nodes\",\n      ]\n    },\n    {\n      rolearn  = module.fargate_profile.fargate_profile_pod_execution_role_arn\n      username = \"system:node:{{SessionName}}\"\n      groups = [\n        \"system:bootstrappers\",\n        \"system:nodes\",\n        \"system:node-proxier\",\n      ]\n    }\n  ]\n\n  aws_auth_users = [\n    {\n      userarn  = \"arn:aws:iam::66666666666:user/user1\"\n      username = \"user1\"\n      groups   = [\"system:masters\"]\n    },\n    {\n      userarn  = \"arn:aws:iam::66666666666:user/user2\"\n      username = \"user2\"\n      groups   = [\"system:masters\"]\n    },\n  ]\n\n  aws_auth_accounts = [\n    \"777777777777\",\n    \"888888888888\",\n  ]\n\n  tags = local.tags\n}\n\n################################################################################\n# Sub-Module Usage on Existing/Separate Cluster\n################################################################################\n\nmodule \"eks_managed_node_group\" {\n  source = \"../../modules/eks-managed-node-group\"\n\n  name            = \"separate-eks-mng\"\n  cluster_name    = module.eks.cluster_name\n  cluster_version = module.eks.cluster_version\n\n  subnet_ids                        = module.vpc.private_subnets\n  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id\n  vpc_security_group_ids = [\n    module.eks.cluster_security_group_id,\n  ]\n\n  ami_type = \"BOTTLEROCKET_x86_64\"\n  platform = \"bottlerocket\"\n\n  # this will get added to what AWS provides\n  bootstrap_extra_args = <<-EOT\n    # extra args added\n    [settings.kernel]\n    lockdown = \"integrity\"\n\n    [settings.kubernetes.node-labels]\n    \"label1\" = \"foo\"\n    \"label2\" = \"bar\"\n  EOT\n\n  tags = merge(local.tags, { Separate = \"eks-managed-node-group\" })\n}\n\nmodule \"self_managed_node_group\" {\n  source = \"../../modules/self-managed-node-group\"\n\n  name                = \"separate-self-mng\"\n  cluster_name        = module.eks.cluster_name\n  cluster_version     = module.eks.cluster_version\n  cluster_endpoint    = module.eks.cluster_endpoint\n  cluster_auth_base64 = module.eks.cluster_certificate_authority_data\n\n  instance_type = \"m5.large\"\n\n  subnet_ids = module.vpc.private_subnets\n  vpc_security_group_ids = [\n    module.eks.cluster_primary_security_group_id,\n    module.eks.cluster_security_group_id,\n  ]\n\n  tags = merge(local.tags, { Separate = \"self-managed-node-group\" })\n}\n\nmodule \"fargate_profile\" {\n  source = \"../../modules/fargate-profile\"\n\n  name         = \"separate-fargate-profile\"\n  cluster_name = module.eks.cluster_name\n\n  subnet_ids = module.vpc.private_subnets\n  selectors = [{\n    namespace = \"kube-system\"\n  }]\n\n  tags = merge(local.tags, { Separate = \"fargate-profile\" })\n}\n\n################################################################################\n# Disabled creation\n################################################################################\n\nmodule \"disabled_eks\" {\n  source = \"../..\"\n\n  create = false\n}\n\nmodule \"disabled_fargate_profile\" {\n  source = \"../../modules/fargate-profile\"\n\n  create = false\n}\n\nmodule \"disabled_eks_managed_node_group\" {\n  source = \"../../modules/eks-managed-node-group\"\n\n  create = false\n}\n\nmodule \"disabled_self_managed_node_group\" {\n  source = \"../../modules/self-managed-node-group\"\n\n  create = false\n}\n\n################################################################################\n# Supporting resources\n################################################################################\n\nmodule \"vpc\" {\n  source  = \"terraform-aws-modules/vpc/aws\"\n  version = \"~> 4.0\"\n\n  name = local.name\n  cidr = local.vpc_cidr\n\n  azs             = local.azs\n  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]\n  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]\n  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]\n\n  enable_nat_gateway = true\n  single_nat_gateway = true\n\n  public_subnet_tags = {\n    \"kubernetes.io/role/elb\" = 1\n  }\n\n  private_subnet_tags = {\n    \"kubernetes.io/role/internal-elb\" = 1\n  }\n\n  tags = local.tags\n}\n\nresource \"aws_security_group\" \"additional\" {\n  name_prefix = \"${local.name}-additional\"\n  vpc_id      = module.vpc.vpc_id\n\n  ingress {\n    from_port = 22\n    to_port   = 22\n    protocol  = \"tcp\"\n    cidr_blocks = [\n      \"10.0.0.0/8\",\n      \"172.16.0.0/12\",\n      \"192.168.0.0/16\",\n    ]\n  }\n\n  tags = merge(local.tags, { Name = \"${local.name}-additional\" })\n}\n\nresource \"aws_iam_policy\" \"additional\" {\n  name = \"${local.name}-additional\"\n\n  policy = jsonencode({\n    Version = \"2012-10-17\"\n    Statement = [\n      {\n        Action = [\n          \"ec2:Describe*\",\n        ]\n        Effect   = \"Allow\"\n        Resource = \"*\"\n      },\n    ]\n  })\n}\n\nmodule \"kms\" {\n  source  = \"terraform-aws-modules/kms/aws\"\n  version = \"~> 1.5\"\n\n  aliases               = [\"eks/${local.name}\"]\n  description           = \"${local.name} cluster encryption key\"\n  enable_default_policy = true\n  key_owners            = [data.aws_caller_identity.current.arn]\n\n  tags = local.tags\n}\n","undoManager":{"mark":-2,"position":7,"stack":[[{"start":{"row":21,"column":20},"end":{"row":21,"column":21},"action":"remove","lines":["1"],"id":2},{"start":{"row":21,"column":19},"end":{"row":21,"column":20},"action":"remove","lines":["-"]},{"start":{"row":21,"column":18},"end":{"row":21,"column":19},"action":"remove","lines":["t"]},{"start":{"row":21,"column":17},"end":{"row":21,"column":18},"action":"remove","lines":["s"]},{"start":{"row":21,"column":16},"end":{"row":21,"column":17},"action":"remove","lines":["e"]},{"start":{"row":21,"column":15},"end":{"row":21,"column":16},"action":"remove","lines":["w"]},{"start":{"row":21,"column":14},"end":{"row":21,"column":15},"action":"remove","lines":["-"]},{"start":{"row":21,"column":13},"end":{"row":21,"column":14},"action":"remove","lines":["u"]},{"start":{"row":21,"column":12},"end":{"row":21,"column":13},"action":"remove","lines":["e"]}],[{"start":{"row":21,"column":12},"end":{"row":21,"column":13},"action":"insert","lines":["a"],"id":3},{"start":{"row":21,"column":13},"end":{"row":21,"column":14},"action":"insert","lines":["p"]},{"start":{"row":21,"column":14},"end":{"row":21,"column":15},"action":"insert","lines":["-"]},{"start":{"row":21,"column":15},"end":{"row":21,"column":16},"action":"insert","lines":["n"]},{"start":{"row":21,"column":16},"end":{"row":21,"column":17},"action":"insert","lines":["o"]},{"start":{"row":21,"column":17},"end":{"row":21,"column":18},"action":"insert","lines":["r"]},{"start":{"row":21,"column":18},"end":{"row":21,"column":19},"action":"insert","lines":["h"]},{"start":{"row":21,"column":19},"end":{"row":21,"column":20},"action":"insert","lines":["t"]}],[{"start":{"row":21,"column":19},"end":{"row":21,"column":20},"action":"remove","lines":["t"],"id":4},{"start":{"row":21,"column":18},"end":{"row":21,"column":19},"action":"remove","lines":["h"]},{"start":{"row":21,"column":17},"end":{"row":21,"column":18},"action":"remove","lines":["r"]}],[{"start":{"row":21,"column":17},"end":{"row":21,"column":18},"action":"insert","lines":["r"],"id":5},{"start":{"row":21,"column":18},"end":{"row":21,"column":19},"action":"insert","lines":["t"]},{"start":{"row":21,"column":19},"end":{"row":21,"column":20},"action":"insert","lines":["h"]},{"start":{"row":21,"column":20},"end":{"row":21,"column":21},"action":"insert","lines":["e"]},{"start":{"row":21,"column":21},"end":{"row":21,"column":22},"action":"insert","lines":["a"]},{"start":{"row":21,"column":22},"end":{"row":21,"column":23},"action":"insert","lines":["s"]},{"start":{"row":21,"column":23},"end":{"row":21,"column":24},"action":"insert","lines":["t"]},{"start":{"row":21,"column":24},"end":{"row":21,"column":25},"action":"insert","lines":["-"]},{"start":{"row":21,"column":25},"end":{"row":21,"column":26},"action":"insert","lines":["2"]}],[{"start":{"row":20,"column":13},"end":{"row":20,"column":14},"action":"remove","lines":["x"],"id":6},{"start":{"row":20,"column":12},"end":{"row":20,"column":13},"action":"remove","lines":["e"]}],[{"start":{"row":20,"column":12},"end":{"row":20,"column":13},"action":"insert","lines":["t"],"id":7},{"start":{"row":20,"column":13},"end":{"row":20,"column":14},"action":"insert","lines":["e"]},{"start":{"row":20,"column":14},"end":{"row":20,"column":15},"action":"insert","lines":["r"]},{"start":{"row":20,"column":15},"end":{"row":20,"column":16},"action":"insert","lines":["r"]},{"start":{"row":20,"column":16},"end":{"row":20,"column":17},"action":"insert","lines":["a"]},{"start":{"row":20,"column":17},"end":{"row":20,"column":18},"action":"insert","lines":["f"]},{"start":{"row":20,"column":18},"end":{"row":20,"column":19},"action":"insert","lines":["o"]},{"start":{"row":20,"column":19},"end":{"row":20,"column":20},"action":"insert","lines":["r"]},{"start":{"row":20,"column":20},"end":{"row":20,"column":21},"action":"insert","lines":["m"]}],[{"start":{"row":20,"column":21},"end":{"row":20,"column":22},"action":"insert","lines":[" "],"id":8}],[{"start":{"row":20,"column":21},"end":{"row":20,"column":22},"action":"remove","lines":[" "],"id":9}]]},"ace":{"folds":[],"scrolltop":0,"scrollleft":0,"selection":{"start":{"row":26,"column":10},"end":{"row":26,"column":10},"isBackwards":false},"options":{"tabSize":4,"useSoftTabs":true,"guessTabSize":false,"useWrapMode":false,"wrapToView":true},"firstLineState":0},"timestamp":1708403783302}