# Monitoring and incident response

## Signals

Application stdout/stderr goes to `/ecs/<project>-<environment>` in CloudWatch Logs. ECS Container Insights supplies cluster/service telemetry. ALB target health provides a user-path availability signal.

| Alarm | Condition | First interpretation |
|---|---|---|
| ECS high CPU | Average CPU >80% for 10 minutes | Load, hot path, or stalled scaling |
| ECS high memory | Average memory >85% for 10 minutes | Leak, undersized task, or request spike |
| ALB 5xx | At least 5 ALB-generated 5xx in 5 minutes | Load balancer/target connectivity problem |
| Unhealthy targets | At least 1 unhealthy target for 2 minutes | Failed health check or broken task |

Set `alarm_sns_topic_arn` to route alarms to an owned notification path. An alarm without a notification action is observability, not paging.

## Initial triage

1. Acknowledge the alert and identify environment/customer impact.
2. Check ALB target health, ECS service events, desired/running/pending counts, and the latest deployment.
3. Correlate CPU/memory and request/error changes with application logs.
4. If impact began after a release, roll back to the last known-good immutable image/task revision.
5. If capacity is the issue, confirm autoscaling activity and raise maximum capacity only with a cost/concurrency review.
6. If database symptoms appear, inspect RDS events, connections, storage, CPU, and failover state without exposing credentials.

Useful commands:

```bash
aws ecs describe-services --cluster <cluster> --services <service>
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
aws logs tail /ecs/<service> --since 30m --follow
aws application-autoscaling describe-scaling-activities \
  --service-namespace ecs --resource-id service/<cluster>/<service>
```

## Severity guide

- **SEV-1:** sustained total production outage, data integrity, or confirmed credential compromise—page immediately, name an incident commander, and open a live incident channel.
- **SEV-2:** material degradation or partial outage—respond promptly, stabilize, and communicate regular updates.
- **SEV-3:** non-production issue or low-impact defect—track during business hours.

## Stabilization priorities

Protect data first, restore a known-good service second, preserve evidence third, and optimize later. Prefer rollback over forward fixes during active customer impact. Avoid Terraform changes during an application-only incident unless infrastructure is the confirmed cause.

## After the incident

Capture detection, impact, timeline, contributing factors, recovery, and action owners. Add or tune alerts based on a symptom that would have shortened detection or diagnosis. Test the corrective action and set a due date. Review alarm noise monthly and exercise rollback and database recovery at least quarterly in a real production program.

