# TestTask Infra Stack (Docker Compose + Ansible)

All the things is also possible to check in project/docker-compose.yml

- NGINX reverse proxy and static storage
- CockroachDB cluster (5 nodes + first init job)
- Monitoring stack: Prometheus, Alertmanager, Node Exporter, NGINX Exporters
- Grafana dashboards
- Custom daemon-monitor sidecar

---

# Install Ansible reqs
ansible-galaxy collection install -r requirements.yml

# Could run locally
ansible-playbook infra_init.yml

# Or remotely
ansible-playbook infra_init.yml -e "target_host=1.2.3.4 target_user=ubuntu"

---

## Services and ports

# Monitoring & metrics
Proxy with storage: 80/443
Prometheus: 9090
Grafana: 3000
Alert-manager: 9093
Node exporter: 9100
Nginx proxy exporter: 9101
Nginx storage exporter: 9102

# DB cluster
CockroachDB: SQL stream = 26256 / UI stream - 8090

# Custom app
Daemon monitor app: 9200

---

## Structure

- infra_init.yml → Ansible playbook
- tasks/docker.yml → install Docker
- roles/stack/ → deploy compose project
- project/ → docker-compose.yml + configs

---

## Data, confs and log folders
All data folders could be found in /data directory.

# Important
Shared files = project/data/local-storage

Dockerfile image and app scripts = project/monitoring/daemon-monitor
Custom app log output with tests = project/data/daemon-monitor/current

Configuration files for prometheus, alert-manager and grafana = project/monitoring/*

Configs for nginx = project/nginx
