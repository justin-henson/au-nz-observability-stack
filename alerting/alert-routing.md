# Alert Routing

This document describes how alerts flow from metrics collection through notification delivery, and how routing decisions are made based on alert properties.

## Alert Flow Architecture

```
┌─────────────────┐
│  Prometheus     │
│  Alert Rules    │
│  (every 15s)    │
└────────┬────────┘
         │
         │ Fires when expr evaluates true for 'for' duration
         │
         ▼
┌─────────────────┐
│  Alertmanager   │
│  - Groups       │
│  - Routes       │
│  - Inhibits     │
└────────┬────────┘
         │
         ├─────────────────────┬─────────────────────┬──────────────────┐
         │                     │                     │                  │
         ▼                     ▼                     ▼                  ▼
    ┌─────────┐          ┌─────────┐          ┌─────────┐       ┌─────────┐
    │PagerDuty│          │  Slack  │          │  Email  │       │ Webhook │
    │ (P1/P2) │          │ (P2/P3) │          │  (P4)   │       │ (Custom)│
    └─────────┘          └─────────┘          └─────────┘       └─────────┘
```

## CloudWatch Alert Flow

```
┌─────────────────┐
│  CloudWatch     │
│  Alarms         │
│  (every 1min)   │
└────────┬────────┘
         │
         │ Enters ALARM state when threshold breached
         │
         ▼
┌─────────────────┐
│  SNS Topics     │
│  - Critical     │
│  - Warning      │
│  - Info         │
└────────┬────────┘
         │
         ├─────────────────────┬─────────────────────┬──────────────────┐
         │                     │                     │                  │
         ▼                     ▼                     ▼                  ▼
    ┌─────────┐          ┌─────────┐          ┌─────────┐       ┌─────────┐
    │PagerDuty│          │  Slack  │          │  Email  │       │ Lambda  │
    │(Critical)│         │(Warning)│          │ (Info)  │       │Function │
    └─────────┘          └─────────┘          └─────────┘       └─────────┘
```

## Routing Rules

### By Severity (Prometheus)

Defined in [`alertmanager.yml`](alertmanager.yml):

| Severity Label | Route | Receiver | Group Wait | Group Interval | Repeat Interval |
|---------------|-------|----------|------------|----------------|-----------------|
| `critical` | pagerduty | pagerduty-critical | 10s | 1m | 4h |
| `warning` | slack | slack-alerts | 30s | 5m | 12h |
| `info` | email | email-digest | 5m | 1h | 24h |

### By Namespace (Kubernetes)

Production workloads in `production` namespace route to critical path. Staging workloads route to Slack only:

```yaml
routes:
  - match:
      namespace: production
    receiver: pagerduty-critical
  - match:
      namespace: staging
    receiver: slack-alerts
```

### By Component

Database alerts route to database team, application alerts to application team:

```yaml
routes:
  - match:
      component: database
    receiver: database-team
  - match:
      component: application
    receiver: application-team
```

## Grouping Strategy

Alerts are grouped by:
1. **alertname**: Groups all instances of the same alert type together
2. **namespace**: Keeps Kubernetes namespace issues isolated
3. **service**: Groups service-specific alerts

**Why**: Prevents alert storm during widespread outages. If 10 pods crash simultaneously, receive 1 notification instead of 10.

**Group Wait**: 10s for critical (get first alert fast), 30s for warnings (allow time for grouping)

**Group Interval**: 1m for critical (frequent updates), 5m for warnings (reduce noise)

## Inhibition Rules

Inhibition prevents low-priority alerts from firing when high-priority alerts are already active.

### Example: Node Down Inhibits Pod Alerts

If a node is down, don't alert on all pods running on that node:

```yaml
inhibit_rules:
  - source_match:
      alertname: NodeNotReady
    target_match:
      alertname: PodNotReady
    equal:
      - node
```

### Example: Service Degradation Inhibits Individual Metrics

If composite alarm "ServiceDegradation" is firing, inhibit individual CPU/latency alerts:

```yaml
inhibit_rules:
  - source_match:
      alertname: ServiceDegradation
    target_match_re:
      alertname: (HighCPU|HighLatency|High5xxRate)
    equal:
      - service
```

## Receiver Configuration

### PagerDuty

**Use**: Critical alerts requiring immediate human response

**Integration**: HTTPS endpoint with PagerDuty integration key

**Escalation**: Managed in PagerDuty (primary → secondary → manager)

**Rate Limiting**: None (all critical alerts must reach on-call)

### Slack

**Use**: Warning alerts requiring attention within hours

**Integration**: Incoming webhook to #alerts channel

