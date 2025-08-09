#!/bin/bash

# Script de diagnostic spécifique Gitea et Docker
# Usage: ./debug-gitea-docker.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}🔍 Diagnostic Gitea et Docker Targets${NC}"
echo -e "${BLUE}====================================${NC}"

# Vérification des ports utilisés sur l'hôte
echo -e "\n${CYAN}🔌 Vérification des ports sur l'hôte:${NC}"
echo -e "${WHITE}Port 3000 (votre application):${NC}"
if ss -tuln | grep -q ":3000 "; then
    port_3000_process=$(ss -tulnp | grep ":3000 " | head -1)
    echo -e "${YELLOW}  ⚠️  Port 3000 utilisé: $port_3000_process${NC}"
else
    echo -e "${GREEN}  ✅ Port 3000 libre sur l'hôte${NC}"
fi

echo -e "${WHITE}Port 3001 (Grafana externe):${NC}"
if ss -tuln | grep -q ":3001 "; then
    echo -e "${GREEN}  ✅ Port 3001 utilisé (Grafana)${NC}"
else
    echo -e "${RED}  ❌ Port 3001 libre (Grafana pas accessible)${NC}"
fi

# Vérification des conteneurs
echo -e "\n${CYAN}📦 État des conteneurs:${NC}"

# Gitea
if docker ps --filter "name=gitea" --filter "status=running" | grep -q "gitea"; then
    echo -e "${GREEN}✅ Gitea: En cours d'exécution${NC}"
    
    # IP interne de Gitea
    gitea_ip=$(docker inspect gitea | grep -o '"IPAddress": "[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "${WHITE}   IP interne: $gitea_ip${NC}"
    
    # Ports exposés
    gitea_ports=$(docker inspect gitea | grep -A5 '"Ports"' | grep -o '"[0-9]*/tcp"' | tr -d '"')
    echo -e "${WHITE}   Ports internes: $gitea_ports${NC}"
    
    # Test de connectivité interne
    echo -e "${CYAN}🔍 Test connectivité Gitea:${NC}"
    if docker exec prometheus nc -z gitea 3000 2>/dev/null; then
        echo -e "${GREEN}  ✅ gitea:3000 accessible depuis Prometheus${NC}"
    else
        echo -e "${RED}  ❌ gitea:3000 NON accessible depuis Prometheus${NC}"
    fi
    
    # Test endpoint métriques
    echo -e "${CYAN}🔍 Test endpoint métriques Gitea:${NC}"
    if docker exec prometheus wget -qO- "http://gitea:3000/metrics?token=prometheus-metrics-token" 2>/dev/null | head -1; then
        echo -e "${GREEN}  ✅ Métriques Gitea accessibles${NC}"
    else
        echo -e "${RED}  ❌ Métriques Gitea NON accessibles${NC}"
        
        # Test sans token
        if docker exec prometheus wget -qO- "http://gitea:3000/metrics" 2>/dev/null | head -1; then
            echo -e "${YELLOW}  ⚠️  Métriques accessibles sans token${NC}"
        else
            echo -e "${RED}  ❌ Endpoint métriques complètement inaccessible${NC}"
        fi
    fi
    
else
    echo -e "${RED}❌ Gitea: Non démarré${NC}"
fi

# Vérification réseau Gitea
echo -e "\n${CYAN}🌐 Réseaux Gitea:${NC}"
if docker ps --filter "name=gitea" --filter "status=running" | grep -q "gitea"; then
    gitea_networks=$(docker inspect gitea | grep -A10 '"Networks"' | grep -o '"[^"]*":' | grep -v '"Networks":' | tr -d '":')
    echo -e "${WHITE}Réseaux connectés: $gitea_networks${NC}"
    
    for network in $gitea_networks; do
        if [[ "$network" == "traefik-net" || "$network" == "tiptop-net" ]]; then
            echo -e "${GREEN}  ✅ Connecté à $network${NC}"
        else
            echo -e "${GRAY}  ℹ️  Connecté à $network${NC}"
        fi
    done
fi

# Docker daemon
echo -e "\n${CYAN}🐳 Docker Daemon Metrics:${NC}"

# Vérifier la configuration Docker
if [[ -f /etc/docker/daemon.json ]]; then
    echo -e "${GREEN}✅ Fichier de configuration Docker existe${NC}"
    
    if grep -q "metrics-addr" /etc/docker/daemon.json 2>/dev/null; then
        echo -e "${GREEN}✅ Métriques configurées dans daemon.json${NC}"
        metrics_addr=$(grep "metrics-addr" /etc/docker/daemon.json | cut -d'"' -f4)
        echo -e "${WHITE}   Adresse métriques: $metrics_addr${NC}"
    else
        echo -e "${RED}❌ Métriques NON configurées dans daemon.json${NC}"
    fi
else
    echo -e "${RED}❌ Fichier daemon.json n'existe pas${NC}"
fi

# Test d'accès aux métriques Docker
echo -e "${CYAN}🔍 Test métriques Docker:${NC}"

# Test depuis l'hôte
if curl -s --max-time 5 http://localhost:9323/metrics > /dev/null 2>&1; then
    echo -e "${GREEN}  ✅ Métriques Docker accessibles depuis l'hôte (localhost:9323)${NC}"
else
    echo -e "${RED}  ❌ Métriques Docker NON accessibles depuis l'hôte${NC}"
fi

# Test depuis Prometheus
if docker exec prometheus nc -z host.docker.internal 9323 2>/dev/null; then
    echo -e "${GREEN}  ✅ host.docker.internal:9323 accessible depuis Prometheus${NC}"
else
    echo -e "${RED}  ❌ host.docker.internal:9323 NON accessible depuis Prometheus${NC}"
    
    # Essayer d'autres moyens d'accès
    echo -e "${YELLOW}  🔍 Test d'alternatives...${NC}"
    
    # Obtenir l'IP du bridge Docker
    docker_bridge_ip=$(docker network inspect bridge | jq -r '.[0].IPAM.Config[0].Gateway' 2>/dev/null)
    if [[ -n "$docker_bridge_ip" && "$docker_bridge_ip" != "null" ]]; then
        echo -e "${WHITE}     IP bridge Docker: $docker_bridge_ip${NC}"
        if docker exec prometheus nc -z $docker_bridge_ip 9323 2>/dev/null; then
            echo -e "${GREEN}     ✅ $docker_bridge_ip:9323 accessible${NC}"
        fi
    fi
fi

# Solutions recommandées
echo -e "\n${BLUE}💡 Solutions Recommandées:${NC}"

echo -e "\n${YELLOW}🦌 Pour Gitea:${NC}"
if ! docker exec prometheus nc -z gitea 3000 2>/dev/null; then
    echo -e "${WHITE}1. Vérifier que Gitea et Prometheus sont sur le même réseau:${NC}"
    echo -e "${GRAY}   docker network connect tiptop-net gitea${NC}"
    echo -e "${GRAY}   docker network connect tiptop-net prometheus${NC}"
fi

echo -e "${WHITE}2. Vérifier la configuration Gitea app.ini:${NC}"
if docker exec gitea test -f /data/gitea/conf/app.ini; then
    metrics_config=$(docker exec gitea grep -A3 "\[metrics\]" /data/gitea/conf/app.ini 2>/dev/null || echo "")
    if [[ -z "$metrics_config" ]]; then
        echo -e "${RED}   ❌ Section [metrics] manquante${NC}"
        echo -e "${GRAY}   Solution: Ajouter dans app.ini:${NC}"
        echo -e "${GRAY}   [metrics]${NC}"
        echo -e "${GRAY}   ENABLED = true${NC}"
    else
        echo -e "${GREEN}   ✅ Section [metrics] trouvée${NC}"
        echo -e "${GRAY}$metrics_config${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  app.ini pas encore généré (premier démarrage de Gitea)${NC}"
fi

echo -e "\n${YELLOW}🐳 Pour Docker:${NC}"
if ! curl -s --max-time 2 http://localhost:9323/metrics > /dev/null 2>&1; then
    echo -e "${WHITE}1. Configurer les métriques Docker:${NC}"
    echo -e "${GRAY}   sudo ./setup-docker-metrics.sh${NC}"
    echo -e "${WHITE}2. Ou manuellement:${NC}"
    echo -e "${GRAY}   sudo tee /etc/docker/daemon.json <<EOF${NC}"
    echo -e "${GRAY}   {${NC}"
    echo -e "${GRAY}     \"metrics-addr\": \"0.0.0.0:9323\",${NC}"
    echo -e "${GRAY}     \"experimental\": true${NC}"
    echo -e "${GRAY}   }${NC}"
    echo -e "${GRAY}   EOF${NC}"
    echo -e "${GRAY}   sudo systemctl restart docker${NC}"
else
    echo -e "${GREEN}✅ Métriques Docker déjà configurées${NC}"
fi

echo -e "\n${CYAN}📋 Résumé des Ports:${NC}"
echo -e "${WHITE}• Gitea interne: 3000 (pas de conflit avec votre app)${NC}"
echo -e "${WHITE}• Votre application: 3000 (externe, pas de conflit)${NC}"
echo -e "${WHITE}• Grafana: 3000 interne → 3001 externe${NC}"
echo -e "${WHITE}• Docker métriques: 9323${NC}"

echo -e "\n${GREEN}🎯 Prochaines étapes:${NC}"
echo -e "${WHITE}1. Corriger les réseaux: ./manage-stack.sh fix-networks${NC}"
echo -e "${WHITE}2. Configurer Docker: sudo ./setup-docker-metrics.sh${NC}"  
echo -e "${WHITE}3. Redémarrer: ./manage-stack.sh restart${NC}"
echo -e "${WHITE}4. Vérifier: ./prometheus-debug.sh${NC}"
