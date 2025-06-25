#!/bin/bash

set -e

# Update system packages
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Add Grafana repository
cat > /etc/yum.repos.d/grafana.repo << EOF
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# Install Grafana
yum install -y grafana


prometheus_private_ip=$${prometheus_private_ip:-"127.0.0.1"}


# Configure Grafana
cat > /etc/grafana/grafana.ini << EOF
[server]
http_addr = 0.0.0.0
http_port = 3000

[security]
admin_user = admin
admin_password = admin123

[users]
allow_sign_up = false

[auth.anonymous]
enabled = false

[dashboards]
default_home_dashboard_path = /var/lib/grafana/dashboards/simplified-java-app-monitoring.json

[unified_alerting]
enabled = true

[smtp]
enabled = false
EOF

# Create datasource provisioning directory and Prometheus datasource config
mkdir -p /etc/grafana/provisioning/datasources
cat > /etc/grafana/provisioning/datasources/prometheus.yml << EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://${prometheus_private_ip}:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "5s"
      queryTimeout: "60s"
      httpMethod: "POST"
EOF

# Create dashboard provisioning directory and config
mkdir -p /etc/grafana/provisioning/dashboards
cat > /etc/grafana/provisioning/dashboards/dashboard.yml << EOF
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

# Create dashboards directory
mkdir -p /var/lib/grafana/dashboards

# Simplified Java App Monitoring Dashboard JSON
cat > /var/lib/grafana/dashboards/simplified-java-app-monitoring.json << 'EOF_JAVA_DASHBOARD'
{
    "id": null,
    "title": "Simplified Java App Monitoring",
    "tags": ["java", "monitoring", "simplified"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "HTTP Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_server_requests_seconds_count[5m]))",
            "legendFormat": "Total Requests",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "HTTP Request Latency (95th Percentile)",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket[5m])) by (le))",
            "legendFormat": "95th Percentile",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "JVM Heap Memory Used",
        "type": "graph",
        "targets": [
          {
            "expr": "jvm_memory_used_bytes{area=\"heap\"}",
            "legendFormat": "Heap Used",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
      },
      {
        "id": 4,
        "title": "Process CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "process_cpu_usage",
            "legendFormat": "Process CPU",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
      }
    ],
    "time": {"from": "now-1h", "to": "now"},
    "refresh": "5s"
  }
EOF_JAVA_DASHBOARD

# Simplified Infrastructure Overview Dashboard JSON
cat > /var/lib/grafana/dashboards/simplified-infrastructure-overview.json << 'EOF_INFRA_DASHBOARD'
{

    "id": null,
    "title": "Simplified Infrastructure Overview",
    "tags": ["infrastructure", "overview", "simplified"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "System Status Overview",
        "type": "stat",
        "targets": [
          {
            "expr": "count(up{job=\"java-app\"} == 1)",
            "legendFormat": "Java App Status",
            "refId": "A"
          },
          {
            "expr": "count(up{job=\"node-exporter\"} == 1)",
            "legendFormat": "Nodes Online",
            "refId": "B"
          }
        ],
        "gridPos": {"h": 6, "w": 24, "x": 0, "y": 0},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "green", "value": 1}
              ]
            },
            "unit": "short"
          }
        }
      },
      {
        "id": 2,
        "title": "Node CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{instance}} CPU Usage",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 6}
      },
      {
        "id": 3,
        "title": "Node Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "{{instance}} Memory Usage",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 6}
      },
      {
        "id": 4,
        "title": "Node Disk Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "(1 - (node_filesystem_avail_bytes{fstype!=\"tmpfs\"} / node_filesystem_size_bytes{fstype!=\"tmpfs\"})) * 100",
            "legendFormat": "{{instance}} {{mountpoint}}",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 14}
      }
    ],
    "time": {"from": "now-6h", "to": "now"},
    "refresh": "1m"
  }
EOF_INFRA_DASHBOARD


chown -R grafana:grafana /etc/grafana
chown -R grafana:grafana /var/lib/grafana

# Start and enable Grafana service
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server

echo "Access Grafana at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
