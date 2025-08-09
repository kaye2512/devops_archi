# Script PowerShell pour gérer la stack DevOps avec monitoring

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status", "logs")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$Service = "all"
)

$ProjectPath = "e:\devops-platform"

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Start-Services {
    Write-ColorOutput Green "🚀 Démarrage de la stack DevOps avec monitoring..."
    
    Set-Location $ProjectPath
    
    # Vérifier si Docker est en marche
    try {
        docker version | Out-Null
        Write-ColorOutput Green "✅ Docker is running"
    }
    catch {
        Write-ColorOutput Red "❌ Docker n'est pas en marche. Veuillez démarrer Docker Desktop."
        return
    }
    
    # Démarrer les services
    Write-ColorOutput Yellow "📦 Démarrage des conteneurs..."
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Tous les services ont été démarrés avec succès!"
        Write-ColorOutput Cyan "`n🌐 Services disponibles:"
        Write-ColorOutput White "  • Traefik Dashboard: https://traefik.wk-archi-023b-4-5-g7.fr"
        Write-ColorOutput White "  • Jenkins: https://jenkins.wk-archi-023b-4-5-g7.fr ou http://localhost:8081"
        Write-ColorOutput White "  • Gitea: https://gitea.wk-archi-023b-4-5-g7.fr"
        Write-ColorOutput White "  • Registry: https://registry.wk-archi-023b-4-5-g7.fr"
        Write-ColorOutput White "  • Prometheus: https://prometheus.wk-archi-023b-4-5-g7.fr ou http://localhost:9090"
        Write-ColorOutput White "  • Grafana: https://grafana.wk-archi-023b-4-5-g7.fr ou http://localhost:3001 (admin/admin)"
        Write-ColorOutput White "  • Node Exporter: http://localhost:9100"
        Write-ColorOutput White "  • cAdvisor: http://localhost:8080"
        Write-ColorOutput Yellow "`n⚠️  Note: Les certificats SSL seront générés automatiquement par Let's Encrypt"
    } else {
        Write-ColorOutput Red "❌ Erreur lors du démarrage des services"
    }
}

function Stop-Services {
    Write-ColorOutput Yellow "🛑 Arrêt de la stack DevOps..."
    Set-Location $ProjectPath
    docker-compose down
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput Green "✅ Tous les services ont été arrêtés avec succès!"
    } else {
        Write-ColorOutput Red "❌ Erreur lors de l'arrêt des services"
    }
}

function Restart-Services {
    Write-ColorOutput Yellow "🔄 Redémarrage de la stack DevOps..."
    Stop-Services
    Start-Sleep -Seconds 3
    Start-Services
}

function Get-Status {
    Write-ColorOutput Cyan "📊 Status des services:"
    Set-Location $ProjectPath
    docker-compose ps
    
    Write-ColorOutput Cyan "`n🔍 Vérification de la connectivité:"
    
    $services = @(
        @{Name="Prometheus"; URL="http://localhost:9090"; Description="Prometheus server"},
        @{Name="Grafana"; URL="http://localhost:3001"; Description="Grafana dashboard"},
        @{Name="Traefik"; URL="http://localhost:8080"; Description="Traefik dashboard"},
        @{Name="Jenkins"; URL="http://localhost:8081"; Description="Jenkins"},
        @{Name="Node Exporter"; URL="http://localhost:9100"; Description="Node metrics"},
        @{Name="cAdvisor"; URL="http://localhost:8080"; Description="Container metrics"}
    )
    
    foreach ($service in $services) {
        try {
            $response = Invoke-WebRequest -Uri $service.URL -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            Write-ColorOutput Green "  ✅ $($service.Name): $($service.URL) - OK"
        }
        catch {
            Write-ColorOutput Red "  ❌ $($service.Name): $($service.URL) - NOK"
        }
    }
}

function Show-Logs {
    Write-ColorOutput Cyan "📝 Logs des services:"
    Set-Location $ProjectPath
    
    if ($Service -eq "all") {
        docker-compose logs -f --tail=100
    } else {
        docker-compose logs -f --tail=100 $Service
    }
}

# Execution du script
switch ($Action) {
    "start" { Start-Services }
    "stop" { Stop-Services }
    "restart" { Restart-Services }
    "status" { Get-Status }
    "logs" { Show-Logs }
}
