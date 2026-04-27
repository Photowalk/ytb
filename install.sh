#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="${SCRIPT_DIR}/bin/ytb"

choose_target_dir() {
  if [[ -n "${YTB_INSTALL_DIR:-}" ]]; then
    printf '%s' "$YTB_INSTALL_DIR"
    return 0
  fi

  if [[ "${EUID}" -eq 0 ]]; then
    printf '/usr/local/bin'
    return 0
  fi

  printf '%s/.local/bin' "$HOME"
}

run_apt_get() {
  if [[ "${EUID}" -eq 0 ]]; then
    apt-get "$@"
    return 0
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    echo "[install] ERROR: sudo is required to install Ubuntu packages." >&2
    exit 1
  fi

  sudo apt-get "$@"
}

ensure_bootstrap_dependencies() {
  local missing=()
  local dep

  for dep in curl jq ffmpeg; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing+=("$dep")
    fi
  done

  if ! command -v ffprobe >/dev/null 2>&1; then
    missing+=("ffprobe")
  fi

  if ((${#missing[@]} == 0)); then
    return 0
  fi

  echo "[install] Installing Ubuntu packages required by ytb: curl jq ffmpeg"
  run_apt_get update
  run_apt_get install -y curl jq ffmpeg
}

TARGET_DIR="$(choose_target_dir)"
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

ensure_bootstrap_dependencies
mkdir -p "$TARGET_DIR"

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
[install] Add this to your shell profile:

export PATH="${TARGET_DIR}:\$PATH"
EOF
    ;;
esac

echo "[install] Next step: run 'ytb \"https://www.youtube.com/watch?v=VIDEO_ID\"'"
