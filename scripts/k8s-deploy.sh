#!/bin/bash
set -e # Exit immediately if a command fails

# 1. Create Cluster
kind create cluster --name muchtodo --config kind-config.yaml || true

# 2. Load Image into Kind
echo "Loading image into Kind..."
kind load docker-image muchtodo-backend:latest --name muchtodo

# 3. Apply Namespace and DB
echo "Applying Manifests..."
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/

# 4. CRITICAL: Wait for MongoDB to be ready
echo "Waiting for MongoDB to initialize..."
kubectl wait --for=condition=ready pod -l app=mongodb -n muchtodo-ns --timeout=90s

# 5. Apply Backend and Ingress
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml

echo "Deployment Done! Check status with: kubectl get pods -n muchtodo-ns"
