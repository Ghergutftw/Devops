#!/bin/bash

# Deployment script for multi-service application
set -e

echo "Starting deployment of multi-service application..."

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
}

# Function to apply manifests in order
deploy_manifest() {
    local manifest_file=$1
    echo "Deploying $manifest_file..."
    kubectl apply -f "$manifest_file"
    echo "✓ $manifest_file deployed successfully"
}

# Function to wait for deployments
wait_for_deployment() {
    local deployment_name=$1
    echo "Waiting for deployment $deployment_name to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment_name
    echo "✓ Deployment $deployment_name is ready"
}

# Function to wait for statefulsets
wait_for_statefulset() {
    local statefulset_name=$1
    echo "Waiting for statefulset $statefulset_name to be ready..."
    kubectl wait --for=condition=ready --timeout=300s pod -l app=$statefulset_name
    echo "✓ StatefulSet $statefulset_name is ready"
}

# Main deployment function
main() {
    check_kubectl
    
    echo "Current context: $(kubectl config current-context)"
    read -p "Continue with deployment? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    # Deploy in order
    deploy_manifest "manifests/storage.yaml"
    deploy_manifest "config/secrets-configmaps.yaml"
    
    # Deploy stateful services first
    deploy_manifest "manifests/database.yaml"
    deploy_manifest "manifests/rabbitmq.yaml"
    
    # Wait for stateful services
    wait_for_statefulset "database"
    wait_for_statefulset "rabbitmq"
    
    # Deploy stateless services
    deploy_manifest "manifests/memcache.yaml"
    deploy_manifest "manifests/microservices.yaml"
    
    # Wait for microservices
    wait_for_deployment "memcache"
    wait_for_deployment "rmq-service"
    wait_for_deployment "mc-service"
    wait_for_deployment "db-service"
    
    # Deploy main application
    kubectl apply -f deployment.yaml
    wait_for_deployment "tomcat-service"
    
    # Deploy networking and policies
    deploy_manifest "manifests/ingress.yaml"
    deploy_manifest "manifests/hpa.yaml"
    deploy_manifest "manifests/network-policies.yaml"
    deploy_manifest "manifests/pdb.yaml"
    
    echo "🎉 All services deployed successfully!"
    echo ""
    echo "Service URLs (when ingress is configured):"
    echo "  - Main Application: https://your-app.example.com"
    echo "  - RabbitMQ Management: https://your-app.example.com/rabbitmq"
    echo ""
    echo "To check service status:"
    echo "  kubectl get pods,svc,pvc"
    echo ""
    echo "To access services locally:"
    echo "  kubectl port-forward svc/tomcat-service 8080:80"
    echo "  kubectl port-forward svc/rabbitmq 15672:15672"
}

# Cleanup function
cleanup() {
    echo "Cleaning up resources..."
    kubectl delete -f manifests/ --ignore-not-found=true
    kubectl delete -f config/ --ignore-not-found=true
    kubectl delete -f deployment.yaml --ignore-not-found=true
    echo "✓ Cleanup completed"
}

# Check command line arguments
if [ "$1" == "cleanup" ]; then
    cleanup
    exit 0
elif [ "$1" == "help" ]; then
    echo "Usage: $0 [cleanup|help]"
    echo "  cleanup: Remove all deployed resources"
    echo "  help: Show this help message"
    echo "  (no args): Deploy the application"
    exit 0
fi

main
