variable "ami_id" {
  description = "AMI ID for exporter instances"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name for exporter instances"
  type        = string
}

variable "exporters_sg" {
  description = "Security group ID for exporter instances"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "user_data" {
  description = "User data script for exporter instances"
  type        = string
}

variable "instance_profile" {
  description = "IAM instance profile to attach to exporter instances"
  type        = string
}

variable "instance_count" {
  description = "Number of exporter instances to create"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to exporter instances"
  type        = map(string)
  default     = {}
}
