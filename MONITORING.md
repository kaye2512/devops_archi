# 📊 Monitoring Stack - Guide Complet

## 🎯 Vue d'Ensemble

La stack de monitoring collecte automatiquement les métriques de tous les services de la plateforme DevOps et les visualise via Grafana.

## 🔧 Architecture Monitoring

```
[Sources de Métriques] → [Prometheus] → [Grafana] → [Dashboards]
         ↓
┌─────────────────────────────────────────────────────────┐
│ • Docker Daemon (host.docker.internal:9323) ✅         │
│ • cAdvisor (containers metrics)              ✅         │  
│ • Node Exporter (system metrics)             ✅         │
│ • Traefik (HTTP metrics)                     ✅         │
│ • Jenkins (CI/CD metrics)                    ✅         │
│ • Gitea (Git metrics)                        ✅         │
│ • Registry (Docker registry)                 ✅         │
│ • Prometheus (self-monitoring)               ✅         │
└─────────────────────────────────────────────────────────┘
```

## 📈 Métriques Collectées

### 🐳 **Docker Daemon Metrics** 
- **Source** : `host.docker.internal:9323`
- **Métriques** :
  - `builder_builds_failed_total` - Builds Docker échoués
  - `docker_container_*` - Statistiques conteneurs
  - `docker_image_*` - Gestion des images  
  - `docker_system_*` - Métriques système Docker

### 📦 **cAdvisor - Container Metrics**
- **Source** : `cadvisor:8080`  
- **Métriques** :
  - `container_cpu_usage_seconds_total` - CPU par conteneur
  - `container_memory_usage_bytes` - Mémoire par conteneur
  - `container_network_*` - Trafic réseau
  - `container_fs_*` - I/O disque

### 🖥️ **Node Exporter - System Metrics** 
- **Source** : `node-exporter:9100`
- **Métriques** :
  - `node_cpu_seconds_total` - CPU système
  - `node_memory_*` - Mémoire système
  - `node_disk_*` - Utilisation disques
  - `node_network_*` - Interfaces réseau

### 🌐 **Traefik Metrics**
- **Source** : `traefik:8080/metrics`
- **Métriques** :
  - `traefik_http_requests_total` - Requêtes HTTP
  - `traefik_http_request_duration_seconds` - Latence
  - `traefik_entrypoint_*` - Points d'entrée
  - `traefik_service_*` - Services backend

### 🔧 **Jenkins Metrics** (si plugin Prometheus installé)
- **Source** : `jenkins:8080/prometheus`
- **Métriques** :
  - `jenkins_builds_*` - Statistiques builds
  - `jenkins_job_*` - Métriques jobs
  - `jenkins_executor_*` - Executeurs disponibles

### 📝 **Gitea Metrics**
- **Source** : `gitea:3000/metrics`
- **Métriques** :
  - `gitea_organizations` - Nombre d'organisations
  - `gitea_repositories` - Nombre de repos
  - `gitea_users` - Utilisateurs actifs

## 🎨 Dashboards Grafana

### **Dashboards Pré-configurés :**

1. **📊 System Overview**
   - CPU, RAM, Disque système
   - Charge système et uptime
   - Interfaces réseau

2. **🐳 Docker Containers**  
   - État des conteneurs
   - Consommation ressources par conteneur
   - Performances réseau containers

3. **🌐 Traefik HTTP**
   - Trafic HTTP temps réel
   - Codes de réponse  
   - Latence des services

4. **⚙️ Services Health**
   - État UP/DOWN des targets Prometheus
   - Alertes actives
   - Disponibilité des services

### **Dashboards Communautaires Recommandés :**

Importez ces dashboards via ID dans Grafana :

```bash
# Node Exporter Full (ID: 1860)
# Docker Container & Host Metrics (ID: 179)  
# Traefik 2.0 Dashboard (ID: 11462)
# Prometheus Stats (ID: 2)
```

## 🚨 Alertes & Notifications

### **Configuration Alertes** : `monitoring/alerts/rules.yml`

```yaml
groups:
  - name: infrastructure
    rules:
      # CPU élevé
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "CPU usage high on {{ $labels.instance }}"

      # Mémoire faible
      - alert: HighMemoryUsage  
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Memory usage critical on {{ $labels.instance }}"

      # Disque plein
      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Disk space low on {{ $labels.instance }}"

      # Service down
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
```

## 🔍 Vérification & Debug

### **Vérifier les Targets Prometheus :**
```bash
# Accéder à Prometheus targets
https://prometheus.wk-archi-o23b-4-5-g7.fr/targets

# Via manage-stack.sh
./manage-stack.sh status
```

### **Debug Métriques Manquantes :**
```bash
# Vérifier connectivité réseau
./manage-stack.sh check-networks

# Corriger les connexions réseau
./manage-stack.sh fix-networks  

# Logs Prometheus
./manage-stack.sh logs prometheus

# Redémarrer Prometheus
docker restart prometheus
```

### **Test Manuel des Métriques :**
```bash
# Docker metrics
curl -s http://localhost:9323/metrics | head -10

# Node metrics  
curl -s http://localhost:9100/metrics | head -10

# cAdvisor metrics
curl -s http://localhost:8080/metrics | head -10
```

## 🎛️ Configuration Avancée

### **Ajout Nouveaux Targets :**

Éditer `monitoring/prometheus.yml` :
```yaml
scrape_configs:
  - job_name: 'nouveau-service'
    static_configs:
      - targets: ['nouveau-service:port']
    scrape_interval: 30s
    metrics_path: '/metrics'
```

### **Métriques Custom - Exemple App :**
```yaml
# Application Node.js avec métriques
  - job_name: 'app-nodejs'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/api/metrics'
    scrape_interval: 15s
```

### **Rétention des Données :**
```yaml
# Dans docker-compose.yml - service prometheus
command:
  - '--storage.tsdb.retention.time=30d'  # 30 jours
  - '--storage.tsdb.retention.size=10GB' # Max 10GB
```

## 📊 Utilisation Quotidienne

### **Surveillance Temps Réel :**
1. **Grafana** : https://grafana.wk-archi-o23b-4-5-g7.fr  
   - Dashboard System Overview
   - Alertes actives

2. **Prometheus** : https://prometheus.wk-archi-o23b-4-5-g7.fr
   - État des targets  
   - Requêtes PromQL

### **Maintenance Monitoring :**
```bash
# Backup métriques (automatique via manage-stack.sh)
./manage-stack.sh backup

# Restart monitoring stack
docker restart prometheus grafana

# Cleanup anciennes métriques
docker exec prometheus rm -rf /prometheus/wal/*
```

---

## 🎯 Résumé

✅ **8 sources de métriques** configurées et fonctionnelles  
✅ **Monitoring complet** : Système + Applications + Docker  
✅ **Dashboards prêts** pour visualisation  
✅ **Alertes configurées** pour problèmes critiques  
✅ **URLs HTTPS** sécurisées pour tous les services  

**🚀 Stack de monitoring production-ready avec collecte automatique !**
