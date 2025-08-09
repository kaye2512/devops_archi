#!/bin/bash

# Script pour configurer Jenkins avec le plugin Prometheus
# Usage: ./setup-jenkins-metrics.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🏗️ Configuration Jenkins pour Prometheus${NC}"

# Vérifier que Jenkins est en cours d'exécution
if ! docker ps --filter "name=jenkins" --filter "status=running" | grep -q "jenkins"; then
    echo -e "${RED}❌ Jenkins n'est pas en cours d'exécution${NC}"
    echo -e "${YELLOW}💡 Démarrez d'abord Jenkins: ./manage-stack.sh start${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Jenkins détecté${NC}"

# Attendre que Jenkins soit complètement démarré
echo -e "${YELLOW}⏳ Vérification que Jenkins est prêt...${NC}"

max_attempts=30
attempt=1

while [[ $attempt -le $max_attempts ]]; do
    if docker exec jenkins curl -s http://localhost:8080/login > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Jenkins est prêt${NC}"
        break
    fi
    
    echo -e "${GRAY}   Tentative $attempt/$max_attempts...${NC}"
    sleep 10
    ((attempt++))
done

if [[ $attempt -gt $max_attempts ]]; then
    echo -e "${RED}❌ Jenkins n'est pas accessible après 5 minutes${NC}"
    exit 1
fi

# Récupérer le mot de passe initial admin
echo -e "${CYAN}🔐 Récupération du mot de passe Jenkins initial...${NC}"

if docker exec jenkins test -f /var/jenkins_home/secrets/initialAdminPassword; then
    JENKINS_PASSWORD=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)
    echo -e "${YELLOW}🔑 Mot de passe admin initial: ${JENKINS_PASSWORD}${NC}"
    echo -e "${YELLOW}📋 Conservez ce mot de passe pour la configuration initiale${NC}"
else
    echo -e "${YELLOW}ℹ️ Jenkins semble déjà configuré${NC}"
fi

# Créer un script de configuration Jenkins
cat > /tmp/jenkins-prometheus-setup.groovy <<'EOF'
import jenkins.model.*
import hudson.util.*
import jenkins.install.*

// Désactiver la configuration initiale si pas encore fait
def instance = Jenkins.getInstance()
if(!instance.getInstallState().equals(InstallState.INITIAL_SETUP_COMPLETED)) {
    println("Configuration initiale Jenkins...")
    instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
    instance.save()
}

// Configuration des plugins à installer
def pluginsToInstall = [
    "prometheus"
]

def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

println("Installation du plugin Prometheus...")

pluginsToInstall.each { pluginName ->
    if (!pm.getPlugin(pluginName)) {
        def plugin = uc.getPlugin(pluginName)
        if (plugin) {
            println("Installation de ${pluginName}...")
            plugin.deploy()
        } else {
            println("Plugin ${pluginName} non trouvé dans l'UpdateCenter")
        }
    } else {
        println("Plugin ${pluginName} déjà installé")
    }
}

instance.save()
println("Configuration terminée")
EOF

# Copier le script dans Jenkins
docker cp /tmp/jenkins-prometheus-setup.groovy jenkins:/tmp/

# Exécuter le script de configuration
echo -e "${YELLOW}🔧 Installation du plugin Prometheus...${NC}"

docker exec jenkins java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ groovy = < /tmp/jenkins-prometheus-setup.groovy

# Instructions manuelles
echo -e "\n${CYAN}📋 Configuration manuelle nécessaire:${NC}"
echo -e "${WHITE}1. Accédez à Jenkins: https://jenkins.wk-archi-o23b-4-5-g7.fr${NC}"

if [[ -n "$JENKINS_PASSWORD" ]]; then
    echo -e "${WHITE}2. Utilisez le mot de passe: ${JENKINS_PASSWORD}${NC}"
fi

echo -e "${WHITE}3. Allez dans 'Manage Jenkins' > 'Manage Plugins'${NC}"
echo -e "${WHITE}4. Dans l'onglet 'Available', recherchez 'Prometheus metrics'${NC}"
echo -e "${WHITE}5. Installez le plugin 'Prometheus metrics plugin'${NC}"
echo -e "${WHITE}6. Redémarrez Jenkins${NC}"
echo -e "${WHITE}7. Les métriques seront disponibles sur: /prometheus${NC}"

echo -e "\n${YELLOW}🔄 Redémarrage de Jenkins pour activer le plugin...${NC}"
docker exec jenkins java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ safe-restart || true

# Nettoyer
rm -f /tmp/jenkins-prometheus-setup.groovy

echo -e "\n${GREEN}🎯 Configuration Jenkins terminée!${NC}"
echo -e "${CYAN}📊 Une fois le plugin installé, les métriques seront sur:${NC}"
echo -e "${WHITE}   https://jenkins.wk-archi-o23b-4-5-g7.fr/prometheus${NC}"

echo -e "\n${YELLOW}⏭️  Prochaines étapes:${NC}"
echo -e "${WHITE}1. Terminez la configuration Jenkins via l'interface web${NC}"
echo -e "${WHITE}2. Redémarrez la stack: ./manage-stack.sh restart${NC}"
echo -e "${WHITE}3. Vérifiez les targets: ./prometheus-debug.sh${NC}"
