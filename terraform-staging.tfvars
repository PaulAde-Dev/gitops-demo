
tags = {
  Environment = "Staging"
  Project     = "EKS-GitOps"
  ManagedBy   = "Terraform"
}

aws_region = "ca-central-1"

vpc_cidr = "10.10.0.0/16"
az_count = 2
public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
private_subnet_cidrs = ["10.10.2.0/24", "10.10.3.0/24"]

eks_endpoint_private_access = true
eks_endpoint_public_access  = true
eks_public_access_cidrs     = ["0.0.0.0/0"]
eks_cluster_security_group_ids = []
eks_enabled_cluster_log_types  = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
eks_log_retention_days         = 30

default_node_group_capacity_type = "ON_DEMAND"
default_node_group_disk_size     = 50
ecr_image_retention_count        = 50

eks_managed_addons_enabled = true
eks_managed_addons         = ["vpc-cni", "coredns", "kube-proxy"]


cluster_name       = "eks-staging-cluster"
kubernetes_version = "1.32"


default_node_pool_name       = "default"
default_node_pool_vm_size    = "t3.medium"
default_node_pool_node_count = 2
default_node_pool_min_count  = 1
default_node_pool_max_count  = 5
enable_auto_scaling          = true

nginx_ingress_enabled          = true
nginx_ingress_release_name     = "ingress-nginx"
nginx_ingress_repository       = "https://kubernetes.github.io/ingress-nginx"
nginx_ingress_chart            = "ingress-nginx"
nginx_ingress_chart_version    = "4.9.0"
nginx_ingress_namespace        = "ingress-nginx"
nginx_ingress_create_namespace = true
nginx_ingress_replica_count    = 2

# ECR (container registry)
ecr_enabled         = true
ecr_repository_name = "sample-app"

ecr_create = false

karpenter_enabled                = false
karpenter_namespace              = "karpenter"
karpenter_release_name           = "karpenter"
karpenter_chart_version          = null
karpenter_interruption_queue_name = "karpenter-interruption"

# ArgoCD Configuration
argocd_enabled                 = true
argocd_release_name            = "argocd"
argocd_repository              = "https://argoproj.github.io/argo-helm"
argocd_chart                   = "argo-cd"
argocd_chart_version           = "5.51.6"
argocd_namespace               = "argocd"
argocd_create_namespace        = true
argocd_server_service_type     = "ClusterIP"
argocd_server_insecure         = true
argocd_ingress_enabled         = true
argocd_ingress_class           = "nginx"
argocd_ingress_host            = "argocd.staging.example.com"
argocd_controller_replicas     = 1
argocd_repo_server_replicas    = 1
argocd_applicationset_replicas = 1
argocd_notifications_enabled   = true
argocd_dex_enabled             = false

# KEDA Configuration
keda_enabled                 = true
keda_release_name            = "keda"
keda_repository              = "https://kedacore.github.io/charts"
keda_chart                   = "keda"
keda_chart_version           = "2.13.1"
keda_namespace               = "keda"
keda_create_namespace        = true
keda_operator_replicas       = 2
keda_metrics_server_replicas = 2
keda_log_level               = "info"
