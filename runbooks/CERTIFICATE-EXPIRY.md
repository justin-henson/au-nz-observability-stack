# Runbook: Certificate Expiry

## Alert

**Alert Name**: `CertificateExpiringSoon` / `CertificateExpiryCritical`
**Severity**: Warning (30 days) / Critical (7 days)

## Impact

**User Experience**: If expired, users see browser security warnings, HTTPS connections fail, API clients reject connections.
**Business Impact**: Complete service unavailability, loss of customer trust, potential compliance violations.

## Investigation

```bash
# Check certificate expiry
echo | openssl s_client -servername <domain> -connect <domain>:443 2>/dev/null | openssl x509 -noout -dates

# Check all certs in cluster
kubectl get certificates -A

# For ACM
aws acm list-certificates --region ap-southeast-2
aws acm describe-certificate --certificate-arn <arn>
```

## Remediation

**For Let's Encrypt / cert-manager**:
```bash
# Force renewal
kubectl delete certificate <cert-name> -n <namespace>
# cert-manager will automatically recreate and renew

# Check renewal status
kubectl describe certificate <cert-name> -n <namespace>
kubectl get certificaterequest -n <namespace>
```

**For ACM**:
```bash
# ACM auto-renews if using DNS validation
# If validation failed, check DNS records
aws acm describe-certificate --certificate-arn <arn> | jq '.Certificate.DomainValidationOptions'

# Update DNS records if needed
aws route53 change-resource-record-sets --hosted-zone-id <zone-id> --change-batch file://dns-change.json
```

**Manual Certificate**:
```bash
# Generate new CSR
openssl req -new -key domain.key -out domain.csr

# Submit to CA and download new cert
# Update Kubernetes secret
kubectl create secret tls <secret-name> --cert=domain.crt --key=domain.key -n <namespace> --dry-run=client -o yaml | kubectl apply -f -

# Restart ingress controller
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
```

## Escalation

Escalate to security team if <3 days to expiry. Escalate to vendor/CA if certificate renewal failing.

## Post-Incident

- [ ] Verify certificate renewed successfully
- [ ] Add monitoring for all TLS endpoints
- [ ] Document renewal process
- [ ] Set up automated renewal if not present

## Additional Resources

- **cert-manager docs**: https://cert-manager.io/docs/
- **Chat**: #security, #platform-team
