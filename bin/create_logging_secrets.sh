#!/usr/bin/env bash

set -euo pipefail

echo "Create honeycomb secret"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: honeycomb-writekey
  namespace: kube-system
  labels:
    app: honeycomb
type: generic
data:
  key: $HONEYCOMB_WRITE_KEY
EOF

LOGZIO_TOKEN_B64=$(echo -n "$LOGZIO_TOKEN" | base64 | tr -d \\n)

echo "Create logzio secret"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: logzio-token
  namespace: kube-system
  labels:
    app: logzio
type: generic
data:
  key: $LOGZIO_TOKEN_B64
EOF
