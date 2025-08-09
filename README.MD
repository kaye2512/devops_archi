# 🚀 Plateforme DevOps

Une plateforme DevOps complète basée sur Docker Compose intégrant Jenkins, Gitea, Traefik, Prometheus et Grafana.

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Services inclus](#services-inclus)
- [Prérequis](#prérequis)
- [Installation et démarrage](#installation-et-démarrage)
- [Configuration](#configuration)
- [Accès aux services](#accès-aux-services)
- [Monitoring](#monitoring)
- [Sécurité](#sécurité)
- [Maintenance](#maintenance)
- [Dépannage](#dépannage)

## 🎯 Vue d'ensemble

Cette plateforme DevOps offre un environnement complet pour le développement, l'intégration continue et le monitoring d'applications. Elle combine les outils essentiels de la chaîne DevOps moderne dans une architecture containerisée.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Traefik      │    │    Jenkins      │    │     Gitea       │
│   (Reverse      │    │   (CI/CD)       │    │   (Git Server)  │
│    Proxy)       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐    ┌─────────────────┐
                    │   Prometheus    │    │    Grafana      │
                    │   (Monitoring)  │    │  (Visualization)│
                    └─────────────────┘    └─────────────────┘
```

## 🔧 Services inclus

### 1. **Traefik** - Reverse Proxy et Load Balancer
- **Version**: v3.4
- **Fonctionnalités** :
  - Gestion automatique des certificats SSL/TLS avec Let's Encrypt
  - Routage intelligent basé sur les labels Docker
  - Dashboard d'administration
  - Redirection HTTP vers HTTPS automatique

### 2. **Jenkins** - Intégration Continue
- **Image**: jenkins-with-docker:latest (custom)
- **Fonctionnalités** :
  - Pipeline CI/CD
  - Intégration Docker native
  - Accès au socket Docker pour les builds
  - Interface web sécurisée

### 3. **Gitea** - Serveur Git
- **Version**: 1.21.11
- **Fonctionnalités** :
  - Gestion de dépôts Git
  - Interface web moderne
  - Gestion des utilisateurs et permissions
  - Intégration avec Jenkins

### 4. **Prometheus** - Monitoring
- **Fonctionnalités** :
  - Collecte de métriques
  - Monitoring des conteneurs Docker
  - Métriques Traefik
  - Stockage des données de monitoring

### 5. **Grafana** - Visualisation
- **Fonctionnalités** :
  - Dashboards de monitoring
  - Intégration Prometheus
  - Visualisation des métriques
  - Alertes configurables

### 6. **Registry** - Registre Docker privé
- **Image**: registry:2
- **Fonctionnalités** :
  - Hébergement d’images Docker privées pour vos projets
  - Accès sécurisé via HTTPS grâce à Traefik et Let's Encrypt
  - Stockage persistant des images dans `./data/registry`
  - Accessible à l’adresse : https://registry.wk-archi-o23b-4-5-g7.fr:5000

## 📋 Prérequis

- **Docker** : Version 20.10 ou supérieure
- **Docker Compose** : Version 2.0 ou supérieure
- **Système** : Linux, macOS ou Windows avec WSL2
- **Ressources** :
  - RAM : Minimum 4GB (recommandé 8GB)
  - CPU : 2 cœurs minimum
  - Stockage : 20GB d'espace libre

## 🚀 Installation et démarrage

### 1. Cloner le projet
```bash
git clone <votre-repo>
cd devops-platform
```

### 2. Construire l'image Jenkins personnalisée
```bash
cd jenkins
docker build -t jenkins-with-docker:latest .
cd ..
```

### 3. Démarrer la plateforme
```bash
docker-compose up -d
```

### 4. Vérifier le statut
```bash
docker-compose ps
```

## ⚙️ Configuration

### Variables d'environnement

Créer un fichier `.env` à la racine du projet :

```env
# Configuration Traefik
TRAEFIK_EMAIL=kayeromy@gmail.com
DOMAIN=wk-archi-o23b-4-5-g7.fr

# Configuration Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin

# Configuration Jenkins
JENKINS_PORT=8081
```

### Configuration des domaines

Modifier les labels Traefik dans `docker-compose.yml` pour vos domaines :

```yaml
labels:
  - "traefik.http.routers.jenkins.rule=Host(`jenkins.votre-domaine.com`)"
  - "traefik.http.routers.gitea.rule=Host(`gitea.votre-domaine.com`)"
  - "traefik.http.routers.grafana.rule=Host(`grafana.votre-domaine.com`)"
```

## 🌐 Accès aux services

Une fois démarré, accédez aux services via :

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Traefik Dashboard** | https://traefik.wk-archi-o23b-4-5-g7.fr | 80/443 | Interface d'administration Traefik |
| **Jenkins** | https://jenkins.wk-archi-o23b-4-5-g7.fr | 8081 | Interface CI/CD |
| **Gitea** | https://gitea.wk-archi-o23b-4-5-g7.fr | 3000 | Serveur Git |
| **Grafana** | https://grafana.wk-archi-o23b-4-5-g7.fr | 3000 | Dashboards de monitoring |
| **Prometheus** | https://prometheus.wk-archi-o23b-4-5-g7.fr | 9090 | Métriques système |
| **Registry** | https://registry.wk-archi-o23b-4-5-g7.fr | 5000 | Registre privé d’images Docker |

### Identifiants par défaut

- **Grafana** : admin/admin
- **Jenkins** : Suivre les instructions d'installation initiale
- **Gitea** : Créer un compte administrateur lors de la première connexion

## 📊 Monitoring

### Métriques collectées

- **Docker** : Utilisation CPU, mémoire, réseau
- **Traefik** : Requêtes HTTP, latence, erreurs
- **Jenkins** : Jobs, builds, temps d'exécution
- **Gitea** : Activité des dépôts, utilisateurs

### Dashboards Grafana

Les dashboards sont automatiquement provisionnés depuis `grafana/provisioning/dashboards/`.

### Alertes

Configurer les alertes dans `monitoring/alerts/rules.yml` :

```yaml
groups:
  - name: docker
    rules:
      - alert: HighCPUUsage
        expr: container_cpu_usage_seconds_total > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
```

## 🔒 Sécurité

### Certificats SSL/TLS
- Certificats automatiques via Let's Encrypt
- Renouvellement automatique
- Redirection HTTP vers HTTPS

### Accès sécurisé
- Traefik comme reverse proxy sécurisé
- Isolation réseau avec Docker networks
- Volumes persistants pour les données sensibles

### Bonnes pratiques
- Changer les mots de passe par défaut
- Configurer les pare-feu
- Surveiller les logs d'accès
- Mettre à jour régulièrement les images

## 🛠️ Maintenance

### Sauvegarde
```bash
# Sauvegarder les volumes
docker run --rm -v devops-platform_jenkins_home:/data -v $(pwd):/backup alpine tar czf /backup/jenkins-backup.tar.gz -C /data .
docker run --rm -v devops-platform_gitea_data:/data -v $(pwd):/backup alpine tar czf /backup/gitea-backup.tar.gz -C /data .
docker run --rm -v devops-platform_grafana_data:/data -v $(pwd):/backup alpine tar czf /backup/grafana-backup.tar.gz -C /data .
```

### Mise à jour
```bash
# Mettre à jour les images
docker-compose pull
docker-compose up -d
```

### Logs
```bash
# Voir les logs de tous les services
docker-compose logs -f

# Logs d'un service spécifique
docker-compose logs -f jenkins
```

## 🔧 Dépannage

### Problèmes courants

#### 1. Services ne démarrent pas
```bash
# Vérifier les logs
docker-compose logs

# Vérifier l'espace disque
df -h

# Vérifier les ports utilisés
netstat -tulpn | grep :80
```

#### 2. Certificats SSL non générés
- Vérifier que le domaine pointe vers le serveur
- Vérifier les logs Traefik : `docker-compose logs traefik`
- Vérifier la configuration Let's Encrypt

#### 3. Jenkins ne peut pas accéder à Docker
```bash
# Vérifier les permissions du socket Docker
ls -la /var/run/docker.sock

# Redémarrer Jenkins
docker-compose restart jenkins
```

#### 4. Gitea ne démarre pas
```bash
# Vérifier les permissions des volumes
sudo chown -R 1000:1000 gitea/

# Redémarrer Gitea
docker-compose restart gitea
```

### Commandes utiles

```bash
# Redémarrer tous les services
docker-compose restart

# Reconstruire et redémarrer
docker-compose up -d --build

# Nettoyer les conteneurs arrêtés
docker-compose down

# Ouvrir une réseau manuelement sur docker si on met external rue
docker network create tiptop-net


# Supprimer tous les volumes (⚠️ ATTENTION)
docker-compose down -v
```

## 📝 Structure du projet

```
devops-platform/
├── docker-compose.yml          # Configuration principale
├── jenkins/
│   └── Dockerfile             # Image Jenkins personnalisée
├── gitea/
│   └── app.ini               # Configuration Gitea
├── grafana/
│   └── provisioning/         # Dashboards et datasources
├── monitoring/
│   ├── prometheus.yml        # Configuration Prometheus
│   └── alerts/
│       └── rules.yml         # Règles d'alertes
└── traefik/
    └── letsencrypt/          # Certificats SSL
```

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

Pour toute question ou problème :
- Ouvrir une issue sur le repository
- Consulter la documentation officielle des outils utilisés
- Vérifier les logs des services

---

**Note** : Cette plateforme est conçue pour un environnement de développement/test. Pour la production, renforcez la sécurité et configurez des sauvegardes automatiques.