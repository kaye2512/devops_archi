#!/bin/bash

# Script de résolution complète pour Gitea et Docker targets
# Usage: ./fix-gitea-docker-targets.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🎯 Résolution Targets Gitea et Docker${NC}"
echo -e "${BLUE}====================================${NC}"

# Fonction de log avec timestamp
log() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] $1${NC}"
}

# Étape 1: Diagnostic initial
log "🔍 Diagnostic initial..."
./debug-gitea-docker.sh > debug-gitea-docker-before.log 2>&1

# Étape 2: Corriger les réseaux
log "🌐 Correction des réseaux Docker..."
if [[ -f "./manage-stack.sh" ]]; then
    ./manage-stack.sh fix-networks
else
    # Connecter manuellement les conteneurs aux réseaux
    docker network connect tiptop-net gitea 2>/dev/null || true
    docker network connect tiptop-net prometheus 2>/dev/null || true
    docker network connect traefik-net gitea 2>/dev/null || true
    docker network connect traefik-net prometheus 2>/dev/null || true
fi

# Étape 3: Configuration Gitea
log "🦌 Configuration des métriques Gitea..."
./setup-gitea-metrics.sh

# Étape 4: Configuration Docker (nécessite sudo)
log "🐳 Vérification de la configuration Docker..."

if curl -s --max-time 2 http://localhost:9323/metrics > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Métriques Docker déjà configurées${NC}"
else
    echo -e "${YELLOW}⚠️  Métriques Docker non configurées${NC}"
    
    if [[ $EUID -eq 0 ]]; then
        echo -e "${CYAN}🔧 Configuration automatique des métriques Docker...${NC}"
        ./setup-docker-metrics.sh
    else
        echo -e "${YELLOW}💡 Exécutez en tant que root pour configurer Docker automatiquement:${NC}"
        echo -e "${WHITE}   sudo ./fix-gitea-docker-targets.sh${NC}"
        echo -e "${WHITE}   # ou manuellement:${NC}"
        echo -e "${WHITE}   sudo ./setup-docker-metrics.sh${NC}"
        
        # Configuration manuelle rapide
        echo -e "\n${CYAN}📋 Configuration manuelle Docker:${NC}"
        cat << 'EOF'
sudo tee /etc/docker/daemon.json <<CONFIG
{
  "metrics-addr": "0.0.0.0:9323",
  "experimental": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
CONFIG
sudo systemctl restart docker
EOF
    fi
fi

# Étape 5: Redémarrage des services
log "🔄 Redémarrage des services pour appliquer les configurations..."

# Redémarrer seulement les services concernés
docker restart gitea
docker restart prometheus

# Attendre que les services se stabilisent
log "⏳ Attente de la stabilisation (20s)..."
sleep 20

# Étape 6: Vérification finale
log "✅ Vérification finale..."

echo -e "\n${CYAN}🧪 Tests de connectivité:${NC}"

# Test Gitea
if docker exec prometheus nc -z gitea 3000 2>/dev/null; then
    echo -e "${GREEN}✅ Gitea accessible depuis Prometheus${NC}"
    
    if docker exec prometheus wget -qO- "http://gitea:3000/metrics" 2>/dev/null | head -1 | grep -q "^#"; then
        echo -e "${GREEN}✅ Métriques Gitea fonctionnelles${NC}"
        gitea_status="UP"
    else
        echo -e "${YELLOW}⚠️  Métriques Gitea pas encore prêtes${NC}"
        gitea_status="PENDING"
    fi
else
    echo -e "${RED}❌ Gitea non accessible${NC}"
    gitea_status="DOWN"
fi

# Test Docker
if curl -s --max-time 2 http://localhost:9323/metrics > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Métriques Docker accessibles${NC}"
    
    if docker exec prometheus nc -z host.docker.internal 9323 2>/dev/null; then
        echo -e "${GREEN}✅ Docker metrics accessibles depuis Prometheus${NC}"
        docker_status="UP"
    else
        echo -e "${YELLOW}⚠️  Docker metrics pas accessibles depuis Prometheus${NC}"
        docker_status="PARTIAL"
    fi
else
    echo -e "${RED}❌ Métriques Docker non configurées${NC}"
    docker_status="DOWN"
fi

# Étape 7: Rapport final
echo -e "\n${BLUE}📊 RAPPORT FINAL${NC}"
echo -e "${BLUE}===============${NC}"

echo -e "\n${WHITE}Status des Targets:${NC}"
case $gitea_status in
    "UP") echo -e "${GREEN}🟢 Gitea: UP${NC}" ;;
    "PENDING") echo -e "${YELLOW}🟡 Gitea: PENDING (redémarrez Prometheus)${NC}" ;;
    "DOWN") echo -e "${RED}🔴 Gitea: DOWN${NC}" ;;
