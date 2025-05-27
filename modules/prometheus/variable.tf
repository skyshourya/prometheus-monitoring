variable "ami_id" {
  description = "AMI ID for the Prometheus instance"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name for the Prometheus instance"
  type        = string
}

variable "sg_ids" {
  description = "List of security group IDs for the Prometheus instance"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "user_data" {
  description = "User data script for the Prometheus instance"
  type        = string
}

variable "instance_profile" {
  description = "IAM instance profile to attach to the Prometheus instance"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Prometheus instance"
  type        = map(string)
  default     = { Name = "Prometheus-Monitoring" }
}
