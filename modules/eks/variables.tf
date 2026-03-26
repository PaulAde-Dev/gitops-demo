variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "node_group_subnet_ids" {
  description = "List of subnet IDs for the EKS node group (defaults to subnet_ids if not specified)"
  type        = list(string)
  default     = null
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_security_group_ids" {
  description = "List of security group IDs to attach to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "enabled_cluster_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "managed_addons_enabled" {
  description = "Manage core EKS add-ons (vpc-cni, coredns, kube-proxy) via aws_eks_addon."
  type        = bool
}

variable "managed_addons" {
  description = "List of EKS managed add-ons to install/manage."
  type        = list(string)
}

# Encryption configuration
variable "cluster_encryption_config_enabled" {
  description = "Enable envelope encryption for Kubernetes secrets"
  type        = bool
  default     = false
}

variable "cluster_encryption_config_kms_key_arn" {
  description = "KMS key ARN for envelope encryption"
  type        = string
  default     = null
}

variable "cluster_encryption_config_resources" {
  description = "List of resources to encrypt (secrets)"
  type        = list(string)
  default     = ["secrets"]
}

# Default Node Group configuration
variable "default_node_group_name" {
  description = "Name of the default node group"
  type        = string
  default     = "default"
}

variable "default_node_group_instance_types" {
  description = "List of instance types for the default node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "default_node_group_capacity_type" {
  description = "Capacity type for the default node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.default_node_group_capacity_type)
    error_message = "Capacity type must be either 'ON_DEMAND' or 'SPOT'."
  }
}

variable "default_node_group_disk_size" {
  description = "Disk size in GB for nodes in the default node group"
  type        = number
}

variable "default_node_group_desired_size" {
  description = "Desired number of nodes in the default node group"
  type        = number
  default     = 2
}

variable "default_node_group_min_size" {
  description = "Minimum number of nodes in the default node group"
  type        = number
  default     = 1
}

variable "default_node_group_max_size" {
  description = "Maximum number of nodes in the default node group"
  type        = number
  default     = 5
}

variable "default_node_group_max_unavailable" {
  description = "Maximum number of unavailable nodes during update"
  type        = number
  default     = 1
}

variable "default_node_group_labels" {
  description = "Labels to apply to nodes in the default node group"
  type        = map(string)
  default     = {}
}

variable "default_node_group_taints" {
  description = "Taints to apply to nodes in the default node group"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# IRSA (IAM Roles for Service Accounts)
variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN to allow node image pulls from (least-privilege). Empty string disables ECR pull policy statements."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to EKS resources"
  type        = map(string)
  default     = {}
}
