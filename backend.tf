terraform {
  backend "s3" {
    bucket       = "terraform-state-gitops-paul"
    key          = "terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
