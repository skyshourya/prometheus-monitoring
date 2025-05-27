#!/bin/bash
set -ex
sudo -s

# Add error checking and logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user data script execution..."

# Update and install required packages
echo "Updating system and installing packages..."
apt-get update
apt-get install -y wget curl unzip tar nginx php-fpm rabbitmq-server

#####################################
# Configure Nginx to expose a status page at /nginx_status
#####################################
echo "Configuring Nginx status page..."
cat <<EOF > /etc/nginx/conf.d/nginx_status.conf
server {
    listen 80;
    server_name localhost;

    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow all;
    }
}
EOF

# Test Nginx configuration and reload
nginx -t && nginx -s reload
echo "Nginx configured and reloaded successfully."

#####################################
# Configure PHP-FPM for monitoring
#####################################
echo "Configuring PHP-FPM..."
# Determine PHP version
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
echo "Detected PHP version: ${PHP_VERSION}"
PHP_FPM_POOL_PATH="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"

# Backup original config
cp $PHP_FPM_POOL_PATH ${PHP_FPM_POOL_PATH}.bak

# Update PHP-FPM configuration to enable status page
sed -i 's/;pm.status_path = \/status/pm.status_path = \/status/' $PHP_FPM_POOL_PATH
sed -i 's/listen = \/run\/php\/php.*-fpm.sock/listen = 127.0.0.1:9000/' $PHP_FPM_POOL_PATH

# Restart PHP-FPM to apply changes
systemctl restart php${PHP_VERSION}-fpm
echo "PHP-FPM configured and restarted successfully."


#####################################
# Install and Configure Node Exporter
#####################################
echo "Installing Node Exporter..."
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar xzf node_exporter-1.3.1.linux-amd64.tar.gz
mv node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.3.1.linux-amd64*

cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/node_exporter --web.listen-address=":9100"

[Install]
WantedBy=multi-user.target
EOF
echo "Node Exporter installed successfully."

#####################################
# Install and Configure Nginx Prometheus Exporter
#####################################
echo "Installing Nginx Exporter..."
wget -q https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.10.0/nginx-prometheus-exporter_0.10.0_linux_amd64.tar.gz
tar xzf nginx-prometheus-exporter_0.10.0_linux_amd64.tar.gz
mv nginx-prometheus-exporter /usr/local/bin/
rm -rf nginx-prometheus-exporter_0.10.0_linux_amd64.tar.gz

cat > /etc/systemd/system/nginx_exporter.service <<EOF
[Unit]
Description=Nginx Prometheus Exporter
After=network.target nginx.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/nginx-prometheus-exporter --nginx.scrape-uri="http://localhost/nginx_status" --web.listen-address=":9113"

[Install]
WantedBy=multi-user.target
EOF
echo "Nginx Exporter installed successfully."

#####################################
# Install and Configure PHP-FPM Exporter
#####################################
echo "Installing PHP-FPM Exporter..."
wget -q https://github.com/hipages/php-fpm_exporter/releases/download/v2.1.0/php-fpm_exporter_2.1.0_linux_amd64.tar.gz
tar xzf php-fpm_exporter_2.1.0_linux_amd64.tar.gz
mv php-fpm_exporter /usr/local/bin/
rm -rf php-fpm_exporter_2.1.0_linux_amd64.tar.gz

cat > /etc/systemd/system/php-fpm_exporter.service <<EOF
[Unit]
Description=PHP-FPM Exporter
After=network.target php${PHP_VERSION}-fpm.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/php-fpm_exporter server --phpfpm.scrape-uri tcp://127.0.0.1:9000/status --web.listen-address=:9253

[Install]
WantedBy=multi-user.target
EOF
echo "PHP-FPM Exporter installed successfully."

#####################################
# Configure RabbitMQ
#####################################
echo "Configuring RabbitMQ..."
# Install RabbitMQ server
apt-get install -y rabbitmq-server

# Enable required plugins
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
rabbitmq-plugins enable rabbitmq_management rabbitmq_prometheus

# Configure Prometheus endpoint (native)
echo "prometheus.return_per_object_metrics = false" >> /etc/rabbitmq/rabbitmq.conf
echo "prometheus.tcp.port = 15692" >> /etc/rabbitmq/rabbitmq.conf
systemctl restart rabbitmq-server

#####################################
# Install and Configure RabbitMQ Exporter
#####################################
echo "Installing RabbitMQ Exporter..."
wget -q https://github.com/kbudde/rabbitmq_exporter/releases/download/v1.0.0/rabbitmq_exporter_1.0.0_linux_amd64.tar.gz
tar xzf rabbitmq_exporter*.tar.gz
mv rabbitmq_exporter /usr/local/bin/

cat > /etc/systemd/system/rabbitmq_exporter.service <<EOF
[Unit]
Description=RabbitMQ Exporter
After=network.target rabbitmq-server.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/rabbitmq_exporter \
  --rabbit.url=http://localhost:15672 \
  --rabbit.user=guest \
  --rabbit.password=guest \
  --web.listen-address=:9419

Restart=always

[Install]
WantedBy=multi-user.target
EOF
#####################################
# Enable and Start Services
#####################################
echo "Enabling and starting all services..."
# Reload systemd to pick up new service files
systemctl daemon-reload

# Enable all services
systemctl enable node_exporter.service
systemctl enable nginx_exporter.service
systemctl enable php-fpm_exporter.service

