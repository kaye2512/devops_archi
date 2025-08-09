#!/bin/bash

# Script pour générer et configurer un token sécurisé pour Gitea
# Usage: ./generate-gitea-token.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔐 Génération d'un token sécurisé pour Gitea${NC}"

# Générer un token aléatoire sécurisé
NEW_TOKEN=$(openssl rand -hex 32)

if [[ -z "$NEW_TOKEN" ]]; then
    # Fallback si openssl n'est pas disponible
    NEW_TOKEN=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 64)
fi

echo -e "${GREEN}✅ Token généré: ${NEW_TOKEN}${NC}"

# Sauvegarder le token dans un fichier sécurisé
echo "GITEA_METRICS_TOKEN=${NEW_TOKEN}" > .env.gitea
chmod 600 .env.gitea

echo -e "${GREEN}✅ Token sauvegardé dans .env.gitea${NC}"

# Demander confirmation pour l'application
echo -e "\n${YELLOW}⚠️  Application du nouveau token:${NC}"
echo -e "${WHITE}Voulez-vous remplacer le token actuel (prometheus-metrics-token) ?${NC}"
echo -e "${GRAY}Cela nécessitera de redémarrer Gitea et Prometheus.${NC}"

read -p "Continuer ? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}🔧 Application du nouveau token...${NC}"
    
    # Mettre à jour app.ini
    if docker ps --filter "name=gitea" --filter "status=running" | grep -q "gitea"; then
        docker exec gitea sed -i "s/TOKEN = .*/TOKEN = ${NEW_TOKEN}/" /data/gitea/conf/app.ini
        echo -e "${GREEN}✅ app.ini mis à jour${NC}"
    else
        echo -e "${YELLOW}⚠️  Gitea non démarré, mise à jour du fichier local...${NC}"
        sed -i "s/TOKEN = .*/TOKEN = ${NEW_TOKEN}/" gitea/app.ini
    fi
    
    # Mettre à jour prometheus.yml
    sed -i "s/token: \['.*'\]/token: ['${NEW_TOKEN}']/" monitoring/prometheus.yml
    echo -e "${GREEN}✅ prometheus.yml mis à jour${NC}"
    
    # Redémarrer les services
    echo -e "${CYAN}🔄 Redémarrage de Gitea et Prometheus...${NC}"
    docker restart gitea prometheus
    
    echo -e "${GREEN}🎉 Token sécurisé appliqué avec succès !${NC}"
    
else
    echo -e "${YELLOW}⏭️  Application annulée${NC}"
    echo -e "${CYAN}💡 Le token est disponible dans .env.gitea pour usage ultérieur${NC}"
fi

echo -e "\n${CYAN}📋 Informations du Token:${NC}"
echo -e "${WHITE}• Token actuel: prometheus-metrics-token (basique)${NC}"
echo -e "${WHITE}• Nouveau token: ${NEW_TOKEN} (sécurisé)${NC}"
echo -e "${WHITE}• Fichier: .env.gitea${NC}"

echo -e "\n${CYAN}🧪 Tests:${NC}"
echo -e "${WHITE}# Ancien token (si toujours actif):${NC}"
echo -e "${GRAY}curl 'http://localhost:3000/metrics?token=prometheus-metrics-token'${NC}"

echo -e "\n${WHITE}# Nouveau token:${NC}"
echo -e "${GRAY}curl 'http://localhost:3000/metrics?token=${NEW_TOKEN}'${NC}"

echo -e "\n${CYAN}📖 Documentation:${NC}"
echo -e "${WHITE}• Le token protège l'accès aux métriques Gitea${NC}"
echo -e "${WHITE}• Prometheus l'utilise automatiquement${NC}"
echo -e "${WHITE}• Changez-le régulièrement pour la sécurité${NC}"
