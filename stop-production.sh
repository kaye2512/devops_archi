#!/bin/bash

# Script d'arrêt pour l'environnement de production WK-Archi Linux
# Usage: ./stop-production.sh

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${YELLOW}🛑 Arrêt de la stack DevOps WK-Archi...${NC}"

# Se déplacer dans le répertoire du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Vérifier si des conteneurs tournent
if docker-compose ps | grep -q "Up"; then
    echo -e "${CYAN}📋 Services actuellement en cours d'exécution:${NC}"
    docker-compose ps
    
    echo -e "\n${YELLOW}⏳ Arrêt en cours...${NC}"
    
    # Arrêt gracieux
    docker-compose stop
    
    # Suppression des conteneurs
    docker-compose down
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Tous les services ont été arrêtés avec succès!${NC}"
    else
        echo -e "${RED}❌ Erreur lors de l'arrêt des services${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}ℹ️  Aucun service n'est actuellement en cours d'exécution${NC}"
fi

echo -e "\n${CYAN}📊 Status final:${NC}"
docker-compose ps

echo -e "\n${GREEN}🎯 Services arrêtés. Pour redémarrer:${NC}"
echo -e "${CYAN}  ./start-production.sh${NC}"
echo -e "${CYAN}  # ou${NC}"
echo -e "${CYAN}  ./manage-stack.sh start${NC}"
