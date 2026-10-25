# Паспорт сервера · ops-03 (учебная копия, ВМ `debian`) · 25.10.2026

Составлен до первой команды, которая изменяет сервер. Исполнитель: Эрик (работа выполняется одним человеком).
Стенд развёрнут командой `sudo bash ~/Downloads/offboarding-stand.sh`, вывод: `ops-03: kozlov has 3 processes`.
Команды, которым не хватило прав, и их повтор через `sudo` описаны в `runbook.md`, раздел «Что пошло не так».

| Сведение | Команда | Что показала |
|---|---|---|
| Версия системы | `cat /etc/os-release` | Debian GNU/Linux 13 (trixie), `DEBIAN_VERSION_FULL=13.6` |
| Версия ядра | `uname -r` | `6.12.107+deb13-amd64` |
| Тип машины, архитектура | `hostnamectl` | имя хоста `debian`; виртуализация Oracle (VirtualBox); архитектура x86-64 |
| Память | `free -h` | ОЗУ 3.8 GiB (свободно 3.4 GiB), swap 2.0 GiB |
| Процессор | не снято | `lscpu` и `nproc` не выполнялись (дописать) |
| Разделы и их заполнение | `df -h` | `/` (debian--vg-root) 37G, занято 1.1G (4%); `/boot` (sda1) 943M, занято 62M (8%); `/tmp` tmpfs 2.0G, 0% |
| Группы пользователей из задания | `id kozlov; id orlova; id lebedeva` | kozlov: uid 1001, группы kozlov, sudo (27), devops (1001), finance (1002)<br>orlova: uid 1002, группы orlova, devops<br>lebedeva: uid 1003, группы lebedeva, finance |
| Учётные записи (оболочка, домашний каталог) | `getent passwd kozlov orlova lebedeva` | у всех троих оболочка `/bin/bash`, домашний каталог `/home/<имя>` |
| Состав групп | `getent group devops finance sudo` | devops: kozlov, orlova<br>finance: kozlov, lebedeva<br>sudo: erik, kozlov |
| Статус пароля kozlov | `passwd -S kozlov` | отказ: `You may not view or modify password information for kozlov.` Статус пароля пока не снят (нужен `sudo`) |
| Срок действия учётной записи kozlov | `sudo chage -l kozlov` | пароль не истекает (`never`), учётная запись не истекает (`Account expires: never`) |
| Права sudo kozlov | `sudo -l -U kozlov` | `(ALL : ALL) ALL` (из группы sudo) и `(ALL) NOPASSWD: ALL` (личное правило) |
| Файл с личным правилом sudo | `sudo grep -rn kozlov /etc/sudoers /etc/sudoers.d` | `/etc/sudoers.d/90-kozlov:1: kozlov ALL=(ALL) NOPASSWD: ALL` |
| Процессы kozlov | `ps -u kozlov -o pid,ppid,lstart,cmd` | PID 1578, родитель 1, с 13:43:20: `/bin/bash /home/kozlov/.local/bin/sync-tunnel.sh`<br>PID 1580, родитель 1, с 13:43:20: `python3 -m http.server 8000 --directory /home/kozlov`<br>дочерний `sleep 30` (родитель 1578; каждый раз новый PID: 1725, затем 2101) |
| Все процессы и их владельцы | `ps -eo user,pid,ppid,lstart,cmd --sort=user` | кроме kozlov: системные процессы root, dhcpcd, systemd-timesyncd, dbus (message+), сессия erik (ssh, `script -a /home/erik/session.log`); процессов orlova и lebedeva нет |
| Открытые порты | `sudo ss -ltnp` | `0.0.0.0:22` sshd (pid 747); `[::]:22` sshd; `0.0.0.0:8000` python3 (pid 1580, процесс kozlov) |
| Каталоги из раздела 1.3 и права | `ls -ld /srv/devops /srv/finance /srv/share /home/kozlov` | `/home/kozlov` `drwx------` kozlov:kozlov<br>`/srv/devops` `drwxrws---` kozlov:devops<br>`/srv/finance` `drwxrws---` lebedeva:finance<br>`/srv/share` `drwxrwxrwt` root:root |
| Содержимое `/srv/devops` | `sudo ls -lR /srv/devops` | `deploy/` и `keys/` — `drwxrws---` kozlov:devops<br>`deploy.sh` `-rwxr-x---` kozlov:devops<br>`inventory.ini` `-rw-r-----` kozlov:devops<br>`keys/prod_deploy_key` `-rw-------` kozlov:devops |
| Содержимое `/srv/finance`, `/srv/share`, `/home/kozlov` | `sudo ls -la /srv/finance /srv/share /home/kozlov` | `/srv/finance/payments-2026-09.csv` `-rw-rw----` lebedeva:finance<br>`/srv/share/db_dump_2026-09-28.sql` `-rw-r--r--` kozlov:kozlov, 24774 байт<br>`/home/kozlov`: `.ssh/` (`drwx------`), `notes.txt` (`-rw-------`, 68 байт), `.local/`, `.bashrc`, `.bash_logout`, `.profile` |

## Что показалось неправильным

Факты, которые отличаются от стандарта компании или от требований задания. Ничего не исправлялось.

- Система Debian 13 (trixie), а не Ubuntu 24.04, как в стандарте компании и в описании стенда; имя хоста `debian`, а не `ops-03`. Потому что у меня установлен Debian и я сделал связанный клон чистой установки.
- У kozlov личное правило `/etc/sudoers.d/90-kozlov` вида `ALL=(ALL) NOPASSWD: ALL`. ПД-02 (п. 2) запрещает такие правила для отдельных сотрудников. Кроме него права root даёт группа `sudo`: источников два.
- kozlov состоит в группе `finance`, хотя платёжные документы бухгалтерии не относятся к его роли (ПД-02, п. 1: права только по необходимости).
- Срок действия учётной записи kozlov не ограничен (`Account expires: never`), статус пароля не снят.
- Два фоновых процесса kozlov запущены не из пользовательской сессии (родитель PID 1). `http.server` слушает `0.0.0.0:8000` и по сети отдаёт весь каталог `/home/kozlov`, где лежат `.ssh` и `notes.txt`.
- `sync-tunnel.sh` в списке процессов выглядит как цикл с `sleep 30`; что именно он делает, надо смотреть по самому файлу и `/proc/PID`.
- В общей папке `/srv/share` лежит `db_dump_2026-09-28.sql` (по имени и размеру — дамп базы) с правами 644: его может прочитать любой пользователь сервера. ПД-02 (п. 3) не разрешает хранить секреты в общих папках. Содержимое не открывалось.
- В домашнем каталоге kozlov лежат `notes.txt` и `.ssh`. ПД-02 (п. 3) запрещает секреты в заметках и домашних каталогах. Содержимое `notes.txt` пока не просматривалось: нужно проверить при аудите, значения в акт не записывать.
- `/srv/devops` целиком принадлежит kozlov, включая `prod_deploy_key` (режим 600). Пока владелец не сменён, orlova ключ прочитать не сможет.
