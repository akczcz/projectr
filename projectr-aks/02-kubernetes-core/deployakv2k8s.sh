#!/bin/bash
# Get AKS cluster credentials
az aks get-credentials --admin -n $1 -g $2

# Add the spvapi Helm repository
helm repo add spv-charts https://charts.spvapi.no

# Update your local Helm chart repository cache
helm repo update

# Upgrade Helm chart, install if not exist
helm upgrade -i \
    akv2k8s \
    spv-charts/akv2k8s \
    --namespace akv2k8s