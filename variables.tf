variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (length should equal az_count)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (length should equal az_count)"
  type        = list(string)
}

variable "eks_endpoint_private_access" {
  description = "Enable private access for the EKS API endpoint"
  type        = bool
}

variable "eks_endpoint_public_access" {
  description = "Enable public access for the EKS API endpoint"
  type        = bool
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS API endpoint"
  type        = list(string)
}

variable "eks_cluster_security_group_ids" {
  description = "Security group IDs to attach to the EKS control plane"
  type        = list(string)
}

variable "eks_enabled_cluster_log_types" {
  description = "List of EKS control plane logging to enable"
  type        = list(string)
}

variable "eks_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
}

variable "default_node_group_capacity_type" {
  description = "Capacity type for the EKS managed node group"
  type        = string

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.default_node_group_capacity_type)
    error_message = "Capacity type must be either 'ON_DEMAND' or 'SPOT'."
  }
}

variable "default_node_group_disk_size" {
  description = "Disk size (GB) for EKS managed nodes"
  type        = number
}

variable "ecr_create" {
  description = "Whether this Terraform state should create the ECR repository. Use false in non-owner environments."
  type        = bool
}

variable "ecr_image_retention_count" {
  description = "Max number of ECR images to retain."
  type        = number
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
}

variable "default_node_pool_vm_size" {
  description = "EC2 instance type for the default node group"
  type        = string
}

variable "default_node_pool_node_count" {
  description = "Initial desired size for the default node group"
  type        = number
}

variable "default_node_pool_min_count" {
  description = "Minimum number of nodes for autoscaling (when enabled)"
  type        = number
}

variable "default_node_pool_max_count" {
  description = "Maximum number of nodes for autoscaling (when enabled)"
  type        = number
}

variable "enable_auto_scaling" {
  description = "Enable cluster autoscaler for the default node pool"
  type        = bool
}

variable "nginx_ingress_enabled" {
  description = "Enable NGINX Ingress Controller installation"
  type        = bool
}

variable "nginx_ingress_release_name" {
  description = "Helm release name for NGINX Ingress"
  type        = string
}

variable "nginx_ingress_repository" {
  description = "Helm repository URL for NGINX Ingress"
  type        = string
}

variable "nginx_ingress_chart" {
  description = "Helm chart name for NGINX Ingress"
  type        = string
}

variable "nginx_ingress_chart_version" {
  description = "Helm chart version for NGINX Ingress"
  type        = string
}

variable "nginx_ingress_namespace" {
  description = "Kubernetes namespace for NGINX Ingress"
  type        = string
}

variable "nginx_ingress_create_namespace" {
  description = "Create namespace for NGINX Ingress if it doesn't exist"
  type        = bool
}

variable "nginx_ingress_replica_count" {
  description = "Number of NGINX Ingress controller replicas"
  type        = number
}

# =============================================================================
# ECR Variables
# =============================================================================

variable "ecr_enabled" {
  description = "Enable ECR repository integration (create or read repo and configure node pull permissions)."
  type        = bool
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
}

# =============================================================================
# EKS Managed Add-ons
# =============================================================================

variable "eks_managed_addons_enabled" {
  description = "Manage core EKS add-ons (vpc-cni, coredns, kube-proxy) via aws_eks_addon."
  type        = bool
}

variable "eks_managed_addons" {
  description = "List of EKS managed add-ons to install/manage."
  type        = list(string)
}

# =============================================================================
# Karpenter Variables
# =============================================================================

variable "karpenter_enabled" {
  description = "Enable Karpenter installation and prerequisites."
  type        = bool
}

variable "karpenter_namespace" {
  description = "Namespace to install Karpenter into."
  type        = string
}

variable "karpenter_release_name" {
  description = "Helm release name for Karpenter."
  type        = string
}

variable "karpenter_chart_version" {
  description = "Karpenter Helm chart version (optional)."
  type        = string
}

variable "karpenter_interruption_queue_name" {
  description = "SQS queue name for Karpenter interruption handling."
  type        = string
}

# =============================================================================
# ArgoCD Variables
# =============================================================================

variable "argocd_enabled" {
  description = "Enable ArgoCD installation"
  type        = bool
}

variable "argocd_release_name" {
  description = "Helm release name for ArgoCD"
  type        = string
}

variable "argocd_repository" {
  description = "Helm repository URL for ArgoCD"
  type        = string
}

variable "argocd_chart" {
  description = "Helm chart name for ArgoCD"
  type        = string
}

variable "argocd_chart_version" {
  description = "Helm chart version for ArgoCD"
  type        = string
}

variable "argocd_namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
}

variable "argocd_create_namespace" {
  description = "Create namespace for ArgoCD if it doesn't exist"
  type        = bool
}

variable "argocd_server_service_type" {
  description = "Service type for ArgoCD server (ClusterIP, LoadBalancer, NodePort)"
  type        = string
}

variable "argocd_server_insecure" {
  description = "Run ArgoCD server in insecure mode (disable TLS)"
  type        = bool
}

variable "argocd_ingress_enabled" {
  description = "Enable Ingress for ArgoCD server"
  type        = bool
}

variable "argocd_ingress_class" {
  description = "Ingress class name for ArgoCD"
  type        = string
}

variable "argocd_ingress_host" {
  description = "Hostname for ArgoCD Ingress"
  type        = string
}

variable "argocd_controller_replicas" {
  description = "Number of ArgoCD Application Controller replicas"
  type        = number
}

variable "argocd_repo_server_replicas" {
  description = "Number of ArgoCD Repo Server replicas"
  type        = number
}

variable "argocd_applicationset_replicas" {
  description = "Number of ArgoCD ApplicationSet Controller replicas"
  type        = number
}

variable "argocd_notifications_enabled" {
  description = "Enable ArgoCD Notifications Controller"
  type        = bool
}

variable "argocd_dex_enabled" {
  description = "Enable Dex for ArgoCD authentication"
  type        = bool
}

# =============================================================================
# KEDA (Kubernetes Event-Driven Autoscaling) Variables
# =============================================================================

variable "keda_enabled" {
  description = "Enable KEDA installation for event-driven pod autoscaling"
  type        = bool
}

variable "keda_release_name" {
  description = "Helm release name for KEDA"
  type        = string
}

variable "keda_repository" {
  description = "Helm repository URL for KEDA"
  type        = string
}

variable "keda_chart" {
  description = "Helm chart name for KEDA"
  type        = string
}

variable "keda_chart_version" {
  description = "Helm chart version for KEDA"
  type        = string
}

variable "keda_namespace" {
  description = "Kubernetes namespace for KEDA"
  type        = string
}

variable "keda_create_namespace" {
  description = "Create namespace for KEDA if it doesn't exist"
  type        = bool
}

variable "keda_operator_replicas" {
  description = "Number of KEDA operator replicas"
  type        = number
}

variable "keda_metrics_server_replicas" {
  description = "Number of KEDA metrics server replicas"
  type        = number
}

variable "keda_log_level" {
  description = "Log level for KEDA operator (debug, info, error)"
  type        = string
}
