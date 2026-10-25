# Журнал работ · ТЗ № 3 · ops-03, закрытие доступа kozlov

Пишется по ходу работы, а не в конце. Ошибки и откаты тоже записываются.
Этап: сбор сведений для паспорта сервера (до первых изменений). Работа выполняется одним человеком.

| Время | Кто | Команда | Результат | Требование | Зачем |
|---|---|---|---|---|---|
| 13:05 | Эрик | `script -a ~/session.log` | запись сеанса терминала идёт в `/home/erik/session.log` | — | сохранить вывод команд для журнала и акта |
| 13:07 | Эрик | `sudo bash ~/Downloads/offboarding-stand.sh` | `ops-03: kozlov has 3 processes` | — | развернуть копию сервера |
| 13:10 | Эрик | `cat /etc/os-release` | Debian GNU/Linux 13 (trixie) | — | версия системы для паспорта |
| 13:11 | Эрик | `uname -r` | `6.12.107+deb13-amd64` | — | версия ядра для паспорта |
| 13:12 | Эрик | `hostnamectl` | хост `debian`, VirtualBox, x86-64 | — | тип машины и архитектура |
| 13:15 | Эрик | `id kozlov; id orlova; id lebedeva` | kozlov в группах sudo, devops, finance; orlova в devops; lebedeva в finance | 2.1.2 | какие группы нужно убрать у kozlov |
| 13:17 | Эрик | `getent passwd kozlov orlova lebedeva` | у всех троих оболочка `/bin/bash`, домашние `/home/<имя>` | 2.1.1 | текущая оболочка kozlov до смены на nologin |
| 13:18 | Эрик | `getent group devops finance sudo` | devops: kozlov, orlova; finance: kozlov, lebedeva; sudo: erik, kozlov | 2.1.2 | состав групп до изменений |
| 13:20 | Эрик | `passwd -S kozlov` | ошибка: `You may not view or modify password information for kozlov.` | 2.1.1 | статус пароля; не получилось без sudo, см. ниже |
| 13:21 | Эрик | `chage -l kozlov` | ошибка: `chage: Permission denied.` | 2.1.1 | срок действия учётной записи; не получилось без sudo, см. ниже |
| 13:23 | Эрик | `sudo -l -U kozlov` | `(ALL : ALL) ALL` и `(ALL) NOPASSWD: ALL` | 2.1.2 | какие права root есть у kozlov |
| 13:25 | Эрик | `sudo grep -rn kozlov /etc/sudoers /etc/sudoers.d` | найдено `/etc/sudoers.d/90-kozlov:1: kozlov ALL=(ALL) NOPASSWD: ALL` | 2.1.2 | найти файл с личным правилом sudo |
| 13:28 | Эрик | `ps -eo user,pid,ppid,lstart,cmd --sort=user` | кроме системных и erik есть 3 процесса kozlov (PID 1578, 1580, 1725) | 2.1.3 | список процессов и владельцев |
| 13:30 | Эрик | `ps -u kozlov -o pid,ppid,lstart,cmd` | `sync-tunnel.sh` (1578), `http.server 8000` (1580), дочерний `sleep 30`; родитель обоих основных процессов — PID 1 | 2.1.3 | записать, что делают процессы, до завершения |
| 13:32 | Эрик | `sudo ss -ltnp` | порт 22 (sshd) и `0.0.0.0:8000` (python3, pid 1580) | 2.1.3 | найти открытые порты kozlov |
| 13:35 | Эрик | `df -h` | `/` 37G, занято 4%; `/boot` 943M, занято 8% | — | заполнение разделов для паспорта |
| 13:36 | Эрик | `free -h` | ОЗУ 3.8 GiB, swap 2.0 GiB | — | память для паспорта |
| 13:38 | Эрик | `ls -ld /srv/devops /srv/finance /srv/share /home/kozlov` | `/srv/devops` kozlov:devops `drwxrws---`; `/srv/finance` lebedeva:finance `drwxrws---`; `/srv/share` `drwxrwxrwt`; `/home/kozlov` `drwx------` | 2.2.1 | владельцы и права каталогов до передачи |
| 13:40 | Эрик | `ls -lR /srv/devops` | ошибка: `Permission denied` | 2.2.1 | содержимое `/srv/devops`; не получилось без sudo, см. ниже |
| 13:41 | Эрик | `sudo ls -lR /srv/devops` | `deploy.sh` 750, `inventory.ini` 640, `prod_deploy_key` 600, все kozlov:devops | 2.2.1 | права файлов до смены владельца (сравнить после) |
| 13:44 | Эрик | `ls -la /srv/finance /srv/share /home/kozlov` | `/srv/share` показан; `/srv/finance` и `/home/kozlov`: `Permission denied` | 2.2.2, 2.3.2, 2.3.3 | содержимое каталогов; не получилось без sudo, см. ниже |
| 13:46 | Эрик | `sudo ls -la /srv/finance /srv/share /home/kozlov` | в `/srv/share` дамп `db_dump_2026-09-28.sql` (644, kozlov); в `/home/kozlov` есть `notes.txt` и `.ssh`; в `/srv/finance` файл `payments-2026-09.csv` | 2.2.2, 2.3.2, 2.3.3 | найти дамп, заметки и ключи; состояние каталога бухгалтерии |
| 13:50 | Эрик | `sudo chage -l kozlov` | пароль не истекает, `Account expires: never` | 2.1.1 | срок действия учётной записи kozlov до блокировки |
| 13:55 | Эрик | `sudo find / -xdev -user kozlov -not -path '/home/kozlov*' -ls 2>/dev/null` | 7 объектов: `/srv/devops` с `deploy`, `deploy.sh`, `inventory.ini`, `keys`, `prod_deploy_key` и дамп `/srv/share/db_dump_2026-09-28.sql` | 2.3.1 | найти все файлы kozlov вне домашнего каталога |
| 13:58 | Эрик | `sudo find / -xdev -perm -4000 -type f 2>/dev/null \| while read f; do dpkg -S "$f" >/dev/null 2>&1 \|\| echo "НЕ ИЗ ПАКЕТА: $f"; done` | вывод пустой: у всех файлов с setuid есть пакет | 2.3.4 | найти программы с setuid не из пакетов системы |
| 14:00 | Эрик | `sudo find / -xdev -perm -4000 -type f 2>/dev/null` | 10 файлов: `dbus-daemon-launch-helper`, `ssh-keysign`, `passwd`, `chsh`, `gpasswd`, `newgrp`, `umount`, `chfn`, `sudo`, `su`, `mount`; все системные | 2.3.4 | проверить, что поиск работает и пустой результат не ошибка |
| 14:03 | Эрик | `sudo find / -xdev -type f -perm /111 -newermt "2026-10-25 13:40" -not -path "/home/*" -not -path "/srv/*" -not -path "/var/lib/*" -not -path "/var/log/*" -ls 2>/dev/null` | найден `/var/tmp/.cache-k/kbash`, владелец root, `-rwxr-xr-x`, 1298416 байт, без бита setuid | 2.3.4 | найти оставленные программы, которых не нашёл поиск по setuid и по владельцу |
| 16:24 | Эрик | `sudo bash audit-user.sh kozlov \| tee audit-before.txt` | Сняты сведения до изменений: группы devops, finance, sudo; правило sudo NOPASSWD; 2 процесса (один слушает порт 8000); файлы вне дома в /srv и /srv/share; setuid-файл вне пакетов в /var/tmp/.cache-k | 2.1.2, 2.1.3, 2.3.1, 2.3.4 | Собрать сведения до блокировки: после неё часть данных не получить; вывод сохранён в audit-before.txt для акта |

