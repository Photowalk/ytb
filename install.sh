#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="${SCRIPT_DIR}/bin/ytb"
TARGET_DIR="${HOME}/.local/bin"
TARGET_SCRIPT="${TARGET_DIR}/ytb"

if [[ ! -f "$SOURCE_SCRIPT" ]]; then
  echo "[install] ERROR: ${SOURCE_SCRIPT} was not found." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
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
