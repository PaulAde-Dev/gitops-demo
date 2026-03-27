locals {
  eks_kubernetes_version = var.kubernetes_version
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

module "vpc" {
  source = "./modules/vpc"

  name         = var.cluster_name
  cluster_name = var.cluster_name

  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

data "aws_ecr_repository" "existing" {
  count = var.ecr_enabled && !var.ecr_create ? 1 : 0
  name  = var.ecr_repository_name
}

module "ecr" {
  source = "./modules/ecr"

  count = var.ecr_enabled && var.ecr_create ? 1 : 0

  repository_name       = var.ecr_repository_name
  image_tag_mutability  = "MUTABLE"
  scan_on_push          = true
  encryption_type       = "AES256"
  image_retention_count = var.ecr_image_retention_count

  tags = var.tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = local.eks_kubernetes_version

  subnet_ids                 = module.vpc.private_subnet_ids
  node_group_subnet_ids      = module.vpc.private_subnet_ids
  endpoint_private_access    = var.eks_endpoint_private_access
  endpoint_public_access     = var.eks_endpoint_public_access
  public_access_cidrs        = var.eks_public_access_cidrs
  cluster_security_group_ids = var.eks_cluster_security_group_ids

  enabled_cluster_log_types = var.eks_enabled_cluster_log_types
  log_retention_days        = var.eks_log_retention_days

  managed_addons_enabled   = var.eks_managed_addons_enabled
  managed_addons_pre_node  = var.eks_managed_addons_pre_node
  managed_addons_post_node = var.eks_managed_addons_post_node

  default_node_group_name           = var.default_node_pool_name
  default_node_group_instance_types = [var.default_node_pool_vm_size]
  default_node_group_desired_size   = var.default_node_pool_node_count
  default_node_group_min_size       = var.enable_auto_scaling ? var.default_node_pool_min_count : var.default_node_pool_node_count
  default_node_group_max_size       = var.enable_auto_scaling ? var.default_node_pool_max_count : var.default_node_pool_node_count
  default_node_group_capacity_type  = var.default_node_group_capacity_type
  default_node_group_disk_size      = var.default_node_group_disk_size

  enable_irsa = true

  tags = var.tags
}

resource "aws_sqs_queue" "karpenter_interruption" {
  count = var.karpenter_enabled ? 1 : 0

  name                      = var.karpenter_interruption_queue_name
  message_retention_seconds = 300

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
  count = var.karpenter_enabled ? 1 : 0

  name = "${var.cluster_name}-karpenter-spot-interruption"
  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_spot_interruption" {
  count = var.karpenter_enabled ? 1 : 0

  rule = aws_cloudwatch_event_rule.karpenter_spot_interruption[0].name
  arn  = aws_sqs_queue.karpenter_interruption[0].arn
}

resource "aws_iam_role" "karpenter_node" {
  count = var.karpenter_enabled ? 1 : 0

  name = "${var.cluster_name}-karpenter-node"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_instance_profile" "karpenter_node" {
  count = var.karpenter_enabled ? 1 : 0

  name = "${var.cluster_name}-karpenter-node"
  role = aws_iam_role.karpenter_node[0].name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_worker" {
  count = var.karpenter_enabled ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  count = var.karpenter_enabled ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr_read" {
  count = var.karpenter_enabled ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  count = var.karpenter_enabled ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "karpenter_controller" {
  count = var.karpenter_enabled ? 1 : 0

  name = "${var.cluster_name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.karpenter_namespace}:karpenter"
          "${replace(module.eks.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "karpenter_controller" {
  count = var.karpenter_enabled ? 1 : 0

  name = "${var.cluster_name}-karpenter-controller"
  role = aws_iam_role.karpenter_controller[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:Describe*",
          "pricing:GetProducts"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = aws_iam_role.karpenter_node[0].arn
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = module.eks.cluster_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.karpenter_interruption[0].arn
      }
    ]
  })
}

resource "kubernetes_config_map_v1" "aws_auth" {
  count = var.karpenter_enabled ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = module.eks.node_group_iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = aws_iam_role.karpenter_node[0].arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
  }

  depends_on = [module.eks]
}

module "karpenter" {
  source = "./modules/helm_release"
  count  = var.karpenter_enabled ? 1 : 0

  release_name     = var.karpenter_release_name
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  chart_version    = var.karpenter_chart_version
  namespace        = var.karpenter_namespace
  create_namespace = true