## Что пошло не так и как исправили

- `passwd -S kozlov` без `sudo` отказал в доступе: статус пароля чужой учётной записи показывает только root. Повторно с `sudo` команда не запускалась, поэтому статус пароля (заблокирован или нет) пока не снят. Нужно выполнить `sudo passwd -S kozlov` до блокировки и дописать результат в паспорт.
- `chage -l kozlov` без `sudo` дала `Permission denied` (читает `/etc/shadow`). Повторил с `sudo` в конце сбора, в 13:50: срок действия не ограничен.
- `ls -lR /srv/devops` без `sudo` дала `Permission denied`: каталог `drwxrws---` kozlov:devops, а erik не входит в группу devops. Повторил с `sudo` (13:41). Своим пользователем чужие закрытые каталоги читать не нужно.
- `ls -la /srv/finance /srv/share /home/kozlov` без `sudo` не открыла `/srv/finance` (группа finance) и `/home/kozlov` (режим 700). Повторил с `sudo` (13:46). Каталог `/srv/share` открывается всем (`drwxrwxrwt`).
- Команды чтения закрытых каталогов и файлов выполняются только с `sudo`. Менять права ради чтения нельзя: паспорт снимает состояние «как было».
- Поиск `find -perm -4000` с проверкой `dpkg -S` ничего не нашёл. Причина: оставленная копия оболочки `/var/tmp/.cache-k/kbash` не имеет бита setuid (он сбрасывается при смене владельца на root), а владелец root, поэтому поиск по `-user kozlov` её тоже не находит. Нашёл её поиском новых исполняемых файлов после запуска стенда (14:03).
