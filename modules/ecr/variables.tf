variable "repository_name" {
  description = "ECR repository name."
  type        = string
}

variable "image_tag_mutability" {
  description = "Whether image tags are mutable or immutable."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "ECR encryption type."
  type        = string
  default     = "AES256"
}

variable "image_retention_count" {
  description = "Max number of images to keep (by tag)."
  type        = number
}

variable "force_delete" {
  description = "Whether to allow force delete of the repository."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the ECR repository."
  type        = map(string)
}

