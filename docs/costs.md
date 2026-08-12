# Estimated AWS costs

## Planning estimate

The following low-traffic ranges use `us-east-1`, roughly 730 hours/month, on-demand Linux/x86 Fargate, 20 GiB RDS gp3 storage, minimal log ingestion, and no meaningful internet data transfer. They are directional estimates as of August 2026, not billing quotes.

| Component | Dev | Prod | Main assumption |
|---|---:|---:|---|
| NAT gateway | ~$33 + data | ~$66 + data | One dev NAT; two prod NATs at about $0.045/hour |
| Application Load Balancer | ~$17–23 | ~$17–23 | ALB hours plus low LCU use |
| ECS Fargate | ~$9 | ~$36 | 1 × 0.25 vCPU/0.5 GiB; 2 × 0.5 vCPU/1 GiB |
| RDS PostgreSQL | ~$15–35 | ~$110–180 | Single-AZ micro vs Multi-AZ small, storage/backups included as a range |
| Logs, ECR, S3 state, Secrets Manager, IPv4, transfer | ~$5–20 | ~$10–45 | Low ingestion/storage/traffic |
| **Planning total** | **~$90–130/month** | **~$250–350/month** | Before taxes and unusual traffic |

AWS charges NAT gateways by provisioned hour and processed GB. ALB pricing combines hourly and LCU charges. Fargate bills requested vCPU and memory from image download until task termination. RDS varies by region, instance, availability model, storage, backup, and transfer. Verify the [VPC pricing](https://aws.amazon.com/vpc/pricing/), [Elastic Load Balancing pricing](https://aws.amazon.com/elasticloadbalancing/pricing/), [Fargate pricing](https://aws.amazon.com/fargate/pricing/), and [RDS PostgreSQL pricing](https://aws.amazon.com/rds/postgresql/pricing/) in the AWS Pricing Calculator before deployment.

Autoscaling can intentionally exceed the baseline. Prod can reach ten 0.5-vCPU/1-GiB tasks, which materially raises Fargate cost during sustained load. Logs, NAT processing, cross-AZ traffic, snapshots beyond included backup storage, and internet egress are usage-sensitive.

## Cost controls

1. Create an AWS Budget and anomaly monitor before applying Terraform.
2. Destroy dev when not in use; RDS and NAT/ALB remain billable while idle.
3. Add ECR/S3 gateway and interface endpoints only after comparing endpoint hourly cost with NAT processing/availability needs.
4. Consider Fargate Spot for interruption-tolerant non-production tasks.
5. Rightsize from Container Insights and RDS metrics, then evaluate Savings Plans or reserved database capacity for stable production usage.
6. Keep log retention explicit and filter high-volume low-value application logs.