  set_values = {
    "serviceAccount.create"                                     = "true"
    "serviceAccount.name"                                       = "karpenter"
    "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = aws_iam_role.karpenter_controller[0].arn
    "settings.clusterName"                                      = module.eks.cluster_name
    "settings.clusterEndpoint"                                  = module.eks.cluster_endpoint
    "settings.interruptionQueue"                                = aws_sqs_queue.karpenter_interruption[0].name
    "settings.aws.defaultInstanceProfile"                       = aws_iam_instance_profile.karpenter_node[0].name
  }

  depends_on = [
    module.eks,
    kubernetes_config_map_v1.aws_auth
  ]
}

module "nginx_ingress" {
  source = "./modules/helm_release"
  count  = var.nginx_ingress_enabled ? 1 : 0

  release_name     = var.nginx_ingress_release_name
  repository       = var.nginx_ingress_repository
  chart            = var.nginx_ingress_chart
  chart_version    = var.nginx_ingress_chart_version
  namespace        = var.nginx_ingress_namespace
  create_namespace = var.nginx_ingress_create_namespace

  set_values = {
    "controller.replicaCount"                                                                            = tostring(var.nginx_ingress_replica_count)
    "controller.service.type"                                                                            = "LoadBalancer"
    "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-healthcheck-path" = "/healthz"
    "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"             = "nlb"
    "controller.admissionWebhooks.enabled"                                                               = "true"
    "controller.metrics.enabled"                                                                         = "true"
  }

  depends_on = [
    module.eks
  ]
}

module "argocd" {
  source = "./modules/helm_release"
  count  = var.argocd_enabled ? 1 : 0

  release_name     = var.argocd_release_name
  repository       = var.argocd_repository
  chart            = var.argocd_chart
  chart_version    = var.argocd_chart_version
  namespace        = var.argocd_namespace
  create_namespace = var.argocd_create_namespace
  timeout          = 600

  set_values = merge(
    {
      "server.service.type"                       = var.argocd_server_service_type
      "configs.params.server\\.insecure"          = tostring(var.argocd_server_insecure)
      "server.ingress.enabled"                    = tostring(var.argocd_ingress_enabled)
      "server.ingress.ingressClassName"           = var.argocd_ingress_class
      "controller.replicas"                       = tostring(var.argocd_controller_replicas)
      "repoServer.replicas"                       = tostring(var.argocd_repo_server_replicas)
      "applicationSet.enabled"                    = "true"
      "applicationSet.replicas"                   = tostring(var.argocd_applicationset_replicas)
      "notifications.enabled"                     = tostring(var.argocd_notifications_enabled)
      "dex.enabled"                               = tostring(var.argocd_dex_enabled)
      "configs.cm.timeout\\.reconciliation"       = "180s"
      "configs.cm.application\\.instanceLabelKey" = "argocd.argoproj.io/instance"
      "server.extraArgs[0]"                       = "--insecure"

      "configs.cm.resource\\.exclusions"                                          = <<-EOT
        - apiGroups:
            - "*"
          kinds:
            - "Endpoints"
          clusters:
            - "*"
      EOT
      "configs.cm.resource\\.customizations\\.health\\.argoproj\\.io_Application" = <<-EOT
        hs = {}
        hs.status = "Progressing"
        hs.message = ""
        if obj.status ~= nil then
          if obj.status.health ~= nil then
            hs.status = obj.status.health.status
            if obj.status.health.message ~= nil then
              hs.message = obj.status.health.message
            end
          end
        end
        return hs
      EOT
    },
    var.argocd_ingress_enabled ? {
      "server.ingress.hosts[0]" = var.argocd_ingress_host
    } : {}
  )

  depends_on = [
    module.eks,
    module.nginx_ingress
  ]
}

module "keda" {
  source = "./modules/helm_release"
  count  = var.keda_enabled ? 1 : 0

  release_name     = var.keda_release_name
  repository       = var.keda_repository
  chart            = var.keda_chart
  chart_version    = var.keda_chart_version
  namespace        = var.keda_namespace
  create_namespace = var.keda_create_namespace
  timeout          = 300

  set_values = {
    "operator.replicaCount"              = tostring(var.keda_operator_replicas)
    "metricsServer.replicaCount"         = tostring(var.keda_metrics_server_replicas)
    "logging.operator.level"             = var.keda_log_level
    "prometheus.operator.enabled"        = "true"
    "prometheus.metricServer.enabled"    = "true"
    "resources.operator.requests.cpu"    = "100m"
    "resources.operator.requests.memory" = "128Mi"
    "resources.operator.limits.cpu"      = "500m"
    "resources.operator.limits.memory"   = "256Mi"
  }

  depends_on = [
    module.eks
  ]
}
