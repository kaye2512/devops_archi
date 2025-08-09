#!/bin/bash

# 🔍 Script de Debug : Authentification Gitea Metrics
echo "=== DEBUG GITEA AUTHENTICATION ==="
echo "Date: $(date)"
echo ""

# Variables
GITEA_CONTAINER="gitea"
PROMETHEUS_CONTAINER="prometheus"
TOKEN="prometheus-metrics-token"

echo "📋 1. Vérification de la configuration Gitea..."
echo "---"
if docker ps | grep -q $GITEA_CONTAINER; then
    echo "✅ Container Gitea: RUNNING"
    
    # Vérifier la config dans le container
    echo ""
    echo "🔍 Configuration metrics dans Gitea:"
    docker exec $GITEA_CONTAINER cat /data/gitea/conf/app.ini | grep -A5 "\[metrics\]" || echo "❌ Section [metrics] non trouvée"
else
    echo "❌ Container Gitea: NOT RUNNING"
    exit 1
fi

echo ""
echo "📋 2. Tests d'accès aux métriques..."
echo "---"

# Test 1: Sans authentification
echo "🔍 Test 1: Accès sans token (devrait échouer)"
docker exec $PROMETHEUS_CONTAINER wget -qO- --timeout=5 "http://gitea:3000/metrics" 2>&1 | head -3 || echo "❌ Échec attendu (pas de token)"

echo ""
# Test 2: Avec token en paramètre GET  
echo "🔍 Test 2: Token en paramètre GET"
docker exec $PROMETHEUS_CONTAINER wget -qO- --timeout=5 "http://gitea:3000/metrics?token=$TOKEN" 2>&1 | head -3 || echo "❌ Échec avec paramètre GET"

echo ""
# Test 3: Avec header Authorization
echo "🔍 Test 3: Token en header Authorization"
docker exec $PROMETHEUS_CONTAINER wget -qO- --timeout=5 --header="Authorization: Bearer $TOKEN" "http://gitea:3000/metrics" 2>&1 | head -3 || echo "❌ Échec avec header Authorization"

echo ""
# Test 4: Avec header Token custom
echo "🔍 Test 4: Token en header Token"
docker exec $PROMETHEUS_CONTAINER wget -qO- --timeout=5 --header="Token: $TOKEN" "http://gitea:3000/metrics" 2>&1 | head -3 || echo "❌ Échec avec header Token"

echo ""
echo "📋 3. Vérification de la connectivité réseau..."
echo "---"
echo "🔍 Test ping Gitea depuis Prometheus:"
docker exec $PROMETHEUS_CONTAINER nc -z gitea 3000 && echo "✅ Port 3000 accessible" || echo "❌ Port 3000 inaccessible"

echo ""
echo "📋 4. Configuration Prometheus actuelle..."
echo "---"
echo "🔍 Job Gitea dans prometheus.yml:"
docker exec $PROMETHEUS_CONTAINER cat /etc/prometheus/prometheus.yml | grep -A10 "job_name: 'gitea'" || echo "❌ Job Gitea non trouvé"

echo ""
echo "📋 5. Logs Gitea (dernières 10 lignes)..."
echo "---"
docker logs --tail=10 $GITEA_CONTAINER 2>&1 | head -10

echo ""
echo "📋 6. Recommandations..."
echo "---"
echo "Si tous les tests échouent:"
echo "1. Vérifier que Gitea expose bien les métriques"
echo "2. Redémarrer Gitea: docker restart $GITEA_CONTAINER"
echo "3. Redémarrer Prometheus: docker restart $PROMETHEUS_CONTAINER"
echo "4. Vérifier les logs: docker logs $GITEA_CONTAINER"

echo ""
echo "=== FIN DEBUG ==="
