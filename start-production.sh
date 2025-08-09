#!/bin/bash

# Script de démarrage pour l'environnement de production WK-Archi Linux
# Usage: ./start-production.sh

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Démarrage de la stack DevOps WK-Archi avec monitoring...${NC}"

# Vérifier si Docker est installé et en marche
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker n'est pas installé${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker n'est pas en marche. Démarrez le service Docker${NC}"
    echo -e "${YELLOW}   sudo systemctl start docker${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker est en marche${NC}"

# Vérifier si Docker Compose est installé
if ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose n'est pas installé${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker Compose est disponible${NC}"

# Se déplacer dans le répertoire du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Créer les réseaux externes si nécessaire
echo -e "${YELLOW}📡 Vérification des réseaux Docker...${NC}"

# Créer le réseau tiptop-net si nécessaire
if ! docker network ls --filter name=tiptop-net --format "{{.Name}}" | grep -q "tiptop-net"; then
    echo -e "${YELLOW}🔨 Création du réseau tiptop-net...${NC}"
    docker network create tiptop-net
    echo -e "${GREEN}✅ Réseau tiptop-net créé${NC}"
else
    echo -e "${GREEN}✅ Réseau tiptop-net existe déjà${NC}"
fi

# Créer le réseau traefik-net si nécessaire  
if ! docker network ls --filter name=traefik-net --format "{{.Name}}" | grep -q "traefik-net"; then
    echo -e "${YELLOW}🔨 Création du réseau traefik-net...${NC}"
    docker network create traefik-net
    echo -e "${GREEN}✅ Réseau traefik-net créé${NC}"
else
    echo -e "${GREEN}✅ Réseau traefik-net existe déjà${NC}"
fi

# Vérifier les fichiers de configuration
echo -e "${YELLOW}🔍 Vérification de la configuration...${NC}"

CONFIG_FILES=(
    "./monitoring/prometheus.yml"
    "./monitoring/alerts/rules.yml"
    "./grafana/provisioning/datasources/datasource.yml"
    "./grafana/provisioning/dashboards/dashboard.yml"
)

for file in "${CONFIG_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file manquant${NC}"
    fi
done

# Créer les répertoires nécessaires s'ils n'existent pas
echo -e "${YELLOW}📁 Création des répertoires nécessaires...${NC}"
mkdir -p ./data/registry
mkdir -p ./letsencrypt
mkdir -p ./monitoring/alerts
mkdir -p ./grafana/provisioning/datasources
mkdir -p ./grafana/provisioning/dashboards

# Définir les permissions appropriées pour letsencrypt
chmod 700 ./letsencrypt
touch ./letsencrypt/acme.json
chmod 600 ./letsencrypt/acme.json

echo -e "${GREEN}✅ Répertoires configurés${NC}"

# Arrêter les services existants s'ils tournent
echo -e "${YELLOW}🛑 Arrêt des services existants...${NC}"
docker compose down

# Démarrer les services
echo -e "${YELLOW}🐳 Démarrage des conteneurs...${NC}"
docker compose up -d

