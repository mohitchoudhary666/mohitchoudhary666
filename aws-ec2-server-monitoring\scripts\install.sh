#!/usr/bin/env bash
set -Eeuo pipefail
[[ "$EUID" -eq 0 ]] || { echo "Run with sudo: sudo ./scripts/install.sh" >&2; exit 1; }
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
install -m 0755 "$repo/scripts/publish-metrics.sh" /usr/local/sbin/ec2-health-check.sh
install -m 0644 "$repo/systemd/ec2-health-check.service" /etc/systemd/system/ec2-health-check.service
install -m 0644 "$repo/systemd/ec2-health-check.timer" /etc/systemd/system/ec2-health-check.timer
systemctl daemon-reload
systemctl enable --now ec2-health-check.timer
systemctl start ec2-health-check.service
echo "Installed. Logs: journalctl -u ec2-health-check.service -f"
