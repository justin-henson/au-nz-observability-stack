# Decision Log

This document records major architectural decisions, alternatives considered, and rationale.

## D1: Dual-Stack Monitoring (CloudWatch + Prometheus)

**Date**: 2026-02-08
**Status**: Accepted
**Context**: Need monitoring for both AWS-managed services and Kubernetes workloads

**Decision**: Use both CloudWatch and Prometheus rather than single platform

**Alternatives Considered**:
1. **CloudWatch only**: Simpler, fully managed, but poor Kubernetes support and high query costs
2. **Prometheus only**: Great for Kubernetes, but requires custom exporters for AWS services and operational overhead
3. **Datadog/New Relic**: Excellent unified experience, but very high cost ($20k+/year for our scale)

**Rationale**:
- CloudWatch is zero-setup for EC2, RDS, ALB metrics
- Prometheus is industry standard for Kubernetes monitoring
- Grafana provides unified visualization layer
- Cost: $150/month CloudWatch + $50/month S3 (Thanos) vs $2000+/month for commercial SaaS
- Flexibility: Can migrate to single platform later without changing instrumentation

**Consequences**:
- ✅ Best-in-class monitoring for each platform
- ✅ Lower cost than commercial SaaS
- ❌ Two systems to maintain and learn
- ❌ Alert routing complexity (two paths to PagerDuty)

---

## D2: Push vs Pull Metrics Collection

**Date**: 2026-02-08
**Status**: Accepted

**Decision**: Use pull-based collection (Prometheus scrape model) for Kubernetes, push for CloudWatch

**Alternatives Considered**:
1. **Push everywhere**: Applications push to collector (simpler networking, but tight coupling)
2. **Pull everywhere**: Export CloudWatch metrics to Prometheus exporter (complexity, polling limits)

