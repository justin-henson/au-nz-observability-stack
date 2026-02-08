# On-Call Handoff Template

Use this template at the end of each on-call rotation to brief the next on-call engineer.

---

## Handoff Information

**Outgoing On-Call**: [Your Name]
**Incoming On-Call**: [Next Person's Name]
**Rotation Period**: [Start Date] - [End Date]
**Handoff Date**: [Today's Date]
**Handoff Time**: [Time] AEDT/NZDT

---

## Rotation Summary

### Incidents

**Total Incidents**: [Number]
**P1 (Critical)**: [Number]
**P2 (High)**: [Number]
**P3 (Medium)**: [Number]
**P4 (Low)**: [Number]

### Notable Incidents

#### [INC-XXXX] - [Brief Title]

**Severity**: P1/P2/P3
**Status**: Resolved / In Progress / Monitoring
**Start Time**: [DateTime]
**Resolution Time**: [DateTime] (or "Ongoing")
**Impact**: [What users experienced]
**Root Cause**: [Brief description or "Under investigation"]
**Action Items**:
- [Ticket-123] [Description] - Assigned to [Person] - Due [Date]
- [Ticket-456] [Description] - Assigned to [Person] - Due [Date]

**Postmortem**: [Link to postmortem doc or "Scheduled for [Date]"]
**Slack Thread**: [Link to #incidents thread]

---

## Active Issues

### Ongoing Incidents

#### [Issue Title]

**Status**: [Active monitoring / In progress / Waiting for deployment]
**Description**: [What's happening]
**Current Mitigation**: [What's in place to reduce impact]
**Expected Resolution**: [Timeline or blocker]
**Ticket**: [Link]
**Contact**: [Who owns this] - [Slack handle or phone]

---

### Known Issues / Workarounds

#### [Known Issue Title]

**Symptoms**: [What you'll see in alerts or dashboards]
**Workaround**: [How to handle when it fires]
**Fix Status**: [Ticket link and ETA]
**Notes**: [Any additional context]

**Example**:
> **Symptoms**: `HighMemory` alert fires on `worker-node-5` every 2-3 days
> **Workaround**: Restart the node - `kubectl drain worker-node-5 --ignore-daemonsets && kubectl uncordon worker-node-5`
> **Fix Status**: OPS-3456 - Memory leak investigation in progress - ETA unknown
> **Notes**: Memory leak suspected in the data-processor pod. Safe to restart node when memory > 95%.

---

## Upcoming Maintenance

### Scheduled Deployments

| Date/Time | Service | Change | Ticket | Owner | Impact |
|-----------|---------|--------|--------|-------|--------|
| [DateTime] | [Service name] | [What's changing] | [Link] | [@person] | [Expected impact] |

**Example**:
| Date/Time | Service | Change | Ticket | Owner | Impact |
|-----------|---------|--------|--------|-------|--------|
| 2026-02-10 03:00 AEDT | PostgreSQL | Major version upgrade | CHG-5678 | @database-team | 15-20 min downtime |

### Planned Maintenance Windows

| Date/Time | System | Work Description | Ticket | Alerts Silenced? |
|-----------|--------|------------------|--------|------------------|
| [DateTime] | [System] | [What's happening] | [Link] | Yes/No |

**Example**:
| Date/Time | System | Work Description | Ticket | Alerts Silenced? |
|-----------|--------|------------------|--------|------------------|
| 2026-02-11 20:00-22:00 AEDT | EKS Cluster | Node group upgrade | OPS-7890 | Yes (see Alertmanager) |

---

## Alert Noise / False Positives

### Alerts to Watch

List any alerts that have been problematic during your rotation:

#### [Alert Name]

**Issue**: [Why it's noisy or problematic]
**Action Taken**: [What you did - e.g., adjusted threshold, silenced, created ticket]
**Ticket**: [Link to follow-up work]
**Notes**: [Context for next on-call]

**Example**:
> **Alert**: `DiskFull` on staging cluster
> **Issue**: Fires every 6 hours due to log volume, but auto-cleanup runs successfully
> **Action Taken**: Ticket OPS-4567 created to increase log retention policy
> **Ticket**: https://jira.company.internal/browse/OPS-4567
> **Notes**: Safe to acknowledge if on staging. Production instances should still be investigated immediately.

---

## Infrastructure Changes

### Recent Changes

List significant infrastructure or configuration changes made during your rotation:

| Date | Change | System | Reason | Rollback Plan |
|------|--------|--------|--------|---------------|
| [Date] | [What changed] | [Where] | [Why] | [How to undo if needed] |

**Example**:
| Date | Change | System | Reason | Rollback Plan |
|------|--------|--------|--------|---------------|
| 2026-02-08 | Increased ALB timeout from 30s to 60s | Production ALB | Frequent 504 errors on report generation | Terraform apply with timeout=30 |

---

## System Health

### Current Metrics (as of handoff time)

**Cluster Status**:
- Running Pods: [Number]
- Pending Pods: [Number]
- Failed Pods: [Number] (acceptable if < 5)
- Node Status: [X/Y ready]

**Application Health**:
- Error Rate (5xx): [Percentage]
- p99 Latency: [Value]
- Request Rate: [Value] req/s

**Infrastructure**:
- Average CPU: [Percentage]
- Average Memory: [Percentage]
- Disk Usage (highest): [Percentage] on [Instance]

**Dashboards**:
- [Infrastructure Overview](https://grafana.company.internal/d/infrastructure-overview)
- [Application Health](https://grafana.company.internal/d/application-health)
- [Kubernetes Cluster](https://grafana.company.internal/d/kubernetes-cluster)

---

## Active Silences

List all active alert silences and why they exist:

| Alert | Matchers | Expires | Reason | Ticket |
|-------|----------|---------|--------|--------|
| [Alert name] | [Labels] | [DateTime] | [Why silenced] | [Link] |

**Example**:
| Alert | Matchers | Expires | Reason | Ticket |
|-------|----------|---------|--------|--------|
| DiskFull | instance="worker-node-3" | 2026-02-10 15:00 | Storage expansion in progress | OPS-5678 |

**Review before expiry!**

---

## Tips for Incoming On-Call

### Things I Learned This Week

- [Tip or lesson from an incident]
- [Useful command or tool discovered]
- [Process improvement suggestion]

**Example**:
> - The new `kubectl debug` command is helpful for inspecting crashed pods
> - Check the #database-team channel before restarting RDS instances - they may be testing
> - PagerDuty has a mobile app that's more reliable than SMS

### Watch Out For

- [Recurring issue to be aware of]
- [Time-sensitive item]
- [Gotcha or trap to avoid]

**Example**:
> - Daily batch job at 2am AEDT causes CPU spike - normal behavior, don't panic
> - SSL cert for api.company.internal expires on 2026-02-15 - reminder already set
> - Never run `terraform apply` in production without engineering manager approval

### Resources You Might Need

- [Link to frequently used dashboard]
- [Slack channel for specific system]
- [Contact for vendor support]

**Example**:
> - AWS Support case portal: https://console.aws.amazon.com/support
> - Database team Slack: #database-team (response time < 30min during business hours)
> - Runbook for most common alert: [HIGH-CPU.md](../runbooks/HIGH-CPU.md)

---

## Handoff Checklist

Before ending your rotation, confirm:

- [ ] All P1/P2 incidents have postmortem scheduled or completed
- [ ] Active silences have expiry times and ticket references
- [ ] All action items from incidents are tracked in tickets
- [ ] Incoming on-call has acknowledged handoff (Slack DM or meeting)
- [ ] PagerDuty rotation shows correct person as primary
- [ ] No unacknowledged alerts in Alertmanager
- [ ] Reviewed dashboards - system health is nominal

---

## Contact Information

**Outgoing On-Call Contact**:
Slack: [@your-handle]
Phone: [Your number] (available for 24 hours post-handoff for questions)

**Key Contacts**:
- **Secondary On-Call**: [@person] - [Phone]
- **Engineering Manager**: [@person] - [Phone]
- **Database Team Lead**: [@person] (business hours only)
- **AWS TAM**: [Name] - [Email]

---

## Additional Notes

[Any other information that doesn't fit above but incoming on-call should know]

---

**Signature**:

Outgoing: [Your Name] - [Date/Time]
Incoming: [Next Person's Name] - [Date/Time] (sign to acknowledge)

---

## References

- [Escalation Policy](escalation-policy.md)
- [Alert Routing](alert-routing.md)
- [Runbooks](../runbooks/)
- [au-nz-ops-runbooks](https://github.com/justin-henson/au-nz-ops-runbooks) - Incident response templates
