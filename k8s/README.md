# Open WebUI - Kubernetes Deployment

Manifests for deploying the custom Open WebUI build to the `dev-deepframe` EKS cluster.

## Structure

```
k8s/
├── base/                        # Environment-agnostic resources
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── pvc.yaml
│   ├── http-route.yaml
│   └── secret.yaml              # Template only — not included in kustomization.yaml
└── overlays/
    └── dev/                     # Dev overlay: nameSuffix -dev, model URLs, secret name
        ├── kustomization.yaml
        └── patch-deployment.yaml
```

## Prerequisites

- AWS CLI configured with credentials (`aws configure`)
- Docker installed
- `kubectl` connected to `arn:aws:eks:us-east-2:262740798135:cluster/dev-deepframe`
- ECR repository `deepframe/open-webui` created (see below)

## One-Time Setup

### 1. Create ECR Repository

```bash
aws ecr create-repository \
  --repository-name deepframe/open-webui \
  --region us-east-2 \
  --image-scanning-configuration scanOnPush=true
```

### 2. Create the Secret (if not already exists)

```bash
kubectl create secret generic open-webui-dev-secret \
  --namespace deepframe \
  --from-literal=WEBUI_SECRET_KEY="$(openssl rand -hex 32)"
```

### 3. Apply All Manifests

```bash
kubectl apply -k k8s/overlays/dev
```

## Build & Deploy

Use the `deploy.sh` script from the repo root:

```bash
./deploy.sh          # Build, push, and deploy using git SHA tag
./deploy.sh latest   # Build, push, and deploy using :latest tag
```

Or manually:

```bash
export REGISTRY=262740798135.dkr.ecr.us-east-2.amazonaws.com/deepframe/open-webui
export IMAGE_TAG=$(git rev-parse --short HEAD)

# Authenticate
aws ecr get-login-password --region us-east-2 | \
  docker login --username AWS --password-stdin 262740798135.dkr.ecr.us-east-2.amazonaws.com

# Build & push
docker build -t $REGISTRY:$IMAGE_TAG --build-arg BUILD_HASH=$IMAGE_TAG .
docker push $REGISTRY:$IMAGE_TAG

# Deploy
kubectl set image deployment/open-webui-dev \
  open-webui-dev=$REGISTRY:$IMAGE_TAG -n deepframe
kubectl rollout status deployment/open-webui-dev -n deepframe
```

## Access

The service is exposed via Tailscale at: `https://df-open-webui-dev.<your-tailnet>`

## File Overview

| File | Description |
|------|-------------|
| `base/pvc.yaml` | 20Gi gp3 PersistentVolumeClaim for `/app/backend/data` |
| `base/secret.yaml` | Template only — use `kubectl create secret` for real values |
| `base/deployment.yaml` | Base deployment: image, probes, resource limits, FSX mount |
| `base/service.yaml` | ClusterIP service with Tailscale proxy annotations |
| `base/http-route.yaml` | Gateway HTTPRoute for `open-webui.dev.deepframe.cloud` |
| `overlays/dev/kustomization.yaml` | Dev overlay: `nameSuffix: -dev`, namespace, labels |
| `overlays/dev/patch-deployment.yaml` | Dev patch: model URLs, secret name, PVC claimName |
