resource "aws_instance" "prometheus" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  user_data              = var.user_data
  vpc_security_group_ids = var.sg_ids

  iam_instance_profile   = var.instance_profile

  root_block_device {
    volume_size = 20
  }

  tags = var.tags
}

output "prometheus_public_ip" {
  value = aws_instance.prometheus.public_ip
}
