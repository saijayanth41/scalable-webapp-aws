#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ALB=$(bash "$DIR/fetch_alb.sh")
URL="http://$ALB/"
echo "Target: $URL"

if command -v hey >/dev/null 2>&1; then
  hey -n 5000 -c 200 "$URL"
elif command -v ab >/dev/null 2>&1; then
  ab -n 5000 -c 200 "$URL"
else
  echo "Install 'hey' or 'ab' to run load test."
  exit 1
fi
