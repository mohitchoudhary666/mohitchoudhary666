#!/usr/bin/env bash
set -Eeuo pipefail
NAMESPACE="${CW_NAMESPACE:-Mohit/EC2Health}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
META=http://169.254.169.254
command -v aws >/dev/null || { echo "AWS CLI is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }

token="$(curl -fsS --max-time 3 -X PUT "$META/latest/api/token" -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600')"
meta() { curl -fsS --max-time 3 -H "X-aws-ec2-metadata-token: $token" "$META/latest/meta-data/$1"; }
instance_id="$(meta instance-id)"
instance_type="$(meta instance-type)"
REGION="${REGION:-$(meta placement/region)}"
[[ "$instance_id" =~ ^i-[a-f0-9]+$ && "$REGION" =~ ^[a-z0-9-]+$ ]] || { echo "Invalid EC2 metadata" >&2; exit 1; }

cpu() { awk '/^cpu / {idle=$5+$6; total=0; for(i=2;i<=NF;i++) total+=$i; print total, idle; exit}' /proc/stat; }
read -r total1 idle1 < <(cpu)
sleep "${CPU_SAMPLE_SECONDS:-1}"
read -r total2 idle2 < <(cpu)
dt=$((total2-total1)); di=$((idle2-idle1))
(( dt > 0 )) || { echo "Unable to sample CPU" >&2; exit 1; }
cpu_pct="$(awk -v t="$dt" -v i="$di" 'BEGIN {printf "%.2f",(t-i)*100/t}')"
mem_pct="$(awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {if(!t) exit 1; printf "%.2f",(t-a)*100/t}' /proc/meminfo)"
disk_pct="$(df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')"
uptime_s="$(awk '{printf "%.0f",$1}' /proc/uptime)"
process_count="$(ps -e --no-headers | wc -l | tr -d ' ')"
failed_units=0
if command -v systemctl >/dev/null && systemctl is-system-running >/dev/null 2>&1; then
  failed_units="$(systemctl --failed --no-legend --plain | wc -l | tr -d ' ')"
fi
data="$(cat <<JSON
[
 {"MetricName":"CpuUtilization","Dimensions":[{"Name":"InstanceId","Value":"$instance_id"},{"Name":"InstanceType","Value":"$instance_type"}],"Unit":"Percent","Value":$cpu_pct},
 {"MetricName":"MemoryUsedPercent","Dimensions":[{"Name":"InstanceId","Value":"$instance_id"},{"Name":"InstanceType","Value":"$instance_type"}],"Unit":"Percent","Value":$mem_pct},
 {"MetricName":"RootDiskUsedPercent","Dimensions":[{"Name":"InstanceId","Value":"$instance_id"},{"Name":"InstanceType","Value":"$instance_type"}],"Unit":"Percent","Value":$disk_pct},
 {"MetricName":"UptimeSeconds","Dimensions":[{"Name":"InstanceId","Value":"$instance_id"},{"Name":"InstanceType","Value":"$instance_type"}],"Unit":"Seconds","Value":$uptime_s},
 {"MetricName":"ProcessCount","Dimensions":[{"Name":"InstanceId","Value":"$instance_id"},{"Name":"InstanceType","Value":"$instance_type"}],"Unit":"Count","Value":$process_count},
 {"MetricName":"FailedSystemdUnits","Dimensions":[{"Name":"InstanceId","Value":"$instance_id"},{"Name":"InstanceType","Value":"$instance_type"}],"Unit":"Count","Value":$failed_units}
]
JSON
)"
aws cloudwatch put-metric-data --region "$REGION" --namespace "$NAMESPACE" --metric-data "$data"
echo "Published health metrics for $instance_id in $REGION"
