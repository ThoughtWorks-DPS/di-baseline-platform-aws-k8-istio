#!/usr/bin/env bash

set -euo pipefail

# pass the environment e.g. staging, nonprod etc..
ENVIRONMENT=$1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR=$SCRIPT_DIR/../manifests
ISTIO_DIR=$SCRIPT_DIR/../istio-$ISTIO_VERSION

echo "Downloading Istio version $ISTIO_VERSION..."
ARTIFACT_NAME="istio-$ISTIO_VERSION-linux.tar.gz"
DOWNLOAD_URL="https://github.com/istio/istio/releases/download/$ISTIO_VERSION/$ARTIFACT_NAME"
curl --show-error --fail -# -L -O "$DOWNLOAD_URL"

echo
echo "Extracting..."
tar xzf "$ARTIFACT_NAME"

echo "list dir"
ls -l
echo "remove book info app"
kubectl delete -f $ISTIO_DIR/samples/bookinfo/platform/kube/bookinfo.yaml

# there is a CRD race condition - per their docs adding this fix
helm template $ISTIO_DIR/install/kubernetes/helm/istio-init --name istio-init \
--namespace istio-system \
--values "$MANIFESTS_DIR/istio-init-values.yaml" | kubectl delete -f -

echo "Deleting Istio..."
helm template \
    $ISTIO_DIR/install/kubernetes/helm/istio \
    --set kiali.dashboard.jaegerURL=http://jaeger.$ENVIRONMENT.vss.twdps.io \
    --set kiali.dashboard.grafanaURL=http://grafana.$ENVIRONMENT.vss.twdps.io \
    --values "$MANIFESTS_DIR/istio-values.yaml" \
    --name istio \
    --namespace istio-system | kubectl delete -f -