if [[ $? -eq 0 ]]; then
    echo -e "\n${GREEN}✅ Tous les services ont été démarrés avec succès!${NC}"
    
    # Attendre que les services soient prêts
    echo -e "${YELLOW}⏳ Attente du démarrage des services (15s)...${NC}"
    sleep 15
    
    # S'assurer que tous les conteneurs sont connectés au réseau traefik-net
    echo -e "${YELLOW}🔗 Vérification des connexions réseau traefik-net...${NC}"
    
    CONTAINERS=("traefik" "jenkins" "gitea" "registry" "prometheus" "grafana" "node-exporter" "cadvisor")
    
    for container in "${CONTAINERS[@]}"; do
        if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
            # Vérifier si le conteneur est déjà connecté au réseau traefik-net
            if ! docker inspect "$container" | grep -q '"traefik-net"'; then
                echo -e "${YELLOW}🔌 Connexion de $container au réseau traefik-net...${NC}"
                docker network connect traefik-net "$container" 2>/dev/null || echo -e "${GRAY}   $container déjà connecté ou erreur ignorée${NC}"
            else
                echo -e "${GREEN}✅ $container déjà connecté au réseau traefik-net${NC}"
            fi
        fi
    done
    
    echo -e "${YELLOW}⏳ Attente supplémentaire (15s)...${NC}"
    sleep 15
    
    echo -e "\n${CYAN}🌐 Vos services sont maintenant disponibles:${NC}"
    echo -e "${WHITE}  • Traefik Dashboard: https://traefik.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${WHITE}  • Jenkins: https://jenkins.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${WHITE}  • Gitea: https://gitea.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${WHITE}  • Registry: https://registry.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${MAGENTA}  • Prometheus: https://prometheus.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${MAGENTA}  • Grafana: https://grafana.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${GRAY}    └─ Identifiants: admin/admin${NC}"
    
    echo -e "\n${CYAN}📊 Services de monitoring locaux (sur le VPS):${NC}"
    echo -e "${WHITE}  • Prometheus: http://localhost:9090${NC}"
    echo -e "${WHITE}  • Grafana: http://localhost:3001${NC}"
    echo -e "${WHITE}  • Node Exporter: http://localhost:9100${NC}"
    echo -e "${WHITE}  • cAdvisor: http://localhost:8080${NC}"
    
    echo -e "\n${YELLOW}🔍 Vérification des targets Prometheus...${NC}"
    
    # Vérifier l'état des services
    echo -e "\n${CYAN}📋 État des conteneurs:${NC}"
    docker compose ps
    
    echo -e "\n${YELLOW}🎯 Prochaines étapes:${NC}"
    echo -e "${WHITE}  1. Accédez à Prometheus: https://prometheus.wk-archi-o23b-4-5-g7.fr/targets${NC}"
    echo -e "${GRAY}     └─ Vérifiez que tous les targets sont 'UP'${NC}"
    echo -e "${WHITE}  2. Accédez à Grafana: https://grafana.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${GRAY}     └─ Connectez-vous avec admin/admin${NC}"
    echo -e "${GRAY}     └─ Le datasource Prometheus est pré-configuré${NC}"
    echo -e "${WHITE}  3. Importez des dashboards recommandés:${NC}"
    echo -e "${GRAY}     └─ Node Exporter Full (ID: 1860)${NC}"
    echo -e "${GRAY}     └─ Docker Container Metrics (ID: 179)${NC}"
    echo -e "${GRAY}     └─ Traefik 2.0 Dashboard (ID: 11462)${NC}"
    
    echo -e "\n${RED}🚨 IMPORTANT - Sécurité:${NC}"
    echo -e "${YELLOW}  • Changez le mot de passe Grafana par défaut (admin/admin)${NC}"
    echo -e "${YELLOW}  • Vérifiez que vos certificats SSL sont bien générés${NC}"
    echo -e "${YELLOW}  • Configurez votre firewall pour protéger les ports de monitoring${NC}"
    
else
    echo -e "${RED}❌ Erreur lors du démarrage des services${NC}"
    echo -e "${YELLOW}📋 Vérifiez les logs avec: docker compose logs${NC}"
    exit 1
fi

echo -e "\n${CYAN}📖 Commandes utiles:${NC}"
echo -e "${WHITE}  • Voir les logs: docker compose logs -f [service]${NC}"
echo -e "${WHITE}  • Arrêter: docker compose down${NC}"
echo -e "${WHITE}  • Redémarrer: docker compose restart [service]${NC}"
echo -e "${WHITE}  • Status: docker compose ps${NC}"

echo -e "\n${CYAN}🔧 Scripts de gestion:${NC}"
echo -e "${WHITE}  • ./manage-stack.sh start|stop|restart|status|logs${NC}"
