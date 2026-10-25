#!/bin/bash
# offboard-kozlov.sh — закрытие доступа kozlov на ops-03 (ТЗ № 3), повторяет runbook.md.
# Запуск на свежем стенде: sudo bash offboard-kozlov.sh
# Перед ним: sudo bash audit-user.sh kozlov | tee audit-before.txt
set -eu
[ "$(id -u)" = 0 ] || { echo "Запустите через sudo"; exit 1; }
U=kozlov
NEW=orlova
B=/var/backups/offboarding/$U
step() { echo; echo "== $*"; }

step "0. Копия и снимки до изменений"
install -d -m 700 -o root -g root "$B"
ls -lR /srv/devops > "$B/devops-ls-before.txt"
cp -a "/etc/sudoers.d/90-$U" "$B/" 2>/dev/null || true
{
  ps -o pid,ppid,lstart,cmd -u "$U"
  for p in $(pgrep -u "$U" || true); do
    echo "PID $p cwd=$(readlink /proc/$p/cwd) exe=$(readlink /proc/$p/exe)"
  done
  ss -ltnp
} > "$B/processes.txt"

step "1. Блокировка входа (пароль, срок, оболочка)"
usermod -L "$U"
usermod -e 1970-01-02 "$U"
usermod -s /usr/sbin/nologin "$U"

step "2. Группы и sudo"
for g in devops finance sudo; do gpasswd -d "$U" "$g" 2>/dev/null || true; done
rm -f "/etc/sudoers.d/90-$U"

step "3. Процессы: сначала SIGTERM, затем SIGKILL"
pkill -TERM -u "$U" || true
sleep 2
pkill -KILL -u "$U" || true
sleep 1

step "4. Передача /srv/devops"
chown -R "$NEW":devops /srv/devops
ls -lR /srv/devops > "$B/devops-ls-after.txt"

step "5. Файлы в копию"
sha256sum /srv/share/db_dump_2026-09-28.sql > "$B/db_dump.sha256"
mv /srv/share/db_dump_2026-09-28.sql "$B/"
mv "/home/$U/notes.txt" "$B/"
mkdir -p "$B/.ssh"
mv "/home/$U/.ssh/authorized_keys" "$B/.ssh/"

step "6. Посторонняя копия bash"
if [ -e /var/tmp/.cache-k/kbash ]; then
  { stat /var/tmp/.cache-k/kbash; sha256sum /var/tmp/.cache-k/kbash; } > "$B/kbash.stat"
  rm -rf /var/tmp/.cache-k
fi

step "7. Права на копию"
chown -R root:root "$B"
chmod 700 "$B"

step "Готово. Дальше: audit-user.sh kozlov | tee audit-after.txt и приёмка"
