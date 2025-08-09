#!/bin/bash

# Script de diagnostic pour les targets Prometheus
# Usage: ./prometheus-debug.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Diagnostic des Targets Prometheus${NC}"
echo -e "${BLUE}====================================${NC}"

# Vérifier que Prometheus est en marche
echo -e "\n${CYAN}📊 Vérification de Prometheus...${NC}"
if docker ps --filter "name=prometheus" --filter "status=running" | grep -q "prometheus"; then
    echo -e "${GREEN}✅ Prometheus est en cours d'exécution${NC}"
else
    echo -e "${RED}❌ Prometheus n'est pas en cours d'exécution${NC}"
    exit 1
fi

# Fonction pour tester la connectivité réseau
test_connectivity() {
    local service=$1
    local port=$2
    local container=${3:-prometheus}
    
    echo -e "${YELLOW}🔍 Test de connectivité: $service:$port${NC}"
    
    # Test depuis Prometheus
    if docker exec $container nc -z $service $port 2>/dev/null; then
        echo -e "${GREEN}  ✅ $service:$port - Accessible depuis Prometheus${NC}"
        return 0
    else
        echo -e "${RED}  ❌ $service:$port - NON accessible depuis Prometheus${NC}"
        return 1
    fi
}

# Fonction pour tester les endpoints de métriques
test_metrics_endpoint() {
    local service=$1
    local port=$2
    local path=$3
    local container=${4:-prometheus}
    
    echo -e "${YELLOW}🔍 Test endpoint métriques: $service:$port$path${NC}"
    
    # Test HTTP depuis Prometheus
    if docker exec $container wget -q --spider "http://$service:$port$path" 2>/dev/null; then
        echo -e "${GREEN}  ✅ $service:$port$path - Endpoint accessible${NC}"
        
        # Vérifier le contenu des métriques
        metrics_count=$(docker exec $container wget -qO- "http://$service:$port$path" 2>/dev/null | grep -c "^[a-zA-Z]" || echo "0")
        if [[ $metrics_count -gt 0 ]]; then
            echo -e "${GREEN}  📊 $metrics_count métriques trouvées${NC}"
        else
            echo -e "${YELLOW}  ⚠️  Aucune métrique trouvée${NC}"
        fi
        return 0
    else
        echo -e "${RED}  ❌ $service:$port$path - Endpoint NON accessible${NC}"
        return 1
    fi
}

# Tests pour chaque service
echo -e "\n${CYAN}🧪 Tests de connectivité réseau...${NC}"

# Docker daemon
echo -e "\n${BLUE}🐳 Docker Daemon${NC}"
if docker exec prometheus nc -z host.docker.internal 9323 2>/dev/null; then
    echo -e "${GREEN}✅ Docker daemon accessible${NC}"
else
    echo -e "${RED}❌ Docker daemon NON accessible${NC}"
    echo -e "${YELLOW}💡 Solution: Activez les métriques Docker${NC}"
    echo -e "${GRAY}   Ajoutez dans /etc/docker/daemon.json:${NC}"
    echo -e "${GRAY}   {\"metrics-addr\": \"0.0.0.0:9323\", \"experimental\": true}${NC}"
fi

# Traefik
echo -e "\n${BLUE}🌐 Traefik${NC}"
test_connectivity "traefik" "8080"
test_metrics_endpoint "traefik" "8080" "/metrics"

# Jenkins  
echo -e "\n${BLUE}🏗️ Jenkins${NC}"
test_connectivity "jenkins" "8080"
if test_connectivity "jenkins" "8080"; then
    test_metrics_endpoint "jenkins" "8080" "/prometheus"
    if ! test_metrics_endpoint "jenkins" "8080" "/prometheus"; then
        echo -e "${YELLOW}💡 Solution Jenkins:${NC}"
        echo -e "${GRAY}   1. Installez le plugin 'Prometheus metrics plugin'${NC}"
        echo -e "${GRAY}   2. Redémarrez Jenkins${NC}"
        echo -e "${GRAY}   3. Les métriques seront disponibles sur /prometheus${NC}"
    fi
fi

