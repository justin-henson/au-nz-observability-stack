# Escalation Policy

This document defines severity levels, response time expectations, and escalation paths for alerts in the production environment.

## Severity Levels

### P1 - Critical

**Definition**: Revenue loss, data loss, complete service outage, or security breach affecting production systems.

**Examples**:
- Complete application outage (all pods down, database unreachable)
- Data corruption or loss detected
- Security breach or unauthorized access
- Payment processing failure
- 100% error rate on critical user flows

**Response Time**: 15 minutes

**Notification Method**: PagerDuty page + Slack #incidents channel + SMS to on-call engineer

**Escalation Timeline**:
- T+0: Page primary on-call engineer
- T+15min: If not acknowledged, page secondary on-call engineer
- T+30min: If not resolved or actively being worked, page engineering manager
- T+60min: Escalate to VP Engineering and initiate incident bridge

**Postmortem**: Required within 48 hours

---

### P2 - High

**Definition**: Degraded service, partial outage, or critical component failure affecting subset of users.

**Examples**:
- Single availability zone failure with reduced capacity
- Database replica failure (primary still healthy)
- 5xx error rate > 5% but < 50%
- Critical background job failures (billing, notifications)
- Certificate expiring within 7 days

**Response Time**: 30 minutes

**Notification Method**: PagerDuty page + Slack #incidents channel

**Escalation Timeline**:
- T+0: Page primary on-call engineer
- T+30min: If not acknowledged, page secondary on-call engineer
- T+60min: If not resolved, notify engineering manager via Slack
- T+120min: Escalate to senior engineering leadership

**Postmortem**: Required within 5 business days

---

### P3 - Medium

**Definition**: Performance degradation, non-critical component failure, or operational issues not immediately impacting users.

**Examples**:
- High CPU/memory usage (warning threshold exceeded)
- Elevated error rates on non-critical endpoints
- Slow query performance
- Single pod crash looping
- Certificate expiring within 30 days
- Failed automated backups

**Response Time**: 2 hours (during business hours)

**Notification Method**: Slack #alerts channel

**Escalation Timeline**:
- T+0: Slack notification to on-call engineer
- T+2hr: If not acknowledged during business hours, email to team distribution list
- T+4hr: If not resolved during business hours, create ticket for next day
- Next business day: Assign to on-call engineer for investigation

**Postmortem**: Optional (recommended for recurring issues)

---

### P4 - Low

**Definition**: Informational alerts, monitoring gaps, or minor issues with no user impact.

**Examples**:
- Monitoring target down (non-production)
- Log volume anomalies
- Deprecated API usage warnings
- Cost threshold notifications
- License expiration warnings (> 30 days out)

**Response Time**: Next business day

**Notification Method**: Email digest (daily summary)

**Escalation Timeline**:
- No escalation required
- Reviewed during daily standup or weekly ops review
- Create backlog ticket if action needed

**Postmortem**: Not required

---

## On-Call Rotation

### Schedule
- Primary on-call: 7-day rotation, Monday 9am to Monday 9am AEDT/NZDT
- Secondary on-call: 7-day rotation, offset by 3-4 days from primary
- Manager on-call: 2-week rotation (P1 escalations only)

### Handoff Process
Use the [On-Call Handoff Template](on-call-handoff-template.md) at the end of each rotation to brief the next on-call engineer on:
- Active incidents and ongoing investigations
- Known issues and workarounds
- Upcoming maintenance or deployments
- Alert fatigue issues or false positives

### On-Call Expectations
- **Availability**: Respond to pages within SLA (15min for P1, 30min for P2)
- **Equipment**: Laptop with VPN access, PagerDuty app, Slack mobile app
- **Acknowledgment**: Acknowledge alerts immediately upon receiving notification
- **Communication**: Update #incidents channel every 30 minutes during P1/P2 incidents
- **Escalation**: Don't hesitate to escalate if stuck or uncertain

---

## Alert Response Guidelines

### Before Taking Action
1. **Acknowledge** the alert in PagerDuty/Slack
2. **Assess** impact using dashboards and logs
3. **Communicate** status in #incidents channel (for P1/P2)
4. **Consult** the relevant runbook (see [runbooks/](../runbooks/))

### During Investigation
- Document findings and actions in incident Slack thread
- Update stakeholders every 30 minutes (P1), 60 minutes (P2)
- Engage additional engineers if needed (use @sre or @backend-team)
- Consider enabling verbose logging or metrics collection

### After Resolution
- **P1/P2**: Post initial summary to #incidents within 1 hour of resolution
- **P1/P2**: Schedule postmortem meeting within 48 hours (P1) or 5 business days (P2)
- **All**: Update runbook if new information discovered
- **All**: Create tickets for follow-up work (monitoring improvements, preventive measures)

---

## False Positive Policy

Alert fatigue reduces response effectiveness. If an alert fires repeatedly without actionable cause:

1. **Immediate**: Silence the alert with expiry and document reason (see [silence-runbook.md](silence-runbook.md))
2. **Within 24hr**: Create ticket to fix alert threshold, add context, or remove alert
3. **Within 1 week**: Resolve ticket and verify alert is actionable

**Metrics**: Track alert signal-to-noise ratio monthly. Target: >80% of P1/P2 alerts result in investigative action or remediation.

---

## Exceptions and Overrides

### Planned Maintenance
- Silence alerts for affected resources during maintenance window
- Document in #incidents channel with start/end times
- Re-enable alerts immediately after maintenance completion

### Known Issues
- If a P1/P2 issue cannot be resolved immediately, demote to P3 and create incident ticket
- Silence repeat alerts for the same root cause
- Include mitigation steps and estimated fix timeline in ticket

### Holiday/Weekend Coverage
- Reduce P3/P4 noise by adjusting notification routing (disable Slack, email only)
- Ensure P1/P2 escalation paths are staffed
- Defer non-urgent on-call tasks to next business day

---

## Contact Information

| Role | Primary Contact | Backup Contact |
|------|----------------|----------------|
| **On-Call Engineer** | PagerDuty rotation | PagerDuty secondary |
| **Engineering Manager** | #engineering-managers | VP Engineering |
| **VP Engineering** | Slack DM | CTO |
| **Security Team** | #security-incidents | security@company.internal |
| **AWS Support** | Enterprise Support case | TAM |

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-08 | SRE Team | Initial version |
