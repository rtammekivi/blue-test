include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//external-secrets"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name = "legacy-web"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  cluster_name = dependency.eks.outputs.cluster_name
}
