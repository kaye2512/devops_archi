# 🎯 Guide de Résolution - Targets Prometheus DOWN

## 🚨 Problème Identifié
Vos targets Prometheus (Gitea, Registry, Jenkins, Docker) sont DOWN parce que :

1. **Docker daemon** : Métriques non activées
2. **Jenkins** : Plugin Prometheus manquant  
3. **Gitea** : Métriques non configurées
4. **Registry** : Port métriques non configuré

## ⚡ Solution Rapide (5 minutes)

### Étape 1: Exécuter le script de correction automatique
```bash
chmod +x *.sh
./fix-prometheus-targets.sh
```

### Étape 2: Activer les métriques Docker (en tant que root)
```bash
sudo ./setup-docker-metrics.sh
```

### Étape 3: Configurer Jenkins (via interface web)
1. Allez sur https://jenkins.wk-archi-o23b-4-5-g7.fr
2. Manage Jenkins > Manage Plugins
3. Installez "Prometheus metrics plugin"
4. Redémarrez Jenkins

### Étape 4: Redémarrer la stack
```bash
./manage-stack.sh restart
```

### Étape 5: Vérifier les résultats
```bash
./prometheus-debug.sh
```

## 📊 Résultats Attendus

Après correction, vos targets devraient être :

| Target | Status | URL Métriques |
|--------|--------|---------------|
| **prometheus** | 🟢 UP | http://prometheus:9090/metrics |
| **traefik** | 🟢 UP | http://traefik:8080/metrics |
| **node-exporter** | 🟢 UP | http://node-exporter:9100/metrics |
| **cadvisor** | 🟢 UP | http://cadvisor:8080/metrics |
| **gitea** | 🟢 UP | http://gitea:3000/metrics |
| **registry** | 🟢 UP | http://registry:5001/metrics |
| **docker** | 🟢 UP | http://host.docker.internal:9323/metrics |
| **jenkins** | 🟢 UP | http://jenkins:8080/prometheus |

## 🔍 Diagnostic Détaillé

Si certains targets restent DOWN après la correction :

```bash
# Test de connectivité complet
./prometheus-debug.sh

# Vérification des réseaux
./network-check.sh validate

# Test manuel d'un endpoint
docker exec prometheus curl -s http://gitea:3000/metrics | head -5
```

## 🛠️ Dépannage par Service

### Docker Daemon DOWN
```bash
# Vérifier la configuration
sudo cat /etc/docker/daemon.json

# Vérifier le service
sudo systemctl status docker

# Tester l'endpoint
curl http://localhost:9323/metrics
```

### Jenkins DOWN
```bash
# Vérifier que Jenkins est accessible
docker exec prometheus curl -s http://jenkins:8080/prometheus

# Voir les logs Jenkins
docker logs jenkins | grep -i prometheus
```

### Gitea DOWN
```bash
# Vérifier la configuration
docker exec gitea cat /data/gitea/conf/app.ini | grep -A3 "\[metrics\]"

# Tester l'endpoint
docker exec prometheus curl -s "http://gitea:3000/metrics?token=prometheus-metrics-token"
```

### Registry DOWN
```bash
# Vérifier les variables d'environnement
docker inspect registry | grep -i prometheus

# Tester l'endpoint debug
docker exec prometheus curl -s http://registry:5001/metrics
```

## ✅ Validation Finale

Une fois tout configuré :

1. **Interface Prometheus** : https://prometheus.wk-archi-o23b-4-5-g7.fr/targets
2. **Tous les targets UP** : 8/8 services actifs
3. **Métriques disponibles** : Chaque service expose ses métriques
4. **Dashboards Grafana** : Données visibles dans Grafana

## 🎯 Points Clés

- **Configuration automatique** : La plupart des corrections sont automatisées
- **Docker metrics** : Requiert les privilèges root (sudo)
- **Jenkins plugin** : Installation manuelle nécessaire
- **Réseaux** : Tous les services connectés automatiquement

## 📞 Support

En cas de problème persistant :
```bash
# Debug complet
./prometheus-debug.sh > debug-prometheus.log 2>&1

# Status des conteneurs
docker compose ps

# Logs Prometheus
docker logs prometheus | tail -50
```

---

🎉 **Après ces étapes, tous vos targets Prometheus devraient être UP et fonctionnels !**
