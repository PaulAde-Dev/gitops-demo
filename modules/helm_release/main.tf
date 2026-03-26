resource "helm_release" "this" {
  name             = var.release_name
  repository       = var.repository
  chart            = var.chart
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  timeout         = var.timeout
  atomic          = var.atomic
  cleanup_on_fail = var.cleanup_on_fail
  wait            = var.wait

  dynamic "set" {
    for_each = tomap(var.set_values)
    content {
      name  = set.key
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = nonsensitive(tomap(var.set_sensitive_values))
    content {
      name  = set_sensitive.key
      value = var.set_sensitive_values[set_sensitive.key]
    }
  }

  values = var.values != null ? [var.values] : []
}
