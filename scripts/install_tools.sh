#!/usr/bin/env bash
# ===============================================================
# GhostChip Installer (Kali / Debian Modernized Shortcut Version)
# PREP MACHINE ONLY — NOT FOR LIVE EVIDENCE SYSTEMS
# ===============================================================

set -euo pipefail

# ---------- Helpers ----------
log()  { printf '%s\n' "[i] $*"; }
ok()   { printf '%s\n' "[+] $*"; }
warn() { printf '%s\n' "[!] $*" >&2; }
err()  { printf '%s\n' "[-] $*" >&2; }

# ---------- 1) System Packages ----------
log "Updating APT and installing core dependencies..."
sudo apt update -y
sudo apt install -y \
  adb libimobiledevice-1.0-6 libimobiledevice-utils usbmuxd \
  python3 python3-pip python3-venv pipx \
  coreutils tar ddrescue gnupg git rsync zip \
  build-essential python3-dev pkg-config liblzma-dev libffi-dev libssl-dev zlib1g-dev

ok "System packages installed."

# ---------- 2) Ensure ~/.local/bin PATH ----------
pipx ensurepath --force || true
export PATH="$HOME/.local/bin:$PATH"
if ! grep -q 'export PATH=\$HOME/.local/bin:\$PATH' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH=$HOME/.local/bin:$PATH' >> "$HOME/.bashrc"
  ok "Added ~/.local/bin to PATH in ~/.bashrc"
fi

# ---------- 3) Mobile Verification Toolkit (MVT) ----------
log "Installing Mobile Verification Toolkit (mvt)..."
pipx install --force mvt --include-deps || true

# Create/repair wrapper to ensure mvt runs from pipx venv
MVT_VENV="$HOME/.local/share/pipx/venvs/mvt"
if [ -x "$MVT_VENV/bin/python" ]; then
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/mvt" <<EOF
#!/usr/bin/env bash
"$MVT_VENV/bin/python" -m mvt "\$@"
EOF
  chmod +x "$HOME/.local/bin/mvt"
  ok "mvt wrapper created."
fi

# ---------- 4) ALEAPP / iLEAPP ----------
log "Installing ALEAPP and iLEAPP from GitHub (via pipx, fallback shim)..."
mkdir -p "$HOME/tools" "$HOME/.local/bin"

install_from_git_or_shim () {
  local NAME="$1" REPO="$2" ENTRY="$3" FILE="$4"
  if ! pipx install "git+${REPO}"; then
    warn "$NAME pipx install failed; using local shim."
    if [[ ! -d "$HOME/tools/$NAME" ]]; then
      git clone "$REPO" "$HOME/tools/$NAME"
    fi
    cat > "$HOME/.local/bin/$ENTRY" <<EOF
#!/usr/bin/env bash
python3 "\$HOME/tools/$NAME/$FILE" "\$@"
EOF
    chmod +x "$HOME/.local/bin/$ENTRY"
    ok "$NAME shim created."
  fi
}

install_from_git_or_shim "ALEAPP" "https://github.com/abrignoni/ALEAPP.git" "aleapp" "aleapp.py"
install_from_git_or_shim "iLEAPP" "https://github.com/abrignoni/iLEAPP.git" "ileapp" "ileapp.py"

# ---------- 5) Plaso ----------
log "Installing Plaso timeline tools (via pipx)..."
pipx install --force plaso || warn "pipx plaso install may take time or fail on low-spec systems."

# Link Plaso binaries from pipx venv to ~/.local/bin
PLASO_VENV="$HOME/.local/share/pipx/venvs/plaso"
if [ -d "$PLASO_VENV/bin" ]; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$PLASO_VENV/bin/log2timeline" "$HOME/.local/bin/log2timeline"
  ln -sf "$PLASO_VENV/bin/psort"        "$HOME/.local/bin/psort"
  ln -sf "$PLASO_VENV/bin/log2timeline" "$HOME/.local/bin/log2timeline.py"
  ln -sf "$PLASO_VENV/bin/psort"        "$HOME/.local/bin/psort.py"
  ok "Linked Plaso CLI tools (log2timeline, psort)."
fi

# ---------- 6) Final PATH Refresh ----------
hash -r || true

# ---------- 7) Health Check ----------
echo
echo "===== GhostChip Prep Environment Check ====="
for cmd in ideviceinfo idevicebackup2 adb mvt mvt-ios mvt-android aleapp ileapp log2timeline psort; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "Found: $cmd -> $(command -v "$cmd")"
  else
    warn "Missing: $cmd"
  fi
done

echo
echo "===== Usage Notes ====="
echo "- All Python tools installed safely via pipx (PEP 668 safe)."
echo "- mvt now callable as both 'mvt', 'mvt-ios', 'mvt-android'."
echo "- log2timeline and psort linked from pipx venv (no .py needed)."
echo "- If anything shows as missing, open a new terminal to refresh PATH."
echo
ok "GhostChip installation complete. Prep machine is ready!"
