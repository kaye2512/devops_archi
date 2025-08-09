# 🚀 DevOps Platform WK-Archi

Plateforme DevOps complète avec monitoring intégré pour l'environnement de production.

## 🎯 Architecture

```
Internet → Traefik (80/443) → Services Backend
                ↓
    [Jenkins] [Gitea] [Registry] [Grafana] [Prometheus]
                ↓
        Monitoring Stack (Node-Exporter, cAdvisor)
```

## 🛠️ Services Déployés

| Service | URL | Description |
|---------|-----|-------------|
| **Traefik** | `https://traefik.wk-archi-o23b-4-5-g7.fr` | Reverse proxy + SSL automatique |
| **Jenkins** | `https://jenkins.wk-archi-o23b-4-5-g7.fr` | CI/CD Pipeline |
| **Gitea** | `https://gitea.wk-archi-o23b-4-5-g7.fr` | Git server |
| **Registry** | `https://registry.wk-archi-o23b-4-5-g7.fr` | Docker registry privé |
| **Grafana** | `https://grafana.wk-archi-o23b-4-5-g7.fr` | Dashboards (admin/admin) |
| **Prometheus** | `https://prometheus.wk-archi-o23b-4-5-g7.fr` | Métriques & monitoring |

## 🚀 Démarrage Rapide

### 1. **Démarrage complet**
```bash
./start-production.sh
```

### 2. **Gestion quotidienne**
```bash
./manage-stack.sh [start|stop|restart|status|logs]
```

### 3. **Vérification santé**
```bash
./check-setup.sh
```

### 4. **Arrêt**
```bash
./stop-production.sh
```

## 📊 Monitoring & Métriques

- **Prometheus** collecte automatiquement :
  - Métriques Docker (conteneurs, images, système)
  - Métriques Traefik (requêtes, latence)
  - Métriques système (CPU, mémoire, disque)
  - Métriques Gitea et Jenkins

- **Dashboards Grafana** pré-configurés pour visualiser toutes les métriques

## 🔧 Maintenance

```bash
# Logs en temps réel
./manage-stack.sh logs [service]

# Backup automatique
./manage-stack.sh backup

# Mise à jour images
./manage-stack.sh update

# Nettoyage Docker
./manage-stack.sh clean

# Diagnostic réseau
./manage-stack.sh check-networks
./manage-stack.sh fix-networks
```

## 🛡️ Sécurité

- ✅ **SSL/TLS automatique** via Let's Encrypt
- ✅ **Certificats auto-renouvelés**
- ✅ **Réseaux Docker isolés**
- ✅ **Accès sécurisé aux métriques**
- ✅ **Redirection HTTP → HTTPS**

## 🔍 Dépannage

| Problème | Solution |
|----------|----------|
| Service ne démarre pas | `./manage-stack.sh logs [service]` |
| Réseau inaccessible | `./manage-stack.sh fix-networks` |
| Métriques manquantes | Redémarrer Prometheus |
| SSL non généré | Vérifier DNS + Logs Traefik |

## 📋 Structure Projet

```
devops-platform/
├── 📄 docker-compose.yml           # Configuration principale
├── 🎛️ monitoring/prometheus.yml     # Config monitoring  
├── 📊 grafana/provisioning/         # Dashboards auto
├── 🔧 start-production.sh          # Démarrage complet
├── 🔧 manage-stack.sh             # Gestion quotidienne
├── 🔧 stop-production.sh          # Arrêt propre  
└── 🔧 check-setup.sh              # Vérifications
```

## ⚠️ Notes Importantes

1. **Premier démarrage** : `./start-production.sh` configure tout automatiquement
2. **Gestion quotidienne** : Utiliser `./manage-stack.sh` pour toutes les opérations
3. **Grafana** : Changer le mot de passe admin/admin après première connexion
4. **Backups** : Planifier `./manage-stack.sh backup` en cron

---
**🎯 Production Ready** | **📊 Monitoring Intégré** | **🔒 Sécurisé SSL** | **🚀 Déploiement 1-clic**
