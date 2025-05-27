#!/bin/bash
# Create directory structure under home for Prometheus setup
mkdir -p /home/ubuntu/prometheus_setup

# Install Docker and related packages
apt-get update
apt-get install -y docker.io docker-compose apt-transport-https ca-certificates curl software-properties-common

# Install latest Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Add the "ubuntu" user to the docker group so that docker commands can be run without sudo
 usermod -aG docker ubuntu

# Write alert rules configuration to /home/ubuntu/prometheus_setup/alert.rules.yml
cat <<EOF > /home/ubuntu/prometheus_setup/alert.rules.yml
groups:
  - name: ec2-alerts
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 20s
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ \$labels.instance }} is down"
          description: "{{ \$labels.instance }} has been down for more than 20 seconds."

  - name: nginx
    rules:
      - alert: NginxDown
        expr: nginx_up == 0
        for: 20s
        labels:
          severity: critical
        annotations:
          summary: "Nginx is down on {{ \$labels.instance }}"
          description: "Nginx process on {{ \$labels.instance }} is unreachable for over 20 seconds."
    
  - name: php-fpm
    rules:
      - alert: PhpFpmDown
        expr: php_fpm_up == 0
        for: 20s
        labels:
          severity: critical
        annotations:
          summary: "PHP-FPM is down on {{ \$labels.instance }}"
          description: "PHP-FPM process on {{ \$labels.instance }} is unreachable for over 20 seconds."

  - name: rabbitmq-alerts
    rules:
      - alert: RabbitMQDown
        expr: rabbitmq_up == 0
        for: 20s
        labels:
          severity: critical
        annotations:
          summary: "RabbitMQ instance {{ \$labels.instance }} is down"
          description: "RabbitMQ on {{ \$labels.instance }} has been down for more than 20 seconds."
  
  - name: supervisord-alerts
    rules:
      - alert: SupervisordProcessDown
        expr: supervisor_process_info == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Process {{ $labels.name }} (group: {{ $labels.group }}) is down"
          description: "Process {{ $labels.name }} in group {{ $labels.group }} has been down for 1 minute"

  - name: vernemq-alerts
    rules:
      - alert: VerneMQDown
        expr: vernemq_up == 0
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "VerneMQ is down on {{ \$labels.instance }}"
          description: "The VerneMQ broker on {{ \$labels.instance }} has been down for more than 30 seconds."

  - name: supervisor-alerts
    rules:
      - alert: SupervisorProcessDown
        expr: supervisor_process_info{group="process"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Process {{ \$labels.name }} (group: {{ \$labels.group }}) is down"
          description: "The process {{ \$labels.name }} (group: {{ \$labels.group }}) is not running. Current state: {{ \$labels.state }}. Exit status: {{ \$labels.exit_status }}."


  - name: ssl-cert-expiry
    rules:
      - alert: SSLCertificateExpiringSoon
        expr: probe_ssl_earliest_cert_expiry - time() < 604800
        for: 1h
        labels:
          severity: critical
        annotations:
          summary: "SSL Certificate for {{ $labels.instance }} is expiring soon!"
          description: "SSL Certificate for {{ $labels.instance }} will expire in less than 7 days."



EOF

# Write Alertmanager configuration to /home/ubuntu/prometheus_setup/alertmanager.yml
cat <<EOF > /home/ubuntu/prometheus_setup/alertmanager.yml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 5s
  group_interval: 10s
  repeat_interval: 1m
  receiver: 'slack-notifications'

  routes:
    - receiver: 'email-notifications'  # <-- Add this line
      matchers:
        - alertname =~ ".*"  # <-- This ensures all alerts are also sent via email

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - send_resolved: true
        channel: '#sunny'
        api_url: 'https://hooks.slack.com/services/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'

  - name: 'email-notifications'
    email_configs:
      - to: 'shouryayadav5@gmail.com'
        from: 'shouryayadav5@gmail.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'shouryayadav5@gmail.com'
        auth_password: 'cqwg octl xsmz pead'   # Use your App Password
        auth_identity: 'shouryayadav5@gmail.com'
        require_tls: true
EOF

# Write Prometheus configuration with service discovery to /home/ubuntu/prometheus_setup/prometheus.yml
# Note: ${region} is a placeholder to be replaced (for example, via Terraform) with your AWS region.
cat <<EOF > /home/ubuntu/prometheus_setup/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'ec2-instances'
    ec2_sd_configs:
      - region: ap-south-1
        port: 9100
        access_key: ""
        secret_key: ""
    relabel_configs:
      - source_labels: [__meta_ec2_tag_prometheus_scrape]
        action: keep
        regex: "true"
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance_id
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance
      - source_labels: [__meta_ec2_tag_Name]  # Add instance name label
        target_label: instance_name
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: "\${1}:9100"


  - job_name: 'nginx_exporter'
    ec2_sd_configs:
      - region: ap-south-1
        port: 9113
    relabel_configs:
      - source_labels: [__meta_ec2_tag_nginx_exporter]
        action: keep
        regex: "true"
      - source_labels: [__meta_ec2_tag_Name]  # Add instance name label
        target_label: instance_name
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: "\${1}:9113"


  - job_name: 'php-fpm'
    ec2_sd_configs:
      - region: ap-south-1  
        port: 9253
    relabel_configs:
      - source_labels: [__meta_ec2_tag_php_fpm_exporter]
        action: keep
        regex: "true"
      - source_labels: [__meta_ec2_tag_Name]  # Add instance name label
        target_label: instance_name
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: "\${1}:9253"
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance
         
       
  - job_name: 'rabbitmq_native'
    ec2_sd_configs:
      - region: ap-south-1  
        port: 15692
    relabel_configs:
      - source_labels: [__meta_ec2_tag_rabbitmq_exporter]
        action: keep
        regex: "true"
      - source_labels: [__meta_ec2_tag_Name]  # Fixed config
        target_label: instance_name
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: "\${1}:15692"

  - job_name: 'supervisord'
    ec2_sd_configs:
      - region: ap-south-1
        port: 9876
    relabel_configs:
      - source_labels: [__meta_ec2_tag_supervisor_exporter]
        action: keep
        regex: "true"
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: "\${1}:9876"
 
  - job_name: 'vernemq'
    ec2_sd_configs:
      - region: ap-south-1
        port: 8888
    relabel_configs:
      - source_labels: [__meta_ec2_tag_vernemq]
        action: keep
        regex: "true"
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: "\${1}:8888"


rule_files:
  - "/etc/prometheus/alert.rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
EOF



# Write Docker Compose file to /home/ubuntu/prometheus_setup/blackbox.yml
cat <<EOF > /home/ubuntu/prometheus_setup/blackbox.yml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: [ "HTTP/1.1", "HTTP/2" ]
      method: GET
      fail_if_ssl: false
      tls_config:
        insecure_skip_verify: false

  ssl_expiry:
    prober: tcp
    timeout: 5s
    tcp:
      tls: true
      tls_config:
        insecure_skip_verify: false

EOF


# Write Docker Compose file to /home/ubuntu/prometheus_setup/docker-compose.yml
cat <<EOF > /home/ubuntu/prometheus_setup/docker-compose.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    environment:
      # Removed AWS keys; Prometheus will use IAM role credentials from instance metadata.
      - AWS_DEFAULT_REGION=ap-south-1
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./alert.rules.yml:/etc/prometheus/alert.rules.yml
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
    ports:
      - "9090:9090"
    depends_on:
      - alertmanager

  alertmanager:
    image: prom/alertmanager
    container_name: alertmanager
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
    command:
      - "--config.file=/etc/alertmanager/alertmanager.yml"
    ports:
      - "9093:9093"

  
  blackbox:
    image: prom/blackbox-exporter
    container_name: blackbox
    ports:
      - "9115:9115"
    command:
      - "--config.file=/etc/blackbox/blackbox.yml"
    volumes:
      - ./blackbox.yml:/etc/blackbox/blackbox.yml


  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    depends_on:
      - prometheus
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
    grafana-data:
EOF

# Change ownership of the setup directory to ubuntu
chown -R ubuntu:ubuntu /home/ubuntu/prometheus_setup

# Start the Docker containers by changing to the setup directory and running docker-compose
cd /home/ubuntu/prometheus_setup
docker-compose up -d