# Start all services
systemctl start node_exporter.service
systemctl start nginx_exporter.service
systemctl start php-fpm_exporter.service

# Verify services are running
echo "Checking service status..."
systemctl status node_exporter.service --no-pager
systemctl status nginx_exporter.service --no-pager
systemctl status php-fpm_exporter.service --no-pager

#####################################
# Verify metrics endpoints
#####################################
echo "Verifying metrics endpoints..."
curl -s localhost:9100/metrics > /dev/null && echo "Node Exporter metrics available" || echo "Node Exporter metrics NOT available"
curl -s localhost:9113/metrics > /dev/null && echo "Nginx Exporter metrics available" || echo "Nginx Exporter metrics NOT available"
curl -s localhost:9253/metrics > /dev/null && echo "PHP-FPM Exporter metrics available" || echo "PHP-FPM Exporter metrics NOT available"

#####################################
# Script Completion Message
#####################################
echo "Installation complete. All exporters are installed and running."
echo "Node Exporter metrics available at http://localhost:9100/metrics"
echo "Nginx Exporter metrics available at http://localhost:9113/metrics"
echo "PHP-FPM Exporter metrics available at http://localhost:9253/metrics"

# Redirect output for debugging (optional)
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting Supervisor and Supervisor Exporter setup..."

#####################################
# Install dependencies for Supervisor and Exporter
#####################################
echo "Starting Supervisor and Supervisor Exporter setup..."

# Install dependencies for Supervisor and Exporter
sudo apt-get update
sudo apt-get install -y supervisor golang-go git

# Verify supervisor installation
which supervisord || echo "Supervisor not installed properly"
supervisord --version || echo "Supervisor command not found"

# Make sure supervisor is enabled and started
sudo systemctl enable supervisor || echo "Could not enable supervisor service"
sudo systemctl start supervisor || echo "Could not start supervisor service"
sleep 5

# Check supervisor status
sudo systemctl status supervisor --no-pager || echo "Supervisor service not running"

# Configure Supervisor with XML-RPC access
sudo bash -c 'cat <<EOF > /etc/supervisor/supervisord.conf
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[inet_http_server]
port=127.0.0.1:9001
username=admin
password=admin

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor

[rpcinterface:supervisor]
supervisor.rpcinterface_factory=supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files=/etc/supervisor/conf.d/*.conf
EOF'

echo "Restarting Supervisor..."
sudo systemctl restart supervisor
sleep 5

# Check that supervisor is running with the new configuration
sudo supervisorctl status || echo "Cannot connect to supervisor"

# Clone and build Supervisor Exporter
echo "Building Supervisor Exporter..."
sudo rm -rf /tmp/supervisord_exporter
mkdir -p /tmp/supervisord_exporter
cd /tmp/supervisord_exporter

# Clone the repository
git clone https://github.com/salimd/supervisord_exporter.git .
cd /tmp/supervisord_exporter

# Build as the current user (not as root)
sudo go build -o supervisord_exporter supervisord_exporter.go

# Use sudo to install the binary
sudo mv supervisord_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/supervisord_exporter

# Create systemd service for Supervisor Exporter
sudo bash -c 'cat <<EOF > /etc/systemd/system/supervisord_exporter.service
[Unit]
Description=Supervisord Exporter for Prometheus
After=network.target supervisor.service

[Service]
Type=simple
ExecStart=/usr/local/bin/supervisord_exporter --supervisord-url=http://127.0.0.1:9001/RPC2 --web.listen-address=:9876
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd and start Supervisor Exporter service
sudo systemctl daemon-reload
sudo systemctl enable supervisord_exporter
sudo systemctl start supervisord_exporter
sleep 5

# Check status and verify metrics endpoint
sudo systemctl status supervisord_exporter --no-pager || echo "Supervisord exporter service not running"
curl -s http://localhost:9876/metrics | grep -q "go_goroutines" && echo "Metrics endpoint working" || echo "Metrics endpoint not working"

echo "Supervisor and Supervisor Exporter setup complete."

#####################################
# Install and Configure VerneMQ
#####################################

# Redirect output for debugging (optional)
exec > >(tee /var/log/vernemq-user-data.log|logger -t vernemq-user-data -s 2>/dev/console) 2>&1

echo "Starting VerneMQ installation via Docker..."

#####################################
# Update package lists and install Docker
#####################################
apt-get update
apt-get install -y docker.io

#####################################
# Enable and start Docker service
#####################################
systemctl enable --now docker

#####################################
# Pull the official VerneMQ Docker image
#####################################
docker pull erlio/docker-vernemq:latest

#####################################
# Run the VerneMQ container
#####################################
# Update package list
sudo apt update

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    sudo apt install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "Docker is already installed."
fi

# Add 'ubuntu' user to the 'docker' group
sudo usermod -aG docker ubuntu
echo "User 'ubuntu' added to 'docker' group. You may need to log out and back in."

# Pull the VerneMQ Docker image
echo "Pulling VerneMQ Docker image..."
docker pull erlio/docker-vernemq

# Run VerneMQ container
echo "Running VerneMQ container..."
docker run -d --name vernemq \
  -p 1883:1883 \
  -p 8888:8888 \
  -e DOCKER_VERNEMQ_ACCEPT_EULA=yes \
  erlio/docker-vernemq

echo "VerneMQ is running. Check with 'docker ps'."