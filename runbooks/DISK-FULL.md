# Runbook: Disk Full

## Alert

**Alert Name**: `DiskFull` (Prometheus) / `disk-usage-high` (CloudWatch)
**Severity**: Warning (>90%) / Critical (>95%)

## Impact

**User Experience**: Application crashes, unable to write logs or data, database write failures, service unavailable.
**Business Impact**: Data loss risk, transaction failures, complete service outage if disk reaches 100%.

## Investigation

```bash
# Check disk usage
df -h

# For Kubernetes
kubectl exec <pod> -n production -- df -h

# Find large files
kubectl exec <pod> -n production -- du -sh /* | sort -h | tail -10

# Check log volume
kubectl exec <pod> -n production -- du -sh /var/log/*
```

## Remediation

**Immediate**:
```bash
# Clear logs
kubectl exec <pod> -n production -- sh -c 'find /var/log -name "*.log" -mtime +7 -delete'

# For EC2 - expand volume
aws ec2 modify-volume --volume-id <vol-id> --size <new-size>
# Then resize filesystem
ssh ec2-user@<instance> 'sudo resize2fs /dev/xvdf'

# Delete old container images
ssh ec2-user@<instance> 'docker system prune -a --force'

# For RDS - increase storage
aws rds modify-db-instance --db-instance-identifier <db-id> --allocated-storage <new-size> --apply-immediately
```

**Permanent**: Implement log rotation, enable log shipping to centralized logging, configure PVC expansion, set up automated cleanup jobs.

## Escalation

Escalate immediately if disk >98% on production database or critical service.

## Additional Resources

- **Dashboard**: [Infrastructure Overview](https://grafana.company.internal/d/infrastructure-overview)
