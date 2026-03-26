output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "eks_kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = module.eks.kubeconfig_command
}

output "ecr_repository_url" {
  description = "ECR repository URI"
  value = var.ecr_enabled ? (
    var.ecr_create ? module.ecr[0].repository_url : data.aws_ecr_repository.existing[0].repository_url
  ) : null
}

output "nginx_ingress_status" {
  description = "Status of the NGINX Ingress Controller Helm release"
  value       = var.nginx_ingress_enabled ? module.nginx_ingress[0].release_metadata : null
}

output "argocd_status" {
  description = "Status of the ArgoCD Helm release"
  value       = var.argocd_enabled ? module.argocd[0].release_metadata : null
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = var.argocd_enabled ? var.argocd_namespace : null
}

output "argocd_server_url" {
  description = "ArgoCD server URL (Ingress host)"
  value       = var.argocd_enabled && var.argocd_ingress_enabled ? "https://${var.argocd_ingress_host}" : null
}
