# 🔧 Configurations alternatives pour Gitea dans Prometheus

# ===========================================
# MÉTHODE 1: Authorization Header (actuelle)
# ===========================================
  - job_name: 'gitea'
    static_configs:
      - targets: ['gitea:3000']
    metrics_path: '/metrics'
    authorization:
      type: Bearer
      credentials: prometheus-metrics-token

# ===========================================
# MÉTHODE 2: Paramètres URL (alternative 1)
# ===========================================
  - job_name: 'gitea'
    static_configs:
      - targets: ['gitea:3000']
    metrics_path: '/metrics'
    params:
      token: ['prometheus-metrics-token']

# ===========================================
# MÉTHODE 3: Header personnalisé (alternative 2)
# ===========================================
  - job_name: 'gitea'
    static_configs:
      - targets: ['gitea:3000']
    metrics_path: '/metrics'
    http_config:
      headers:
        Token: prometheus-metrics-token

# ===========================================
# MÉTHODE 4: Sans authentification (test)
# ===========================================
  - job_name: 'gitea'
    static_configs:
      - targets: ['gitea:3000']
    metrics_path: '/metrics'

# ===========================================
# MÉTHODE 5: Basic Auth (si configuré dans Gitea)
# ===========================================
  - job_name: 'gitea'
    static_configs:
      - targets: ['gitea:3000']
    metrics_path: '/metrics'
    basic_auth:
      username: prometheus
      password: prometheus-metrics-token