**Rationale**:
- Pull model aligns with Prometheus best practices
- Service discovery automatic for Kubernetes
- CloudWatch push is AWS-native behavior (can't change)
- Pull model makes scrape failures visible (missing target != failing service)

**Consequences**:
- ✅ Prometheus can detect when targets disappear
- ✅ No application-side configuration for metrics endpoint
- ❌ Requires network connectivity from Prometheus to all targets
- ❌ Hybrid approach adds cognitive overhead

---

## D3: Alert Severity Model (4 Levels)

**Date**: 2026-02-08
**Status**: Accepted

**Decision**: Use 4-level severity model (Critical, Warning, Info, Debug)

**Alternatives Considered**:
1. **2 levels (Page / Don't Page)**: Too coarse, loses signal about importance
2. **5+ levels**: Too granular, difficult to define boundaries
3. **3 levels**: Industry common, but found we need distinction between "degraded" (P2) and "annoying" (P3)

**Rationale**:
- P1 (Critical): Revenue/data impact → page immediately
- P2 (High): Degraded service → page but less urgent
- P3 (Medium): Performance issue → Slack during business hours
- P4 (Low): Informational → email digest

**Consequences**:
- ✅ Clear escalation paths
- ✅ Reduces alert fatigue (not everything is critical)
- ❌ Requires discipline to correctly classify alerts
- ❌ Edge cases between P2 and P3 can be ambiguous

---

## D4: SLO Target Selection (99.9%)

**Date**: 2026-02-08
**Status**: Accepted

**Decision**: 99.9% availability SLO (43.8 minutes downtime/month allowed)

**Alternatives Considered**:
1. **99.99% (4 nines)**: Only 4.38 min/month, requires significant investment, may not be achievable with current architecture
2. **99.5%**: Too loose, allows 3.65 hours/month downtime, not competitive
3. **99% (2 nines)**: Unacceptable for B2B SaaS, 7.2 hours/month downtime

**Rationale**:
- 99.9% is industry standard for B2B SaaS
- Achievable with multi-AZ architecture and current team size
- Allows for monthly deployment windows and occasional incidents
- User research shows <5 min outages don't significantly impact satisfaction

**Consequences**:
- ✅ Realistic target that drives good practices without perfection paralysis
- ✅ Error budget allows innovation without fear
- ❌ May need to tighten to 99.95% for enterprise tier customers
- ❌ Single-AZ maintenance windows consume significant budget

---

## D5: Dashboard Design (RED Method + USE Method)

**Date**: 2026-02-08
**Status**: Accepted

**Decision**: Use RED method for services, USE method for resources

**Alternatives Considered**:
1. **Custom dashboards per team**: Flexible but inconsistent, hard to compare
2. **Generic "everything" dashboard**: Too noisy, slow to load
3. **Google's Four Golden Signals**: Similar to RED, but less prescriptive

**Rationale**:
- **RED** (Rate, Errors, Duration) is perfect for request-driven services
- **USE** (Utilization, Saturation, Errors) is perfect for system resources (CPU, memory, disk)
- Industry-proven patterns reduce cognitive load
- Consistent dashboards across services aid troubleshooting

**Consequences**:
- ✅ Dashboards are immediately understandable to new team members
- ✅ Clear pattern to follow when adding new services
- ❌ May not fit all service types (batch jobs, message queues)
- ❌ Requires discipline to not add "one more panel"

---

## D6: Prometheus Retention (30 Days Local + Unlimited S3)

**Date**: 2026-02-08
**Status**: Accepted

**Decision**: 30-day local TSDB retention, unlimited Thanos S3 retention

**Alternatives Considered**:
1. **7-day local**: Saves disk space, but insufficient for monthly SLO reporting
2. **90-day local**: Expensive disk usage, slow queries, diminishing returns
3. **No long-term storage**: Lose historical data, can't do year-over-year comparisons

**Rationale**:
- 30 days covers monthly SLO window plus buffer
- S3 storage is cheap ($0.023/GB/month vs EBS $0.10/GB/month)
- Thanos compaction downsamples old data (5m→1h→1d) for efficiency
- Can query 1-year trends without impacting production Prometheus

**Consequences**:
- ✅ Fast queries for recent data (30 days)
- ✅ Unlimited retention for capacity planning and SLO reporting
- ❌ Queries spanning 30+ days are slower (hit S3)
- ❌ Adds complexity (Thanos sidecar, compactor, store gateway)

---

## D7: Grafana Provisioning (GitOps)

**Date**: 2026-02-08
**Status**: Accepted

**Decision**: Store dashboards in Git, provision via ConfigMaps

**Alternatives Considered**:
1. **Manual creation in UI**: Fast for prototyping, but not version controlled or reproducible
2. **Grafana API**: Programmatic, but requires CI/CD integration
3. **Terraform provider**: IaC, but dashboard JSON in HCL is unreadable

**Rationale**:
- Dashboards are code, should be in version control
- ConfigMap approach is Kubernetes-native
- Changes reviewed via pull request before deployment
- Easy rollback via Git

**Consequences**:
- ✅ Dashboard changes are audited and reviewed
- ✅ Disaster recovery: redeploy from Git
- ❌ Slower iteration (commit → push → apply vs save in UI)
- ❌ JSON diffs in PRs are hard to review

---

## D8: Alert Routing by Severity (Not by Team)

**Date**: 2026-02-08
**Status**: Accepted

**Decision**: Route alerts based on severity first, then by team/service

**Alternatives Considered**:
1. **Route by service**: Each service has dedicated on-call, more targeted but requires more people
2. **Route by team**: Backend vs platform vs data, clean ownership but cross-functional incidents are messy
3. **Route by time of day**: Business hours vs after-hours, but doesn't account for severity

**Rationale**:
- Severity determines urgency, urgency determines response time
- Small team (10 engineers) makes per-service rotation impractical
- Critical alerts should wake someone immediately regardless of team
- Team-specific routing as secondary layer for P3/P4 alerts

**Consequences**:
- ✅ Simple on-call rotation (primary + secondary)
- ✅ Ensures critical alerts always get attention
- ❌ On-call engineer may not be familiar with service that alerted
- ❌ Requires good runbooks for cross-training

---

## Future Decisions

These topics need decisions as the system matures:

1. **Distributed Tracing**: Jaeger vs Tempo vs commercial (Honeycomb, Lightstep)
2. **Log Aggregation**: ELK vs Loki vs CloudWatch Logs Insights
3. **Synthetic Monitoring**: Blackbox exporter vs Pingdom vs Datadog Synthetics
4. **Anomaly Detection**: PromQL-based vs ML-based (Amazon Lookout, Datadog Watchdog)
5. **Multi-Region Monitoring**: Single Prometheus vs federated per-region instances

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-08 | SRE Team | Initial decision log |
