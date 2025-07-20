# Variables
variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the public key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "eu-milan-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

variable "preferred_ad" {
  description = "Preferred availability domain (0, 1, or 2)"
  type        = number
  default     = 0
}
variable "use_x86_fallback" {
  description = "Use x86 instance instead of ARM if ARM is not available"
  type        = bool
  default     = false
}