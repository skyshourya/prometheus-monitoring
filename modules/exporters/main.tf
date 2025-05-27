resource "aws_instance" "exporters" {
  count                = var.instance_count
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  key_name             = var.key_name
  user_data            = var.user_data
  vpc_security_group_ids = [var.exporters_sg]

  iam_instance_profile = var.instance_profile

  root_block_device {
    volume_size = 20
  }

  tags = merge(var.tags, {
    Name = "Exporter-${count.index + 1}"
    prometheus_scrape = "true"
    nginx_exporter = "true"
    node_exporter = "true"
    php_fpm_exporter = "true"
    rabbitmq_exporter = "true"
    supervisor_exporter = "true"
    vernemq = "true"
  })
}

output "exporter_ips" {
  value = aws_instance.exporters[*].public_ip
}
