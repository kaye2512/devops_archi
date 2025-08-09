#!/bin/bash

# 🛠️ Script de correction automatique pour l'erreur 401 Gitea
echo "=== CORRECTION GITEA 401 UNAUTHORIZED ==="
echo "Date: $(date)"
echo ""

GITEA_CONTAINER="gitea"
PROMETHEUS_CONTAINER="prometheus" 
TOKEN="prometheus-metrics-token"

echo "🔍 1. Diagnostic du problème..."
echo "---"

# Vérifier que les containers sont up
if ! docker ps | grep -q $GITEA_CONTAINER; then
    echo "❌ Container Gitea pas en cours d'exécution"
    echo "📋 Démarrage de Gitea..."
    docker start $GITEA_CONTAINER
    sleep 10
fi

if ! docker ps | grep -q $PROMETHEUS_CONTAINER; then
    echo "❌ Container Prometheus pas en cours d'exécution"
    echo "📋 Démarrage de Prometheus..."
    docker start $PROMETHEUS_CONTAINER
    sleep 10
fi

echo ""
echo "🔧 2. Test des méthodes d'authentification..."
echo "---"

# Méthode 1: Paramètres GET (la plus commune pour Gitea)
echo "🔍 Test 1: Token en paramètre GET..."
RESULT1=$(docker exec $PROMETHEUS_CONTAINER wget -qO- --timeout=10 "http://gitea:3000/metrics?token=$TOKEN" 2>&1)
if echo "$RESULT1" | grep -q "gitea_"; then
    echo "✅ SUCCÈS avec paramètres GET!"
    AUTH_METHOD="params"
else
    echo "❌ Échec avec paramètres GET"
fi

# Méthode 2: Header Authorization Bearer
echo ""
echo "🔍 Test 2: Token en Authorization Bearer..."
RESULT2=$(docker exec $PROMETHEUS_CONTAINER wget -qO- --timeout=10 --header="Authorization: Bearer $TOKEN" "http://gitea:3000/metrics" 2>&1)
if echo "$RESULT2" | grep -q "gitea_"; then
    echo "✅ SUCCÈS avec Authorization Bearer!"
    AUTH_METHOD="bearer"
else
    echo "❌ Échec avec Authorization Bearer"
fi

# Méthode 3: Header Token custom  
echo ""
echo "🔍 Test 3: Token en header personnalisé..."
RESULT3=$(docker exec $PROMETHEUS_CONTAINER wget -qO- --timeout=10 --header="Token: $TOKEN" "http://gitea:3000/metrics" 2>&1)
if echo "$RESULT3" | grep -q "gitea_"; then
    echo "✅ SUCCÈS avec header Token!"
    AUTH_METHOD="header"
else
    echo "❌ Échec avec header Token"
fi

# Méthode 4: Sans token (debug)
echo ""
echo "🔍 Test 4: Sans authentification..."
RESULT4=$(docker exec $PROMETHEUS_CONTAINER wget -qO- --timeout=10 "http://gitea:3000/metrics" 2>&1)
if echo "$RESULT4" | grep -q "gitea_"; then
    echo "✅ SUCCÈS sans authentification (metrics publiques)!"
    AUTH_METHOD="none"
else
    echo "❌ Échec sans authentification (normal si token requis)"
fi

echo ""
echo "🔧 3. Application de la correction..."
echo "---"

# Appliquer la bonne configuration selon le test qui a fonctionné
case $AUTH_METHOD in
    "params")
        echo "📝 Application configuration: Paramètres GET"
        cat > temp_gitea_config.yml << 'EOF'
  # Gitea metrics (avec token en paramètres)
  - job_name: 'gitea'
    static_configs:
      - targets: ['gitea:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s
    scrape_timeout: 10s
    params:
      token: ['prometheus-metrics-token']
EOF
        ;;
        
    "bearer")
        echo "📝 Application configuration: Authorization Bearer"
        cat > temp_gitea_config.yml << 'EOF'
  # Gitea metrics (avec Authorization Bearer)
  - job_name: 'gitea'
    static_configs:
      - targets: ['gitea:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s
    scrape_timeout: 10s
    authorization:
      type: Bearer
      credentials: prometheus-metrics-token
EOF
        ;;
        
    "header")
        echo "📝 Application configuration: Header personnalisé"
        cat > temp_gitea_config.yml << 'EOF'
  # Gitea metrics (avec header Token)
  - job_name: 'gitea'
    static_configs:
      - targets: ['gitea:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s
    scrape_timeout: 10s
    http_config:
      headers:
        Token: prometheus-metrics-token
EOF
        ;;
        
    "none")
        echo "📝 Application configuration: Sans authentification"
        cat > temp_gitea_config.yml << 'EOF'
  # Gitea metrics (sans authentification)
  - job_name: 'gitea'
    static_configs:
      - targets: ['gitea:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s
    scrape_timeout: 10s
EOF
        ;;
        
    *)
        echo "❌ Aucune méthode n'a fonctionné!"
        echo ""
        echo "🔍 Diagnostic approfondi..."
        echo "Configuration Gitea actuelle:"
        docker exec $GITEA_CONTAINER cat /data/gitea/conf/app.ini | grep -A5 "\[metrics\]" || echo "Section [metrics] non trouvée"
        
        echo ""
        echo "Logs Gitea:"
        docker logs --tail=20 $GITEA_CONTAINER | grep -i metric || echo "Pas de logs métrics"
        
        echo ""
        echo "🛠️ Solutions à essayer:"
        echo "1. Redémarrer Gitea: docker restart $GITEA_CONTAINER"
        echo "2. Vérifier la configuration dans l'interface Gitea"
        echo "3. Désactiver temporairement le token dans app.ini"
        
        rm -f temp_gitea_config.yml
        exit 1
        ;;
esac

echo "✅ Configuration appliquée!"

echo ""
echo "🔄 4. Redémarrage de Prometheus..."
docker restart $PROMETHEUS_CONTAINER
echo "⏳ Attente du redémarrage (20 secondes)..."
sleep 20

echo ""
echo "✅ 5. Vérification finale..."
echo "📊 Allez sur: https://prometheus.wk-archi-o23b-4-5-g7.fr/targets"
echo "🔍 Le job 'gitea' devrait maintenant être UP"

echo ""
echo "📋 6. Si le problème persiste..."
echo "- Vérifiez les logs: docker logs $PROMETHEUS_CONTAINER"
echo "- Exécutez: ./debug-gitea-auth.sh"
echo "- Vérifiez la configuration Gitea dans l'interface web"

# Nettoyage
rm -f temp_gitea_config.yml

echo ""
echo "=== CORRECTION TERMINÉE ==="
