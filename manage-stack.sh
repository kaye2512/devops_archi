#!/bin/bash

# Script de gestion pour la stack DevOps WK-Archi
# Usage: ./manage-stack.sh [start|stop|restart|status|logs|backup|restore]

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo -e "${CYAN}🛠️  Script de gestion de la stack DevOps WK-Archi${NC}"
    echo -e "${WHITE}Usage: ./manage-stack.sh [COMMAND] [SERVICE]${NC}"
    echo ""
    echo -e "${YELLOW}Commandes disponibles:${NC}"
    echo -e "${WHITE}  start    - Démarre tous les services${NC}"
    echo -e "${WHITE}  stop     - Arrête tous les services${NC}"
    echo -e "${WHITE}  restart  - Redémarre tous les services${NC}"
    echo -e "${WHITE}  status   - Affiche le statut des services${NC}"
    echo -e "${WHITE}  logs     - Affiche les logs (ajouter nom du service pour un service spécifique)${NC}"
    echo -e "${WHITE}  backup   - Sauvegarde les données importantes${NC}"
    echo -e "${WHITE}  restore  - Restaure une sauvegarde${NC}"
    echo -e "${WHITE}  update   - Met à jour les images Docker${NC}"
    echo -e "${WHITE}  clean    - Nettoie les ressources Docker inutilisées${NC}"
    echo ""
    echo -e "${YELLOW}Exemples:${NC}"
    echo -e "${GRAY}  ./manage-stack.sh start${NC}"
    echo -e "${GRAY}  ./manage-stack.sh logs prometheus${NC}"
    echo -e "${GRAY}  ./manage-stack.sh status${NC}"
}

start_services() {
    echo -e "${GREEN}🚀 Démarrage de la stack DevOps...${NC}"
    
    # Créer le réseau si nécessaire
    if ! docker network ls --filter name=tiptop-net --format "{{.Name}}" | grep -q "tiptop-net"; then
        docker network create tiptop-net
    fi
    
    docker-compose up -d
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Services démarrés avec succès!${NC}"
        sleep 5
        show_services_urls
    else
        echo -e "${RED}❌ Erreur lors du démarrage${NC}"
    fi
}

stop_services() {
    echo -e "${YELLOW}🛑 Arrêt de la stack DevOps...${NC}"
    docker-compose down
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Services arrêtés avec succès!${NC}"
    else
        echo -e "${RED}❌ Erreur lors de l'arrêt${NC}"
    fi
}

restart_services() {
    echo -e "${YELLOW}🔄 Redémarrage de la stack DevOps...${NC}"
    stop_services
    sleep 3
    start_services
}

show_status() {
    echo -e "${CYAN}📊 Statut des services:${NC}"
    docker-compose ps
    
    echo -e "\n${CYAN}🔍 Vérification de la connectivité:${NC}"
    
    services=(
        "prometheus:9090:Prometheus"
        "grafana:3001:Grafana"
        "node-exporter:9100:Node Exporter"
        "cadvisor:8080:cAdvisor"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r container port name <<< "$service_info"
        
        if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
            if nc -z localhost "$port" 2>/dev/null; then
                echo -e "${GREEN}  ✅ $name (localhost:$port) - OK${NC}"
            else
                echo -e "${YELLOW}  ⚠️  $name (localhost:$port) - Container running but port not accessible${NC}"
            fi
        else
            echo -e "${RED}  ❌ $name - Container not running${NC}"
        fi
    done
    
    echo -e "\n${CYAN}🌐 URLs publiques:${NC}"
    show_services_urls
}

show_services_urls() {
    echo -e "${MAGENTA}  • Prometheus: https://prometheus.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${MAGENTA}  • Grafana: https://grafana.wk-archi-o23b-4-5-g7.fr (admin/admin)${NC}"
    echo -e "${WHITE}  • Traefik: https://traefik.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${WHITE}  • Jenkins: https://jenkins.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${WHITE}  • Gitea: https://gitea.wk-archi-o23b-4-5-g7.fr${NC}"
    echo -e "${WHITE}  • Registry: https://registry.wk-archi-o23b-4-5-g7.fr${NC}"
}

show_logs() {
    local service="$1"
    
    if [[ -n "$service" ]]; then
        echo -e "${CYAN}📝 Logs pour le service: $service${NC}"
        docker-compose logs -f --tail=100 "$service"
    else
        echo -e "${CYAN}📝 Logs de tous les services:${NC}"
        docker-compose logs -f --tail=50
    fi
}

backup_data() {
    echo -e "${YELLOW}💾 Sauvegarde des données...${NC}"
    
    BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Sauvegarder les volumes Docker
    echo -e "${CYAN}Sauvegarde des volumes Docker...${NC}"
    docker run --rm -v jenkins_home:/data -v "$PWD/$BACKUP_DIR":/backup alpine tar czf /backup/jenkins_home.tar.gz -C /data .
    docker run --rm -v gitea_data:/data -v "$PWD/$BACKUP_DIR":/backup alpine tar czf /backup/gitea_data.tar.gz -C /data .
    docker run --rm -v grafana_data:/data -v "$PWD/$BACKUP_DIR":/backup alpine tar czf /backup/grafana_data.tar.gz -C /data .
    docker run --rm -v prometheus_data:/data -v "$PWD/$BACKUP_DIR":/backup alpine tar czf /backup/prometheus_data.tar.gz -C /data .
    
    # Sauvegarder les fichiers de configuration
    echo -e "${CYAN}Sauvegarde de la configuration...${NC}"
    tar czf "$BACKUP_DIR/config.tar.gz" docker-compose.yml monitoring/ grafana/ letsencrypt/
    
    echo -e "${GREEN}✅ Sauvegarde terminée dans: $BACKUP_DIR${NC}"
}

update_images() {
    echo -e "${CYAN}🔄 Mise à jour des images Docker...${NC}"
    docker-compose pull
    
    echo -e "${YELLOW}Redémarrage avec les nouvelles images...${NC}"
    docker-compose up -d
    
    echo -e "${GREEN}✅ Mise à jour terminée${NC}"
}

clean_docker() {
    echo -e "${YELLOW}🧹 Nettoyage des ressources Docker...${NC}"
    
    echo -e "${CYAN}Suppression des conteneurs arrêtés...${NC}"
    docker container prune -f
    
    echo -e "${CYAN}Suppression des images inutilisées...${NC}"
    docker image prune -f
    
    echo -e "${CYAN}Suppression des volumes inutilisés...${NC}"
    docker volume prune -f
    
    echo -e "${CYAN}Suppression des réseaux inutilisés...${NC}"
    docker network prune -f
    
    echo -e "${GREEN}✅ Nettoyage terminé${NC}"
}

# Script principal
case "${1:-help}" in
    "start")
        start_services
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs "$2"
        ;;
    "backup")
        backup_data
        ;;
    "update")
        update_images
        ;;
    "clean")
        clean_docker
        ;;
    "help"|*)
        show_help
        ;;
esac
