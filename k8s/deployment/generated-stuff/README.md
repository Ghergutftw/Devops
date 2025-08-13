# Multi-Service Kubernetes Application

This repository contains a complete Kubernetes deployment for a multi-tier application architecture with the following components:

## Architecture Overview

```
┌─────────────────┐
│   Load Balancer │
└─────────┬───────┘
          │
┌─────────▼───────┐
│     Ingress     │
└─────────┬───────┘
          │
┌─────────▼───────┐
│  Tomcat Service │
└─────┬─┬─┬───────┘
      │ │ │
   ┌──▼─▼─▼──┐
   │Microservices│
   │ RMQ│MC│DB │
   └──┬─┬─┬───┘
      │ │ │
   ┌──▼─▼─▼──┐
   │RabbitMQ │
   │Memcache │
   │Database │
   └─────────┘
```

## Components

### Infrastructure Services
- **Database**: MySQL 8.0 StatefulSet with persistent storage
- **RabbitMQ**: Message queue cluster with management interface
- **Memcache**: Distributed caching layer

### Application Services
- **Tomcat Service**: Main web application server
- **Microservices**: 
  - RMQ Service: RabbitMQ integration service
  - MC Service: Memcache integration service
  - DB Service: Database integration service

### Kubernetes Objects
- **StorageClasses**: Fast SSD and EFS storage
- **StatefulSets**: For database and RabbitMQ
- **Deployments**: For stateless services
- **Services**: ClusterIP and LoadBalancer
- **Ingress**: Path-based routing with SSL
- **HPA**: Horizontal Pod Autoscaling
- **NetworkPolicies**: Security policies
- **PodDisruptionBudgets**: High availability

## Prerequisites

1. Kubernetes cluster (1.20+)
2. kubectl configured
3. NGINX Ingress Controller
4. Metrics Server (for HPA)
5. EBS CSI Driver (for AWS)
6. EFS CSI Driver (for shared storage)

## Quick Start

### 1. Configure Storage

Edit `manifests/storage.yaml` and update the EFS filesystem ID:
```yaml
parameters:
  fileSystemId: fs-xxxxxxxxx  # Replace with your EFS ID
```

### 2. Update Image References

Edit the following files to use your container images:
- `manifests/microservices.yaml`
- Update `image: your-registry/service-name:latest`

### 3. Configure Domain

Edit `manifests/ingress.yaml`:
```yaml
spec:
  tls:
  - hosts:
    - your-app.example.com  # Replace with your domain
```

### 4. Deploy

```bash
# Make deploy script executable
chmod +x deploy.sh

# Deploy all components
./deploy.sh

# Or deploy manually
kubectl apply -f config/
kubectl apply -f manifests/
kubectl apply -f deployment.yaml
```

### 5. Verify Deployment

```bash
# Check all pods are running
kubectl get pods

# Check services
kubectl get svc

# Check ingress
kubectl get ingress

# Check HPA status
kubectl get hpa
```

## Configuration

### Environment Variables

The application uses ConfigMaps and Secrets for configuration:

**ConfigMap (app-config)**:
- `database.url`: JDBC connection string
- `rabbitmq.host`: RabbitMQ hostname
- `memcache.servers`: Memcache server list

**Secrets**:
- `mysql-secret`: Database credentials
- `rabbitmq-secret`: RabbitMQ credentials

### Resource Requirements

| Service | CPU Request | Memory Request | CPU Limit | Memory Limit |
|---------|-------------|----------------|-----------|--------------|
| Tomcat | 250m | 512Mi | 500m | 1Gi |
| Database | 500m | 1Gi | 1000m | 2Gi |
| RabbitMQ | 250m | 512Mi | 500m | 1Gi |
| Microservices | 200m | 256Mi | 500m | 512Mi |
| Memcache | 100m | 256Mi | 200m | 512Mi |

## Scaling

### Horizontal Pod Autoscaler

Services automatically scale based on CPU/Memory usage:
- **Tomcat**: 2-10 replicas (70% CPU threshold)
- **Microservices**: 2-5 replicas each (70% CPU threshold)

### Manual Scaling

```bash
# Scale tomcat service
kubectl scale deployment tomcat-service --replicas=5

# Scale microservice
kubectl scale deployment rmq-service --replicas=3
```

## Monitoring

### Health Checks

All services include:
- **Liveness Probes**: Restart unhealthy pods
- **Readiness Probes**: Control traffic routing

### Service URLs

When ingress is configured:
- Main Application: `https://your-app.example.com`
- RabbitMQ Management: `https://your-app.example.com/rabbitmq`

### Local Access

```bash
# Tomcat service
kubectl port-forward svc/tomcat-service 8080:80

# RabbitMQ management
kubectl port-forward svc/rabbitmq 15672:15672

# Database
kubectl port-forward svc/database 3306:3306
```

## Security

### Network Policies

- Database access restricted to db-service and tomcat-service
- RabbitMQ access restricted to rmq-service and tomcat-service  
- Memcache access restricted to mc-service and tomcat-service
- Default deny-all policy with DNS exceptions

### Secrets Management

- Database passwords stored in Kubernetes secrets
- RabbitMQ credentials in separate secret
- All secrets base64 encoded

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Check Services
```bash
kubectl get svc
kubectl get endpoints
```

### Check Storage
```bash
kubectl get pv,pvc
kubectl describe pvc <pvc-name>
```

### Check Network Policies
```bash
kubectl get networkpolicy
kubectl describe networkpolicy <policy-name>
```

## Cleanup

```bash
# Remove all resources
./deploy.sh cleanup

# Or manually
kubectl delete -f manifests/
kubectl delete -f config/
kubectl delete -f deployment.yaml
```

## Development

### Local Development

1. Use `kubectl port-forward` to access services
2. Override image tags for development versions
3. Use ConfigMap overrides for local configuration

### CI/CD Integration

The deployment can be integrated with CI/CD pipelines:

1. Build and push images
2. Update image tags in manifests
3. Run `./deploy.sh` or use kubectl apply
4. Verify deployment with health checks

## Support

For issues and questions:
1. Check pod logs: `kubectl logs <pod-name>`
2. Check events: `kubectl get events --sort-by=.metadata.creationTimestamp`
3. Verify resource quotas: `kubectl describe node`
4. Check network connectivity between services
