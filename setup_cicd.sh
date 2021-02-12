#!/usr/bin/env bash

set -e

SERVICE_ACCOUNT_NAME="github-actions"
TARGET_FOLDER="/tmp"
KUBECFG_FILE_NAME="/tmp/kubeconfig.yaml"

function setup_cicd() {
    NAMESPACE="${1:?}"
    echo "⏳ Setting service account for namespace ${NAMESPACE:?}..."

    kubectl get sa "${SERVICE_ACCOUNT_NAME}" --namespace "${NAMESPACE}" > /dev/null 2>&1 || kubectl create sa "${SERVICE_ACCOUNT_NAME}" --namespace "${NAMESPACE}"
    SECRET_NAME=$(kubectl get sa "${SERVICE_ACCOUNT_NAME}" --namespace="${NAMESPACE}" -o json | jq -r .secrets[].name)

    kubectl get secret --namespace "${NAMESPACE}" "${SECRET_NAME}" -o json | jq -r '.data["ca.crt"]' | base64 --decode > "${TARGET_FOLDER}/ca.crt"
    USER_TOKEN=$(kubectl get secret --namespace "${NAMESPACE}" "${SECRET_NAME}" -o json | jq -r '.data["token"]' | base64 --decode)

    context=$(kubectl config current-context)

    CLUSTER_NAME=$(kubectl config get-contexts "$context" | awk '{print $3}' | tail -n 1)


    ENDPOINT=$(kubectl config view \
        -o jsonpath="{.clusters[?(@.name == \"${CLUSTER_NAME}\")].cluster.server}")

    kubectl config set-cluster "${CLUSTER_NAME}" \
        --kubeconfig="${KUBECFG_FILE_NAME}" \
        --server="${ENDPOINT}" \
        --certificate-authority="${TARGET_FOLDER}/ca.crt" \
        --embed-certs=true

    kubectl config set-credentials \
        "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
        --kubeconfig="${KUBECFG_FILE_NAME}" \
        --token="${USER_TOKEN}"


    kubectl config set-context \
        "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
        --kubeconfig="${KUBECFG_FILE_NAME}" \
        --cluster="${CLUSTER_NAME}" \
        --user="${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
        --namespace="${NAMESPACE}"

    kubectl config use-context "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
        --kubeconfig="${KUBECFG_FILE_NAME}"
    kubectl apply -f "$(dirname "$(realpath "$0")")/manifests/rbac.yaml" -n "${NAMESPACE}"
    echo -e "✅ Service account created.\n"
}

setup_cicd staging
setup_cicd prod

echo "⏳ Updating Github secret..."
gh secret set KUBECONFIG -b"$(base64 --input ${KUBECFG_FILE_NAME})"
echo -e "✅ Github secret updated.\n"