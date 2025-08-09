# Configuration spécifique pour l'environnement de production OVH

## 🌍 Domaines configurés

Vos services sont maintenant accessibles via les domaines suivants :

### Services principaux
- **Traefik Dashboard**: https://traefik.wk-archi-023b-4-5-g7.fr
- **Jenkins**: https://jenkins.wk-archi-023b-4-5-g7.fr
- **Gitea**: https://gitea.wk-archi-023b-4-5-g7.fr
- **Registry**: https://registry.wk-archi-023b-4-5-g7.fr

### Monitoring
- **Prometheus**: https://prometheus.wk-archi-023b-4-5-g7.fr
- **Grafana**: https://grafana.wk-archi-023b-4-5-g7.fr

## 🔐 Certificats SSL

Les certificats SSL sont automatiquement générés par Let's Encrypt via Traefik pour tous vos domaines.

## 📊 Accès local (backup)

En cas de problème avec les domaines, vous pouvez toujours accéder localement :
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001
- Jenkins: http://localhost:8081
- Node Exporter: http://localhost:9100
- cAdvisor: http://localhost:8080

## ⚙️ Configuration DNS requise

Assurez-vous que vos enregistrements DNS pointent vers votre serveur :

```dns
traefik.wk-archi-023b-4-5-g7.fr    A    [IP_SERVEUR]
jenkins.wk-archi-023b-4-5-g7.fr    A    [IP_SERVEUR] 
gitea.wk-archi-023b-4-5-g7.fr      A    [IP_SERVEUR]
registry.wk-archi-023b-4-5-g7.fr   A    [IP_SERVEUR]
prometheus.wk-archi-023b-4-5-g7.fr A    [IP_SERVEUR]
grafana.wk-archi-023b-4-5-g7.fr    A    [IP_SERVEUR]
```

## 🚀 Démarrage

```powershell
.\manage-stack.ps1 start
```

## 🔍 Vérification

Une fois démarré, vérifiez :

1. **Traefik Dashboard**: https://traefik.wk-archi-023b-4-5-g7.fr pour voir tous les services
2. **Prometheus targets**: https://prometheus.wk-archi-023b-4-5-g7.fr/targets
3. **Grafana**: https://grafana.wk-archi-023b-4-5-g7.fr (admin/admin)

## 📈 Prometheus Targets

Prometheus surveille automatiquement :
- ✅ Traefik metrics (via traefik:8080/metrics)
- ✅ Docker daemon (via host.docker.internal:9323)  
- ✅ Jenkins (via jenkins:8080/prometheus - nécessite plugin)
- ✅ Gitea (via gitea:3000/metrics)
- ✅ Registry (via registry:5000/metrics)
- ✅ Node Exporter (via node-exporter:9100)
- ✅ cAdvisor (via cadvisor:8080)
- ✅ Prometheus self-monitoring

## 🛡️ Sécurité

- Changez le mot de passe Grafana par défaut (admin/admin)
- Configurez l'authentification pour Prometheus si nécessaire
- Les certificats SSL sont automatiquement renouvelés
