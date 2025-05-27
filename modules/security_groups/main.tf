resource "aws_security_group" "prometheus_sg" {
  name        = "prometheus-sg"
  description = "Security group for Prometheus server"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Prometheus web access
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Prometheus web access"
  }

  # Grafana web access
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana web access"
  }
  ingress {
  from_port   = 587
  to_port     = 587
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow SMTP traffic for email notifications"
}
ingress {
  from_port   = 465
  to_port     = 465
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow SMTP SSL traffic for email notifications"
}

  # Alertmanager web access
  ingress {
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Alertmanager web access"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "prometheus-sg"
  }
}

resource "aws_security_group" "exporters_sg" {
  name        = "exporters-sg"
  description = "Security group for exporter instances"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Node Exporter access
  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus_sg.id]
    description     = "Node Exporter metrics access"
  }

  # Nginx Exporter access
  ingress {
    from_port       = 9113
    to_port         = 9113
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus_sg.id]
    description     = "Nginx Exporter metrics access"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  # RabbitMQ native Prometheus metrics access
  ingress {
    from_port   = 15692
    to_port     = 15692
    protocol    = "tcp"
    security_groups = [aws_security_group.prometheus_sg.id]
    description = "RabbitMQ native Prometheus metrics"
  }

  # Supervisord Exporter access
  ingress {
    from_port   = 9876
    to_port     = 9876
    protocol    = "tcp"
    security_groups = [aws_security_group.prometheus_sg.id]
    description = "Supervisord Exporter metrics access"
  }
  # VerneMQ metrics access
  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    security_groups = [aws_security_group.prometheus_sg.id]
    description = "VerneMQ metrics access"
  }


  # PHP-FPM Exporter access
  ingress {
    from_port       = 9253
    to_port         = 9253
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus_sg.id]
    description     = "PHP-FPM Exporter metrics access"
  }
  # RabbitMQ Exporter access
  ingress {
    from_port = 9419
    to_port = 9419
    protocol = "tcp"
    security_groups = [aws_security_group.prometheus_sg.id]
    description = "RabbitMQ Exporter metrics access"
  }
  # RabbitMQ Management interface access
  ingress {
    from_port = 15672
    to_port = 15672
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "RabbitMQ Management interface access"
  }
  ingress {
    from_port   = 15692
    to_port     = 15692
    protocol    = "tcp"
    security_groups = [aws_security_group.prometheus_sg.id]
    description = "RabbitMQ native Prometheus metrics"
  }

  

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }


  tags = {
    Name = "exporters-sg"
  }
}

output "prometheus_sg_id" {
  value = aws_security_group.prometheus_sg.id
}

output "exporters_sg_id" {
  value = aws_security_group.exporters_sg.id
}
