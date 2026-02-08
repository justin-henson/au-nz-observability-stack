# Runbook: High Memory Usage

## Alert

**Alert Name**: `HighMemory` (Prometheus) / `rds-memory-low` (CloudWatch)
**Severity**: Warning (>90%) / Critical (OOMKilled)

## Impact

**User Experience**: Service slowdowns, intermittent errors, or complete service unavailability if OOM kill occurs.
**Business Impact**: Service degradation, potential data loss if killed during transaction, SLA violations.

## Investigation

```bash
# Check memory usage
kubectl top pod -n production
kubectl top node

# For RDS
aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name FreeableMemory --dimensions Name=DBInstanceIdentifier,Value=<db-id> --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average

# Check for memory leaks
kubectl exec <pod> -n production -- top -b -n 1 -o %MEM
```

## Remediation

**Immediate**:
```bash
# Restart pods to clear memory
kubectl rollout restart deployment/<deployment> -n production

# Scale up for RDS
aws rds modify-db-instance --db-instance-identifier <db-id> --db-instance-class db.r5.xlarge --apply-immediately

# Increase pod memory limits
kubectl patch deployment <deployment> -n production -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"limits":{"memory":"2Gi"}}}]}}}}'
```

**Permanent**: Investigate memory leak, optimize queries, implement caching, right-size resources.

## Escalation

Escalate if memory continues growing after restart (indicates leak) or if database requires immediate scaling.

## Additional Resources

- **Dashboard**: [Infrastructure Overview](https://grafana.company.internal/d/infrastructure-overview)
- **Related**: [HIGH-CPU.md](HIGH-CPU.md), [POD-CRASHLOOP.md](POD-CRASHLOOP.md)
