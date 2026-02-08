# Service Level Objectives (SLO) Definitions

This document defines Service Level Objectives for baseline web services, including availability and latency targets.

## Overview

SLOs represent the promises we make to users about service reliability. They are measurable, achievable targets that balance user needs with engineering effort.

## Core SLOs

### 1. Availability SLO

**Objective**: 99.9% availability over 30-day rolling window

**Definition**: Percentage of successful HTTP requests (non-5xx) divided by total HTTP requests

**Calculation**:
```promql
sum(rate(http_requests_total{status!~"5.."}[30d])) /
sum(rate(http_requests_total[30d]))
```

**Target**: 99.9%
**Error Budget**: 43.8 minutes of downtime per month (0.1% of 43,800 minutes)

**Rationale**:
- 99.9% is industry standard for B2B SaaS applications
- Allows for planned maintenance and unexpected issues
- Achievable with current architecture (multi-AZ, auto-scaling, health checks)

**Exclusions**:
- Planned maintenance windows (announced 48 hours in advance)
- Client errors (4xx status codes)
- DDoS attacks or abuse (>1000 requests/second from single source)

---

### 2. Latency SLO

**Objective**: 95% of requests complete in < 500ms, 99% in < 2000ms over 30-day rolling window

**Definition**: Request duration measured at application load balancer, from request received to response sent

**Calculation**:
```promql
# p95 latency
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[30d])) by (le))

# p99 latency
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[30d])) by (le))
```

**Targets**:
- p95 latency < 500ms
- p99 latency < 2000ms

**Error Budget**: 5% of requests may exceed 500ms, 1% may exceed 2000ms

**Rationale**:
- 500ms is user-perceptible threshold for "fast" interactions
- 2000ms prevents user frustration and abandoned sessions
- Accounts for database queries, external API calls, and network variability

**Exclusions**:
- Long-polling or streaming connections
- File upload/download operations (>1MB)
- Batch processing endpoints (explicitly marked as async)

---

### 3. Error Rate SLO

**Objective**: < 1% of requests result in server errors (5xx) over 30-day rolling window

**Definition**: Percentage of HTTP 5xx responses divided by total HTTP requests

**Calculation**:
```promql
sum(rate(http_requests_total{status=~"5.."}[30d])) /
sum(rate(http_requests_total[30d]))
```

**Target**: < 1% error rate
**Error Budget**: 1% of requests may fail

**Rationale**:
- Server errors indicate infrastructure or application problems under our control
- 1% allows for transient failures, dependencies, deployments
- Stricter than availability SLO (which includes client errors)

**Exclusions**:
- Errors from invalid client requests (malformed JSON, missing auth)
- Rate-limited requests (429 status code)
- Requests rejected by WAF

---

## SLO Measurement

### Measurement Window

All SLOs use 30-day rolling window:
- Smooths out short-term spikes
- Aligns with monthly reporting cycles
- Provides sufficient data for statistical significance

### Data Sources

- **Primary**: Prometheus metrics from application instrumentation
- **Secondary**: ALB access logs (for validation and debugging)
- **Backup**: CloudWatch metrics

### Burn Rate Calculation

Error budget burn rate indicates how quickly we're consuming our error budget:

```
Burn Rate = (Error Rate / SLO Target) × Time Window
```

**Example**: If availability is 99.5% (0.5% error rate) when target is 99.9% (0.1% error budget):
```
Burn Rate = (0.5% / 0.1%) = 5×
```

This means we're burning error budget 5× faster than acceptable. At this rate, we'll exhaust the monthly budget in 6 days.

### Multi-Window Multi-Burn-Rate Alerting

We use two alert windows to balance false positives vs detection speed:

| Window | Burn Rate | Budget Consumed | Alert Severity | Response Time |
|--------|-----------|-----------------|----------------|---------------|
| 1 hour | 14.4× | 10% in 1hr | Critical | Page immediately |
| 6 hours | 6× | 25% in 6hr | Warning | Notify in Slack |

**Why these numbers?**
- 1-hour window catches severe outages quickly
- 14.4× burn rate means budget exhausted in 50 hours (2 days) if sustained
- 6-hour window catches sustained degradation
- 6× burn rate means budget exhausted in 5 days if sustained

## Service-Specific SLOs

### Web API Service

**User Journey**: User submits form, receives confirmation within 2 seconds

**SLI**: HTTP POST to /api/submit endpoint

**SLOs**:
- Availability: 99.9%
- p99 Latency: < 2000ms
- Error Rate: < 0.5%

### Authentication Service

**User Journey**: User logs in and receives session token

**SLI**: HTTP POST to /auth/login endpoint

**SLOs**:
- Availability: 99.95% (stricter - critical path)
- p99 Latency: < 1000ms (must be fast for good UX)
- Error Rate: < 0.1%

### Background Jobs

**User Journey**: Data export completes and email sent within 15 minutes

**SLI**: Job success rate and duration

**SLOs**:
- Success Rate: 99%
- p95 Duration: < 10 minutes
- p99 Duration: < 15 minutes

## SLO Review Process

### Monthly Review

- **When**: First Monday of each month
- **Attendees**: SRE team, Engineering leads, Product
- **Agenda**:
  1. Review SLO attainment (met/missed)
  2. Analyze error budget consumption
  3. Discuss incidents that impacted SLOs
  4. Propose SLO adjustments if needed

### Quarterly Review

- **When**: End of each quarter
- **Attendees**: Engineering, Product, Customer Success
- **Agenda**:
  1. Validate SLO targets still align with user needs
  2. Review error budget policy effectiveness
  3. Identify services needing new SLOs
  4. Update SLO dashboard and documentation

## Improving SLOs

### Before Tightening SLOs

- Consistently meet current SLO for 3 months
- Demonstrate demand from users/customers
- Ensure monitoring and alerting is reliable
- Account for increased engineering effort

### Before Loosening SLOs

- Document why current SLO is unachievable
- Demonstrate user impact is acceptable
- Propose architectural changes to reach original target
- Get approval from Product and Engineering leadership

---

## References

- [Google SRE Book - Chapter 4: Service Level Objectives](https://sre.google/sre-book/service-level-objectives/)
- [Error Budget Policy](error-budget-policy.md)
- [SLO Dashboard](slo-dashboard.json)
- [Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/)

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-08 | SRE Team | Initial SLO definitions |
