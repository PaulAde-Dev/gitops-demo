output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.this.name
}

output "release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.this.namespace
}

output "release_version" {
  description = "Version of the deployed chart"
  value       = helm_release.this.version
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.this.status
}

output "release_metadata" {
  description = "Metadata of the Helm release"
  value = {
    name        = helm_release.this.name
    namespace   = helm_release.this.namespace
    version     = helm_release.this.version
    chart       = helm_release.this.chart
    app_version = helm_release.this.metadata[0].app_version
  }
}
