# Prometheus configuration, need more input details for excute as expected.
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "monitoring"
  create_namespace = true

  values = [<<EOF
server:
  global:
    scrape_interval: 15s
  resources:
    limits:
      cpu: 500m
      memory: 512Mi

alertmanager:
  enabled: false

pushgateway:
  enabled: false

kubeStateMetrics:
  enabled: true
EOF
  ]
}

/stats/prometheus


