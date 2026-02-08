# Runbook: High CPU

## Alert

**Alert Name**: `HighCPU` (Prometheus) / `ec2-cpu-warning` (CloudWatch)
**Severity**: Warning (>80%) / Critical (>95%)
**Service/Component**: EC2 instances, Kubernetes nodes, application containers

## Impact

**User Experience**:
Users may experience slow response times, timeouts, or degraded performance. API calls may take longer than normal.

**Business Impact**:
- Increased latency affects user satisfaction and may violate SLO targets
- Potential cascading failures if load balancer health checks fail
- Risk of instance/pod termination if CPU sustains at 100%

**Scope**:
Typically affects single instance or pod. If multiple instances affected simultaneously, indicates traffic spike or code regression.

## Investigation

### 1. Verify the Alert

**Check Dashboards**:
- [Infrastructure Overview](https://grafana.company.internal/d/infrastructure-overview) - See cluster-wide CPU
- [Kubernetes Cluster](https://grafana.company.internal/d/kubernetes-cluster) - See pod-level resource usage

**Confirm High CPU**:
```bash
# For EC2/bare metal
top -b -n 1 | head -20

# For Kubernetes pod
kubectl top pod <pod-name> -n <namespace>

# Get detailed process list
kubectl exec <pod-name> -n <namespace> -- ps aux --sort=-%cpu | head -20
```

### 2. Gather Context

**Check Recent Changes**:
```bash
# Recent deployments
kubectl rollout history deployment -n production

# Recent HPA scaling events
kubectl get hpa -n production -o wide
kubectl describe hpa <hpa-name> -n production
```

**Review Application Logs**:
```bash
# Check for error spikes or unusual log volume
kubectl logs -n production -l app=web-api --tail=100 --since=30m | grep -i error

# Check for long-running requests
kubectl logs -n production -l app=web-api --tail=100 | grep "duration" | awk '{print $NF}' | sort -n | tail
```

**Check Traffic Patterns**:
```bash
# Query request rate
curl -g 'http://prometheus:9090/api/v1/query?query=rate(http_requests_total[5m])'

# Check if traffic increased
# Compare current rate to baseline (should be in Grafana dashboard)
```

### 3. Identify Root Cause

**Common Causes**:
1. **Traffic spike**: Sudden increase in legitimate user requests
2. **Inefficient code**: New deployment with CPU-intensive operations
3. **Background job**: Scheduled task consuming resources
4. **Resource contention**: Multiple CPU-intensive processes competing
5. **Attack**: DDoS or crypto mining malware

**Diagnostic Commands**:
```bash
# Identify top CPU consumers
kubectl exec <pod-name> -n production -- top -b -n 1

# Check if it's a specific endpoint
# Review APM traces or application logs for slow endpoints

# Check for abnormal processes
kubectl exec <pod-name> -n production -- ps aux | grep -v "app-process"

# For EC2 instance
ssh ec2-user@<instance-ip>
top -c  # Press 'P' to sort by CPU
```

## Remediation

### Immediate Mitigation (Warning - 80-95% CPU)

**Goal**: Prevent reaching critical threshold and maintain service availability

**Steps**:
1. **Scale Horizontally** (if using HPA):
   ```bash
   # Check current replica count
   kubectl get deployment <deployment-name> -n production

   # Manually scale if HPA not responding fast enough
   kubectl scale deployment <deployment-name> -n production --replicas=<new-count>

   # Verify new pods are running
   kubectl get pods -n production -l app=<app-name> -w
   ```
   **Expected Result**: CPU distributed across more instances, average drops below 80%
   **Verification**: Check dashboard or `kubectl top nodes`

2. **Verify Health Checks Passing**:
   ```bash
   # Ensure high CPU hasn't caused health check failures
   kubectl get pods -n production -l app=<app-name> -o wide

   # Check ALB target health
   aws elbv2 describe-target-health --target-group-arn <arn>
   ```

### Immediate Mitigation (Critical - >95% CPU)

**Goal**: Prevent instance failure and restore service immediately

**Steps**:
1. **Emergency Scaling**:
   ```bash
   # Increase replicas aggressively
   kubectl scale deployment <deployment-name> -n production --replicas=<current+5>

   # For EC2 Auto Scaling Group
   aws autoscaling set-desired-capacity \
     --auto-scaling-group-name <asg-name> \
     --desired-capacity <new-count>
   ```

2. **If Instance is Unresponsive**:
   ```bash
   # Drain and replace Kubernetes node
   kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
   kubectl delete node <node-name>

   # For EC2
   aws ec2 terminate-instances --instance-ids <instance-id>
   # ASG will launch replacement automatically
   ```

### Permanent Fix

**After immediate mitigation**, investigate and implement fix:

1. **If caused by traffic spike**:
   - Review and adjust HPA configuration:
   ```bash
   kubectl edit hpa <hpa-name> -n production
   # Adjust targetCPUUtilizationPercentage or add custom metrics
   ```
   - Consider implementing request rate limiting
   - Review capacity planning

2. **If caused by code change**:
   - Identify problematic code using APM/profiling
   - Rollback deployment if severe:
   ```bash
   kubectl rollout undo deployment/<deployment-name> -n production
   kubectl rollout status deployment/<deployment-name> -n production
   ```
   - Create ticket for code optimization
   - Add performance testing to CI/CD

3. **If caused by background job**:
   - Reschedule job to off-peak hours
   - Add CPU limits to job pod:
   ```yaml
   resources:
     limits:
       cpu: "500m"
   ```
   - Consider moving to dedicated worker pool

## Escalation

**When to Escalate**:
- CPU remains >95% for more than 15 minutes despite scaling
- Unable to identify root cause within 30 minutes
- Scaling is ineffective (pods still overloaded)
- Suspected security incident (crypto mining, DDoS)

**Escalation Path**:
1. **Primary**: @backend-team-lead via #incidents channel
2. **Secondary**: Page engineering manager via PagerDuty
3. **Security Team**: @security if malicious activity suspected

**Information to Provide**:
- Which instances/pods affected and for how long
- Current CPU percentage and trend
- Traffic patterns (increased/normal)
- Recent deployments or changes
- Scaling actions already taken and their effect

## Post-Incident

### Immediate (Within 1 Hour)

- [ ] Verify CPU returned to normal (<70%)
- [ ] Confirm all pods/instances are healthy
- [ ] Document root cause and actions taken
- [ ] Update #incidents channel

### Short-Term (Within 24 Hours)

- [ ] Create ticket to review CPU resource requests/limits
- [ ] Create ticket for HPA tuning if scaling was slow
- [ ] Update monitoring if new pattern discovered
- [ ] Review alert threshold (was 80% appropriate?)

### Long-Term (P1/P2 Only)

- [ ] Schedule postmortem if critical severity or > 1 hour duration
- [ ] Review application performance optimization opportunities
- [ ] Consider vertical pod autoscaling (VPA) if horizontal scaling insufficient
- [ ] Update capacity planning model

## Additional Resources

- **Dashboard**: [Infrastructure Overview](https://grafana.company.internal/d/infrastructure-overview)
- **Related Runbooks**: [HIGH-MEMORY.md](HIGH-MEMORY.md), [POD-CRASHLOOP.md](POD-CRASHLOOP.md)
- **HPA Documentation**: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- **Chat**: #backend-team, #sre

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-08 | SRE Team | Initial version |
