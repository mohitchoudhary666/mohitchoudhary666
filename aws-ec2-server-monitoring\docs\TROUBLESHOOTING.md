# Troubleshooting

## Timer or service is inactive
```bash
sudo systemctl status ec2-health-check.timer
sudo systemctl list-timers ec2-health-check.timer
sudo journalctl -u ec2-health-check.service -n 100 --no-pager
```
Enable with `sudo systemctl enable --now ec2-health-check.timer`.

## AccessDenied or no metrics
- Confirm an EC2 instance profile: `aws sts get-caller-identity`.
- Check the policy allows `cloudwatch:PutMetricData` for `Mohit/EC2Health`.
- Confirm outbound TCP 443 reaches the regional CloudWatch endpoint.
- Check the AWS account and region in the console.

## IMDS error
The script requires IMDSv2 and does not fall back to IMDSv1. Ensure instance metadata is enabled and reachable by host processes.

## Missing or implausible values
Check `/proc`, `df`, `ps`, and `systemctl`. CPU is sampled over one second, so it can differ from the EC2 console metric. Failed systemd units report zero if systemd is unavailable.

Run `sudo /usr/local/sbin/ec2-health-check.sh` manually and inspect the error. Review CloudTrail for denied API calls. After fixing the issue, restart the timer.
