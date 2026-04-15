#!/bin/bash
set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
AWS_ACCOUNT_ID="262740798135"
AWS_REGION="us-east-2"
AWS_PROFILE="${AWS_PROFILE:-im-dev}"
ECR_REPO="deepframe/open-webui"
REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
NAMESPACE="deepframe"
DEPLOYMENT="open-webui"
CONTAINER="open-webui"

export AWS_PROFILE

# ── Determine image tag ─────────────────────────────────────────────────────
IMAGE_TAG="${1:-$(git rev-parse --short HEAD)}"
FULL_IMAGE="${REGISTRY}:${IMAGE_TAG}"

echo "==> Registry:  ${REGISTRY}"
echo "==> Image tag: ${IMAGE_TAG}"
echo "==> Full image: ${FULL_IMAGE}"
echo ""

# ── Step 1: Authenticate to ECR ─────────────────────────────────────────────
echo "==> Authenticating to ECR (profile: ${AWS_PROFILE})..."
aws ecr get-login-password --region "${AWS_REGION}" --profile "${AWS_PROFILE}" | \
  docker login --username AWS --password-stdin \
  "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
echo ""

# ── Step 2: Build the Docker image ──────────────────────────────────────────
echo "==> Building image..."
docker build \
  -t "${FULL_IMAGE}" \
  --build-arg BUILD_HASH="${IMAGE_TAG}" \
  .
echo ""

# ── Step 3: Push to ECR ─────────────────────────────────────────────────────
echo "==> Pushing ${FULL_IMAGE}..."
docker push "${FULL_IMAGE}"

# Also tag and push as :latest if an explicit tag was used
if [ "${IMAGE_TAG}" != "latest" ]; then
  docker tag "${FULL_IMAGE}" "${REGISTRY}:latest"
  echo "==> Pushing ${REGISTRY}:latest..."
  docker push "${REGISTRY}:latest"
fi
echo ""

# ── Step 4: Update the Kubernetes deployment ─────────────────────────────────
echo "==> Updating deployment ${DEPLOYMENT} in namespace ${NAMESPACE}..."
kubectl set image "deployment/${DEPLOYMENT}" \
  "${CONTAINER}=${FULL_IMAGE}" \
  -n "${NAMESPACE}"

# ── Step 5: Wait for rollout ─────────────────────────────────────────────────
echo "==> Waiting for rollout to complete..."
kubectl rollout status "deployment/${DEPLOYMENT}" -n "${NAMESPACE}" --timeout=300s

# ── Step 6: Show pod status ──────────────────────────────────────────────────
echo ""
echo "==> Deployment complete. Pod status:"
kubectl get pods -n "${NAMESPACE}" -l "run=${DEPLOYMENT}" -o wide
echo ""
echo "==> Image running:"
kubectl get pods -n "${NAMESPACE}" -l "run=${DEPLOYMENT}" \
  -o jsonpath='{.items[0].spec.containers[0].image}'
echo ""
