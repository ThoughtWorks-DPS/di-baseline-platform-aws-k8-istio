#!/usr/bin/env bash

set -euo pipefail

mkdir -p ~/.aws
cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id=$1
aws_secret_access_key=$2
region=$3
EOF
