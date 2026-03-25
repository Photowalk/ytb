#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="${SCRIPT_DIR}/bin/ytb"
TARGET_DIR="${HOME}/.local/bin"
TARGET_SCRIPT="${TARGET_DIR}/ytb"
TARGET_YTDLP="${TARGET_DIR}/yt-dlp"

detect_ytdlp_asset() {
  case "$(uname -m)" in
    x86_64|amd64)
      printf 'yt-dlp_linux'
      ;;
    aarch64|arm64)
      printf 'yt-dlp_linux_aarch64'
      ;;
    *)
      printf 'yt-dlp'
      ;;
  esac
}

install_latest_ytdlp() {
  local asset url temp_file

  asset="$(detect_ytdlp_asset)"
  url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/${asset}"
  temp_file="$(mktemp)"

  echo "[install] Downloading latest yt-dlp from ${url}"
  curl -fsSL "$url" -o "$temp_file"
  install -m 0755 "$temp_file" "$TARGET_YTDLP"
  rm -f "$temp_file"
  echo "[install] Installed yt-dlp $("$TARGET_YTDLP" --version) to ${TARGET_YTDLP}"
}

if [[ ! -f "$SOURCE_SCRIPT" ]]; then
  echo "[install] ERROR: ${SOURCE_SCRIPT} was not found." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1 || ! command -v ffmpeg >/dev/null 2>&1; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "[install] ERROR: sudo is required to install curl, jq, and ffmpeg." >&2
    exit 1
  fi
  if [[ ! -t 0 || ! -t 1 ]]; then
    echo "[install] ERROR: curl, jq, and ffmpeg are required." >&2
    echo "[install] Run this in a normal terminal first:" >&2
    echo "sudo apt-get update && sudo apt-get install -y curl jq ffmpeg" >&2
    exit 1
  fi
  echo "[install] Installing Ubuntu packages: curl jq ffmpeg"
  sudo apt-get update
  sudo apt-get install -y curl jq ffmpeg
elif [[ -t 0 && -t 1 ]]; then
  echo "[install] Refreshing Ubuntu packages: curl jq ffmpeg"
  sudo apt-get update
  sudo apt-get install -y --only-upgrade curl jq ffmpeg
else
  echo "[install] Non-interactive session detected; skipping Ubuntu package refresh."
  echo "[install] To refresh Ubuntu packages later, run:"
  echo "sudo apt-get update && sudo apt-get install -y --only-upgrade curl jq ffmpeg"
fi

install_latest_ytdlp
install -m 0755 "$SOURCE_SCRIPT" "$TARGET_SCRIPT"

echo "[install] Installed ytb to ${TARGET_SCRIPT}"

case ":${PATH}:" in
  *":${TARGET_DIR}:"*)
    echo "[install] ${TARGET_DIR} is already in PATH."
    ;;
  *)
    cat <<EOF
[install] ${TARGET_DIR} is not currently in PATH.
[install] On Ubuntu, add this to ~/.profile if it is missing:

if [ -d "\$HOME/.local/bin" ] ; then
    PATH="\$HOME/.local/bin:\$PATH"
fi

[install] Then run:
source ~/.profile
EOF
    ;;
esac

echo "[install] Next step: run 'ytb <youtube-url>'"
