#!/bin/bash
set -e

# Update and install Docker & Docker Compose
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# monitoring folder
mkdir -p /opt/monitoring && cd /opt/monitoring

# .env for sensitive variables
cat > .env <<EOF
DOCKER_USERNAME=${DOCKER_USERNAME}
DOCKER_PASSWORD=${DOCKER_PASSWORD}
DB_HOST=${DB_HOST}
DB_PASSWORD=${DB_PASSWORD}
EOF

# Docker Compose config
cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  java-app:
    image: ${DOCKER_USERNAME}/employee-backend:latest
    container_name: employee
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=${DB_HOST}
      - DB_NAME=cfydb
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_USER=postgres
    networks:
      - monitoring
    restart: unless-stopped
    depends_on:
      - prometheus

  prometheus:
    image: prom/prometheus:v2.45.0
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml
      - prometheus_data:/prometheus
    networks:
      - monitoring
    restart: unless-stopped

  grafana:
    image: grafana/grafana:10.0.0
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
      - grafana_data:/var/lib/grafana
    networks:
      - monitoring
    restart: unless-stopped
    depends_on:
      - prometheus

  node-exporter:
    image: prom/node-exporter:v1.6.1
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
EOF


# Prometheus config
mkdir -p prometheus
cat > prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/alerts.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'java-app'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['java-app:8080']
    scrape_interval: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
EOF

cat > prometheus/alerts.yml <<'EOF'
groups:
  - name: employee_app_alerts
    rules:
      - alert: AppDown
        expr: up{job="java-app"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Employee app is down"
          description: "Check the Java app container."

      - alert: HighAppLatency
        expr: histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) > 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High 95th pct latency"
          description: "Latency is over 1s—check app performance."

  - name: infra_alerts
    rules:
      - alert: HighNodeCPU
        expr: 100 - avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High CPU usage"
          description: "Node CPU stayed above 90%."
EOF


# Grafana provisioning
mkdir -p grafana/provisioning/{datasources,dashboards}
mkdir -p grafana/dashboards

cat > grafana/provisioning/datasources/prometheus.yml <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

cat > grafana/provisioning/dashboards/dashboard.yml <<'EOF'
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    type: file
    options:
      path: /var/lib/grafana/dashboards
EOF

# Dashboard with useful panels
cat > grafana/dashboards/employee-dashboard.json <<'EOF'
{
  "id": null,
  "title": "Employee App Metrics",
  "tags": ["employee", "simple", "overview"],
  "timezone": "browser",
  "panels": [
    {
      "id": 1,
      "title": "Total Employees",
      "type": "stat",
      "datasource": "Prometheus",
      "targets": [
        { "expr": "employee_total", "refId": "A" }
      ],
      "gridPos": { "h": 4, "w": 6, "x": 0, "y": 0 }
    },
    {
      "id": 2,
      "title": "Removed (24h)",
      "type": "barchart",
      "datasource": "Prometheus",
      "targets": [
        { "expr": "increase(employee_deleted_today[24h])", "refId": "A" }
      ],
      "gridPos": { "h": 4, "w": 6, "x": 0, "y": 4 }
    },
    {
      "id": 3,
      "title": "Net Change (24h)",
      "type": "graph",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "increase(employee_added_today[24h]) - increase(employee_deleted_today[24h])",
          "refId": "A"
        }
      ],
      "gridPos": { "h": 4, "w": 6, "x": 6, "y": 4 }
    },

    {
      "id": 4,
      "title": "CPU Usage (%)",
      "type": "graph",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "100 - avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100",
          "refId": "A"
        }
      ],
      "gridPos": { "h": 6, "w": 12, "x": 0, "y": 8 }
    },
    {
      "id": 5,
      "title": "Memory Usage (Bytes)",
      "type": "graph",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)",
          "refId": "A"
        }
      ],
      "gridPos": { "h": 6, "w": 12, "x": 0, "y": 14 }
    },
    {
      "id": 6,
      "title": "Disk Usage (%)",
      "type": "graph",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "100 * (node_filesystem_size_bytes{mountpoint=\"/\"} - node_filesystem_free_bytes{mountpoint=\"/\"}) / node_filesystem_size_bytes{mountpoint=\"/\"}",
          "refId": "A"
        }
      ],
      "gridPos": { "h": 6, "w": 12, "x": 0, "y": 20 }
    },
    {
      "id": 7,
      "title": "Network Traffic (Bytes/sec) RX + TX",
      "type": "graph",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "rate(node_network_receive_bytes_total[5m]) + rate(node_network_transmit_bytes_total[5m])",
          "refId": "A"
        }
      ],
      "gridPos": { "h": 6, "w": 12, "x": 0, "y": 26 }
    },
    {
      "id": 8,
      "title": "Filesystem Status",
      "type": "table",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "node_filesystem_avail_bytes",
          "refId": "A"
        },
        {
          "expr": "node_filesystem_size_bytes",
          "refId": "B"
        }
      ],
      "gridPos": { "h": 6, "w": 12, "x": 0, "y": 32 }
    }
  ],
  "schemaVersion": 27,
  "version": 1,
  "refresh": "10s"
}
EOF


# Permissions, login, start stack
chown -R ec2-user:ec2-user /opt/monitoring
echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

cd /opt/monitoring
docker-compose up -d

