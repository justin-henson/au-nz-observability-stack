# Prometheus Configuration for Kubernetes

This directory contains Prometheus configuration files for monitoring an EKS cluster with comprehensive alerting rules and recording rules.

## Files

- **prometheus.yml**: Main Prometheus configuration with Kubernetes service discovery
- **alert-rules.yml**: Alert rules for infrastructure, Kubernetes, and application monitoring
- **recording-rules.yml**: Pre-computed metrics following the RED method (Rate, Errors, Duration)

## Deployment on EKS

### Prerequisites

- EKS cluster deployed (see [au-nz-k8s-baseline-eks](https://github.com/justin-henson/au-nz-k8s-baseline-eks))
- kubectl configured to access the cluster
- Helm 3 installed

### Install with Helm

The recommended way to deploy Prometheus on Kubernetes is using the kube-prometheus-stack Helm chart:

```bash
# Add the prometheus-community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.externalLabels.cluster=baseline-eks \
  --set prometheus.prometheusSpec.externalLabels.environment=production \
  --set prometheus.prometheusSpec.externalLabels.region=ap-southeast-2 \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.retentionSize=50GB \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=gp3
```

### Apply Custom Alert Rules

After deploying Prometheus, apply the custom alert and recording rules:

```bash
# Create ConfigMap from alert rules
kubectl create configmap prometheus-alert-rules \
  --from-file=alert-rules.yml \
  --namespace monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# Create ConfigMap from recording rules
kubectl create configmap prometheus-recording-rules \
  --from-file=recording-rules.yml \
  --namespace monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# Update Prometheus to use the custom rules
kubectl patch prometheus prometheus-kube-prometheus-prometheus \
  --namespace monitoring \
  --type merge \
  --patch '{"spec":{"ruleSelector":{"matchLabels":{"prometheus":"kube-prometheus"}}}}'
```

### Configure IRSA for Thanos/S3 (Optional)

For long-term storage using Thanos and S3:

```bash
# Create IAM policy for S3 access
aws iam create-policy \
  --policy-name PrometheusThanosPolicyapache \
  --policy-document file://thanos-s3-policy.json

# Create IRSA service account
eksctl create iamserviceaccount \
  --name prometheus-thanos \
  --namespace monitoring \
  --cluster baseline-eks \
  --attach-policy-arn arn:aws:iam::123456789012:policy/PrometheusThanosPolicy \
  --approve \
  --override-existing-serviceaccounts

# Configure Thanos sidecar in Helm values
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --reuse-values \
  --set prometheus.prometheusSpec.thanos.image=quay.io/thanos/thanos:v0.32.0 \
  --set prometheus.prometheusSpec.thanos.objectStorageConfig.key=thanos.yaml \
  --set prometheus.prometheusSpec.thanos.objectStorageConfig.name=thanos-objstore-config
```

Example `thanos.yaml` for S3:

```yaml
type: S3
config:
  bucket: prometheus-metrics-baseline-eks
  endpoint: s3.ap-southeast-2.amazonaws.com
  region: ap-southeast-2
```

## Alert Rules Overview

### Node Alerts

- **HighCPU**: CPU usage > 80% for 5 minutes (warning)
- **CriticalCPU**: CPU usage > 95% for 3 minutes (critical)
- **HighMemory**: Memory usage > 90% for 5 minutes (warning)
- **DiskFull**: Disk usage > 90% for 15 minutes (warning)
- **DiskCritical**: Disk usage > 95% for 5 minutes (critical)
- **TargetDown**: Scrape target unreachable for 5 minutes (critical)

### Kubernetes Alerts

- **PodCrashLooping**: Pod restarting repeatedly for 15 minutes (warning)
- **PodNotReady**: Pod not in Running/Succeeded state for 10 minutes (warning)
- **DeploymentReplicasMismatch**: Deployment replicas != available replicas for 10 minutes (warning)
- **NodeNotReady**: Node in NotReady state for 5 minutes (critical)
- **PersistentVolumeClaimPending**: PVC pending for 10 minutes (warning)

### Application Alerts

- **High5xxRate**: 5xx error rate > 5% for 5 minutes (critical)
- **HighLatency**: p99 latency > 2 seconds for 5 minutes (warning)
- **LowRequestRate**: Request rate < 1 req/s for 10 minutes (warning)

### Certificate Alerts

- **CertificateExpiringSoon**: Certificate expires within 30 days (warning)
- **CertificateExpiryCritical**: Certificate expires within 7 days (critical)

## Recording Rules

Recording rules pre-compute expensive queries to improve dashboard performance and reduce query load.

### RED Method Metrics

- `service:http_requests:rate5m`: Request rate by service and status code
- `service:http_request_errors:rate5m`: Error rate by service
- `service:http_request_error_rate:ratio`: Error ratio by service
- `service:http_request_duration:p50/p90/p99`: Latency percentiles by service

### Resource Utilization Metrics

- `instance:node_cpu_utilization:ratio`: CPU utilization per node
- `instance:node_memory_utilization:ratio`: Memory utilization per node
- `instance:node_disk_utilization:ratio`: Disk utilization per node
- `namespace:container_cpu_usage:sum`: CPU usage per namespace
- `pod:container_memory_usage:sum`: Memory usage per pod

## Integration with Alertmanager

Prometheus sends alerts to Alertmanager, which routes them based on severity and labels. See [`../alerting/alertmanager.yml`](../alerting/alertmanager.yml) for routing configuration.

## Accessing Prometheus

Port-forward to access Prometheus UI:

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Then open http://localhost:9090 in your browser.

## Validating Configuration

Before deploying, validate the configuration files:

```bash
# Validate Prometheus config (requires promtool)
promtool check config prometheus.yml

# Validate alert rules
promtool check rules alert-rules.yml

# Validate recording rules
promtool check rules recording-rules.yml
```

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Alert rule examples](https://awesome-prometheus-alerts.grep.to/)
