# Guide de Déploiement Linux - Stack DevOps WK-Archi

## 🚀 Installation et Configuration sur VPS Linux

### Prérequis

1. **Docker et Docker Compose**
```bash
# Installation Docker (Ubuntu/Debian)
sudo apt update
sudo apt install -y docker.io

# Ou installer Docker avec Docker Compose intégré (recommandé)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Démarrer Docker
sudo systemctl enable docker
sudo systemctl start docker

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER

# Vérifier que Docker Compose est disponible
docker compose version
```

2. **Git** (si pas déjà installé)
```bash
sudo apt install -y git
```

### 📥 Déploiement

1. **Cloner le repository** (si pas déjà fait)
```bash
git clone https://github.com/kaye2512/devops_archi.git
cd devops_archi
```

2. **Rendre les scripts exécutables**
```bash
chmod +x start-production.sh manage-stack.sh stop-production.sh check-setup.sh network-check.sh
```

3. **Configurer votre domaine**
Assurez-vous que vos enregistrements DNS pointent vers votre VPS :
```
traefik.wk-archi-o23b-4-5-g7.fr    -> IP_DE_VOTRE_VPS
jenkins.wk-archi-o23b-4-5-g7.fr    -> IP_DE_VOTRE_VPS  
gitea.wk-archi-o23b-4-5-g7.fr      -> IP_DE_VOTRE_VPS
registry.wk-archi-o23b-4-5-g7.fr   -> IP_DE_VOTRE_VPS
prometheus.wk-archi-o23b-4-5-g7.fr -> IP_DE_VOTRE_VPS
grafana.wk-archi-o23b-4-5-g7.fr    -> IP_DE_VOTRE_VPS
```

### 🎯 Démarrage

```bash
# Démarrage complet
./start-production.sh

# Ou utilisation du script de gestion
./manage-stack.sh start
```

### 🛠️ Gestion

```bash
# Voir le statut
./manage-stack.sh status

# Voir les logs
./manage-stack.sh logs
./manage-stack.sh logs prometheus  # Pour un service spécifique

# Vérifier les connexions réseau
./manage-stack.sh check-networks

# Corriger les connexions réseau
./manage-stack.sh fix-networks

# Redémarrer
./manage-stack.sh restart

# Arrêter
./manage-stack.sh stop
```

### 🌐 Gestion des Réseaux

```bash
# Validation complète des réseaux
./network-check.sh

# Créer les réseaux Docker
./network-check.sh create

# Connecter les services aux réseaux
./network-check.sh connect

# Valider les connexions
./network-check.sh validate

# Tester la connectivité
./network-check.sh test
```

### 🔥 Firewall (Important!)

Configurez votre firewall pour sécuriser votre VPS :

```bash
# UFW (Ubuntu Firewall)
sudo ufw allow 22      # SSH
sudo ufw allow 80      # HTTP
sudo ufw allow 443     # HTTPS
sudo ufw enable

# Les ports des services de monitoring ne doivent PAS être ouverts publiquement
# Ils sont accessibles via Traefik avec SSL
```

### 📊 Accès aux Services

Une fois démarré, vos services seront disponibles à :

| Service | URL | Credentials |
|---------|-----|-------------|
| **Prometheus** | https://prometheus.wk-archi-o23b-4-5-g7.fr | - |
| **Grafana** | https://grafana.wk-archi-o23b-4-5-g7.fr | admin/admin |
| Traefik | https://traefik.wk-archi-o23b-4-5-g7.fr | - |
| Jenkins | https://jenkins.wk-archi-o23b-4-5-g7.fr | Setup initial |
| Gitea | https://gitea.wk-archi-o23b-4-5-g7.fr | Setup initial |
| Registry | https://registry.wk-archi-o23b-4-5-g7.fr | - |

### 🔍 Monitoring - Configuration

#### 1. Prometheus
- Accédez à https://prometheus.wk-archi-o23b-4-5-g7.fr
- Vérifiez les targets : `/targets`
- Tous les services doivent être "UP"

#### 2. Grafana
- Accédez à https://grafana.wk-archi-o23b-4-5-g7.fr
- Connectez-vous : admin/admin
- **CHANGEZ LE MOT DE PASSE immédiatement !**
- Le datasource Prometheus est pré-configuré

#### 3. Dashboards recommandés à importer

Dans Grafana, allez sur `+` → `Import` et utilisez ces IDs :

```
1860  - Node Exporter Full (métriques système)
179   - Docker Container & Host Metrics
11462 - Traefik 2.0 Dashboard
3662  - Prometheus 2.0 Overview
```

### 📈 Métriques Surveillées

- **Système** : CPU, RAM, Disque, Réseau (Node Exporter)
- **Containers** : Utilisation CPU/RAM par container (cAdvisor)  
- **Traefik** : Requêtes, codes de réponse, certificats SSL
- **Jenkins** : Jobs, build queue (nécessite plugin Prometheus)
- **Gitea** : Repos, utilisateurs, requêtes
- **Docker Registry** : Push/pull d'images

### 🚨 Alertes Configurées

Les alertes suivantes sont pré-configurées :
- Service indisponible (> 1min)
- CPU élevé (> 80% pendant 5min)
- Mémoire élevée (> 80% pendant 5min) 
- Espace disque faible (> 90%)
- CPU container élevé (> 80%)

### 💾 Sauvegardes

```bash
# Sauvegarde complète
./manage-stack.sh backup

# Les sauvegardes sont dans ./backups/YYYYMMDD_HHMMSS/
```

### 🔧 Configuration des Métriques par Service

### Réseaux Docker
Votre stack utilise deux réseaux principaux :
- **traefik-net** : Réseau pour l'exposition des services via Traefik
- **tiptop-net** : Réseau interne pour la communication inter-services

Tous les services de monitoring sont automatiquement connectés aux deux réseaux pour assurer :
- L'accès externe via Traefik (traefik-net)
- La collecte de métriques interne (tiptop-net)

### Jenkins

```bash
# Mettre à jour les images
./manage-stack.sh update

# Nettoyer Docker
./manage-stack.sh clean

# Voir les logs en temps réel
./manage-stack.sh logs
```

### 🐛 Dépannage

#### Services ne démarrent pas
```bash
# Vérifier les logs
./manage-stack.sh logs

# Vérifier l'espace disque
df -h

# Vérifier la mémoire
free -h

# Redémarrer Docker
sudo systemctl restart docker
./manage-stack.sh restart
```

#### Certificats SSL
```bash
# Vérifier les certificats dans les logs Traefik
./manage-stack.sh logs traefik

# Les certificats sont stockés dans ./letsencrypt/acme.json
```

#### Prometheus ne collecte pas les métriques
```bash
# Vérifier la connectivité réseau entre conteneurs
docker network ls
docker network inspect tiptop-net

# Vérifier la config Prometheus
cat monitoring/prometheus.yml

# Vérifier les targets Prometheus
curl http://localhost:9090/targets
```

### 🔐 Sécurité de Production

1. **Changez tous les mots de passe par défaut**
2. **Activez l'authentification 2FA où possible**  
3. **Configurez des sauvegardes automatiques**
4. **Surveillez les logs régulièrement**
5. **Mettez à jour régulièrement les images Docker**

### 📞 Support

En cas de problème, vérifiez :
1. Les logs : `./manage-stack.sh logs [service]`
2. Le status : `./manage-stack.sh status` 
3. L'espace disque : `df -h`
4. La connectivité DNS de vos domaines

## 🎉 Félicitations !

Votre stack DevOps avec monitoring est maintenant opérationnelle sur votre VPS Linux !
