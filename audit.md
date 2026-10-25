# Акт аудита · ops-03 · закрытие доступа kozlov

Дата: 25.10.2026. Начало: 16:23, окончание: ___.
Исполнитель: Эрик (учётная запись `erik`). Заявка: SEC-2026-0088. Регламент: РД-05.
Сведения собраны до первой команды, изменяющей сервер (`sudo bash audit-user.sh kozlov | tee audit-before.txt`).

## Сведения до изменений

- Группы: `id kozlov` → `uid=1001(kozlov) gid=1003(kozlov) groups=1003(kozlov),27(sudo),1001(devops),1002(finance)`
- Права sudo: (1) группа `sudo`; (2) личный файл `/etc/sudoers.d/90-kozlov` с правилом `ALL=(ALL) NOPASSWD: ALL` (запрещено ПД-02, п. 2). Проверено: `grep -rnw kozlov /etc/sudoers /etc/sudoers.d`, `sudo -l -U kozlov`.
- Процессы (`ps -o pid,ppid,lstart,cmd -u kozlov`, `/proc/PID/cwd`, `ss -ltnp`): 

| PID | Командная строка | Родитель | Текущий каталог | Запущен | Порт |
|---|---|---|---|---|---|
| 3296 | `/bin/bash /home/kozlov/.local/bin/sync-tunnel.sh` | 1 | /home/erik | 25.10.2026 15:47:21 | — |
| 3299 | `python3 -m http.server 8000 --directory /home/kozlov` | 1 | /home/erik | 25.10.2026 15:47:21 2026 | 8000/tcp |

- Файлы вне домашнего каталога (`find / -xdev -user kozlov -not -path '/home/kozlov*'`):
  - `/srv/share/db_dump_2026-09-28.sql`
  - `/srv/share/db_dump_2026-09-28.sql`
  - `/srv/devops`
  - `/srv/devops/deploy`
  - `/srv/devops/deploy/deploy.sh`
  - `/srv/devops/deploy/inventory.ini`
  - `/srv/devops/keys`
  - `/srv/devops/keys/prod_deploy_key`

  
- setuid вне пакетов: `/var/tmp/.cache-k/kbash` (`find / -xdev -perm -4000`, `dpkg -S`).
