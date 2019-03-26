#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "Deploy HoneyComb"
# kubectl apply secret generic -n honeycomb honeycomb-writekey \
# --from-literal=key=00d9a58e4cdb0bbc1e926f7b687cc91f
kubectl apply -f $SCRIPT_DIR/../manifests/honeycomb-agent.yaml 
kubectl apply -f $SCRIPT_DIR/../manifests/honeycomb-tracing.yaml 

deployments=$(kubectl get --namespace=honeycomb deployments --output=name)
for deployment in $deployments ; do
    kubectl rollout status --namespace=honeycomb "$deployment"
done