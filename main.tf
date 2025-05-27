terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = aws_default_vpc.default.id
}

module "prometheus" {
  source           = "./modules/prometheus"
  sg_ids           = [module.security_groups.prometheus_sg_id]
  region           = var.region
  key_name         = var.prometheus_key_name
  ami_id           = var.prometheus_ami_id != "" ? var.prometheus_ami_id : data.aws_ami.ubuntu.id
  user_data        = file("${path.module}/modules/prometheus/user_data.sh")
  instance_profile = aws_iam_instance_profile.prometheus_profile.name
  tags             = { Name = "Prometheus-Monitoring" }
}

module "exporters" {
  source           = "./modules/exporters"
  exporters_sg     = module.security_groups.exporters_sg_id
  region           = var.region
  key_name         = var.exporter_key_name
  ami_id           = var.exporter_ami_id != "" ? var.exporter_ami_id : data.aws_ami.ubuntu.id
  user_data        = file("${path.module}/modules/exporters/user_data.sh")
  instance_count   = var.instance_count
  instance_profile = aws_iam_instance_profile.prometheus_profile.name
  tags             = { prometheus_scrape = "true" }
}