esac

case $docker_status in
    "UP") echo -e "${GREEN}🟢 Docker: UP${NC}" ;;
    "PARTIAL") echo -e "${YELLOW}🟡 Docker: PARTIAL (configuration réseau)${NC}" ;;
    "DOWN") echo -e "${RED}🔴 Docker: DOWN (configuration requise)${NC}" ;;
esac

echo -e "\n${CYAN}🔍 URLs de vérification:${NC}"
echo -e "${WHITE}• Prometheus targets: https://prometheus.wk-archi-o23b-4-5-g7.fr/targets${NC}"
echo -e "${WHITE}• Gitea: https://gitea.wk-archi-o23b-4-5-g7.fr${NC}"
echo -e "${WHITE}• Métriques Gitea direct: http://gitea:3000/metrics (dans réseau Docker)${NC}"
echo -e "${WHITE}• Métriques Docker: http://localhost:9323/metrics${NC}"

# Actions recommandées
echo -e "\n${YELLOW}⏭️  Actions recommandées:${NC}"

if [[ "$gitea_status" != "UP" ]]; then
    echo -e "${WHITE}🦌 Pour Gitea:${NC}"
    echo -e "${GRAY}   1. Vérifiez l'interface Gitea: https://gitea.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${GRAY}   2. Terminez la configuration initiale si nécessaire${NC}"
    echo -e "${GRAY}   3. Redémarrez: docker restart gitea prometheus${NC}"
fi

if [[ "$docker_status" != "UP" ]]; then
    echo -e "${WHITE}🐳 Pour Docker:${NC}"
    if [[ $EUID -ne 0 ]]; then
        echo -e "${GRAY}   1. Exécutez: sudo ./setup-docker-metrics.sh${NC}"
        echo -e "${GRAY}   2. Ou utilisez la configuration manuelle ci-dessus${NC}"
    else
        echo -e "${GRAY}   1. Vérifiez les logs: journalctl -u docker.service${NC}"
        echo -e "${GRAY}   2. Testez: curl http://localhost:9323/metrics${NC}"
    fi
fi

# Sauvegarde du diagnostic
log "💾 Sauvegarde du diagnostic final..."
./debug-gitea-docker.sh > debug-gitea-docker-after.log 2>&1

echo -e "\n${GREEN}🎉 Processus de résolution terminé !${NC}"
echo -e "${CYAN}📄 Logs sauvegardés:${NC}"
echo -e "${WHITE}   • Avant: debug-gitea-docker-before.log${NC}"  
echo -e "${WHITE}   • Après: debug-gitea-docker-after.log${NC}"

# Proposition de commandes de vérification
echo -e "\n${CYAN}🧪 Commandes de vérification:${NC}"
echo -e "${WHITE}# Vérifier les targets Prometheus${NC}"
echo -e "${GRAY}curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'${NC}"

echo -e "\n${WHITE}# Tester manuellement les endpoints${NC}"
echo -e "${GRAY}docker exec prometheus wget -qO- http://gitea:3000/metrics | head -5${NC}"
echo -e "${GRAY}curl -s http://localhost:9323/metrics | head -5${NC}"

# Note sur les ports
echo -e "\n${BLUE}📋 Note sur les Ports:${NC}"
echo -e "${WHITE}✅ Pas de conflit de port 3000:${NC}"
echo -e "${GRAY}   • Votre application: Port 3000 externe${NC}"
echo -e "${GRAY}   • Gitea: Port 3000 interne au conteneur (via réseau Docker)${NC}"
echo -e "${GRAY}   • Grafana: Port 3000 interne → 3001 externe${NC}"
echo -e "${WHITE}   → Tout fonctionne en parallèle sans conflit !${NC}"
