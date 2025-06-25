#!/bin/bash

# Prometheus Setup Script
set -e

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Create prometheus user
useradd --no-create-home --shell /bin/false prometheus

# Create directories
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus

# Download and install Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvf prometheus-2.45.0.linux-amd64.tar.gz
cp prometheus-2.45.0.linux-amd64/prometheus /usr/local/bin/
cp prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

# Copy console files
cp -r prometheus-2.45.0.linux-amd64/consoles /etc/prometheus
cp -r prometheus-2.45.0.linux-amd64/console_libraries /etc/prometheus
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries

# Create simplified alert rules file
cat > /etc/prometheus/simplified-prometheus-alerts.yml << 'EOF_ALERTS'
groups:
  - name: simplified_java_app_alerts
    rules:
      - alert: JavaAppDown
        expr: up{job="java-app"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Java Application is Down"
          description: "The Java application instance {{ $labels.instance }} is unreachable."

      - alert: HighJavaAppLatency
        expr: histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) > 2
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High Latency for Java Application"
          description: "The 95th percentile request latency for {{ $labels.uri }} is {{ $value }}s."

      - alert: HighJavaAppMemoryUsage
        expr: (jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}) > 0.9
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High JVM Heap Memory Usage"
          description: "JVM heap memory usage is at {{ $value | humanizePercentage }} on instance {{ $labels.instance }}."

  - name: simplified_infrastructure_alerts
    rules:
      - alert: HighNodeCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High CPU Usage on Node"
          description: "CPU usage is {{ $value }}% on node {{ $labels.instance }}."

EOF_ALERTS

chown prometheus:prometheus /etc/prometheus/simplified-prometheus-alerts.yml

# Create Prometheus configuration
cat > /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/simplified-prometheus-alerts.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'java-app'
    static_configs:
      - targets: ['${java_app_private_ip}:8080']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['${java_app_private_ip}:9100']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Create systemd service file
cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
    --config.file /etc/prometheus/prometheus.yml \\
    --storage.tsdb.path /var/lib/prometheus/ \\
    --web.console.templates=/etc/prometheus/consoles \\
    --web.console.libraries=/etc/prometheus/console_libraries \\
    --web.listen-address=0.0.0.0:9090 \\
    --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Prometheus
systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

# Install Node Exporter for system metrics
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xvf node_exporter-1.6.1.linux-amd64.tar.gz
cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/node_exporter

# Create systemd service for Node Exporter
cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Node Exporter
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

echo "Prometheus setup completed successfully!"