# Gitea
echo -e "\n${BLUE}🦌 Gitea${NC}"
test_connectivity "gitea" "3000"
if test_connectivity "gitea" "3000"; then
    test_metrics_endpoint "gitea" "3000" "/metrics"
    if ! test_metrics_endpoint "gitea" "3000" "/metrics"; then
        echo -e "${YELLOW}💡 Solution Gitea:${NC}"
        echo -e "${GRAY}   1. Activez les métriques dans app.ini:${NC}"
        echo -e "${GRAY}   [metrics]${NC}"
        echo -e "${GRAY}   ENABLED = true${NC}"
        echo -e "${GRAY}   TOKEN = <votre-token>${NC}"
    fi
fi

# Registry
echo -e "\n${BLUE}🗃️ Registry${NC}"
test_connectivity "registry" "5000"
if test_connectivity "registry" "5000"; then
    test_metrics_endpoint "registry" "5000" "/metrics"
    if ! test_metrics_endpoint "registry" "5000" "/metrics"; then
        echo -e "${YELLOW}💡 Solution Registry:${NC}"
        echo -e "${GRAY}   Les métriques Registry ne sont pas activées par défaut${NC}"
        echo -e "${GRAY}   Configuration nécessaire dans le docker-compose.yml${NC}"
    fi
fi

# Node Exporter
echo -e "\n${BLUE}📊 Node Exporter${NC}"
test_connectivity "node-exporter" "9100"
test_metrics_endpoint "node-exporter" "9100" "/metrics"

# cAdvisor
echo -e "\n${BLUE}📈 cAdvisor${NC}"
test_connectivity "cadvisor" "8080"
test_metrics_endpoint "cadvisor" "8080" "/metrics"

# Vérifier la configuration des réseaux
echo -e "\n${CYAN}🌐 Vérification des réseaux...${NC}"

SERVICES=("prometheus" "traefik" "jenkins" "gitea" "registry" "node-exporter" "cadvisor")

for service in "${SERVICES[@]}"; do
    if docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
        networks=$(docker inspect "$service" | grep -o '"NetworkMode": "[^"]*"' | cut -d'"' -f4)
        connected_networks=$(docker inspect "$service" | grep -A5 '"Networks"' | grep -o '"[^"]*":' | grep -v '"Networks":' | tr -d '":')
        
        echo -e "${WHITE}📦 $service:${NC}"
        echo -e "${GRAY}   NetworkMode: $networks${NC}"
        echo -e "${GRAY}   Réseaux connectés: $connected_networks${NC}"
        
        # Vérifier traefik-net
        if echo "$connected_networks" | grep -q "traefik-net"; then
            echo -e "${GREEN}   ✅ Connecté à traefik-net${NC}"
        else
            echo -e "${RED}   ❌ NON connecté à traefik-net${NC}"
        fi
        
        # Vérifier tiptop-net
        if echo "$connected_networks" | grep -q "tiptop-net"; then
            echo -e "${GREEN}   ✅ Connecté à tiptop-net${NC}"
        else
            echo -e "${YELLOW}   ⚠️  NON connecté à tiptop-net${NC}"
        fi
    fi
done

# Suggestions de correction
echo -e "\n${CYAN}🔧 Corrections recommandées...${NC}"

echo -e "\n${YELLOW}1. Activer les métriques Docker:${NC}"
echo -e "${GRAY}sudo tee /etc/docker/daemon.json <<EOF
{
  \"metrics-addr\": \"0.0.0.0:9323\",
  \"experimental\": true
}
EOF
sudo systemctl restart docker${NC}"

echo -e "\n${YELLOW}2. Correction Jenkins (installer plugin):${NC}"
echo -e "${GRAY}# Dans Jenkins > Manage Jenkins > Manage Plugins
# Installez: 'Prometheus metrics plugin'${NC}"

echo -e "\n${YELLOW}3. Activer métriques Gitea:${NC}"
echo -e "${GRAY}# Modifiez gitea/app.ini:
[metrics]
ENABLED = true${NC}"

echo -e "\n${YELLOW}4. Corriger les réseaux:${NC}"
echo -e "${GRAY}./manage-stack.sh fix-networks${NC}"

echo -e "\n${BLUE}📋 Vérifier les targets Prometheus:${NC}"
echo -e "${CYAN}curl http://localhost:9090/api/v1/targets${NC}"

echo -e "\n${GREEN}🎯 Une fois les corrections appliquées, redémarrez:${NC}"
echo -e "${CYAN}./manage-stack.sh restart${NC}"
