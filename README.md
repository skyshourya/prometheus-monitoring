# 🚀 Monitoring & Alerting Stack on AWS Using Terraform

A fully automated, production-ready monitoring and alerting infrastructure deployed on AWS using **Terraform**, **Docker**, and **EC2 instances**, integrating **Prometheus**, **Grafana**, and **Alertmanager**, with a comprehensive set of exporters for deep observability.

---

## 🧱 Architecture Overview

This stack provisions:

- A **Prometheus server** EC2 instance with:
  - Prometheus (metrics collection & alerting engine)
  - Grafana (dashboard & visualization)
  - Alertmanager (notification routing to Slack and Email)

- A dynamic **Exporter Fleet** (t3.micro × N) with:
  - Node Exporter
  - Nginx Exporter
  - PHP-FPM Exporter
  - RabbitMQ Exporter
  - VerneMQ Broker (via Docker)
  - Supervisord Exporter

All resources are managed by Terraform with reusable modules:
- `modules/iam`
- `modules/exporters`
- `modules/prometheus`

---

## 🗺️ Diagram

![Architecture Diagram](./uml_flow.png)

---

## 🔧 Tech Stack

- **Terraform** (modular IaC)
- **AWS EC2, IAM, Security Groups**
- **Docker & Docker Compose**
- **Prometheus**
- **Grafana**
- **Alertmanager**
- **Slack & Email integration**
- **Node/Nginx/PHP-FPM/RabbitMQ/VerneMQ Exporters**

---

## 🌐 System Flow

1. **Terraform Root Module**
   - Orchestrates:
     - EC2 provisioning (Prometheus & Exporters)
     - IAM roles/policies
     - SG and instance profile assignments

2. **Prometheus Server (t3.small)**
   - Runs Prometheus, Grafana, and Alertmanager in Docker
   - Pulls metrics from Exporter EC2s via static configs and IAM role-based service discovery
   - Triggers alerts based on custom rules

3. **Exporter Fleet (t3.micro × N)**
   - Runs various exporters for system and service observability
   - Metrics scraped by Prometheus
   - IAM roles enable dynamic discovery

4. **Alertmanager**
   - Sends alerts to Slack & Email channels

5. **Grafana**
   - Visualizes Prometheus metrics for dashboards

---

## 📁 Directory Structure

