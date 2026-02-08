# Cost Estimate

Monthly cost estimate for the observability stack at different scales.

## Small Scale (Startup / Development)

**Infrastructure**: 10 EC2 instances, 2 RDS, 1 ALB, 5-node EKS cluster

### CloudWatch

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| Metrics (Standard) | 500 metrics | First 10k free | $0 |
| Detailed Monitoring | 10 instances × 7 metrics | $0.14/instance/month | $1.40 |
| Custom Metrics | 100 metrics | $0.30/metric | $30.00 |
| Alarms | 30 alarms | First 10 free, then $0.10 | $2.00 |
| Logs Ingestion | 50 GB | $0.50/GB | $25.00 |
| Logs Storage | 50 GB | $0.03/GB | $1.50 |
| Dashboard | 3 dashboards | $3/dashboard/month | $9.00 |
| **CloudWatch Total** | | | **$68.90** |

### Prometheus + Thanos

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| EBS (Prometheus) | 100 GB gp3 | $0.08/GB | $8.00 |
| S3 (Thanos storage) | 200 GB | $0.023/GB | $4.60 |
| S3 Requests | 1M PUT, 5M GET | Various | $0.50 |
| Data Transfer | 10 GB out | $0.09/GB | $0.90 |
| **Prometheus/Thanos Total** | | | **$14.00** |

### Grafana

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| EBS (Storage) | 10 GB | $0.08/GB | $0.80 |
| **Grafana Total** | | | **$0.80** |

### SNS + PagerDuty

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| SNS Notifications | 1000/month | First 1000 free | $0.00 |
| PagerDuty | 5 users | $21/user | $105.00 |
| **Notification Total** | | | **$105.00** |

**Small Scale Total: $188.70/month**

---

## Medium Scale (Growth Stage)

**Infrastructure**: 50 EC2 instances, 5 RDS, 3 ALB, 20-node EKS cluster

### CloudWatch

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| Metrics (Standard) | 2000 metrics | $0.30 per metric after 10k | $0.00 |
| Detailed Monitoring | 50 instances × 7 metrics | $0.14/instance | $7.00 |
| Custom Metrics | 500 metrics | $0.30/metric | $150.00 |
| Alarms | 100 alarms | $0.10 each after 10 | $9.00 |
| Logs Ingestion | 300 GB | $0.50/GB | $150.00 |
| Logs Storage | 500 GB | $0.03/GB | $15.00 |
| Dashboard | 10 dashboards | $3/dashboard | $30.00 |
| **CloudWatch Total** | | | **$361.00** |

### Prometheus + Thanos

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| EBS (Prometheus) | 500 GB gp3 | $0.08/GB | $40.00 |
| S3 (Thanos storage) | 2 TB | $0.023/GB | $47.00 |
| S3 Requests | 10M PUT, 50M GET | Various | $5.00 |
| Data Transfer | 100 GB out | $0.09/GB | $9.00 |
| **Prometheus/Thanos Total** | | | **$101.00** |

### Grafana

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| EBS (Storage) | 50 GB | $0.08/GB | $4.00 |
| **Grafana Total** | | | **$4.00** |

### SNS + PagerDuty

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| SNS Notifications | 10000/month | $0.50/1000 after free tier | $4.50 |
| PagerDuty | 15 users | $21/user | $315.00 |
| **Notification Total** | | | **$319.50** |

**Medium Scale Total: $785.50/month**

---

## Large Scale (Enterprise)

**Infrastructure**: 200 EC2 instances, 20 RDS, 10 ALB, 100-node EKS cluster

### CloudWatch

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| Metrics (Standard) | 10000 metrics | $0.30 per metric after 10k | $0.00 |
| Detailed Monitoring | 200 instances × 7 metrics | $0.14/instance | $28.00 |
| Custom Metrics | 5000 metrics | $0.30/metric | $1,500.00 |
| Alarms | 500 alarms | $0.10 each after 10 | $49.00 |
| Logs Ingestion | 2 TB | $0.50/GB | $1,024.00 |
| Logs Storage | 5 TB | $0.03/GB | $153.60 |
| Dashboard | 50 dashboards | $3/dashboard | $150.00 |
| **CloudWatch Total** | | | **$2,904.60** |

