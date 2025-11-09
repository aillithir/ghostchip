#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 ]]; then echo "Usage: $0 <CASE_ROOT>"; exit 1; fi
CASE_ROOT="$1"; LOG="${CASE_ROOT}/Logs/acquisition.log"; MANIFEST="${CASE_ROOT}/Logs/hash_manifest.txt"; ART_DIR="${CASE_ROOT}/Artifacts"
mkdir -p "${ART_DIR}"; touch "${LOG}" "${MANIFEST}"
exists() { command -v "$1" >/dev/null 2>&1; }
echo "[i] Tooling check:" | tee -a "${LOG}"
for t in adb idevicebackup2 dd tar sha256sum md5sum; do
  if exists "$t"; then echo "  [+] $t found" | tee -a "${LOG}"; else echo "  [-] $t NOT found" | tee -a "${LOG}"; fi
done
echo "GhostChip Acquisition Orchestrator"; echo "Case: ${CASE_ROOT}"; echo "----------------------------------"
echo "  1) Android - Logical (ADB)"; echo "  2) iOS - Backup (libimobiledevice)"; echo "  3) Physical - dd image"; echo "  4) Cloud - MVT placeholder"; echo "  5) Quit"
read -rp "Choice [1-5]: " choice
run_and_log() { local cmd="$1"; echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $cmd" | tee -a "${LOG}"; bash -c "$cmd"; local s=$?; echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] exit_code=$s" | tee -a "${LOG}"; return $s; }
hash_and_record(){ local p="$1"; if [[ -f "$p" ]]; then sha=$(sha256sum "$p"|awk '{print $1}'); m=$(md5sum "$p"|awk '{print $1}'); echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")|$p|sha256|$sha" | tee -a "${MANIFEST}"; echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")|$p|md5|$m" | tee -a "${MANIFEST}"; fi; }
case "$choice" in
  1) if ! exists adb; then echo "[-] adb not found"; exit 2; fi; OUT="${ART_DIR}/android_logical_$(date +%s)"; mkdir -p "$OUT"; run_and_log "adb pull /sdcard '$OUT'" || true; tar -czf "${OUT}.tar.gz" -C "${OUT%/*}" "$(basename "$OUT")"; hash_and_record "${OUT}.tar.gz"; echo "[+] Android logical packaged: ${OUT}.tar.gz";;
  2) if ! exists idevicebackup2; then echo "[-] idevicebackup2 not found"; exit 2; fi; OUT="${ART_DIR}/ios_backup_$(date +%s)"; mkdir -p "$OUT"; run_and_log "idevicebackup2 backup '$OUT'" || true; tar -czf "${OUT}.tar.gz" -C "${OUT%/*}" "$(basename "$OUT")"; hash_and_record "${OUT}.tar.gz"; echo "[+] iOS backup packaged: ${OUT}.tar.gz";;
  3) read -rp "Block device (e.g., /dev/sdX): " blk; OUT="${ART_DIR}/physical_image_$(date +%s).dd"; run_and_log "dd if='${blk}' of='${OUT}' bs=4M status=progress conv=sync,noerror" || true; hash_and_record "${OUT}"; echo "[+] Physical image: ${OUT}";;
  4) OUT="${ART_DIR}/cloud_mvt_$(date +%s)"; mkdir -p "$OUT"; echo "MVT placeholder: document legal authority, provider, tokens." > "${OUT}/READ_ME_FIRST.txt"; tar -czf "${OUT}.tar.gz" -C "${OUT%/*}" "$(basename "$OUT")"; hash_and_record "${OUT}.tar.gz"; echo "[+] Cloud placeholder packaged: ${OUT}.tar.gz";;
  5) echo "Bye."; exit 0;;
  *) echo "Invalid choice"; exit 1;;
esac
echo "[i] Acquisition complete. See ${LOG} and ${MANIFEST}."
