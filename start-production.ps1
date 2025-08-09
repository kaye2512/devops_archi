# Script de démarrage pour l'environnement de production WK-Archi
# Usage: .\start-production.ps1

Write-Host "🚀 Démarrage de la stack DevOps WK-Archi avec monitoring..." -ForegroundColor Green

# Vérifier si Docker est en marche
try {
    docker version | Out-Null
    Write-Host "✅ Docker est en marche" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker n'est pas en marche. Veuillez démarrer Docker Desktop." -ForegroundColor Red
    exit 1
}

# Se déplacer dans le répertoire du projet
Set-Location "e:\devops-platform"

# Créer le réseau externe si nécessaire
Write-Host "📡 Vérification du réseau tiptop-net..." -ForegroundColor Yellow
$networkExists = docker network ls --filter name=tiptop-net --format "{{.Name}}"
if (-not $networkExists) {
    Write-Host "🔨 Création du réseau tiptop-net..." -ForegroundColor Yellow
    docker network create tiptop-net
    Write-Host "✅ Réseau tiptop-net créé" -ForegroundColor Green
} else {
    Write-Host "✅ Réseau tiptop-net existe déjà" -ForegroundColor Green
}

# Vérifier les fichiers de configuration
Write-Host "🔍 Vérification de la configuration..." -ForegroundColor Yellow

$configFiles = @(
    ".\monitoring\prometheus.yml",
    ".\monitoring\alerts\rules.yml",
    ".\grafana\provisioning\datasources\datasource.yml",
    ".\grafana\provisioning\dashboards\dashboard.yml"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file manquant" -ForegroundColor Red
    }
}

# Démarrer les services
Write-Host "🐳 Démarrage des conteneurs..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Tous les services ont été démarrés avec succès!" -ForegroundColor Green
    
    # Attendre que les services soient prêts
    Write-Host "⏳ Attente du démarrage des services (30s)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    Write-Host "`n🌐 Vos services sont maintenant disponibles:" -ForegroundColor Cyan
    Write-Host "  • Traefik Dashboard: https://traefik.wk-archi-023b-4-5-g7.fr" -ForegroundColor White
    Write-Host "  • Jenkins: https://jenkins.wk-archi-023b-4-5-g7.fr (local: http://localhost:8081)" -ForegroundColor White
    Write-Host "  • Gitea: https://gitea.wk-archi-023b-4-5-g7.fr" -ForegroundColor White
    Write-Host "  • Registry: https://registry.wk-archi-023b-4-5-g7.fr" -ForegroundColor White
    Write-Host "  • Prometheus: https://prometheus.wk-archi-023b-4-5-g7.fr (local: http://localhost:9090)" -ForegroundColor Magenta
    Write-Host "  • Grafana: https://grafana.wk-archi-023b-4-5-g7.fr (local: http://localhost:3001)" -ForegroundColor Magenta
    Write-Host "    └─ Identifiants: admin/admin" -ForegroundColor Gray
    
    Write-Host "`n📊 Services de monitoring locaux:" -ForegroundColor Cyan
    Write-Host "  • Node Exporter: http://localhost:9100" -ForegroundColor White
    Write-Host "  • cAdvisor: http://localhost:8080" -ForegroundColor White
    
    Write-Host "`n🔍 Vérification des targets Prometheus..." -ForegroundColor Yellow
    
    # Vérifier l'état des services
    Write-Host "`n📋 État des conteneurs:" -ForegroundColor Cyan
    docker-compose ps
    
    Write-Host "`n🎯 Prochaines étapes:" -ForegroundColor Yellow
    Write-Host "  1. Accédez à Prometheus: https://prometheus.wk-archi-023b-4-5-g7.fr/targets" -ForegroundColor White
    Write-Host "     └─ Vérifiez que tous les targets sont 'UP'" -ForegroundColor Gray
    Write-Host "  2. Accédez à Grafana: https://grafana.wk-archi-023b-4-5-g7.fr" -ForegroundColor White
    Write-Host "     └─ Connectez-vous avec admin/admin" -ForegroundColor Gray
    Write-Host "     └─ Le datasource Prometheus est pré-configuré" -ForegroundColor Gray
    Write-Host "  3. Importez des dashboards recommandés:" -ForegroundColor White
    Write-Host "     └─ Node Exporter Full (ID: 1860)" -ForegroundColor Gray
    Write-Host "     └─ Docker Container Metrics (ID: 179)" -ForegroundColor Gray
    Write-Host "     └─ Traefik 2.0 Dashboard (ID: 11462)" -ForegroundColor Gray
    
    Write-Host "`n🚨 IMPORTANT - Sécurité:" -ForegroundColor Red
    Write-Host "  • Changez le mot de passe Grafana par défaut (admin/admin)" -ForegroundColor Yellow
    Write-Host "  • Vérifiez que vos certificats SSL sont bien générés" -ForegroundColor Yellow
    
} else {
    Write-Host "❌ Erreur lors du démarrage des services" -ForegroundColor Red
    Write-Host "📋 Vérifiez les logs avec: docker-compose logs" -ForegroundColor Yellow
}

Write-Host "`n📖 Pour plus d'informations, consultez PRODUCTION-CONFIG.md" -ForegroundColor Cyan
