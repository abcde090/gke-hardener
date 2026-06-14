variable "project_id" {
  type        = string
  description = "Project that hosts the cluster."
}

variable "name" {
  type        = string
  description = "Cluster name."
  default     = "hardened-autopilot"
}

variable "location" {
  type        = string
  description = "Region for the Autopilot cluster."
  default     = "australia-southeast1"
}

variable "network" {
  type        = string
  description = "VPC network self-link or name."
  default     = "default"
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork self-link or name."
  default     = "default"
}

variable "release_channel" {
  type        = string
  description = "GKE release channel (RAPID, REGULAR, STABLE)."
  default     = "REGULAR"
}

variable "deletion_protection" {
  type        = bool
  description = "Block accidental cluster deletion."
  default     = true
}

variable "secrets_kms_key" {
  type        = string
  description = "Cloud KMS key (full resource ID) for application-layer Secret encryption. null to skip."
  default     = null
}

variable "bulletins_topic" {
  type        = string
  description = "Pub/Sub topic (full resource ID) for security-bulletin notifications. null to skip."
  default     = null
}
