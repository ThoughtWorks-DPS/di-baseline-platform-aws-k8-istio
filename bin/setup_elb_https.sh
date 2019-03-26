#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT=$1
DNS_ROOT="$ENVIRONMENT".twdps.io
CERT_DOMAIN="*".$DNS_ROOT

CERTIFICATE_ARN=$(aws acm list-certificates | jq '.CertificateSummaryList[] | select( .DomainName=='\"${CERT_DOMAIN}\"') | .CertificateArn' -r)
if [[ -z $CERTIFICATE_ARN ]]; then
    echo "No certificate found for $CERT_DOMAIN"
    exit 1;
fi

LOAD_BALANCER_DNS_NAME=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [[ -z LOAD_BALANCER_DNS_NAME ]]; then
    echo "No Load Balancer found for Istio Mesh"
    exit 1;
fi

LOAD_BALANCER_NAME=$(aws elb describe-load-balancers | jq  '.LoadBalancerDescriptions[] | select( .DNSName=='\"${LOAD_BALANCER_DNS_NAME}\"') | .LoadBalancerName' -r)

echo "Remove the 443 port"
aws elb delete-load-balancer-listeners --load-balancer-name $LOAD_BALANCER_NAME --load-balancer-ports 443

if [ $? -eq 1 ]; then
    echo "Unable to remove listener"
    exit 1;
fi 

echo "Add 443 Port"
ADD_LB=$(aws elb  create-load-balancer-listeners --load-balancer-name $LOAD_BALANCER_NAME --listeners "Protocol=HTTPS,LoadBalancerPort=443,InstanceProtocol=HTTP,InstancePort=31390,SSLCertificateId=$CERTIFICATE_ARN")
if [ $? -eq 1 ]; then
    echo "Unable to add listener"
    exit 1;
fi

