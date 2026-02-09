# Grafana Dashboards

This directory contains Grafana dashboard JSON files and provisioning configuration for automated dashboard deployment.

## Dashboards

### Infrastructure Overview
**File**: `dashboards/infrastructure-overview.json`

Comprehensive view of system-level metrics across all infrastructure:
- CPU utilization across all nodes
- Memory usage and available memory
- Network traffic (in/out)
- Disk usage and I/O metrics

Use this dashboard to identify capacity issues, resource bottlenecks, and infrastructure health trends.

### Application Health
**File**: `dashboards/application-health.json`

RED method (Rate, Errors, Duration) dashboard for application monitoring:
- **Rate**: Request throughput per service
- **Errors**: 5xx error rate and count
- **Duration**: p50, p90, p99 latency percentiles

Use this dashboard to monitor user-facing service health and detect performance degradation early.

### Kubernetes Cluster
**File**: `dashboards/kubernetes-cluster.json`

Cluster-level Kubernetes metrics:
- Pod count by status (Running, Pending, Failed)
- Resource requests vs limits vs actual usage
- HPA (Horizontal Pod Autoscaler) scaling events
- Node health and capacity

Use this dashboard to manage cluster capacity, troubleshoot pod scheduling issues, and monitor autoscaling behavior.

### Cost Overview
**File**: `dashboards/cost-overview.json`

AWS cost and usage tracking:
- Daily spend trends
- Cost by service (EC2, RDS, EKS, data transfer)
- Budget tracking and forecasts

Use this dashboard to understand cloud spend patterns and identify cost optimization opportunities.

## Deployment on EKS

### Install Grafana with Helm

```bash
# Add Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create values file for Grafana configuration
cat > grafana-values.yaml <<EOF
persistence:
  enabled: true
  storageClassName: gp3
  size: 10Gi

# Set a strong password via Kubernetes secret or Helm values override
adminPassword: ""

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090
        access: proxy
        isDefault: true

dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
      - name: default
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default

dashboardsConfigMaps:
  default: grafana-dashboards

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/GrafanaServiceAccountRole

rbac:
  create: true
EOF

# Install Grafana
helm install grafana grafana/grafana \
  --namespace monitoring \
  --values grafana-values.yaml
```

### Deploy Dashboards

```bash
# Create ConfigMap from dashboard JSON files
kubectl create configmap grafana-dashboards \
  --from-file=dashboards/ \
  --namespace monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart Grafana to load dashboards
kubectl rollout restart deployment grafana -n monitoring
```

### Configure IRSA for CloudWatch Access

To enable CloudWatch datasource, configure IAM Roles for Service Accounts (IRSA):

```bash
# Create IAM policy for CloudWatch read access
cat > cloudwatch-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:DescribeAlarmHistory",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:GetMetricData"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups",
        "logs:GetLogGroupFields",
        "logs:StartQuery",
        "logs:StopQuery",
        "logs:GetQueryResults",
        "logs:GetLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeTags",
        "ec2:DescribeInstances",
        "ec2:DescribeRegions"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["tag:GetResources"],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name GrafanaCloudWatchPolicy \
  --policy-document file://cloudwatch-policy.json

# Create IRSA service account
eksctl create iamserviceaccount \
  --name grafana \
  --namespace monitoring \
  --cluster baseline-eks \
  --attach-policy-arn arn:aws:iam::123456789012:policy/GrafanaCloudWatchPolicy \
  --approve \
  --override-existing-serviceaccounts
```

### Access Grafana UI

Get the admin password:

```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Port-forward to access Grafana:

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
```

Then open http://localhost:3000 and log in with username `admin` and the password from above.

## Dashboard Configuration

### Variables

All dashboards use template variables for dynamic filtering:

- **cluster**: Select Kubernetes cluster
- **namespace**: Filter by namespace
- **service**: Filter by service name
- **node**: Filter by node name

### Time Range

Default time range is last 6 hours, but can be adjusted via the time picker in the top right.

### Refresh Rate

Dashboards auto-refresh every 30 seconds. Adjust this in the dashboard settings if needed.

## Customization

To customize dashboards:

1. Make changes in the Grafana UI
2. Export the dashboard JSON (Share → Export → Save to file)
3. Replace the corresponding file in `dashboards/`
4. Update the ConfigMap: `kubectl create configmap grafana-dashboards --from-file=dashboards/ -n monitoring --dry-run=client -o yaml | kubectl apply -f -`
5. Restart Grafana to reload: `kubectl rollout restart deployment grafana -n monitoring`

## Alerting Integration

Grafana can be configured to send alerts based on dashboard panel queries. However, we recommend using Prometheus Alertmanager for production alerting (see [`../alerting/`](../alerting/)) and using Grafana for visualization and ad-hoc analysis.

## References

- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [Grafana Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana)

## Dashboard Preview

These dashboards are JSON definitions in Grafana's export format. To preview them:

**Option 1 — Import into any Grafana instance:**
1. Open Grafana → Dashboards → Import
2. Upload the JSON file or paste its contents
3. Select your Prometheus datasource when prompted

**Option 2 — Use Grafana's provisioning (automated):**
The `provisioning/` directory auto-loads all dashboards on startup. Deploy Grafana with
the provisioning config mounted and dashboards appear immediately.

**What you'll see when deployed:**

| Dashboard | Panels | Key Metrics |
|-----------|--------|-------------|
| Infrastructure Overview | 8 panels across 4 rows | CPU, memory, network, disk per node |
| Application Health | 6 panels in 3 rows (RED method) | Request rate, error rate, p50/p90/p99 latency |
| Kubernetes Cluster | 8 panels | Pod status, resource requests vs limits, HPA events |
| Cost Overview | 4 panels | Daily spend, service breakdown, cost trends, budget alerts |
| SLO Burn Rate | 4 panels | Availability SLI, error budget remaining, multi-window burn rate |

Every panel includes a description field explaining what to look for and when to investigate.
