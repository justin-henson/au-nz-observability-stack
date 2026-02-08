# Error Budget Policy

This document defines how we respond when consuming error budget at different rates, and what restrictions apply when budget is exhausted.

## Error Budget Overview

**Error Budget** is the maximum amount of unreliability we can tolerate while still meeting our SLO. It represents the balance between reliability and feature velocity.

For a 99.9% availability SLO:
- **Total minutes per month**: 43,800 (30 days × 24 hours × 60 minutes)
- **Allowed downtime**: 43.8 minutes (0.1%)
- **This is our error budget**: 43.8 minutes of unavailability per 30-day window

## Error Budget Consumption Levels

### Level 1: Healthy (0-50% consumed)

**Status**: ✅ Operating normally

**Actions**:
- **Feature Development**: Full speed ahead - prioritize new features
- **Deployments**: Multiple deployments per day allowed
- **Change Frequency**: No restrictions
- **Testing**: Standard testing practices
- **On-Call**: Normal rotation

**Engineering Focus**: 80% feature development, 20% reliability work

---

### Level 2: Warning (50-80% consumed)

**Status**: ⚠️ Approaching limits

**Actions**:
- **Feature Development**: Slow down - prioritize reliability improvements
- **Deployments**: Reduce to 1-2 deployments per day
- **Change Frequency**: Prefer off-peak hours
- **Testing**: Increase canary deployment time to 2 hours
- **On-Call**: Review on-call coverage, ensure secondary is available

**Engineering Focus**: 50% feature development, 50% reliability work

**Required Activities**:
- [ ] Review recent incidents and identify patterns
- [ ] Prioritize bug fixes and tech debt that impact reliability
- [ ] Schedule postmortems for any outstanding incidents
- [ ] Review and update monitoring coverage
- [ ] Consider deferring risky features to next sprint

**Communication**:
- Alert #engineering channel when 50% threshold crossed
- Include error budget status in daily standups
- Report to leadership in weekly updates

---

### Level 3: Critical (80-100% consumed)

**Status**: 🔴 Error budget nearly exhausted

**Actions**:
- **Feature Development**: **FREEZE** - only critical bug fixes and reliability improvements
- **Deployments**: Emergency change approval required (VP Engineering)
- **Change Frequency**: Minimize all changes
- **Testing**: Extended canary period (4 hours), manual approval gates
- **On-Call**: Add extra on-call rotation, improve coverage

**Engineering Focus**: 0% features, 100% reliability

**Required Activities**:
- [ ] **IMMEDIATE**: Convene incident review meeting
- [ ] Identify top 3 reliability issues and create tickets
- [ ] Assign dedicated engineer(s) to reliability work
- [ ] Daily error budget review until under 80%
- [ ] Postpone all non-critical releases

**Communication**:
- Page engineering leadership when 80% threshold crossed
- Daily updates to #engineering and #leadership channels
- Prepare communication for customers if necessary

**Change Approval Process**:
1. Engineer proposes change with risk assessment
2. Engineering manager reviews and approves/rejects
3. VP Engineering gives final approval for production changes
4. Changes must have rollback plan and monitoring

---

### Level 4: Exhausted (>100% consumed)

**Status**: 🚨 **SLO BREACH** - Error budget exceeded

**Actions**:
- **Feature Development**: **COMPLETE FREEZE** - absolute minimum changes only
- **Deployments**: Emergency-only with CTO approval
- **Change Frequency**: Only for incident remediation
- **Testing**: All changes require manual testing and approval
- **On-Call**: 24/7 coverage until SLO restored

**Engineering Focus**: 100% incident response and recovery

**Required Activities**:
- [ ] **IMMEDIATE**: Escalate to VP Engineering and CTO
- [ ] Convene emergency incident bridge
- [ ] Identify all contributing incidents and root causes
- [ ] Create recovery plan with timeline
- [ ] Assign war room team for continuous focus
- [ ] Communicate to customers about service reliability

**Communication**:
- Immediate escalation to executive team
- Customer communication required (template below)
- Daily leadership updates until budget restored
- Prepare detailed postmortem

