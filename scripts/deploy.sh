#!/usr/bin/env bash
set -euo pipefail

# Deployer den statiske GIHC-side til k3s.
#
# k3s API'et er ikke offentligt tilgængeligt. Åbn SSH-tunnelen først:
#   ssh -L 6443:localhost:6443 -N -f root@65.109.233.92
#
# På udviklingsmaskinen er 6443 optaget af et lokalt k3s-cluster. Brug derfor:
#   ssh -L 16443:localhost:6443 -N -f hetzner-k3s
#   KUBECTL_SERVER=https://127.0.0.1:16443 ./scripts/deploy.sh
#
# Brug:
#   ./scripts/deploy.sh
#   IMAGE=ghcr.io/gihc-org/gihc:latest ./scripts/deploy.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/gihc.yml}"

NAMESPACE="gihc-site"
DEPLOYMENT="gihc-site"
IMAGE="${IMAGE:-ghcr.io/gihc-org/gihc:latest}"
IMAGE_PULL_POLICY="${IMAGE_PULL_POLICY:-}"

KUBECTL=(kubectl)
if [ -n "${KUBECTL_SERVER:-}" ]; then
    KUBECTL+=(--server="$KUBECTL_SERVER")
fi

if [ -n "$IMAGE_PULL_POLICY" ]; then
    case "$IMAGE_PULL_POLICY" in
        Always|IfNotPresent|Never) ;;
        *)
            echo "IMAGE_PULL_POLICY skal være Always, IfNotPresent eller Never" >&2
            exit 2
            ;;
    esac
fi

echo "==> Anvender Kubernetes-manifester"
"${KUBECTL[@]}" apply -f "${ROOT_DIR}/k8s/namespace.yaml"
"${KUBECTL[@]}" apply -f "${ROOT_DIR}/k8s/deployment.yaml"
"${KUBECTL[@]}" apply -f "${ROOT_DIR}/k8s/service.yaml"
"${KUBECTL[@]}" apply -f "${ROOT_DIR}/k8s/ingress.yaml"

echo "==> Bruger image ${IMAGE}"
"${KUBECTL[@]}" -n "$NAMESPACE" set image "deployment/${DEPLOYMENT}" "web=${IMAGE}"
if [ -n "$IMAGE_PULL_POLICY" ]; then
    "${KUBECTL[@]}" -n "$NAMESPACE" patch "deployment/${DEPLOYMENT}" \
        --type=json \
        -p="[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/imagePullPolicy\",\"value\":\"${IMAGE_PULL_POLICY}\"}]"
fi
"${KUBECTL[@]}" -n "$NAMESPACE" annotate "deployment/${DEPLOYMENT}" \
    "kubernetes.io/change-cause=Deploy ${IMAGE}" --overwrite
"${KUBECTL[@]}" -n "$NAMESPACE" rollout restart "deployment/${DEPLOYMENT}"

echo "==> Venter på rollout"
"${KUBECTL[@]}" -n "$NAMESPACE" rollout status "deployment/${DEPLOYMENT}" --timeout=180s

echo "==> Venter på, at cert-manager udsteder TLS-certifikatet"
for _ in $(seq 1 30); do
    READY="$("${KUBECTL[@]}" -n "$NAMESPACE" get certificate gihc-online-tls \
        -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
    if [ "$READY" = "True" ]; then
        echo "==> Certifikatet er klart"
        break
    fi
    sleep 5
done

if [ "${READY:-}" != "True" ]; then
    echo "==> Certifikatet er ikke klart endnu. Se:" >&2
    echo "    kubectl -n ${NAMESPACE} describe certificate gihc-online-tls" >&2
fi

"${KUBECTL[@]}" -n "$NAMESPACE" get pods,service,ingress,certificate -o wide
echo
echo "==> https://gihc.online"