**Message Format**: Includes alert summary, severity, runbook link, and dashboard link

**Rate Limiting**: Group identical alerts, max 1 notification per 5 minutes

### Email

**Use**: Informational alerts, daily digest

**Integration**: SMTP to team distribution list

**Message Format**: HTML email with alert table, grouped by severity

**Rate Limiting**: Daily digest at 9am AEDT, or immediate for critical if PagerDuty fails

## Time-Based Routing

### Business Hours vs After Hours

Route low-priority alerts to email only outside business hours:

```yaml
routes:
  - match:
      severity: warning
    receiver: slack-alerts
    continue: true
    active_time_intervals:
      - business_hours
  - match:
      severity: warning
    receiver: email-digest
```

**business_hours** defined as Monday-Friday 9am-5pm AEDT/NZDT in Alertmanager config.

## Alert Enrichment

Alerts are enriched with metadata before routing:

| Field | Source | Purpose |
|-------|--------|---------|
| `runbook_url` | Alert annotation | Link to troubleshooting steps |
| `dashboard_url` | Alert annotation | Link to relevant Grafana dashboard |
| `environment` | Alert label | Production vs staging routing |
| `service` | Alert label | Service ownership and routing |
| `priority` | Derived from severity | PagerDuty incident priority |

## Notification Templates

### PagerDuty Notification

```
[P1] ServiceDegradation: baseline-web-api

Service baseline-web-api is degraded: 5xx error rate 12% AND p99 latency 3.2s

Environment: production
Namespace: production
Started: 2026-02-08 14:23:45 AEDT

Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/5XX-SPIKE.md
Dashboard: https://grafana.company.internal/d/application-health
```

### Slack Notification

```
🔴 CRITICAL: High5xxRate

Service: baseline-web-api
5xx error rate: 8.5% (threshold: 5%)
Duration: 6m 12s

📊 Dashboard: https://grafana.company.internal/d/application-health
📖 Runbook: https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/5XX-SPIKE.md
```

### Email Digest

```
Subject: [ALERTS] Daily Summary - 3 warnings, 1 info

Warning Alerts (3):
- HighCPU on i-0a1b2c3d4e5f (16:45 AEDT)
- CertificateExpiringSoon for api.company.internal (20:12 AEDT)
- HighMemory on production-worker-3 (22:30 AEDT)

Info Alerts (1):
- MonitoringTargetDown for staging-prometheus (11:20 AEDT)

Review: https://grafana.company.internal/alerting/list
```

## Testing Alert Routing

### Manual Test

Force an alert to fire using PromQL:

```bash
# Add temporary alert rule
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-test-rules
  namespace: monitoring
data:
  test-rules.yml: |
    groups:
      - name: test
        interval: 15s
        rules:
          - alert: TestAlert
            expr: vector(1)
            for: 1m
            labels:
              severity: warning
            annotations:
              summary: "Test alert - ignore"
EOF

# Reload Prometheus configuration
kubectl exec -n monitoring prometheus-kube-prometheus-prometheus-0 -- kill -HUP 1

# Wait 2 minutes, verify alert appears in Slack

# Remove test rule
kubectl delete configmap prometheus-test-rules -n monitoring
```

### Verify Receiver Connectivity

Check Alertmanager status:

```bash
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093

# Open http://localhost:9093/#/status
# Verify all receivers show "Healthy"
```

## Troubleshooting

### Alert Not Routing

1. Check alert is firing in Prometheus: http://localhost:9090/alerts
2. Check Alertmanager received it: http://localhost:9093/#/alerts
3. Check routing configuration: http://localhost:9093/#/status
4. Check receiver logs: `kubectl logs -n monitoring alertmanager-kube-prometheus-alertmanager-0`

### Too Many Notifications

1. Review grouping configuration (increase `group_wait` and `group_interval`)
2. Check for missing inhibition rules
3. Review alert thresholds (may need adjustment)
4. Consider adding `active_time_intervals` for non-critical alerts

### Delayed Notifications

1. Check `group_wait` setting (may be too long)
2. Verify Alertmanager is not overwhelmed (check CPU/memory)
3. Check receiver endpoint latency (PagerDuty, Slack webhook response times)
4. Review network connectivity between Alertmanager and receivers

---

## Related Documentation

- [Escalation Policy](escalation-policy.md) - Severity definitions and response times
- [Alertmanager Configuration](alertmanager.yml) - Complete routing config
- [Silence Runbook](silence-runbook.md) - When and how to silence alerts
- [Runbooks](../runbooks/) - Alert-specific troubleshooting guides
