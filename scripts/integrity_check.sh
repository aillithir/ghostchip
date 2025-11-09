#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 3 ]]; then echo "Usage: $0 <CASE_ROOT> <path> <pre|post>"; exit 1; fi
CASE_ROOT="$1"; TARGET="$2"; PHASE="$3"
LOG="${CASE_ROOT}/Logs/integrity_${PHASE}.txt"; MANIFEST="${CASE_ROOT}/Logs/hash_manifest.txt"
if [[ ! -f "$TARGET" ]]; then echo "[-] Target not found: $TARGET"; exit 2; fi
sha256sum "$TARGET" | tee -a "$LOG" | awk '{print strftime("%Y-%m-%dT%H:%M:%SZ",systime()),"|"$2,"|sha256|",$1}' >> "$MANIFEST"
md5sum "$TARGET"    | tee -a "$LOG" | awk '{print strftime("%Y-%m-%dT%H:%M:%SZ",systime()),"|"$2,"|md5|",$1}' >> "$MANIFEST"
echo "[+] Integrity ${PHASE} recorded."
