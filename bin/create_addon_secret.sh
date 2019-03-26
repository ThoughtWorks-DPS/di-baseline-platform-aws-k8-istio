#!/usr/bin/env bash

set -euo pipefail

KIALI_USERNAME_B64=$(echo -n "$KIALI_USERNAME" | base64 | tr -d \\n)
KIALI_PASSPHRASE_B64=$(echo -n "$KIALI_PASSPHRASE" | base64 | tr -d \\n)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: istio-system
  labels:
    app: kiali
type: Opaque
data:
  username: $KIALI_USERNAME_B64
  passphrase: $KIALI_PASSPHRASE_B64
EOF

GRAFANA_USERNAME_B64=$(echo -n "$GRAFANA_USERNAME" | base64 | tr -d \\n)
GRAFANA_PASSPHRASE_B64=$(echo -n "$GRAFANA_PASSPHRASE" | base64 | tr -d \\n)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: grafana
  namespace: istio-system
  labels:
    app: grafana
type: Opaque
data:
  username: $GRAFANA_USERNAME_B64
  passphrase: $GRAFANA_PASSPHRASE_B64
EOF