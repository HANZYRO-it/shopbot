#!/usr/bin/env bash
# Установка бота на чистый сервер Ubuntu/Debian одной командой:  sudo bash install.sh
set -euo pipefail
cd "$(dirname "$0")"

if [ "$(id -u)" -ne 0 ]; then
  echo "Запустите от root:  sudo bash install.sh"
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo ">>> Устанавливаю Docker (официальный скрипт get.docker.com)..."
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker >/dev/null 2>&1 || true

# записывает KEY=value в .env, заменяя старое значение (безопасно для любых символов)
set_kv() {
  local key="$1" value="$2"
  { grep -v "^${key}=" .env || true; } > .env.tmp
  printf '%s=%s\n' "$key" "$value" >> .env.tmp
  mv .env.tmp .env
}

if [ ! -f .env ]; then
  cp .env.example .env
  echo
  read -rp "Токен бота от @BotFather: " TOKEN
  read -rp "Ваш Telegram ID (число, от @userinfobot): " ADMIN
  read -rp "Строка подключения к PostgreSQL (DATABASE_URL, см. DEPLOY_FREE.md): " DBURL
  read -rp "Название магазина: " SHOP
  read -rp "Символ валюты (например € или ₴ или \$): " CUR
  set_kv BOT_TOKEN "$TOKEN"
  set_kv ADMIN_IDS "$ADMIN"
  set_kv DATABASE_URL "$DBURL"
  [ -n "$SHOP" ] && set_kv SHOP_NAME "$SHOP"
  [ -n "$CUR" ] && set_kv CURRENCY "$CUR"
  chmod 600 .env
  echo ">>> Файл .env создан. Остальное (контакты, оплата) можно поправить: nano .env"
fi

echo ">>> Собираю и запускаю бота..."
docker compose up -d --build

echo
echo "Готово! Бот запущен и будет работать круглосуточно."
echo "  Логи:        docker compose logs -f"
echo "  Перезапуск:  docker compose restart"
echo "  Остановка:   docker compose down"
