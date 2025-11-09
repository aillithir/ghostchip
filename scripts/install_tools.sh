#!/usr/bin/env bash
set -euo pipefail
echo "[i] Optional installer for PREP machines (not evidence boxes)."
read -rp "Proceed with apt-based installs? [y/N]: " a
if [[ "${a:-N}" =~ ^[Yy]$ ]]; then
  sudo apt update
  sudo apt install -y adb libimobiledevice6 libimobiledevice-utils usbmuxd       python3 python3-pip python3-venv coreutils tar ddrescue guymager gnupg git
fi
read -rp "Install Python tools via pip (user scope)? [y/N]: " b
if [[ "${b:-N}" =~ ^[Yy]$ ]]; then
  python3 -m pip install --upgrade --user aleapp ileapp mvt plaso
fi
echo "[+] Installer complete."
