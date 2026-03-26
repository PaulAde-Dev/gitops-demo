# AWS EKS Module

This Terraform module creates an Amazon Elastic Kubernetes Service (EKS) cluster with a managed node group.

## Features

- EKS cluster with configurable Kubernetes version
- Managed node group with autoscaling support
- IAM roles for cluster and node group
- CloudWatch logging for control plane
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Optional envelope encryption for Kubernetes secrets

## Usage

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name       = "my-eks-cluster"
  kubernetes_version = "1.28"
  subnet_ids         = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]

  default_node_group_instance_types = ["t3.medium"]
  default_node_group_desired_size   = 2
  default_node_group_min_size       = 1
  default_node_group_max_size       = 5

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| tls | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the EKS cluster | `list(string)` | n/a | yes |
| kubernetes_version | Kubernetes version for the EKS cluster | `string` | `"1.28"` | no |
| endpoint_private_access | Enable private API server endpoint | `bool` | `true` | no |
| endpoint_public_access | Enable public API server endpoint | `bool` | `true` | no |
| public_access_cidrs | List of CIDR blocks that can access the public API server endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| enabled_cluster_log_types | List of control plane logging to enable | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | no |
| log_retention_days | Number of days to retain CloudWatch logs | `number` | `30` | no |
| default_node_group_name | Name of the default node group | `string` | `"default"` | no |
| default_node_group_instance_types | List of instance types for the default node group | `list(string)` | `["t3.medium"]` | no |
| default_node_group_capacity_type | Capacity type (ON_DEMAND or SPOT) | `string` | `"ON_DEMAND"` | no |
| default_node_group_disk_size | Disk size in GB for nodes | `number` | `50` | no |
| default_node_group_desired_size | Desired number of nodes | `number` | `2` | no |
| default_node_group_min_size | Minimum number of nodes | `number` | `1` | no |
| default_node_group_max_size | Maximum number of nodes | `number` | `5` | no |
| enable_irsa | Enable IAM Roles for Service Accounts | `bool` | `true` | no |
| tags | Tags to apply to EKS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | Name of the EKS cluster |
| cluster_id | ID of the EKS cluster |
| cluster_arn | ARN of the EKS cluster |
| cluster_endpoint | Endpoint for the EKS cluster API server |
| cluster_certificate_authority_data | Base64 encoded certificate data for the cluster |
| cluster_iam_role_arn | IAM role ARN of the EKS cluster |
| node_group_iam_role_arn | IAM role ARN of the EKS node group |
| oidc_provider_arn | ARN of the OIDC provider for IRSA |
| kubeconfig_command | AWS CLI command to update kubeconfig |

## Connecting to the Cluster

After the cluster is created, configure kubectl:

```bash
aws eks update-kubeconfig --region <REGION> --name <CLUSTER_NAME>
```
