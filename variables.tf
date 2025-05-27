variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}

variable "prometheus_ami_id" {
  description = "AMI ID to use for the Prometheus instance"
  type        = string
  default     = "ami-06b6e5225d1db5f46"
}

variable "prometheus_key_name" {
  description = "SSH key pair name for Prometheus instance"
  type        = string
  default     = "prometheous-key.pem"
}

variable "exporter_key_name" {
  description = "SSH key pair name for exporter instances"
  type        = string
  default     = "node_exporter-key"
}

variable "instance_count" {
  description = "Number of exporter instances to create"
  type        = number
  default     = 3
}

variable "exporter_ami_id" {
  description = "AMI ID to use for exporter instances. If empty, the latest Ubuntu AMI is used."
  type        = string
  default     = ""
}
variable "instance_ids" {
  description = "List of EC2 instance IDs to stop"
  type        = list(string)
}

variable "stop_on_apply" {
  description = "When true, Terraform will invoke a stop command against the instances"
  type        = bool
  default     = false
}
