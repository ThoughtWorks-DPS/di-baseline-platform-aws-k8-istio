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

echo "remove book info app"
echo "install book info"
kubectl delete -f $SCRIPT_DIR/istio-$ISTIO_VERSION/samples/bookinfo/platform/kube/bookinfo.yaml

# there is a CRD race condition - per their docs adding this fix
helm template $SCRIPT_DIR/istio-$ISTIO_VERSION/install/kubernetes/helm/istio-init --name istio-init \
--namespace istio-system \
--values "$MANIFESTS_DIR/istio-init-values.yaml" | kubectl delete -f -

echo "Deleting Istio..."
helm template \
    $SCRIPT_DIR/istio-$ISTIO_VERSION/install/kubernetes/helm/istio \
    --set kiali.dashboard.jaegerURL=http://jaeger.$ENVIRONMENT.vss.twdps.io \
    --set kiali.dashboard.grafanaURL=http://grafana.$ENVIRONMENT.vss.twdps.io \
    --values "$MANIFESTS_DIR/istio-values.yaml" \
    --name istio \
    --namespace istio-system | kubectl delete -f -
