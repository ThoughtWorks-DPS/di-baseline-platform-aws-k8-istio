#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT=$1

LOAD_BALANCER_DNS_NAME=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

LOAD_BALANCER_HOST_NAME="dualstack.$LOAD_BALANCER_DNS_NAME"
LOAD_BALANCER_HOST_ZONE=$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[?DNSName==\`$LOAD_BALANCER_DNS_NAME\`].{CanonicalHostedZoneNameID:CanonicalHostedZoneNameID}[0]" --output text)

HOSTED_ZONE_NAME="$ENVIRONMENT.twdps.io"


HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name==\`$HOSTED_ZONE_NAME.\`].{Id:Id}[0]" --output=text)

HOSTED_ZONE_ID=${HOSTED_ZONE_ID#"/hostedzone/"}

# setup 3 api gateways ingress aliases and then ones for observability

prefixes="api bookinfo grafana prometheus kiali jaeger"

for prefix in $prefixes; do 
LOAD_BALANCER_ALIAS_NAME="$prefix.$HOSTED_ZONE_NAME"
echo "Creating A record alias $LOAD_BALANCER_ALIAS_NAME to load balancer $LOAD_BALANCER_HOST_NAME in hosted zone $HOSTED_ZONE_ID|"

cat <<EOF | aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file:///dev/stdin
{
  "Comment": "Creating A record alias $LOAD_BALANCER_ALIAS_NAME to load balancer $LOAD_BALANCER_HOST_NAME in hosted zone $HOSTED_ZONE_ID",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$LOAD_BALANCER_ALIAS_NAME",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "$LOAD_BALANCER_HOST_ZONE",
          "DNSName": "$LOAD_BALANCER_HOST_NAME",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

done 
