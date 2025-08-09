#!/bin/bash

# Script pour configurer les métriques Docker
# Usage: sudo ./setup-docker-metrics.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🐳 Configuration des métriques Docker${NC}"

# Vérifier les permissions
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Ce script doit être exécuté en tant que root (sudo)${NC}"
   exit 1
fi

# Backup de la configuration existante
if [[ -f /etc/docker/daemon.json ]]; then
    echo -e "${YELLOW}📋 Sauvegarde de la configuration Docker existante...${NC}"
    cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
fi

# Créer la configuration avec métriques
echo -e "${YELLOW}🔧 Configuration des métriques Docker...${NC}"

# Lire la config existante et la fusionner
if [[ -f /etc/docker/daemon.json ]]; then
    # Fusionner avec la config existante
    existing_config=$(cat /etc/docker/daemon.json)
    
    # Créer une nouvelle config en ajoutant les métriques
    echo "$existing_config" | jq '. + {"metrics-addr": "0.0.0.0:9323", "experimental": true}' > /tmp/daemon.json
else
    # Créer une nouvelle config
    cat > /tmp/daemon.json <<EOF
{
  "metrics-addr": "0.0.0.0:9323",
  "experimental": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
fi

# Valider le JSON
if jq empty /tmp/daemon.json 2>/dev/null; then
    echo -e "${GREEN}✅ Configuration JSON valide${NC}"
    mv /tmp/daemon.json /etc/docker/daemon.json
else
    echo -e "${RED}❌ Configuration JSON invalide${NC}"
    
    # Configuration de fallback
    cat > /etc/docker/daemon.json <<EOF
{
  "metrics-addr": "0.0.0.0:9323",
  "experimental": true
}
EOF
fi

echo -e "${CYAN}📋 Configuration Docker appliquée:${NC}"
cat /etc/docker/daemon.json

# Redémarrer Docker
echo -e "${YELLOW}🔄 Redémarrage du service Docker...${NC}"
systemctl restart docker

# Vérifier que Docker redémarre correctement
sleep 5
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✅ Docker redémarré avec succès${NC}"
else
    echo -e "${RED}❌ Erreur lors du redémarrage de Docker${NC}"
    
    # Restaurer la sauvegarde si elle existe
    if [[ -f /etc/docker/daemon.json.backup.* ]]; then
        latest_backup=$(ls -t /etc/docker/daemon.json.backup.* | head -n1)
        echo -e "${YELLOW}🔄 Restauration de la sauvegarde: $latest_backup${NC}"
        cp "$latest_backup" /etc/docker/daemon.json
        systemctl restart docker
    fi
    exit 1
fi

# Tester l'accès aux métriques
echo -e "${CYAN}🧪 Test de l'endpoint métriques...${NC}"
sleep 3

if curl -s http://localhost:9323/metrics > /dev/null; then
    echo -e "${GREEN}✅ Métriques Docker accessibles sur http://localhost:9323/metrics${NC}"
    
    # Afficher quelques métriques d'exemple
    echo -e "\n${CYAN}📊 Exemple de métriques disponibles:${NC}"
    curl -s http://localhost:9323/metrics | head -10
    echo -e "${GRAY}... (et beaucoup d'autres)${NC}"
    
else
    echo -e "${RED}❌ Métriques Docker non accessibles${NC}"
    echo -e "${YELLOW}💡 Vérifiez les logs: journalctl -u docker.service${NC}"
fi

echo -e "\n${GREEN}🎉 Configuration terminée!${NC}"
echo -e "${CYAN}📋 Prochaines étapes:${NC}"
echo -e "${WHITE}  1. Redémarrez votre stack: ./manage-stack.sh restart${NC}"
echo -e "${WHITE}  2. Vérifiez les targets: ./prometheus-debug.sh${NC}"
echo -e "${WHITE}  3. Accédez à Prometheus: https://prometheus.wk-archi-o23b-4-5-g7.fr/targets${NC}"
