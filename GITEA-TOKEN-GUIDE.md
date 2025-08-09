# 🔐 Guide Complet : Token Métriques Gitea

## 🎯 Qu'est-ce que `prometheus-metrics-token` ?

### **Définition Simple**
Le `prometheus-metrics-token` est comme un **mot de passe** que Prometheus utilise pour accéder aux métriques privées de Gitea.

## 🔍 **Fonctionnement Détaillé**

### **Sans Token (Accès Libre)**
```bash
# Tentative d'accès sans authentification
curl http://gitea:3000/metrics
# ❌ Résultat : "Forbidden" ou "Unauthorized"
```

### **Avec Token (Accès Autorisé)**
```bash
# Accès avec le token correct
curl "http://gitea:3000/metrics?token=prometheus-metrics-token"
# ✅ Résultat : Données de métriques complètes
```

## 📋 **Configuration Actuelle**

### **Dans gitea/app.ini :**
```ini
[metrics]
ENABLED = true
TOKEN = prometheus-metrics-token  # ← Le token d'authentification
```

### **Dans monitoring/prometheus.yml :**
```yaml
- job_name: 'gitea'
  static_configs:
    - targets: ['gitea:3000']
  params:
    token: ['prometheus-metrics-token']  # ← Prometheus utilise ce token
```

## 🔐 **Sécurité du Token**

### **Token Actuel : `prometheus-metrics-token`**
- ✅ **Avantage** : Simple à comprendre
- ⚠️ **Inconvénient** : Prévisible, pas très sécurisé
- 🎯 **Usage** : OK pour développement/test

### **Token Sécurisé Recommandé**
```bash
# Exemple de token sécurisé (64 caractères aléatoires)
a1b2c3d4e5f6...xyz789  # Généré aléatoirement
```

## 🛠️ **Gestion du Token**

### **1. Voir le Token Actuel**
```bash
# Dans le conteneur Gitea
docker exec gitea cat /data/gitea/conf/app.ini | grep -A2 "\[metrics\]"

# Dans la configuration locale
cat gitea/app.ini | grep -A2 "\[metrics\]"
```

### **2. Changer le Token (Méthode Manuelle)**
```bash
# 1. Modifier gitea/app.ini
TOKEN = votre-nouveau-token-super-secret

# 2. Modifier monitoring/prometheus.yml
params:
  token: ['votre-nouveau-token-super-secret']

# 3. Redémarrer les services
docker restart gitea prometheus
```

### **3. Changer le Token (Script Automatique)**
```bash
chmod +x generate-gitea-token.sh
./generate-gitea-token.sh
```

## 🔍 **Tests et Vérification**

### **Test depuis l'Hôte (si Gitea expose le port)**
```bash
# Avec le token
curl "http://localhost:3000/metrics?token=prometheus-metrics-token"

# Sans token (devrait échouer)
curl "http://localhost:3000/metrics"
```

### **Test depuis Prometheus**
```bash
# Test de connectivité
docker exec prometheus nc -z gitea 3000

# Test de récupération des métriques
docker exec prometheus wget -qO- "http://gitea:3000/metrics?token=prometheus-metrics-token" | head -5
```

### **Vérifier dans Prometheus UI**
1. Allez sur https://prometheus.wk-archi-o23b-4-5-g7.fr/targets
2. Cherchez le job "gitea"
3. Status devrait être "UP" avec le bon token

## 🔒 **Bonnes Pratiques de Sécurité**

### **1. Token Fort**
```bash
# ✅ Bon token (aléatoire, long)
TOKEN = 4f8a2c9e1d7b5a3f9e8d7c6b5a4f3e2d1c9b8a7f6e5d4c3b2a1f9e8d7c6b5a4f

# ❌ Mauvais token (prévisible)
TOKEN = password123
TOKEN = gitea-token
```

### **2. Rotation Régulière**
- Changez le token **tous les 3-6 mois**
- Utilisez un générateur de tokens sécurisé
- Documentez les changements

### **3. Stockage Sécurisé**
```bash
# ✅ Fichier avec permissions restrictives
chmod 600 .env.gitea
echo "GITEA_TOKEN=secret" > .env.gitea

# ❌ Token en clair dans les logs
echo "Mon token est: secret"  # Ne faites jamais ça !
```

## 🚨 **Dépannage Token**

### **Problème : Gitea target toujours DOWN**

1. **Vérifier le token dans app.ini**
```bash
docker exec gitea cat /data/gitea/conf/app.ini | grep TOKEN
```

2. **Vérifier le token dans prometheus.yml**
```bash
grep -A3 "job_name: 'gitea'" monitoring/prometheus.yml
```

3. **Test manuel du token**
```bash
docker exec prometheus wget -qO- "http://gitea:3000/metrics?token=prometheus-metrics-token"
```

### **Problème : Token refusé**
- Le token dans app.ini ≠ token dans prometheus.yml
- Redémarrer Gitea après modification de app.ini
- Redémarrer Prometheus après modification de prometheus.yml

## 💡 **Alternatives au Token**

### **Option 1 : Pas de Token (moins sécurisé)**
```ini
[metrics]
ENABLED = true
# TOKEN = # Commenté = pas de token requis
```

### **Option 2 : Authentification Basique**
```yaml
# Dans prometheus.yml
basic_auth:
  username: prometheus
  password: secret
```

### **Option 3 : TLS avec Certificats**
```yaml
# Configuration avancée avec certificats
tls_config:
  cert_file: /path/to/cert
  key_file: /path/to/key
```

## 📊 **Métriques Disponibles avec le Token**

Une fois le token configuré, Gitea expose ces métriques :

- **`gitea_organizations`** : Nombre d'organisations
- **`gitea_users`** : Nombre d'utilisateurs  
- **`gitea_repositories`** : Nombre de repositories
- **`gitea_issues`** : Nombre d'issues
- **`gitea_pulls`** : Nombre de pull requests
- **Et beaucoup d'autres...**

## 🎯 **Résumé**

Le `prometheus-metrics-token` est :
- 🔐 **Un système de sécurité** pour protéger les métriques
- 🤝 **Un accord** entre Gitea et Prometheus  
- 🔑 **Une clé d'accès** aux données de monitoring
- 📊 **Essentiel** pour le bon fonctionnement du target Gitea

**C'est normal et nécessaire !** Sans ce token, Prometheus ne pourrait pas récupérer les métriques de Gitea de manière sécurisée.
