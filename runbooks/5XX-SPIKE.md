# Runbook: 5xx Error Spike

## Alert

**Alert Name**: `High5xxRate` (Prometheus) / `alb-5xx-errors` (CloudWatch)
**Severity**: Critical
**Service/Component**: Application services, API endpoints

## Impact

**User Experience**: Users receive "Internal Server Error" or "Service Unavailable" messages. Transactions fail, data may not be saved, user workflows interrupted.

**Business Impact**: Direct revenue loss from failed transactions, SLA violations, customer trust erosion, potential data consistency issues.

**Scope**: Can be isolated to single endpoint or service-wide depending on root cause.

## Investigation

### 1. Verify Alert

**Check Dashboards**:
```bash
# Query current error rate
curl -g 'http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~"5.."}[5m])'

# Check ALB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=<alb-arn-suffix> \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### 2. Identify Affected Endpoints

**Analyze Error Distribution**:
```bash
# Group errors by endpoint
kubectl logs -n production -l app=web-api --since=15m | grep " 5[0-9][0-9] " | awk '{print $7}' | sort | uniq -c | sort -rn

# Check specific endpoint logs
kubectl logs -n production -l app=web-api --since=15m | grep "POST /api/checkout"
```

### 3. Identify Root Cause

**Common Causes**:
1. **Database connection exhaustion**: Connection pool depleted
2. **External dependency failure**: Downstream service unavailable
3. **Recent deployment**: New code with bugs
4. **Resource exhaustion**: Out of memory, disk full
5. **Rate limiting**: Upstream service rejecting requests

**Diagnostic Commands**:
```bash
# Check database connections
kubectl exec <pod> -n production -- psql -U app -c "SELECT count(*) FROM pg_stat_activity;"

# Check external dependency health
kubectl exec <pod> -n production -- curl -I https://api.external-service.com/health

# Check pod resource usage
kubectl top pod -n production -l app=web-api

# Review recent deployments
kubectl rollout history deployment/web-api -n production
```

## Remediation

### Immediate Mitigation

1. **Rollback if Recent Deployment**:
   ```bash
   kubectl rollout undo deployment/web-api -n production
   kubectl rollout status deployment/web-api -n production
   ```

2. **Scale Up to Handle Load**:
   ```bash
   kubectl scale deployment/web-api -n production --replicas=<current+3>
   ```

3. **Restart Pods if Connection Pool Issue**:
   ```bash
   kubectl rollout restart deployment/web-api -n production
   ```

4. **Enable Circuit Breaker** (if supported):
   ```bash
   # Update feature flag or config to fail fast
   kubectl set env deployment/web-api CIRCUIT_BREAKER_ENABLED=true -n production
   ```

### Permanent Fix

1. **Database Connection Issues**:
   - Increase connection pool size
   - Implement connection retry logic
   - Add connection pool monitoring

2. **External Dependency Failures**:
   - Implement circuit breakers and timeouts
   - Add retry with exponential backoff
   - Implement graceful degradation

3. **Code Bugs**:
   - Fix bug in application code
   - Add error handling and logging
   - Implement canary deployments

## Escalation

**When to Escalate**:
- Error rate >10% for more than 10 minutes
- Rollback unsuccessful
- External dependency outage beyond our control
- Database or infrastructure issues suspected

**Escalation Path**:
1. @backend-team-lead
2. Page engineering manager
3. External vendor support if third-party service issue

## Post-Incident

- [ ] Document root cause and resolution
- [ ] Review error handling and retry logic
- [ ] Add monitoring for early detection
- [ ] Implement canary deployments if not present
- [ ] Schedule postmortem

## Additional Resources

- **Dashboard**: [Application Health](https://grafana.company.internal/d/application-health)
- **Chat**: #backend-team

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-08 | SRE Team | Initial version |
