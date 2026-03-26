variable "release_name" {
  description = "Name of the Helm release"
  type        = string
}

variable "repository" {
  description = "Helm chart repository URL"
  type        = string
}

variable "chart" {
  description = "Name of the Helm chart"
  type        = string
}

variable "chart_version" {
  description = "Version of the Helm chart"
  type        = string
  default     = null
}

variable "namespace" {
  description = "Kubernetes namespace for the release"
  type        = string
  default     = "default"
}

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 300
}

variable "atomic" {
  description = "Rollback on failure"
  type        = bool
  default     = true
}

variable "cleanup_on_fail" {
  description = "Delete new resources on failure"
  type        = bool
  default     = true
}

variable "wait" {
  description = "Wait for resources to be ready"
  type        = bool
  default     = true
}

variable "set_values" {
  description = "Map of values to set in the Helm chart"
  type        = map(string)
  default     = {}
}

variable "set_sensitive_values" {
  description = "Map of sensitive values to set in the Helm chart"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "values" {
  description = "YAML string of values for the Helm chart"
  type        = string
  default     = null
}
