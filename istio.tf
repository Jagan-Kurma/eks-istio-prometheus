# Alternateway 
```
#Istio Base
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = "istio-system"
  create_namespace = true
}
# Control plane
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"

  depends_on = [helm_release.istio_base]

  values = [<<EOF
meshConfig:
  enablePrometheusMerge: true
  accessLogFile: /dev/stdout
EOF
  ]
}

#ingress gataeway
resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"

  depends_on = [helm_release.istiod]

  values = [<<EOF
service:
  type: LoadBalancer
EOF
  ]
}

#sidecar Injection"
resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}
```
