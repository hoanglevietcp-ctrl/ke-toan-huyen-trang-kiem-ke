#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8765}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "Chưa có cloudflared. Cài bằng: brew install cloudflared"
  exit 1
fi

cleanup() {
  if [[ -n "${tunnel_pid:-}" ]]; then
    kill "$tunnel_pid" 2>/dev/null || true
  fi
  if [[ -n "${server_pid:-}" ]]; then
    kill "$server_pid" 2>/dev/null || true
  fi
  rm -f "${tunnel_log:-}"
}
trap cleanup EXIT INT TERM

echo "Đang mở trang tại http://127.0.0.1:$PORT"
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$ROOT_DIR" >/dev/null 2>&1 &
server_pid=$!

sleep 1
if ! kill -0 "$server_pid" 2>/dev/null; then
  echo "Không thể mở web server ở cổng $PORT. Thử lại với: PORT=8766 pnpm dev"
  exit 1
fi

echo "Đang tạo link HTTPS cho điện thoại…"
tunnel_log="$(mktemp)"
cloudflared tunnel --url "http://127.0.0.1:$PORT" >"$tunnel_log" 2>&1 &
tunnel_pid=$!

for _ in {1..30}; do
  phone_url="$(grep -Eo 'https://[-a-z0-9]+\.trycloudflare\.com' "$tunnel_log" | head -n 1 || true)"
  if [[ -n "$phone_url" ]]; then
    printf '\n============================================================\n'
    printf ' MỞ LINK NÀY TRÊN ĐIỆN THOẠI:\n\n %s\n' "$phone_url"
    printf '\n Máy tính phải để lệnh pnpm dev đang chạy trong lúc sử dụng.\n'
    printf ' Nhấn Control + C để tắt.\n'
    printf '============================================================\n\n'
    wait "$tunnel_pid"
    exit $?
  fi
  if ! kill -0 "$tunnel_pid" 2>/dev/null; then
    echo "Không thể tạo link HTTPS:"
    cat "$tunnel_log"
    exit 1
  fi
  sleep 1
done

echo "Tạo link HTTPS quá lâu. Hãy kiểm tra kết nối Internet rồi chạy lại pnpm dev."
exit 1
