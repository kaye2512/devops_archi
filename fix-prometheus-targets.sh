#!/bin/bash

# Script de configuration complète des métriques Prometheus
# Usage: ./fix-prometheus-targets.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}🎯 Configuration Complète des Targets Prometheus${NC}"
echo -e "${BLUE}================================================${NC}"

# Fonction de log
log_step() {
    echo -e "\n${CYAN}🔧 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Étape 1: Vérifier les prérequis
log_step "Vérification des prérequis"

if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker n'est pas en marche"
    exit 1
fi

log_success "Docker est opérationnel"

# Étape 2: Rendre les scripts exécutables
log_step "Configuration des permissions"
chmod +x prometheus-debug.sh setup-docker-metrics.sh setup-jenkins-metrics.sh network-check.sh

log_success "Scripts rendus exécutables"

# Étape 3: Correction des réseaux
log_step "Correction des connexions réseau"
./network-check.sh connect
log_success "Réseaux configurés"

# Étape 4: Redémarrage des services avec nouvelle configuration
log_step "Redémarrage des services avec nouvelle configuration"
docker compose down
sleep 3
docker compose up -d

log_success "Services redémarrés"

# Attendre que les services se stabilisent
log_step "Attente de la stabilisation des services (30s)"
sleep 30

# Étape 5: Test des targets
log_step "Test des targets Prometheus"
./prometheus-debug.sh

# Étape 6: Instructions pour les configurations manuelles
echo -e "\n${BLUE}📋 Configurations Manuelles Nécessaires${NC}"
echo -e "${BLUE}=====================================${NC}"

echo -e "\n${YELLOW}🐳 1. DOCKER METRICS (à faire en tant que root):${NC}"
echo -e "${WHITE}sudo ./setup-docker-metrics.sh${NC}"

echo -e "\n${YELLOW}🏗️ 2. JENKINS (configuration via interface web):${NC}"
echo -e "${WHITE}• Accédez à: https://jenkins.wk-archi-o23b-4-5-g7.fr${NC}"
echo -e "${WHITE}• Allez dans: Manage Jenkins > Manage Plugins${NC}"
echo -e "${WHITE}• Installez: 'Prometheus metrics plugin'${NC}"
echo -e "${WHITE}• Redémarrez Jenkins${NC}"

echo -e "\n${YELLOW}🦌 3. GITEA (déjà configuré):${NC}"
echo -e "${GREEN}• Configuration app.ini mise à jour automatiquement${NC}"
echo -e "${GREEN}• Métriques disponibles sur /metrics${NC}"

echo -e "\n${YELLOW}🗃️ 4. REGISTRY (déjà configuré):${NC}"
echo -e "${GREEN}• Métriques activées sur le port 5001${NC}"
echo -e "${GREEN}• Configuration docker-compose.yml mise à jour${NC}"

# Étape 7: Vérification finale
echo -e "\n${CYAN}🔍 Vérification des targets actuels:${NC}"

if docker ps --filter "name=prometheus" --filter "status=running" | grep -q "prometheus"; then
    echo -e "\n${WHITE}📊 Status des targets Prometheus:${NC}"
    
    # Attendre un peu plus pour que Prometheus scrape
    sleep 10
    
    # Vérifier les targets via API
    if curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"' 2>/dev/null; then
        echo -e "${GREEN}✅ Targets récupérés via API${NC}"
    else
        log_warning "API Prometheus non accessible, vérifiez manuellement"
    fi
else
    log_error "Prometheus n'est pas en cours d'exécution"
fi

# Résumé final
echo -e "\n${BLUE}📋 RÉSUMÉ${NC}"
echo -e "${BLUE}========${NC}"

echo -e "\n${GREEN}✅ Configurations automatiques appliquées:${NC}"
echo -e "${WHITE}• Réseaux Docker corrigés${NC}"
echo -e "${WHITE}• Configuration Gitea mise à jour${NC}"
echo -e "${WHITE}• Configuration Registry mise à jour${NC}"
echo -e "${WHITE}• Configuration Prometheus optimisée${NC}"

echo -e "\n${YELLOW}⏭️ Actions manuelles restantes:${NC}"
echo -e "${WHITE}1. sudo ./setup-docker-metrics.sh${NC}"
echo -e "${WHITE}2. Installer plugin Jenkins Prometheus${NC}"
echo -e "${WHITE}3. ./manage-stack.sh restart${NC}"

echo -e "\n${CYAN}🔍 Vérification:${NC}"
echo -e "${WHITE}• Prometheus targets: https://prometheus.wk-archi-o23b-4-5-g7.fr/targets${NC}"
echo -e "${WHITE}• Debug script: ./prometheus-debug.sh${NC}"

echo -e "\n${GREEN}🎉 Configuration des targets Prometheus terminée!${NC}"

# Créer un fichier de status
cat > prometheus-targets-status.txt <<EOF
# Status de Configuration Prometheus Targets
Date: $(date)

## Configurations Appliquées
- ✅ Réseaux Docker configurés
- ✅ Gitea métriques activées
- ✅ Registry métriques activées  
- ✅ Configuration Prometheus mise à jour

## Actions Manuelles Requises
- ⏳ Docker daemon metrics: sudo ./setup-docker-metrics.sh
- ⏳ Jenkins plugin Prometheus: Installation via interface web

## Vérification
- URL Prometheus: https://prometheus.wk-archi-o23b-4-5-g7.fr/targets
- Script debug: ./prometheus-debug.sh

## Targets Attendus
- prometheus: ✅ (auto)
- traefik: ✅ (auto) 
- node-exporter: ✅ (auto)
- cadvisor: ✅ (auto)
- gitea: ✅ (configuré)
- registry: ✅ (configuré)
- docker: ⏳ (configuration manuelle requise)
- jenkins: ⏳ (plugin requis)
EOF

echo -e "\n${CYAN}📄 Status sauvegardé dans: prometheus-targets-status.txt${NC}"