### Prometheus + Thanos

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| EBS (Prometheus) | 2 TB gp3 | $0.08/GB | $163.84 |
| S3 (Thanos storage) | 20 TB | $0.023/GB | $471.04 |
| S3 Requests | 100M PUT, 500M GET | Various | $50.00 |
| Data Transfer | 1 TB out | $0.09/GB (first 10 TB) | $92.16 |
| **Prometheus/Thanos Total** | | | **$777.04** |

### Grafana

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| EBS (Storage) | 200 GB | $0.08/GB | $16.00 |
| **Grafana Total** | | | **$16.00** |

### SNS + PagerDuty

| Item | Volume | Unit Cost | Monthly Cost |
|------|--------|-----------|--------------|
| SNS Notifications | 100000/month | $0.50/1000 | $49.50 |
| PagerDuty | 50 users | $21/user (volume discount) | $1,050.00 |
| **Notification Total** | | | **$1,099.50** |

**Large Scale Total: $4,797.14/month**

---

## Cost Comparison vs Commercial SaaS

### Datadog (Medium Scale Equivalent)

- 50 hosts × $15/host = $750/month
- 500 custom metrics × $0.05 = $25/month
- 300 GB logs × $0.10/GB = $30/month (first 150 GB free with infra)
- APM (5 hosts) × $31/host = $155/month
- **Datadog Total: ~$960/month** (before volume discounts)

### New Relic (Medium Scale Equivalent)

- Standard tier with 100 GB ingest: $549/month base
- Additional data: 200 GB × $0.30/GB = $60/month
- **New Relic Total: ~$609/month**

### Self-Hosted Comparison

| Scale | Self-Hosted | Datadog Estimate | Savings |
|-------|-------------|------------------|---------|
| Small | $189/mo | $300/mo | 37% |
| Medium | $786/mo | $960/mo | 18% |
| Large | $4,797/mo | $8,000+/mo | 40% |

**Note**: Commercial SaaS includes support, managed infrastructure, and premium features (APM, real user monitoring, incident management). Self-hosted requires engineering time.

---

## Cost Optimization Strategies

### CloudWatch

1. **Use metric filters instead of custom metrics**: Extract metrics from logs ($0.50/GB log ingestion vs $0.30/metric/month)
2. **Aggregate before sending**: Send 1 metric with dimensions instead of N metrics
3. **Use standard resolution**: 5-minute intervals free, 1-minute is $0.30/metric
4. **Set appropriate log retention**: 7 days for debug logs, 30 days for application logs, 90 days for audit
5. **Use CloudWatch Logs Insights**: Query logs instead of exporting to S3/Elasticsearch

### Prometheus

1. **Use recording rules**: Pre-compute expensive queries, reduce query load
2. **Set appropriate scrape intervals**: 30s instead of 15s for low-change metrics
3. **Limit metric cardinality**: Drop high-cardinality labels, use relabeling
4. **Configure Thanos downsampling**: 5m→1h→1d for old data reduces S3 storage 90%
5. **Use S3 Intelligent-Tiering**: Automatically move old blocks to cheaper storage

### Grafana

1. **Cache dashboard queries**: 1-minute refresh sufficient for most views
2. **Limit CloudWatch API calls**: Use longer query intervals (5m instead of 1m)
3. **Prefer Prometheus for high-cardinality**: CloudWatch charges per unique metric series

---

## Monitoring the Monitoring Costs

### CloudWatch Cost Alerts

```bash
# Create billing alarm
aws cloudwatch put-metric-alarm \
  --alarm-name cloudwatch-cost-high \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 500 \
  --comparison-operator GreaterThanThreshold
```

### Cost Visibility Dashboard

Track these metrics monthly:
- CloudWatch Metrics count and cost
- CloudWatch Logs GB ingested and cost
- S3 storage size and cost
- Cost per GB log ingested
- Cost per service monitored

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-08 | SRE Team | Initial cost estimate |
