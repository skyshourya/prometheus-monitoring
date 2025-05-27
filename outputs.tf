output "prometheus_public_ip" {
  value = module.prometheus.prometheus_public_ip
}

output "prometheus_dashboard" {
  value = "http://${module.prometheus.prometheus_public_ip}:9090"
}

output "grafana_dashboard" {
  value = "http://${module.prometheus.prometheus_public_ip}:3000"
}

output "exporter_ips" {
  value = module.exporters.exporter_ips
}

output "ssh_command_prometheus" {
  value = "ssh -i ${var.prometheus_key_name}.pem ubuntu@${module.prometheus.prometheus_public_ip}"
}

output "ssh_command_exporters" {
  value = [for ip in module.exporters.exporter_ips : "ssh -i ${var.exporter_key_name}.pem ubuntu@${ip}"]
}
