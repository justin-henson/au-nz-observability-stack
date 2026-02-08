# Alert Silence Runbook

This document provides guidelines for when and how to silence alerts, ensuring silences are used appropriately and with proper audit trails.

## When to Silence Alerts

### Acceptable Use Cases

#### 1. Planned Maintenance
Silence alerts for resources undergoing scheduled maintenance.

**Example**: Database migration during maintenance window
```
Duration: Match maintenance window exactly
Reason: "Planned database migration - Ticket: OPS-1234"
Matchers: instance=~"db-prod-.*"
```

#### 2. Known Issues with Scheduled Fix
Silence recurring alerts for issues with approved remediation plans.

**Example**: Disk space issue with storage expansion scheduled
```
Duration: Until fix deployment time
Reason: "Known issue - storage expansion scheduled for 2026-02-10 03:00 AEDT - Ticket: OPS-5678"
Matchers: alertname="DiskFull", instance="worker-node-3"
```

#### 3. False Positives Under Investigation
Temporarily silence alerts while investigating and fixing false positive triggers.

**Example**: Alert firing incorrectly due to metric collection gap
```
Duration: 24 hours (review and extend if needed)
Reason: "False positive investigation - metrics collection issue - Ticket: MON-9012"
Matchers: alertname="TargetDown", job="staging-exporter"
```

#### 4. Testing and Development
Silence non-production alerts during testing activities.

**Example**: Load testing in staging environment
```
Duration: Duration of load test
Reason: "Load testing in staging - ignoring expected high resource usage - Test: PERF-3456"
Matchers: namespace="staging", severity=~"warning|info"
```

### Unacceptable Use Cases

❌ **Silencing production critical alerts to "reduce noise"**
- Fix the root cause or adjust alert thresholds instead

❌ **Long-duration silences without expiry**
- Maximum silence duration: 7 days (review weekly)

❌ **Silencing alerts because "we know about it"**
- Use incident tracking and postmortems, don't hide alerts

❌ **Silencing to hit SLO targets**
- SLOs should reflect actual service performance

## How to Create a Silence

### Via Alertmanager UI

1. Navigate to Alertmanager UI: `http://localhost:9093` (port-forward if needed)
2. Click "New Silence" button
3. Fill in matchers:
   - **Label**: Select label to match (e.g., `alertname`, `instance`, `namespace`)
   - **Operator**: `=` for exact match, `=~` for regex
   - **Value**: Value to match (e.g., `HighCPU`, `prod-.*`)
4. Set duration:
   - **Start**: Now (default) or future time for scheduled maintenance
   - **End**: Specific end time (recommended) or duration from now
5. **Creator**: Automatically filled with your username
6. **Comment**: **REQUIRED** - explain why, include ticket number
7. Click "Create"

### Via amtool (CLI)

```bash
# Install amtool
go install github.com/prometheus/alertmanager/cmd/amtool@latest

# Configure amtool
export ALERTMANAGER_URL=http://localhost:9093

# Create silence
amtool silence add \
  alertname="HighCPU" \
  instance="prod-web-1" \
  --duration=2h \
  --comment="Planned deployment - Ticket: OPS-1234" \
  --author="alice@company.internal"

# List active silences
amtool silence query

# Expire a silence
amtool silence expire <silence-id>
```

### Via kubectl (for Kubernetes-based Alertmanager)

```bash
# Port-forward to Alertmanager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093

# Use amtool or UI as above
```

## Silence Best Practices

### 1. Always Include Context

**Bad**:
```
Comment: "Silencing for maintenance"
```

**Good**:
```
Comment: "Database upgrade during planned maintenance window - Ticket: OPS-1234 - Change: CHG0012345"
```

### 2. Use Specific Matchers

**Bad** (too broad):
```
Matchers: severity="warning"
```

**Good** (specific to affected resource):
```
Matchers: alertname="DiskFull", instance="worker-node-3", mountpoint="/data"
```

### 3. Set Expiry Times

**Bad**:
```
Duration: 30 days
```

**Good**:
```
Duration: 2 hours (matches maintenance window)
```

### 4. Review Silences Regularly

Schedule weekly review of active silences:
- Expire silences that are no longer needed
- Update comments if situation has changed
- Create tickets for repeatedly silenced alerts

## Silence Audit Trail

### Viewing Active Silences

```bash
# List all active silences
amtool silence query

# List silences for specific alert
amtool silence query alertname="HighCPU"

# Show silence details
amtool silence query --expired false --output=json | jq .
```

### Silence Metrics

Track silence usage with Prometheus metrics:

```promql
# Number of active silences
alertmanager_silences

# Number of silences by state
sum by(state) (alertmanager_silences)

# Alerts suppressed by silences
alertmanager_alerts{state="suppressed"}
```

### Monthly Silence Report

