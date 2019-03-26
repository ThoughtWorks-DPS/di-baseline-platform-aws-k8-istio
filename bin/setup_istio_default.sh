#!/usr/bin/env bash

set -euo pipefail

# pass the environment e.g. staging, nonprod etc..
ENVIRONMENT=$1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR=$SCRIPT_DIR/../manifests


echo "Downloading Istio version $ISTIO_VERSION..."
ARTIFACT_NAME="istio-$ISTIO_VERSION-linux.tar.gz"
DOWNLOAD_URL="https://github.com/istio/istio/releases/download/$ISTIO_VERSION/$ARTIFACT_NAME"
curl --show-error --fail -# -L -O "$DOWNLOAD_URL"

echo
echo "Extracting..."
tar xzf "$ARTIFACT_NAME"

# first install CRDs
helm template $SCRIPT_DIR/istio-$ISTIO_VERSION/install/kubernetes/helm/istio-init --name istio-init \
--namespace istio-system \
--values "$MANIFESTS_DIR/istio-init-values.yaml" | kubectl apply -f -

CRD_COUNT=0
until [ $CRD_COUNT = "58" ]
do 
    echo "waiting for CRDs to apply"
    sleep 10
    CRD_COUNT=$(kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l)
    echo "CRD_COUNT->$CRD_COUNT|"
done 

echo "Applying Istio..."
helm template \
    $SCRIPT_DIR/istio-$ISTIO_VERSION/install/kubernetes/helm/istio \
    --set kiali.dashboard.jaegerURL=https://jaeger.$ENVIRONMENT.twdps.io \
    --set kiali.dashboard.grafanaURL=https://grafana.$ENVIRONMENT.twdps.io \
    --values "$MANIFESTS_DIR/istio-values.yaml" \
    --name istio \
    --namespace istio-system | kubectl apply -f -

echo
echo "Waiting for Istio deployments to complete... "
deployments=$(kubectl get --namespace=istio-system deployments --output=name)

for deployment in $deployments ; do
    kubectl rollout status --namespace=istio-system "$deployment"
done

echo
echo "install book info"
kubectl apply -f $SCRIPT_DIR/istio-$ISTIO_VERSION/samples/bookinfo/platform/kube/bookinfo.yaml
