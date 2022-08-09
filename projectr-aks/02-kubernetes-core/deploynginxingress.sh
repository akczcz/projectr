#!/bin/bash
# Get AKS cluster credentials
az aks get-credentials --admin -n $1 -g $2

# Add the Kubernetes Ingress repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update your local Helm chart repository cache
helm repo update

# Upgrade Helm chart, install if not exist
helm upgrade -i \
    nginx-ingress \
    ingress-nginx/ingress-nginx \
    --namespace ingress \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.service.loadBalancerIP="$3" \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"="$4" \
    --set controller.service.externalTrafficPolicy=Local