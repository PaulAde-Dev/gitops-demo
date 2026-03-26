variable "cluster_name" {
  description = "EKS cluster name (used for Kubernetes subnet tags)."
  type        = string
}

variable "name" {
  description = "Name prefix for VPC resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "az_count" {
  description = "Number of AZs to use."
  type        = number
}

variable "azs" {
  description = "Optional explicit list of AZs (e.g. [\"us-east-1a\",\"us-east-1b\"]). If empty, will use the first az_count available AZs."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (must match az_count if azs is empty)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (must match az_count if azs is empty)."
  type        = list(string)
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

