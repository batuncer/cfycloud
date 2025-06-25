#!/bin/bash

# Grafana Setup Script with Enhanced Dashboard Configuration
set -e

# Update system
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
default_home_dashboard_path = /var/lib/grafana/dashboards/java-backend-monitoring.json

[alerting]
enabled = true
execute_alerts = true

[smtp]
enabled = false
EOF

# Create datasource configuration
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

# Create dashboard provisioning configuration
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

# Download dashboard configurations from the Terraform directory
# Note: In a real deployment, these would be copied from your Terraform configuration
cat > /var/lib/grafana/dashboards/java-backend-monitoring.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Java Backend Monitoring Dashboard",
    "description": "Comprehensive monitoring dashboard for Java backend application and infrastructure",
    "tags": ["java", "monitoring", "prometheus", "infrastructure"],
    "timezone": "browser",
    "editable": true,
    "graphTooltip": 1,
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "timepicker": {
      "refresh_intervals": ["5s", "10s", "30s", "1m", "5m", "15m", "30m", "1h", "2h", "1d"],
      "time_options": ["5m", "15m", "1h", "6h", "12h", "24h", "2d", "7d", "30d"]
    },
    "refresh": "30s",
    "panels": [
      {
        "id": 1,
        "title": "Service Overview",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"java-app\"}",
            "legendFormat": "Java App Status",
            "refId": "A"
          },
          {
            "expr": "up{job=\"prometheus\"}",
            "legendFormat": "Prometheus Status",
            "refId": "B"
          },
          {
            "expr": "up{job=\"node-exporter\"}",
            "legendFormat": "Node Exporter Status",
            "refId": "C"
          }
        ],
        "gridPos": {"h": 6, "w": 24, "x": 0, "y": 0},
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "green", "value": 1}
              ]
            },
            "mappings": [
              {"options": {"0": {"text": "DOWN"}}, "type": "value"},
              {"options": {"1": {"text": "UP"}}, "type": "value"}
            ]
          }
        }
      },
      {
        "id": 2,
        "title": "HTTP Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_server_requests_seconds_count[5m])) by (uri, method)",
            "legendFormat": "{{method}} {{uri}}",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 6},
        "yAxes": [
          {"label": "Requests/sec", "min": 0},
          {"show": false}
        ],
        "xAxis": {"show": true},
        "legend": {"show": true, "values": false, "min": false, "max": false, "current": false, "total": false, "avg": false}
      },
      {
        "id": 3,
        "title": "HTTP Request Latency",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket[5m])) by (le, uri, method))",
            "legendFormat": "{{method}} {{uri}} - 95th",
            "refId": "A"
          },
          {
            "expr": "histogram_quantile(0.50, sum(rate(http_server_requests_seconds_bucket[5m])) by (le, uri, method))",
            "legendFormat": "{{method}} {{uri}} - 50th",
            "refId": "B"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 6},
        "yAxes": [
          {"label": "Seconds", "min": 0},
          {"show": false}
        ]
      },
      {
        "id": 4,
        "title": "JVM Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "jvm_memory_used_bytes{area=\"heap\"}",
            "legendFormat": "Heap Used",
            "refId": "A"
          },
          {
            "expr": "jvm_memory_max_bytes{area=\"heap\"}",
            "legendFormat": "Heap Max",
            "refId": "B"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 14},
        "yAxes": [
          {"label": "Bytes", "min": 0},
          {"show": false}
        ]
      },
      {
        "id": 5,
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "system_cpu_usage",
            "legendFormat": "System CPU",
            "refId": "A"
          },
          {
            "expr": "process_cpu_usage",
            "legendFormat": "Process CPU",
            "refId": "B"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 14},
        "yAxes": [
          {"label": "Percentage", "min": 0, "max": 1},
          {"show": false}
        ]
      }
    ]
  }
}
EOF

cat > /var/lib/grafana/dashboards/infrastructure-overview.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Infrastructure Overview Dashboard",
    "description": "High-level overview of infrastructure health and performance",
    "tags": ["infrastructure", "overview", "monitoring"],
    "timezone": "browser",
    "editable": true,
    "graphTooltip": 1,
    "time": {
      "from": "now-6h",
      "to": "now"
    },
    "refresh": "1m",
    "panels": [
      {
        "id": 1,
        "title": "System Status Overview",
        "type": "stat",
        "targets": [
          {
            "expr": "count(up{job=\"java-app\"} == 1)",
            "legendFormat": "Java Apps Online",
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
        "title": "Uptime History",
        "type": "graph",
        "targets": [
          {
            "expr": "up{job=\"java-app\"}",
            "legendFormat": "Java Application",
            "refId": "A"
          },
          {
            "expr": "up{job=\"node-exporter\"}",
            "legendFormat": "Node Exporter",
            "refId": "B"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 6},
        "yAxes": [
          {"label": "Status", "min": 0, "max": 1},
          {"show": false}
        ]
      }
    ]
  }
}
EOF

# Set ownership
chown -R grafana:grafana /etc/grafana
chown -R grafana:grafana /var/lib/grafana

# Start and enable Grafana
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server

echo "Grafana setup completed successfully!"
echo "Access Grafana at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "Default credentials: admin/admin123"
echo "Dashboards have been automatically provisioned"