Create monthly report of silence usage:

```bash
# Generate report for last 30 days
amtool silence query --expired --within=720h | \
  awk '{print $3}' | sort | uniq -c | sort -rn
```

Review for patterns indicating:
- Frequent silences for same alert (fix alert or threshold)
- Long-duration silences (may indicate alert fatigue)
- Silences without ticket references (improve process compliance)

## Handling Silence-Related Incidents

### Scenario 1: Critical Alert Was Silenced During Incident

**Problem**: P1 incident occurred, but alert was silenced due to previous maintenance

**Immediate Action**:
1. Acknowledge incident via alternative detection method
2. Expire the silence immediately
3. Respond to incident per escalation policy

**Follow-Up**:
- Review silence matchers (were they too broad?)
- Update silence procedures (should critical alerts never be silenced?)
- Add to postmortem: "Delayed detection due to active silence"

### Scenario 2: Silence Expired but Issue Not Fixed

**Problem**: Silence expires, alerts start firing, underlying issue still present

**Immediate Action**:
1. Assess if issue is still being worked (check ticket status)
2. If fix in progress, extend silence with updated comment
3. If fix stalled, escalate to engineering manager

**Follow-Up**:
- Why did fix take longer than expected?
- Should alert have been silenced, or threshold adjusted?
- Create process for reviewing long-running issues

### Scenario 3: Someone Silenced Alerts Without Documentation

**Problem**: Active silence with no ticket reference or inadequate comment

**Immediate Action**:
1. Contact silence creator (shown in Alertmanager)
2. Request context and ticket number
3. Update silence comment with full details

**Follow-Up**:
- Remind team of silence documentation requirements
- Consider implementing silence validation webhook
- Add to team playbook review

## Integration with Incident Management

### Linking Silences to Tickets

Always include ticket reference in silence comment:

```
Format: "Reason - Ticket: <TICKET-ID> - Change: <CHANGE-ID> - ETA: <TIMESTAMP>"

Example: "Database replica rebuild after disk failure - Ticket: OPS-8765 - Change: CHG0023456 - ETA: 2026-02-09 15:00 AEDT"
```

### Creating Silences from Incident Slack Thread

Use Slack bot command (if available):

```
/silence create alertname=HighCPU instance=prod-web-1 duration=2h reason="Incident INC-1234: Emergency scaling in progress"
```

Or include link to create silence in incident runbook steps.

## Alternatives to Silencing

Before silencing an alert, consider these alternatives:

### 1. Adjust Alert Threshold

If alert fires too frequently with low signal:

```yaml
# Before: too sensitive
- alert: HighCPU
  expr: cpu_usage > 70

# After: more appropriate threshold
- alert: HighCPU
  expr: cpu_usage > 85
  for: 5m
```

### 2. Add Alert Context

If alert lacks information for triage:

```yaml
annotations:
  description: "CPU usage is {{ $value }}% on {{ $labels.instance }}. Check for unexpected processes or consider scaling."
  runbook_url: "https://github.com/justin-henson/au-nz-observability-stack/blob/main/runbooks/HIGH-CPU.md"
```

### 3. Create Inhibition Rule

If alert is redundant when higher-severity alert is firing:

```yaml
inhibit_rules:
  - source_match:
      alertname: ServiceDegradation
    target_match:
      alertname: HighLatency
```

### 4. Remove Alert

If alert provides no value after extended observation:

- Document decision in ticket
- Remove alert rule
- Monitor for 2 weeks to ensure no missed incidents
- Add to alert retrospective for team learning

## Silence Governance

### Required Approvals

| Silence Scope | Duration | Approval Required |
|--------------|----------|-------------------|
| Non-production | Any | On-call engineer |
| Production, warning severity | < 24h | On-call engineer |
| Production, warning severity | 24h - 7d | Engineering manager |
| Production, critical severity | < 4h | On-call engineer + incident commander |
| Production, critical severity | > 4h | VP Engineering |

### Audit Requirements

All silences lasting > 24 hours must be reviewed in:
- Weekly on-call handoff meeting
- Monthly SRE retrospective
- Quarterly alerting effectiveness review

---

## Quick Reference

| Action | Command |
|--------|---------|
| Create silence | `amtool silence add alertname="HighCPU" --duration=2h --comment="..."` |
| List silences | `amtool silence query` |
| Show silence details | `amtool silence query <silence-id>` |
| Extend silence | `amtool silence update <silence-id> --duration=4h` |
| Expire silence | `amtool silence expire <silence-id>` |
| Port-forward Alertmanager | `kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093` |

---

## Related Documentation

- [Escalation Policy](escalation-policy.md) - When to page vs silence
- [Alert Routing](alert-routing.md) - How alerts flow through Alertmanager
- [Runbooks](../runbooks/) - Troubleshooting guides for specific alerts
