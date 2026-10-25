#!/bin/bash
# audit-user.sh — сведения о доступе пользователя к серверу.
#   sudo bash audit-user.sh имя
# Ничего не изменяет, только печатает.
set -u
U=${1:-}
[ -n "$U" ] || { echo "Использование: sudo bash $0 имя"; exit 2; }
[ "$(id -u)" = 0 ] || { echo "Запустите через sudo"; exit 1; }
id "$U" >/dev/null 2>&1 || { echo "Нет пользователя $U"; exit 1; }
H=$(getent passwd "$U" | cut -d: -f6)
BK=/var/backups/offboarding/$U

section() { echo; echo "== $*"; }

section "Учётная запись"
getent passwd "$U"
passwd -S "$U"
echo "-- срок действия (chage):"
chage -l "$U" | grep -E 'Account expires|Password expires'
echo "-- оболочка: $(getent passwd "$U" | cut -d: -f7)"

section "Группы"
id "$U"

section "Права sudo"
echo "-- упоминания $U в /etc/sudoers и /etc/sudoers.d:"
grep -rnsw -- "$U" /etc/sudoers /etc/sudoers.d || echo "(нет)"
echo "-- sudo -l -U:"
sudo -l -U "$U" 2>&1
echo "-- участник групп sudo/admin/wheel:"
for g in sudo admin wheel; do
  getent group "$g" | grep -qw -- "$U" && echo "$U входит в группу $g"
done

section "Процессы"
PIDS=$(pgrep -u "$U")
if [ -z "$PIDS" ]; then
  echo "(процессов нет)"
else
  for p in $PIDS; do
    echo "--- PID $p"
    ps -o pid,ppid,lstart,cmd -p "$p" | tail -1
    echo "cwd: $(readlink /proc/$p/cwd 2>/dev/null)"
    echo "exe: $(readlink /proc/$p/exe 2>/dev/null)"
  done
  echo "--- слушающие порты процессов $U:"
  ss -ltnpH 2>/dev/null | grep -E "pid=($(echo $PIDS | tr ' ' '|'))[,)]" || echo "(нет)"
fi

section "Файлы вне $H"
# все файлы пользователя на корневом разделе, кроме домашнего каталога и копии аудита
find / -xdev -user "$U" \
  -not -path "$H" -not -path "$H/*" \
  -not -path "$BK" -not -path "$BK/*" \
  -ls 2>/dev/null
echo "-- другие разделы (без -xdev, исключая /proc /sys /dev /run):"
find / -user "$U" \
  -not -path "$H/*" -not -path "$BK/*" \
  -not -path '/proc/*' -not -path '/sys/*' -not -path '/dev/*' -not -path '/run/*' \
  -not -path "$H" 2>/dev/null | head -50
echo "-- файлы группы $U (если есть одноимённая группа), вне дома:"
find / -xdev -group "$U" -not -user "$U" -not -path "$H/*" 2>/dev/null | head -50
echo "-- в общих каталогах (/srv/share, /tmp, /var/tmp), включая скрытые:"
find /srv/share /tmp /var/tmp -user "$U" 2>/dev/null
echo "-- дампы и ключи в общих местах:"
find /srv /tmp /var/tmp -xdev \( -iname 'db_dump*' -o -iname '*.sql' -o -iname 'id_*' -o -iname '*key*' \) 2>/dev/null

section "Программы с setuid вне пакетов системы"
find / -xdev -perm -4000 -type f 2>/dev/null | sort | while read -r f; do
  if dpkg -S "$f" >/dev/null 2>&1; then
    continue                       # файл принадлежит пакету
  fi
  echo "ВНЕ ПАКЕТОВ: $(stat -c '%A %U:%G %s байт  %n' "$f")"
done
echo "-- (setuid-файлы, принадлежащие $U, независимо от пакетов):"
find / -xdev -perm -4000 -user "$U" -type f 2>/dev/null
echo "-- (setgid вне пакетов не проверяется; при необходимости: find / -xdev -perm -2000 -type f)"
