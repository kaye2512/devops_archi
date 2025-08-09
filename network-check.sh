#!/bin/bash

# Script de validation et correction des réseaux
# Usage: ./network-check.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🌐 Validation et Configuration des Réseaux Docker${NC}"
echo -e "${BLUE}=================================================${NC}"

# Fonction pour créer les réseaux
create_networks() {
    echo -e "\n${CYAN}🔨 Création/Vérification des réseaux...${NC}"
    
    # Créer traefik-net
    if ! docker network ls --filter name=traefik-net --format "{{.Name}}" | grep -q "traefik-net"; then
        echo -e "${YELLOW}🔧 Création du réseau traefik-net...${NC}"
        docker network create traefik-net --driver bridge
        echo -e "${GREEN}✅ Réseau traefik-net créé${NC}"
    else
        echo -e "${GREEN}✅ Réseau traefik-net existe déjà${NC}"
    fi
    
    # Créer tiptop-net
    if ! docker network ls --filter name=tiptop-net --format "{{.Name}}" | grep -q "tiptop-net"; then
        echo -e "${YELLOW}🔧 Création du réseau tiptop-net...${NC}"
        docker network create tiptop-net --driver bridge
        echo -e "${GREEN}✅ Réseau tiptop-net créé${NC}"
    else
        echo -e "${GREEN}✅ Réseau tiptop-net existe déjà${NC}"
    fi
}

# Fonction pour afficher les détails des réseaux
show_network_details() {
    echo -e "\n${CYAN}📋 Détails des réseaux:${NC}"
    
    for network in "traefik-net" "tiptop-net"; do
        if docker network ls --filter name=$network --format "{{.Name}}" | grep -q "$network"; then
            echo -e "\n${YELLOW}🌐 Réseau: $network${NC}"
            docker network inspect $network --format '  Subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}'
            docker network inspect $network --format '  Gateway: {{range .IPAM.Config}}{{.Gateway}}{{end}}'
            
            # Lister les conteneurs connectés
            containers=$(docker network inspect $network --format '{{range .Containers}}{{.Name}} {{end}}')
            if [[ -n "$containers" ]]; then
                echo -e "  ${GREEN}Conteneurs connectés: $containers${NC}"
            else
                echo -e "  ${YELLOW}Aucun conteneur connecté${NC}"
            fi
        fi
    done
}

# Fonction pour connecter tous les services au bon réseau
connect_services() {
    echo -e "\n${CYAN}🔗 Connexion des services aux réseaux...${NC}"
    
    # Services qui doivent être sur traefik-net
    TRAEFIK_SERVICES=("traefik" "jenkins" "gitea" "registry" "prometheus" "grafana" "node-exporter" "cadvisor")
    
    # Services qui doivent être sur tiptop-net  
    TIPTOP_SERVICES=("jenkins" "gitea" "registry" "prometheus" "grafana" "node-exporter" "cadvisor")
    
    echo -e "${YELLOW}🔌 Connexion au réseau traefik-net...${NC}"
    for service in "${TRAEFIK_SERVICES[@]}"; do
        if docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
            if docker network connect traefik-net "$service" 2>/dev/null; then
                echo -e "${GREEN}  ✅ $service connecté à traefik-net${NC}"
            else
                echo -e "${GRAY}  ℹ️  $service déjà connecté à traefik-net${NC}"
            fi
        else
            echo -e "${YELLOW}  ⚠️  $service n'est pas en cours d'exécution${NC}"
        fi
    done
    
    echo -e "\n${YELLOW}🔌 Connexion au réseau tiptop-net...${NC}"
    for service in "${TIPTOP_SERVICES[@]}"; do
        if docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
            if docker network connect tiptop-net "$service" 2>/dev/null; then
                echo -e "${GREEN}  ✅ $service connecté à tiptop-net${NC}"
            else
                echo -e "${GRAY}  ℹ️  $service déjà connecté à tiptop-net${NC}"
            fi
        else
            echo -e "${YELLOW}  ⚠️  $service n'est pas en cours d'exécution${NC}"
        fi
    done
}

# Fonction pour valider les connexions
validate_connections() {
    echo -e "\n${CYAN}✅ Validation des connexions...${NC}"
    
    SERVICES=("traefik" "jenkins" "gitea" "registry" "prometheus" "grafana" "node-exporter" "cadvisor")
    
    for service in "${SERVICES[@]}"; do
        if docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
            echo -e "\n${BLUE}📦 Service: $service${NC}"
            
            # Vérifier traefik-net
            if docker inspect "$service" | grep -q '"traefik-net"'; then
                echo -e "${GREEN}  ✅ Connecté à traefik-net${NC}"
            else
                echo -e "${RED}  ❌ NON connecté à traefik-net${NC}"
            fi
            
            # Vérifier tiptop-net (sauf pour traefik)
            if [[ "$service" != "traefik" ]]; then
                if docker inspect "$service" | grep -q '"tiptop-net"'; then
                    echo -e "${GREEN}  ✅ Connecté à tiptop-net${NC}"
                else
                    echo -e "${RED}  ❌ NON connecté à tiptop-net${NC}"
                fi
            fi
            
            # Afficher l'IP sur traefik-net
            traefik_ip=$(docker inspect "$service" | grep -A 1 '"traefik-net"' | grep '"IPAddress"' | sed 's/.*": "//;s/".*//')
            if [[ -n "$traefik_ip" ]]; then
                echo -e "${CYAN}  🌐 IP traefik-net: $traefik_ip${NC}"
            fi
            
        else
            echo -e "\n${RED}📦 Service: $service - NON DÉMARRÉ${NC}"
        fi
    done
}

# Fonction pour tester la connectivité
test_connectivity() {
    echo -e "\n${CYAN}🔍 Test de connectivité réseau...${NC}"
    
    # Test de connectivité entre les services
    if docker ps --filter "name=prometheus" --filter "status=running" | grep -q "prometheus"; then
        echo -e "\n${YELLOW}🔍 Test depuis Prometheus...${NC}"
        
        # Tester les targets Prometheus
        TARGETS=("traefik:8080" "jenkins:8080" "gitea:3000" "node-exporter:9100" "cadvisor:8080")
        
        for target in "${TARGETS[@]}"; do
            service_name=$(echo $target | cut -d: -f1)
            port=$(echo $target | cut -d: -f2)
            
            if docker exec prometheus nc -z $service_name $port 2>/dev/null; then
                echo -e "${GREEN}  ✅ $target accessible${NC}"
            else
                echo -e "${RED}  ❌ $target NON accessible${NC}"
            fi
        done
    fi
}

# Menu principal
case "${1:-all}" in
    "create")
        create_networks
        ;;
    "connect")
        connect_services
        ;;
    "validate")
        validate_connections
        ;;
    "test")
        test_connectivity
        ;;
    "details")
        show_network_details
        ;;
    "all"|*)
        create_networks
        connect_services
        show_network_details
        validate_connections
        test_connectivity
        ;;
esac

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 Validation des réseaux terminée !${NC}"
echo -e "\n${CYAN}💡 Commandes utiles:${NC}"
echo -e "${WHITE}  ./network-check.sh create    - Créer les réseaux${NC}"
echo -e "${WHITE}  ./network-check.sh connect   - Connecter les services${NC}"
echo -e "${WHITE}  ./network-check.sh validate  - Valider les connexions${NC}"
echo -e "${WHITE}  ./network-check.sh test      - Tester la connectivité${NC}"
echo -e "${WHITE}  ./network-check.sh details   - Afficher les détails${NC}"
