# Runbook Template

Use this template when creating new runbooks for alerts.

---

## Alert

**Alert Name**: `[AlertName from Prometheus/CloudWatch]`
**Severity**: [Critical / Warning / Info]
**Service/Component**: [Which system this affects]

---

## Impact

**User Experience**:
[What do users experience when this alert fires? Be specific about the impact]

**Business Impact**:
[What's the business consequence? Revenue loss, SLA breach, security risk, etc.]

**Scope**:
[How many users/systems/services are affected? Partial or total outage?]

---

## Investigation

### 1. Verify the Alert

**Check Dashboards**:
- [Link to primary dashboard for this alert]
- [Link to secondary dashboard if relevant]

**Confirm Symptoms**:
```bash
# [Command to verify the issue exists]
# [Expected output if alert is accurate]
# [What you'll see if it's a false positive]
```

### 2. Gather Context

**Check Recent Changes**:
```bash
# Check recent deployments
kubectl rollout history deployment/<deployment-name> -n <namespace>

# Check recent infrastructure changes
git log --since="2 hours ago" --oneline -- terraform/
```

**Review Logs**:
```bash
# Application logs
kubectl logs -n <namespace> -l app=<app-name> --tail=100 --since=30m

# System logs
journalctl -u <service-name> --since "30 minutes ago"
```

**Check Metrics**:
```bash
# Query Prometheus directly
curl -g 'http://prometheus:9090/api/v1/query?query=<metric-query>'

# Or use promtool
promtool query instant http://prometheus:9090 '<metric-query>'
```

### 3. Identify Root Cause

**Common Causes**:
1. [Most common cause - explain how to identify]
2. [Second most common cause - diagnostic steps]
3. [Less common but possible causes]

**Diagnostic Commands**:
```bash
# [Specific command to identify root cause #1]
# [Interpretation of output]

# [Specific command to identify root cause #2]
# [Interpretation of output]
```

---

## Remediation

### Immediate Mitigation

**Goal**: [What are you trying to achieve immediately? Stop user impact, prevent data loss, etc.]

**Steps**:
1. **[Action #1]**:
   ```bash
   # [Command]
   ```
   **Expected Result**: [What should happen]
   **Verification**: [How to confirm it worked]

2. **[Action #2]**:
   ```bash
   # [Command]
   ```
   **Expected Result**: [What should happen]
   **Verification**: [How to confirm it worked]

### Permanent Fix

**After immediate mitigation**, implement permanent fix:

1. **[Fix description]**:
   ```bash
   # [Commands for permanent fix]
   ```
   **Testing**: [How to verify the fix works]
   **Rollback Plan**: [How to undo if fix causes problems]

---

## Escalation

**When to Escalate**:
- [Condition #1 - e.g., issue persists after 30 minutes]
- [Condition #2 - e.g., you can't identify root cause]
- [Condition #3 - e.g., requires vendor support]

**Escalation Path**:
1. **Primary**: [@team-lead or @senior-engineer] via Slack
2. **Secondary**: Page engineering manager via PagerDuty
3. **Vendor Support**: [How to contact vendor if needed]

**Information to Provide**:
- Alert details (when it started, current status)
- Investigation steps already performed
- Mitigation attempts and their results
- Current user impact assessment

---

## Post-Incident

### Immediate (Within 1 Hour of Resolution)

- [ ] Update #incidents channel with resolution summary
- [ ] Verify alert has cleared in Alertmanager/CloudWatch
- [ ] Confirm systems are back to normal (check dashboards)
- [ ] Document timeline and actions taken in incident ticket

### Short-Term (Within 24 Hours)

- [ ] Create tickets for follow-up work:
  - [ ] [Type of ticket needed - e.g., alert threshold adjustment]
  - [ ] [Type of ticket needed - e.g., monitoring gap fix]
  - [ ] [Type of ticket needed - e.g., preventive measure]
- [ ] Update this runbook if new information discovered
- [ ] Review alert signal-to-noise ratio (was this actionable?)

### Long-Term (P1/P2 Only)

- [ ] Schedule postmortem meeting (within 48h for P1, 5 days for P2)
- [ ] Document incident in postmortem (use template from [au-nz-ops-runbooks](https://github.com/justin-henson/au-nz-ops-runbooks))
- [ ] Identify and track preventive measures
- [ ] Share learnings with team in next retrospective

---

## Additional Resources

- **Dashboard**: [Link to relevant Grafana dashboard]
- **Logs**: [Link to CloudWatch Logs Insights or Kibana]
- **Related Runbooks**: [Links to related runbooks]
- **Documentation**: [Links to system documentation]
- **Chat**: #[relevant-slack-channel]

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| YYYY-MM-DD | [Your Name] | Initial version |
