#!/bin/bash

# Script de configuration Gitea pour métriques Prometheus
# Usage: ./setup-gitea-metrics.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🦌 Configuration Gitea pour Prometheus${NC}"

# Vérifier que Gitea est en cours d'exécution
if ! docker ps --filter "name=gitea" --filter "status=running" | grep -q "gitea"; then
    echo -e "${RED}❌ Gitea n'est pas en cours d'exécution${NC}"
    echo -e "${YELLOW}💡 Démarrez d'abord: ./manage-stack.sh start${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Gitea détecté${NC}"

# Attendre que Gitea soit prêt
echo -e "${YELLOW}⏳ Vérification que Gitea est prêt...${NC}"

max_attempts=10
attempt=1

while [[ $attempt -le $max_attempts ]]; do
    if docker exec gitea wget -q --spider http://localhost:3000 2>/dev/null; then
        echo -e "${GREEN}✅ Gitea est prêt${NC}"
        break
    fi
    
    echo -e "${GRAY}   Tentative $attempt/$max_attempts...${NC}"
    sleep 5
    ((attempt++))
done

if [[ $attempt -gt $max_attempts ]]; then
    echo -e "${RED}❌ Gitea n'est pas accessible après 50 secondes${NC}"
    exit 1
fi

# Vérifier si app.ini existe et est configuré
if docker exec gitea test -f /data/gitea/conf/app.ini; then
    echo -e "${GREEN}✅ Fichier app.ini existe${NC}"
    
    # Vérifier si la section metrics existe déjà
    if docker exec gitea grep -q "\[metrics\]" /data/gitea/conf/app.ini 2>/dev/null; then
        echo -e "${GREEN}✅ Section [metrics] déjà présente${NC}"
        
        # Vérifier si ENABLED = true
        if docker exec gitea grep -A5 "\[metrics\]" /data/gitea/conf/app.ini | grep -q "ENABLED.*true" 2>/dev/null; then
            echo -e "${GREEN}✅ Métriques déjà activées${NC}"
        else
            echo -e "${YELLOW}⚠️  Métriques pas activées, activation...${NC}"
            
            # Activer les métriques
            docker exec gitea sed -i '/\[metrics\]/,/^\[/{s/ENABLED.*/ENABLED = true/}' /data/gitea/conf/app.ini
        fi
    else
        echo -e "${YELLOW}📝 Ajout de la section [metrics]...${NC}"
        
        # Ajouter la section metrics
        docker exec gitea bash -c 'echo -e "\n[metrics]\nENABLED = true\nTOKEN = prometheus-metrics-token" >> /data/gitea/conf/app.ini'
    fi
else
    echo -e "${YELLOW}⚠️  Fichier app.ini n'existe pas encore${NC}"
    echo -e "${CYAN}ℹ️  Gitea n'est peut-être pas encore configuré${NC}"
    
    # Créer le répertoire de configuration s'il n'existe pas
    docker exec gitea mkdir -p /data/gitea/conf
    
    # Créer un app.ini minimal avec métriques
    docker exec gitea bash -c 'cat > /data/gitea/conf/app.ini << EOF
[server]
ROOT_URL = https://gitea.wk-archi-o23b-4-5-g7.fr/
DOMAIN = gitea.wk-archi-o23b-4-5-g7.fr
HTTP_PORT = 3000

[database]
DB_TYPE = sqlite3

[security]
INSTALL_LOCK = false

[metrics]
ENABLED = true
TOKEN = prometheus-metrics-token

[log]
MODE = console
LEVEL = Info
EOF'
    
    echo -e "${GREEN}✅ Configuration app.ini créée${NC}"
fi

# Redémarrer Gitea pour appliquer la configuration
echo -e "${YELLOW}🔄 Redémarrage de Gitea...${NC}"
docker restart gitea

# Attendre que Gitea redémarre
echo -e "${YELLOW}⏳ Attente du redémarrage (15s)...${NC}"
sleep 15

# Tester l'endpoint métriques
echo -e "${CYAN}🧪 Test de l'endpoint métriques...${NC}"

max_attempts=5
attempt=1

while [[ $attempt -le $max_attempts ]]; do
    if docker exec gitea wget -qO- "http://localhost:3000/metrics?token=prometheus-metrics-token" 2>/dev/null | head -1 | grep -q "^#"; then
        echo -e "${GREEN}✅ Endpoint métriques accessible avec token${NC}"
        break
    elif docker exec gitea wget -qO- "http://localhost:3000/metrics" 2>/dev/null | head -1 | grep -q "^#"; then
        echo -e "${GREEN}✅ Endpoint métriques accessible sans token${NC}"
        break
    else
        echo -e "${GRAY}   Tentative $attempt/$max_attempts...${NC}"
        sleep 5
        ((attempt++))
    fi
done

if [[ $attempt -gt $max_attempts ]]; then
    echo -e "${RED}❌ Endpoint métriques non accessible${NC}"
    
    # Debug
    echo -e "${CYAN}🔍 Debug Gitea:${NC}"
    echo -e "${WHITE}Logs Gitea (10 dernières lignes):${NC}"
    docker logs gitea --tail 10
    
    echo -e "\n${WHITE}Configuration app.ini actuelle:${NC}"
    docker exec gitea cat /data/gitea/conf/app.ini 2>/dev/null || echo "Fichier non trouvé"
else
    echo -e "${GREEN}🎉 Gitea configuré avec succès!${NC}"
fi

# Test depuis Prometheus
echo -e "\n${CYAN}🔍 Test connectivité depuis Prometheus...${NC}"

if docker exec prometheus nc -z gitea 3000 2>/dev/null; then
    echo -e "${GREEN}✅ gitea:3000 accessible depuis Prometheus${NC}"
    
    if docker exec prometheus wget -qO- "http://gitea:3000/metrics?token=prometheus-metrics-token" 2>/dev/null | head -1 | grep -q "^#"; then
        echo -e "${GREEN}✅ Métriques Gitea accessibles depuis Prometheus${NC}"
    else
        echo -e "${YELLOW}⚠️  Métriques pas encore accessibles, test sans token...${NC}"
        if docker exec prometheus wget -qO- "http://gitea:3000/metrics" 2>/dev/null | head -1 | grep -q "^#"; then
            echo -e "${GREEN}✅ Métriques accessibles sans token${NC}"
        else
            echo -e "${RED}❌ Métriques pas accessibles${NC}"
        fi
    fi
else
    echo -e "${RED}❌ gitea:3000 non accessible depuis Prometheus${NC}"
    echo -e "${YELLOW}💡 Vérifiez les réseaux: ./manage-stack.sh check-networks${NC}"
fi

echo -e "\n${CYAN}📋 Configuration terminée${NC}"
echo -e "${WHITE}• Gitea configuré pour exposer les métriques${NC}"
echo -e "${WHITE}• Endpoint: http://gitea:3000/metrics${NC}"
echo -e "${WHITE}• Token (si nécessaire): prometheus-metrics-token${NC}"

echo -e "\n${YELLOW}⏭️  Prochaines étapes:${NC}"
echo -e "${WHITE}1. Vérifiez la target dans Prometheus${NC}"
echo -e "${WHITE}2. Si toujours DOWN: ./debug-gitea-docker.sh${NC}"
echo -e "${WHITE}3. Interface Gitea: https://gitea.wk-archi-o23b-4-5-g7.fr${NC}"
