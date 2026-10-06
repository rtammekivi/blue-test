include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=21.26.0"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id          = "vpc-00000000"
    private_subnets = ["subnet-00000000", "subnet-11111111", "subnet-22222222"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  name               = "legacy-web"
  kubernetes_version = "1.37"
  service_ipv4_cidr  = "172.20.0.0/16"

  enable_cluster_creator_admin_permissions = true

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "system"]
  }
}
