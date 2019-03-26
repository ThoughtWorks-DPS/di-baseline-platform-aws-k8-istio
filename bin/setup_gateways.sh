#!/usr/bin/env bash

set -euo pipefail
ENVIRONMENT=$1
ISTIO_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$ISTIO_SCRIPT_DIR/.."
TEMPLATE_DIR="$PROJECT_DIR/templates"


GATEWAYS="bookinfo dev-api test-api kiali grafana jaeger prometheus"

for GATEWAY in $GATEWAYS; do
    FILE=$TEMPLATE_DIR/$GATEWAY-gateway.yml

    sed -i -e "s@{{ENVIRONMENT}}@${ENVIRONMENT}@g" "${FILE}"
    kubectl apply -f ${FILE}
done

