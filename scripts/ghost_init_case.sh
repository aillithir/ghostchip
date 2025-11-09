#!/usr/bin/env bash
set -euo pipefail
timestamp=$(date +"%Y%m%d_%H%M%S")
case_root="Cases/Case_${timestamp}"
read -rp "Investigator name: " investigator
read -rp "Agency/Unit (optional): " agency
read -rp "Device label/description: " device_label
read -rp "Device OS (Android/iOS/Other): " device_os
read -rp "Device identifier (IMEI/Serial/UDID) (optional): " device_id
mkdir -p "${case_root}"/{Identification,Acquisition,Analysis,Reports,Logs,Artifacts}
cat > "${case_root}/Identification/case_metadata.json" <<JSON
{
  "case_id": "Case_${timestamp}",
  "created_utc": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "investigator": "${investigator}",
  "agency": "${agency}",
  "device": {"label": "${device_label}", "os": "${device_os}", "identifier": "${device_id}"},
  "sop": "NIST SP 800-101 aligned (identification, preservation, acquisition, analysis, reporting)"
}
JSON
echo "[+] Case created at ${case_root}"
echo "[i] Next: run ./ghost_acquire.sh ${case_root}"
