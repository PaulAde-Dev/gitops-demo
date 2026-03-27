resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = var.cluster_security_group_ids
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config_enabled ? [1] : []
    content {
      provider {
        key_arn = var.cluster_encryption_config_kms_key_arn
      }
      resources = var.cluster_encryption_config_resources
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.this,
  ]

  lifecycle {
    ignore_changes = [
      version,
    ]
  }
}

moved {
  from = aws_eks_addon.core["coredns"]
  to   = aws_eks_addon.post_node["coredns"]
}

moved {
  from = aws_eks_addon.pre_node["kube-proxy"]
  to   = aws_eks_addon.kube_proxy[0]
}

moved {
  from = aws_eks_addon.pre_node["vpc-cni"]
  to   = aws_eks_addon.vpc_cni[0]
}

locals {
  pre_node_has_kube_proxy = var.managed_addons_enabled && contains(var.managed_addons_pre_node, "kube-proxy")
  pre_node_has_vpc_cni    = var.managed_addons_enabled && contains(var.managed_addons_pre_node, "vpc-cni")
  pre_node_other = var.managed_addons_enabled ? [
    for a in var.managed_addons_pre_node : a if !contains(["kube-proxy", "vpc-cni"], a)
  ] : []
}

resource "aws_eks_addon" "kube_proxy" {
  count = local.pre_node_has_kube_proxy ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_addon" "vpc_cni" {
  count = local.pre_node_has_vpc_cni ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_addon.kube_proxy,
  ]
}

resource "aws_eks_addon" "pre_node_other" {
  for_each = toset(local.pre_node_other)

  cluster_name = aws_eks_cluster.this.name
  addon_name   = each.value

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.vpc_cni,
  ]
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.default_node_group_name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.node_group_subnet_ids != null ? var.node_group_subnet_ids : var.subnet_ids

  instance_types = var.default_node_group_instance_types
  capacity_type  = var.default_node_group_capacity_type
  disk_size      = var.default_node_group_disk_size

  scaling_config {
    desired_size = var.default_node_group_desired_size
    min_size     = var.default_node_group_min_size
    max_size     = var.default_node_group_max_size
  }

  update_config {
    max_unavailable = var.default_node_group_max_unavailable
  }

  labels = var.default_node_group_labels

  dynamic "taint" {
    for_each = var.default_node_group_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.vpc_cni,
    aws_eks_addon.pre_node_other,
  ]

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}

resource "aws_eks_addon" "post_node" {
  for_each = var.managed_addons_enabled ? toset(var.managed_addons_post_node) : toset([])

  cluster_name = aws_eks_cluster.this.name
  addon_name   = each.value

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}

data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = var.tags
}