**Recovery Plan**:
1. Stabilize service (resolve active incidents)
2. Identify and fix top 3 reliability issues
3. Wait for error budget to recover naturally (time-based)
4. Resume normal operations only when budget < 80%

**Customer Communication Template**:
```
Subject: Service Reliability Update

We are writing to inform you about recent service reliability below our
normal standards. Over the past [timeframe], our service availability
was [percentage], slightly below our 99.9% target.

What happened:
[Brief explanation of incidents]

What we're doing:
- Resolved immediate issues
- Implementing additional monitoring
- Addressing root causes
- Temporarily pausing feature releases to focus on stability

We apologize for any inconvenience and are committed to restoring our
high reliability standards. Please contact support with any concerns.
```

---

## Error Budget Calculation Examples

### Example 1: Single Outage

**Scenario**: Complete service outage for 20 minutes

**Calculation**:
- Downtime: 20 minutes
- Error Budget: 43.8 minutes
- **Consumed**: 20 / 43.8 = 45.7%
- **Status**: Level 2 (Warning)

**Response**: Slow down deployments, prioritize fixing root cause

---

### Example 2: Elevated Error Rate

**Scenario**: 5% error rate for 2 hours (120 minutes)

**Calculation**:
- Errors during period: 5% × 120 min = 6 minutes of "bad" requests
- This counts as 6 minutes of unavailability
- **Consumed**: 6 / 43.8 = 13.7%
- **Status**: Level 1 (Healthy)

**Response**: Normal operations, create ticket to investigate errors

---

### Example 3: Multiple Small Incidents

**Scenario**: Five separate 5-minute incidents over the month

**Calculation**:
- Total downtime: 5 × 5 = 25 minutes
- **Consumed**: 25 / 43.8 = 57.1%
- **Status**: Level 2 (Warning)

**Response**: Pattern indicates systemic issue, prioritize reliability work

---

## Recovering Error Budget

Error budget recovers naturally as the 30-day rolling window moves forward:

**Recovery Rate**: Old data falls out of window at same rate as new data enters

**Example**:
- Day 1-30: Consumed 30 minutes of budget (68%)
- Day 2-31: If Day 1 had 2 minutes of downtime, and Day 31 is perfect:
  - Budget improves by 2 minutes
  - New consumption: 28 / 43.8 = 63.9%

**Fastest Recovery**: Perfect availability for 30 days fully restores budget

**Practical Recovery**: With 99.99% uptime, full recovery takes ~2-3 weeks

---

## Policy Enforcement

### Who Enforces

- **Level 1-2**: Engineering Manager monitors and recommends actions
- **Level 3**: VP Engineering enforces change freeze
- **Level 4**: CTO enforces complete freeze

### Exceptions

Change freeze exceptions require:
1. Written justification of business impact
2. Risk assessment and rollback plan
3. Approval from VP Engineering (Level 3) or CTO (Level 4)
4. Postmortem required regardless of outcome

**Valid Exceptions**:
- Security vulnerability fix (critical CVE)
- Data loss prevention
- Legal/compliance requirement

**Invalid Exceptions**:
- Customer-requested feature (defer until budget recovers)
- Marketing deadline (adjust timeline)
- Competitor pressure

---

## Quarterly Review

Policy effectiveness reviewed quarterly:

**Metrics to Review**:
- How often did we hit each level?
- Did freezes actually improve reliability?
- Were exceptions appropriate and documented?
- Did error budget influence prioritization decisions?

**Potential Adjustments**:
- Threshold levels (maybe 60/85/100 instead of 50/80/100)
- Required actions at each level
- Exception approval process
- SLO targets themselves

---

## Tools and Dashboards

- **SLO Dashboard**: [slo-dashboard.json](slo-dashboard.json)
- **Error Budget Tracking**: Grafana panel showing current consumption
- **Alerting**: Prometheus alerts at 50%, 80%, 100% thresholds
- **Slack Bot**: `/slo status` command for current error budget

---

## References

- [SLO Definitions](SLO-DEFINITIONS.md)
- [Google SRE Workbook - Error Budget Policy](https://sre.google/workbook/error-budget-policy/)
- [Alerting](../alerting/)

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-08 | SRE Team | Initial error budget policy |
