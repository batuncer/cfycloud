# Single-Instance Java Backend Monitoring with Docker Compose

This repository provides a complete Terraform setup to deploy my Java backend, database (RDS), and security on AWS. It also includes a monitoring solution using Docker Compose.

Everything — my Java app, Prometheus, Grafana, and Node Exporter — runs on a single EC2 instance. This makes it cost-effective and easy to manage for both development and production use.

## Architecture Overview

The solution deploys a single EC2 instance (`aws_instance.cfy_cloud`) that runs:
- **Java Application**: Dockerized Spring Boot application with Micrometer metrics
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Node Exporter**: System metrics collection
- **CloudWatch**: AWS infrastructure monitoring

## Service Configuration

### Docker Compose Services

My `docker-compose.yml` file defines four main services:

1. **java-app**: Java application container
   - Exposes port 8080
   - Connects to PostgreSQL database
   - Provides metrics at `/actuator/prometheus`

2. **prometheus**: Metrics collection service
   - Exposes port 9090
   - Scrapes metrics from Java app and Node Exporter
   - Includes alerting rules

3. **grafana**: Visualization service
   - Exposes port 3000
   - Pre-configured with Prometheus datasource
   - Includes pre-built dashboards

4. **node-exporter**: System metrics collector
   - Exposes port 9100
   - Provides host system metrics

### Monitoring Coverage

#### Service Level Metrics
- HTTP request rate and latency (95th percentile)
- JVM heap memory usage
- Thread count, active sessions, custom business metrics

#### Infrastructure Metrics
- Node CPU, memory, and disk usage
- System status (up/down indicators)
- Container health and resource usage

### Employee Metrics Dashboard

This project includes a custom **Employee Dashboard** in Grafana, which monitors business-specific metrics related to employee operations collected from the Java backend via Micrometer.

The dashboard shows:

- Total number of employees created, deleted, and updated (`employee_created_total`, `employee_deleted_total`, `employee_updated_total`)
- Latency of employee-related operations (`employee_operation_latency`) measured in milliseconds
- Time-series charts for employee creation, deletion, and update counts over time
-  Employee operations
- Alerts on high latency or abnormal employee operation counts

### Alert Rules

- **JavaAppDown**: Critical alert when Java application is unreachable
- **HighJavaAppLatency**: Warning when 95th percentile latency exceeds 2 seconds
- **HighJavaAppMemoryUsage**: Critical alert when JVM heap usage exceeds 90%
- **HighNodeCPUUsage**: Critical alert when CPU usage exceeds 90%
- **EmployeeOpsHighLatency**: Warning if latency for employee operations exceeds 1 second
- **EmployeeOpsErrorRate**: Critical alert if employee operation failure rate spikes  