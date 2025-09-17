# TestTask Infra Stack (Docker Compose + Ansible)

This repository provisions and deploys a complete infrastructure stack using **Ansible** and **Docker Compose v2**.  
It includes:

- **NGINX reverse proxy** and static storage
- **CockroachDB cluster** (5 nodes + init job)
- **Monitoring stack**: Prometheus, Alertmanager, Node Exporter, NGINX Exporters
- **Grafana dashboards**
- **Custom daemon-monitor sidecar**

---

## 🔧 Quickstart

```bash
# Clone repo
git clone <this-repo-url>
cd testtask-infra

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml

# Run locally
ansible-playbook infra_init.yml

# Or run remotely
ansible-playbook infra_init.yml -e "target_host=1.2.3.4 target_user=ubuntu"
```

---

## 📡 Services

| Service    | Port(s)   | Notes             |
|------------|-----------|-------------------|
| Proxy      | 80,443    | HTTP/HTTPS        |
| Prometheus | 9090      | Metrics           |
| Grafana    | 3000      | Dashboards        |
| Cockroach  | 26257–61  | SQL endpoints     |
| …          | …         | …                 |

(see full table in compose file)

---

## 📂 Structure

- `infra_init.yml` → Ansible playbook  
- `tasks/docker.yml` → install Docker  
- `roles/stack/` → deploy compose project  
- `project/` → docker-compose.yml + configs  

---

## 🧹 Maintenance

- Stop stack:  
  ```bash
  ansible-playbook infra_init.yml --tags stack -e "state=absent"
  ```
- Check containers: `docker ps`  
- Logs: `docker compose -f /opt/infra/docker-compose.yml logs -f`
