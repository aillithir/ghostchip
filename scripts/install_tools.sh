#!/usr/bin/env bash
# ===============================================================
# GhostChip Installer (Kali-ready)
# PREP MACHINE ONLY — NOT FOR LIVE EVIDENCE SYSTEMS
# - Uses apt wherever possible (PEP 668 safe)
# - Uses pipx for Python CLIs when no apt package exists
# - Provides compatibility shims for Plaso tool names
# ===============================================================
set -euo pipefail

# ---------- Pretty output ----------
log()  { printf '%s\n' "[i] $*"; }
ok()   { printf '%s\n' "[+] $*"; }
warn() { printf '%s\n' "[!] $*" >&2; }
err()  { printf '%s\n' "[-] $*" >&2; }

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    return 1
  fi
}

# ---------- Sanity: are we on Debian/Kali family? ----------
if ! [ -r /etc/os-release ]; then
  warn "/etc/os-release not found; proceeding cautiously."
else
  . /etc/os-release
  log "Detected OS: ${NAME:-unknown} ${VERSION:-}"
fi

# ---------- 1) Base system packages ----------
log "Updating APT and installing core dependencies..."
sudo apt update -y
sudo apt install -y \
  adb libimobiledevice-1.0-6 libimobiledevice-utils usbmuxd \
  python3 python3-venv python3-pip pipx \
  coreutils tar ddrescue gnupg git rsync zip \
  build-essential python3-dev pkg-config liblzma-dev libffi-dev libssl-dev zlib1g

ok "Core packages installed."

# ---------- 2) Ensure ~/.local/bin on PATH (for pipx shims) ----------
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  export PATH="$HOME/.local/bin:$PATH"
fi
if ! grep -q 'export PATH=\$HOME/.local/bin:\$PATH' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH=$HOME/.local/bin:$PATH' >> "$HOME/.bashrc"
  ok "Added ~/.local/bin to PATH in ~/.bashrc"
fi

# Make sure pipx puts launchers there
pipx ensurepath --force || true

# ---------- 3) Mobile Verification Toolkit (MVT) ----------
log "Installing Mobile Verification Toolkit (mvt) via pipx..."
if ! pipx install --include-deps mvt 2>/dev/null; then
  warn "pipx mvt install encountered issues; will attempt a re-install with verbose logs."
  pipx install --force --include-deps mvt || warn "mvt install failed; you can run: pipx install --include-deps mvt"
fi

# Optional wrapper to guarantee the module runner
MVT_VENV="$HOME/.local/share/pipx/venvs/mvt"
if [ -x "$MVT_VENV/bin/python" ]; then
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/mvt" <<'EOF'
#!/usr/bin/env bash
"$HOME/.local/share/pipx/venvs/mvt/bin/python" -m mvt "$@"
EOF
  chmod +x "$HOME/.local/bin/mvt"
  ok "mvt wrapper created at ~/.local/bin/mvt"
fi

# ---------- 4) ALEAPP / iLEAPP (pipx with git, shim fallback) ----------
log "Installing ALEAPP and iLEAPP (pipx/git with shim fallback)..."
mkdir -p "$HOME/tools" "$HOME/.local/bin"

install_from_git_or_shim () {
  local NAME="$1" REPO="$2" ENTRY="$3" FILE="$4"
  if ! pipx install "git+${REPO}"; then
    warn "$NAME pipx install failed; creating local shim."
    if [[ ! -d "$HOME/tools/$NAME" ]]; then
      git clone "$REPO" "$HOME/tools/$NAME"
    fi
    cat > "$HOME/.local/bin/$ENTRY" <<EOF
#!/usr/bin/env bash
python3 "$HOME/tools/$NAME/$FILE" "\$@"
EOF
    chmod +x "$HOME/.local/bin/$ENTRY"
    ok "$NAME shim created at ~/.local/bin/$ENTRY"
  else
    ok "$NAME installed via pipx"
  fi
}

install_from_git_or_shim "ALEAPP" "https://github.com/abrignoni/ALEAPP.git" "aleapp" "aleapp.py"
install_from_git_or_shim "iLEAPP" "https://github.com/abrignoni/iLEAPP.git" "ileapp" "ileapp.py"

# ---------- 5) Plaso via APT (preferred on Kali) ----------
log "Installing Plaso timeline tools from apt (python3-plaso)..."
if sudo apt install -y python3-plaso; then
  ok "Installed python3-plaso from apt."

  # Provide compatibility launchers for legacy tool names
  mkdir -p "$HOME/.local/bin"
  # Kali packages expose /usr/bin/plaso-log2timeline and /usr/bin/plaso-psort
  ln -sf /usr/bin/plaso-log2timeline "$HOME/.local/bin/log2timeline"
  ln -sf /usr/bin/plaso-psort        "$HOME/.local/bin/psort"
  ln -sf /usr/bin/plaso-log2timeline "$HOME/.local/bin/log2timeline.py"
  ln -sf /usr/bin/plaso-psort        "$HOME/.local/bin/psort.py"
  ok "Created compatibility shims: log2timeline{,.py}, psort{,.py}"
else
  warn "python3-plaso not available via apt (mirror or distro issue)."
  warn "You can: 1) retry after apt update; 2) use Docker image log2timeline/plaso; 3) use pipx with Python <=3.11 if wheels are available."
fi

# ---------- 6) Refresh hash lookup ----------
hash -r || true

# ---------- 7) Health Check ----------
echo
echo "===== GhostChip Prep Environment Check ====="
for cmd in \
  ideviceinfo idevicebackup2 usbmuxd adb \
  mvt mvt-ios mvt-android \
  aleapp ileapp \
  plaso-log2timeline plaso-psort log2timeline log2timeline.py psort psort.py
  do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "Found: $cmd -> $(command -v "$cmd")"
  else
    warn "Missing: $cmd"
  fi
done

# ---------- 8) Usage Notes ----------
echo
cat <<'EON'
===== Usage Notes =====
- Python tools are installed via pipx where possible (PEP 668 compliant).
- On Kali, Plaso binaries are named: plaso-log2timeline and plaso-psort.
  This installer also provides compatibility shims: log2timeline{,.py} and psort{,.py}.
- If tools appear missing, open a NEW terminal so PATH updates take effect.
- If apt cannot find python3-plaso, consider: sudo apt update, change mirrors, or use Docker:
    docker run --rm -it -v "$PWD:/data" log2timeline/plaso:latest bash
EON

echo
ok "GhostChip installation complete. This machine is ready for prep tasks."
