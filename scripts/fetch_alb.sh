#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"/..
terraform output -raw alb_dns_name
