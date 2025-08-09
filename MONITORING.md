# DevOps Platform with Monitoring

Cette plateforme DevOps inclut un stack de monitoring complet avec Prometheus et Grafana.

## 🚀 Services Inclus

### Infrastructure
- **Traefik**: Reverse proxy et load balancer
- **Jenkins**: CI/CD 
- **Gitea**: Git repository manager
- **Docker Registry**: Registry Docker privé

### Monitoring
- **Prometheus**: Collecte de métriques
- **Grafana**: Visualisation et dashboards
- **Node Exporter**: Métriques système
- **cAdvisor**: Métriques containers

## 🎯 Accès aux Services

| Service | URL Locale | URL avec Traefik | Credentials |
|---------|------------|------------------|-------------|
| Traefik Dashboard | http://localhost:8080 | http://traefik.localhost | - |
| Jenkins | http://localhost:8081 | http://jenkins.localhost | Setup initial |
| Gitea | - | http://gitea.localhost | Setup initial |
| Registry | http://localhost:5000 | http://registry.localhost | - |
| **Prometheus** | **http://localhost:9090** | **http://prometheus.localhost** | **-** |
| **Grafana** | **http://localhost:3001** | **http://grafana.localhost** | **admin/admin** |
| Node Exporter | http://localhost:9100 | - | - |
| cAdvisor | http://localhost:8080 | - | - |

## 🛠️ Utilisation

### Démarrage rapide avec PowerShell
```powershell
# Démarrer tous les services
.\manage-stack.ps1 start

# Vérifier le status
.\manage-stack.ps1 status

# Voir les logs
.\manage-stack.ps1 logs

# Redémarrer
.\manage-stack.ps1 restart

# Arrêter
.\manage-stack.ps1 stop
```

### Commandes Docker Compose classiques
```bash
# Démarrer
docker-compose up -d

# Arrêter
docker-compose down

# Voir les logs
docker-compose logs -f

# Status
docker-compose ps
```

## 📊 Configuration Monitoring

### Prometheus
- **Configuration**: `monitoring/prometheus.yml`
- **Alertes**: `monitoring/alerts/rules.yml`
- **Targets surveillées**:
  - Docker daemon metrics
  - Traefik metrics 
  - Jenkins metrics (nécessite le plugin Prometheus)
  - Gitea metrics
  - Registry metrics
  - Node Exporter (métriques système)
  - cAdvisor (métriques containers)

### Grafana
- **Datasource**: Prometheus (configuré automatiquement)
- **Provisioning**: `grafana/provisioning/`
- **Credentials par défaut**: admin/admin
- **Dashboards recommandés à importer**:
  - Node Exporter Full (ID: 1860)
  - Docker Container & Host Metrics (ID: 179)
  - Traefik 2.0 Dashboard (ID: 11462)

## 🔧 Configuration des Métriques par Service

### Jenkins
Pour activer les métriques Prometheus dans Jenkins :
1. Installer le plugin "Prometheus metrics plugin"
2. Les métriques seront disponibles sur `/prometheus`

### Gitea
Les métriques Gitea sont activées par défaut sur `/metrics`

### Traefik
Les métriques Traefik sont activées via les paramètres de configuration dans docker-compose.yml

## 🚨 Alertes Configurées

Les alertes suivantes sont configurées dans `monitoring/alerts/rules.yml`:
- **ServiceDown**: Service indisponible
- **HighCPUUsage**: CPU > 80%
- **HighMemoryUsage**: Mémoire > 80% 
- **DiskSpaceLow**: Espace disque > 90%
- **ContainerHighCPU**: CPU container > 80%

## 🌐 Configuration réseau

- **traefik-net**: Réseau pour les services exposés via Traefik
- **tiptop-net**: Réseau externe pour la communication inter-services

## 📁 Structure des Volumes

```
data/registry/          # Données Docker Registry
jenkins_home/           # Configuration Jenkins
gitea_data/            # Données Gitea
grafana_data/          # Dashboards et configuration Grafana
```

## 🔍 Troubleshooting

### Vérifier les services
```powershell
.\manage-stack.ps1 status
```

### Voir les logs d'un service spécifique
```powershell
.\manage-stack.ps1 logs prometheus
.\manage-stack.ps1 logs grafana
```

### Accès aux métriques
- Prometheus targets: http://localhost:9090/targets
- Prometheus metrics: http://localhost:9090/metrics  
- Node metrics: http://localhost:9100/metrics
- Container metrics: http://localhost:8080/metrics

### Domaines .localhost
Si les domaines .localhost ne fonctionnent pas, ajoutez-les à votre fichier hosts :
```
127.0.0.1 traefik.localhost
127.0.0.1 jenkins.localhost  
127.0.0.1 gitea.localhost
127.0.0.1 registry.localhost
127.0.0.1 prometheus.localhost
127.0.0.1 grafana.localhost
```

## 📈 Premiers pas avec Grafana

1. Connectez-vous à Grafana: http://localhost:3001 (admin/admin)
2. Le datasource Prometheus est déjà configuré
3. Importez des dashboards :
   - Go to + > Import
   - Utilisez les IDs recommandés ci-dessus
   - Sélectionnez Prometheus comme datasource

## 🔐 Sécurité

- Changez les mots de passe par défaut en production
- Utilisez HTTPS avec des certificats valides
- Configurez l'authentification appropriée
- Limitez l'accès aux interfaces d'administration
