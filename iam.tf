```
# Iam policy
data "aws_iam_policy_document" "eks_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_role" {
  name               = "${var.cluster_name}-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Enable OIDC
data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.this.name
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10df6"]

  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

# Trust Policy (IRSA Core)
data "aws_iam_policy_document" "istio_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:istio-system:istio-ingressgateway"]
    }
  }
}

resource "aws_iam_role" "istio_irsa_role" {
  name               = "istio-ingress-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.istio_assume_role.json
}

resource "aws_iam_role_policy_attachment" "istio_attach" {
  role       = aws_iam_role.istio_irsa_role.name
  policy_arn = aws_iam_policy.istio_policy.arn
}

# K8s SA- IAM Annotation
resource "kubernetes_service_account" "istio_ingress_sa" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.istio_irsa_role.arn
    }
  }
}

# Attach SA to Istio Gateway (Helm)
resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"

  values = [<<EOF
serviceAccount:
  create: false
  name: istio-ingressgateway
EOF
  ]
}
```
