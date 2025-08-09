#!/bin/bash

# Script de vérification de la configuration
# Usage: ./check-setup.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔍 Vérification de la configuration de la stack DevOps${NC}"

# Vérifier Docker
echo -e "\n${YELLOW}📦 Vérification Docker...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker est installé$(docker --version)${NC}"
    
    if docker info &> /dev/null; then
        echo -e "${GREEN}✅ Docker daemon est en marche${NC}"
    else
        echo -e "${RED}❌ Docker daemon n'est pas en marche${NC}"
        echo -e "${YELLOW}   Démarrez avec: sudo systemctl start docker${NC}"
    fi
else
    echo -e "${RED}❌ Docker n'est pas installé${NC}"
fi

# Vérifier Docker Compose
echo -e "\n${YELLOW}🐙 Vérification Docker Compose...${NC}"
if docker compose version &> /dev/null; then
    echo -e "${GREEN}✅ Docker Compose est disponible ($(docker compose version --short))${NC}"
else
    echo -e "${RED}❌ Docker Compose n'est pas disponible${NC}"
    echo -e "${YELLOW}   Installez avec: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh${NC}"
fi

# Vérifier les fichiers de configuration
echo -e "\n${YELLOW}📁 Vérification des fichiers de configuration...${NC}"

CONFIG_FILES=(
    "docker-compose.yml:Configuration Docker Compose"
    "monitoring/prometheus.yml:Configuration Prometheus"
    "monitoring/alerts/rules.yml:Règles d'alerting"
    "grafana/provisioning/datasources/datasource.yml:Datasource Grafana"
    "grafana/provisioning/dashboards/dashboard.yml:Configuration dashboards Grafana"
    "start-production.sh:Script de démarrage"
    "manage-stack.sh:Script de gestion"
    "stop-production.sh:Script d'arrêt"
)

for config in "${CONFIG_FILES[@]}"; do
    IFS=':' read -r file description <<< "$config"
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✅ $file ($description)${NC}"
    else
        echo -e "${RED}❌ $file manquant ($description)${NC}"
    fi
done

# Vérifier les permissions des scripts
echo -e "\n${YELLOW}🔐 Vérification des permissions...${NC}"
SCRIPTS=("start-production.sh" "manage-stack.sh" "stop-production.sh")

for script in "${SCRIPTS[@]}"; do
    if [[ -x "$script" ]]; then
        echo -e "${GREEN}✅ $script est exécutable${NC}"
    else
        echo -e "${YELLOW}⚠️  $script n'est pas exécutable${NC}"
        echo -e "${CYAN}   Correction: chmod +x $script${NC}"
    fi
done

# Vérifier les réseaux Docker
echo -e "\n${YELLOW}🌐 Vérification des réseaux Docker...${NC}"
NETWORKS=("tiptop-net" "traefik-net")

for network in "${NETWORKS[@]}"; do
    if docker network ls --filter name=$network --format "{{.Name}}" | grep -q "$network"; then
        echo -e "${GREEN}✅ Réseau $network existe${NC}"
    else
        echo -e "${YELLOW}⚠️  Réseau $network n'existe pas${NC}"
        echo -e "${CYAN}   Il sera créé automatiquement au démarrage${NC}"
    fi
done

# Vérifier les ports disponibles
echo -e "\n${YELLOW}🔌 Vérification des ports...${NC}"
PORTS=(80 443 9090 3001 9100 8080)

for port in "${PORTS[@]}"; do
    if ! ss -tuln | grep -q ":$port "; then
        echo -e "${GREEN}✅ Port $port disponible${NC}"
    else
        echo -e "${RED}❌ Port $port déjà utilisé${NC}"
        echo -e "${CYAN}   Processus utilisant le port: $(ss -tulnp | grep ":$port ")${NC}"
    fi
done

# Vérifier l'espace disque
echo -e "\n${YELLOW}💾 Vérification de l'espace disque...${NC}"
DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $DISK_USAGE -lt 80 ]]; then
    echo -e "${GREEN}✅ Espace disque suffisant (${DISK_USAGE}% utilisé)${NC}"
else
    echo -e "${RED}❌ Espace disque faible (${DISK_USAGE}% utilisé)${NC}"
fi

# Résumé final
echo -e "\n${CYAN}📋 Résumé:${NC}"
if docker compose version &> /dev/null && [[ -f "docker-compose.yml" ]] && [[ -x "start-production.sh" ]]; then
    echo -e "${GREEN}🎉 Configuration prête! Vous pouvez démarrer avec:${NC}"
    echo -e "${CYAN}   ./start-production.sh${NC}"
else
    echo -e "${YELLOW}⚠️  Configuration incomplète. Veuillez corriger les erreurs ci-dessus.${NC}"
fi

echo -e "\n${CYAN}📖 Aide:${NC}"
echo -e "${CYAN}   ./manage-stack.sh help    - Aide complète${NC}"
echo -e "${CYAN}   ./start-production.sh     - Démarrer tous les services${NC}"
echo -e "${CYAN}   ./manage-stack.sh status  - Vérifier le statut${NC}"
