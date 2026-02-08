# Runbook: Pod CrashLoop

## Alert

**Alert Name**: `PodCrashLooping` (Prometheus) / `eks-pod-crashloop` (CloudWatch)
**Severity**: Warning
**Service/Component**: Kubernetes pods

## Impact

**User Experience**:
Service degradation or complete unavailability depending on replica count. Users may see 502/503 errors if all replicas are crash looping.

**Business Impact**:
- Reduced capacity as crashed pods cannot serve traffic
- Complete service outage if single-replica deployment
- Increased load on healthy pods may trigger cascading failures

**Scope**:
Typically single pod, but can affect entire deployment if caused by recent code or config change.

## Investigation

### 1. Verify the Alert

**Check Pod Status**:
```bash
# List pods with restart counts
kubectl get pods -n <namespace> | grep -v "Running.*0/"

# Check specific pod status
kubectl describe pod <pod-name> -n <namespace>

# View restart count trend
kubectl get pod <pod-name> -n <namespace> -w
```

### 2. Gather Context

**Check Pod Logs**:
```bash
# Current container logs
kubectl logs <pod-name> -n <namespace>

# Previous container logs (from before crash)
kubectl logs <pod-name> -n <namespace> --previous

# All restarts
kubectl logs <pod-name> -n <namespace> --all-containers --previous
```

**Review Pod Events**:
```bash
# Events show termination reason
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | grep <pod-name>

# Describe shows exit code and reason
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 "State:"
```

**Check Recent Changes**:
```bash
# Recent deployments
kubectl rollout history deployment <deployment-name> -n <namespace>

# ConfigMap/Secret changes
kubectl describe configmap <configmap-name> -n <namespace>
```

### 3. Identify Root Cause

**Common Exit Codes**:
- **Exit 0**: Clean exit (check if liveness probe too aggressive)
- **Exit 1**: Application error (check logs for stack trace)
- **Exit 137**: OOMKilled (memory limit too low)
- **Exit 139**: Segmentation fault (application bug)
- **Exit 143**: SIGTERM (shutdown during termination)

**Diagnostic Commands**:
```bash
# Check if OOMKilled
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'

# Check resource usage vs limits
kubectl top pod <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace> | grep -A 5 "Limits:"

# Exec into running pod to debug
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
```

## Remediation

### Immediate Mitigation

**Goal**: Stabilize service and restore capacity

**Steps**:
1. **If caused by recent deployment - Rollback**:
   ```bash
   # View rollout history
   kubectl rollout history deployment/<deployment-name> -n <namespace>

   # Rollback to previous version
   kubectl rollout undo deployment/<deployment-name> -n <namespace>

   # Monitor rollback
   kubectl rollout status deployment/<deployment-name> -n <namespace>

   # Verify pods stable
   kubectl get pods -n <namespace> -w
   ```

2. **If OOMKilled - Increase Memory Limit**:
   ```bash
   # Patch deployment with higher memory
   kubectl patch deployment <deployment-name> -n <namespace> -p \
     '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"memory":"2Gi"}}}]}}}}'

   # Or edit interactively
   kubectl edit deployment <deployment-name> -n <namespace>
   # Increase memory limit, save, and exit
   ```

3. **If ConfigMap/Secret Issue - Fix Config**:
   ```bash
   # Edit ConfigMap
   kubectl edit configmap <configmap-name> -n <namespace>

   # Restart deployment to pick up changes
   kubectl rollout restart deployment/<deployment-name> -n <namespace>
   ```

4. **Temporary - Delete Crashlooping Pod**:
   ```bash
   # Force pod recreation (only if preventing deployment updates)
   kubectl delete pod <pod-name> -n <namespace> --force --grace-period=0
   ```

### Permanent Fix

**After stabilization**:

1. **For Application Crashes**:
   - Review application logs for stack traces
   - Reproduce crash in staging environment
   - Add error handling and graceful degradation
   - Improve liveness/readiness probe configuration:
   ```yaml
   livenessProbe:
     httpGet:
       path: /health
       port: 8080
     initialDelaySeconds: 60  # Give app time to start
     periodSeconds: 10
     failureThreshold: 3  # Allow 3 failures before restart
   ```

2. **For Resource Issues**:
   - Review actual usage patterns in Grafana
   - Right-size resource requests and limits:
   ```yaml
   resources:
     requests:
       memory: "512Mi"
       cpu: "250m"
     limits:
       memory: "1Gi"
       cpu: "500m"
   ```

3. **For External Dependencies**:
   - Add retry logic and circuit breakers
   - Implement graceful degradation when dependencies unavailable
   - Add startup probe for slow-starting applications:
   ```yaml
   startupProbe:
     httpGet:
       path: /health
       port: 8080
     failureThreshold: 30  # 30 * 10s = 5min to start
     periodSeconds: 10
   ```

## Escalation

**When to Escalate**:
- Unable to stabilize pods after rollback
- Unknown root cause after 30 minutes investigation
- Critical production service with no healthy replicas
- Suspected infrastructure or cluster issue

**Escalation Path**:
1. **Primary**: @platform-team-lead for infrastructure issues, @app-team-lead for application issues
2. **Secondary**: Page engineering manager via PagerDuty
3. **AWS Support**: If suspected EKS control plane or node issue

**Information to Provide**:
- Pod name, namespace, deployment name
- Exit code and termination reason
- Recent changes (deployments, config updates)
- Logs from crashed container
- Resource usage at time of crash

## Post-Incident

### Immediate

- [ ] Verify all pods running and healthy
- [ ] Check replica count matches desired state
- [ ] Confirm service is accepting traffic (health checks passing)
- [ ] Document root cause and fix applied

### Short-Term

- [ ] Create ticket to improve liveness/readiness probes if needed
- [ ] Create ticket to adjust resource limits based on actual usage
- [ ] Update monitoring to detect this failure mode earlier
- [ ] Add integration test to prevent regression

### Long-Term

- [ ] Review application startup and shutdown procedures
- [ ] Implement chaos engineering to test resilience
- [ ] Add circuit breakers for external dependencies
- [ ] Review and update deployment strategy (canary, blue-green)

## Additional Resources

- **Dashboard**: [Kubernetes Cluster](https://grafana.company.internal/d/kubernetes-cluster)
- **Related Runbooks**: [HIGH-MEMORY.md](HIGH-MEMORY.md), [HIGH-CPU.md](HIGH-CPU.md)
- **Kubernetes Debug**: https://kubernetes.io/docs/tasks/debug/debug-application/
- **Chat**: #platform-team, #sre

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-02-08 | SRE Team | Initial version |
