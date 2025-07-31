FROM jenkins/jenkins:lts

USER root

# Installer Docker CLI
RUN apt-get update && apt-get install -y docker.io

# Optionnel : ajouter l'utilisateur jenkins au groupe docker pour accès au socket
RUN usermod -aG docker jenkins

USER jenkins
