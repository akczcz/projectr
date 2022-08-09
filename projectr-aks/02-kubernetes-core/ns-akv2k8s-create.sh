#!/bin/bash
az aks get-credentials --admin -n $1 -g $2
cd _projectr.Infrastructure.CI/infrastructure/projectr-aks/02-kubernetes-core/
kubectl apply -f ns-akv2k8s.yaml