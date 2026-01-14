MuchToDo - Kubernetes Deployment
A full-stack Todo application with a Go (Golang) backend and a MongoDB database, containerized and orchestrated via Kubernetes.
The goal of this project was to move the application from a "bare-metal" server execution model to a scalable, containerized architecture using Docker for development and Kubernetes (Kind) for local production-like orchestration.

Architecture Overview
The application follows a standard 3-tier microservices architecture:

Database Layer: MongoDB instance for persistent storage.

Backend Layer: Go-based REST API handling CRUD operations and user management.

Networking Layer: Kubernetes Services (ClusterIP & NodePort) and Ingress for traffic routing.


Deployment Components
1. Database (MongoDB)
Service: A ClusterIP service named mongodb ensures the database is only reachable within the cluster.

Storage: Configuration is handled via mongodb-config (ConfigMap) and mongodb-secret (Secret).

Deployment: Runs a single pod using the official MongoDB image.

2. Backend (Go API)
Image: muchtodo-backend:latest

Service: A NodePort service mapping port 3000 to the host port 30080.

Configuration: Utilizes a unique Secret-to-Volume mount strategy to provide a .env file directly to the Go application.

container-assessment/
├── Dockerfile              # Multi-stage Golang build
├── docker-compose.yml      # Local dev environment
├── .dockerignore           # Build optimization
├── kubernetes/
│   ├── namespace.yaml      # Resource isolation
│   ├── mongodb/            # DB Deployment, Service, PVC, Secret
│   ├── backend/            # App Deployment, Service, ConfigMap
│   └── ingress.yaml        # External traffic routing
├── scripts/                # Automation scripts
└── evidence/               # Deployment screenshots

Getting Started
Prerequisites
Ensure you have the following installed:

Docker 

Kind

Kubectl

Phase 1: Local Development (Docker)
The Docker setup uses a multi-stage build to ensure the final production image is small (based on Alpine) and secure (running as a non-root user).

Build the Image:
chmod +x scripts/*.sh  # very essential
./scripts/docker-build.sh

2: Run with Docker Compose:
./scripts/docker-run.sh

3: Verify: Open http://localhost:3000/health in your browser.

Phase 2: Kubernetes Deployment (Kind)

he Kubernetes setup utilizes Ingress to route traffic and Persistent Volume Claims (PVC) to ensure database data is not lost if a pod restarts.

Deploy the Cluster: This script creates a Kind cluster, installs the NGINX Ingress Controller, loads your local image, and applies all manifests.

./scripts/k8s-deploy.sh

Verify Deployment: Check that all pods are running in the correct namespace:
kubectl create namespace muchtodo-ns
kubectl get pods -n muchtodo-ns

Create Secrets & ConfigMaps:
# Create the .env file secret for the backend
kubectl create secret generic backend-secrets -n muchtodo-ns \
  --from-literal=.env="MONGO_URI=mongodb://admin:password@mongodb:27017/muchtodo?authSource=admin
DB_NAME=muchtodo
PORT=3000
JWT_SECRET_KEY=your_random_secret_string"

Apply Manifests

kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/

Check Pod Status

kubectl get pods -n muchtodo-ns
Ensure both pods show 1/1 READY and STATUS Running.


Test the API
Since the backend is exposed via a NodePort, you can test the health check:

curl http://localhost:30080/health

Expected Response:
{"cache":"disabled","database":"ok"}
Access the App: Because we are using an Ingress Controller, the app is available on the standard HTTP port: http://localhost/health example http://http://192.168.111.135:3000/health

Cleanup:
./scripts/k8s-cleanup.sh

To stop Docker Compose:
docker-compose down -v

Maintenance
Updating Secrets: After updating the backend-secrets, you must restart the pod to refresh the .env file: kubectl rollout restart deployment backend -n muchtodo-ns

Logs: To view live application logs for debugging: kubectl logs -l app=backend -n muchtodo-ns -f


