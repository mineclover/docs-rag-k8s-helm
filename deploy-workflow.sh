#!/bin/bash
set -e

# ===============================================
# 🚀 n8n Kubernetes Deployment Workflow
# ===============================================

# 1. 환경 감지 및 .env 로드
if [ -z "$GITHUB_ACTIONS" ]; then
  echo "ℹ Info: Running in local environment"
  if [ -f .env ]; then
    echo "ℹ Info: Loading environment variables from .env file"
    export $(grep -v '^#' .env | xargs)
  else
    echo "❌ .env 파일이 없습니다. .env.template을 복사해 생성하세요."
    exit 1
  fi
else
  echo "ℹ Info: Running in GitHub Actions environment"
fi

# 2. 필수 환경 변수 체크
if [ -z "$KUBECONFIG_DATA" ]; then
  echo "❌ KUBECONFIG_DATA 환경 변수가 필요합니다."
  exit 1
fi
if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
  echo "❌ POSTGRES_USER, POSTGRES_PASSWORD 환경 변수가 필요합니다."
  exit 1
fi

NAMESPACE=${NAMESPACE:-n8n}
KUBE_DIR="n8n-hosting/kubernetes"

# 3. kubeconfig 설정
echo "▶ Starting: Set up kubectl"
echo "$KUBECONFIG_DATA" | base64 -d > kubeconfig.tmp
export KUBECONFIG=$(pwd)/kubeconfig.tmp

# 4. 클러스터 연결 확인
kubectl version --client
kubectl cluster-info

# 5. 네임스페이스 생성
kubectl apply -f "$KUBE_DIR/namespace.yaml"

# 6. 시크릿 생성 (덮어쓰기)
kubectl delete secret postgres-secret -n $NAMESPACE --ignore-not-found
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_USER="$POSTGRES_USER" \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -n $NAMESPACE

# 7. ConfigMap, PVC, Deployment, Service 적용
for f in "$KUBE_DIR"/*.yaml; do
  fname=$(basename "$f")
  if [[ "$fname" == "namespace.yaml" || "$fname" == "postgres-secret.yaml" ]]; then
    continue
  fi
  echo "▶ Applying: $fname"
  kubectl apply -f "$f"
done

# 8. 배포 대기 및 상태 확인
kubectl rollout status deployment/postgres -n $NAMESPACE
kubectl rollout status deployment/n8n -n $NAMESPACE
kubectl get all -n $NAMESPACE

# 9. kubeconfig 정리
rm -f kubeconfig.tmp

echo "🎉 Deployment Workflow Completed Successfully!" 