# ТЗ № 3 · Закрытие доступа уволенного администратора и аудит сервера ops-03

Курсовая работа по дисциплине ОП.05 «Операционные системы и среды».
Компания «Пятый склад», группа эксплуатации.

| | |
|---|---|
| Практикант 1 |Эрик, GitHub @SpideErik |
| Сервер | ops-03, Debian 13 |
| Итог приёмки | 17 из 17 (файл [`acceptance.txt`](acceptance.txt)) |

## Состав репозитория

| Файл | Что в нём |
|---|---|
| [`server-passport.md`](server-passport.md) | паспорт сервера до изменений |
| [`runbook.md`](runbook.md) | журнал работ: время, кто из пары, команда, результат, номер требования |
| [`audit.md`](audit.md) | акт аудита: находки, действия, что сменить вне сервера |
| [`audit-user.sh`](audit-user.sh) | скрипт: для имени пользователя из аргумента печатает группы, правила sudo, процессы, файлы вне домашнего каталога. Проверка: стенд заново, sudo bash audit-user.sh kozlov находит всё, что вошло в акт. |
| [`offboard-kozlov.sh`](offboard-kozlov.sh) | скрипт: для прекращения доступа пользователя kozlov, составлен по журналу работ |
| [`acceptance.txt`](acceptance.txt) | вывод приёмки после финального прогона |
| [`audit-before.txt`](audit-before.txt) | вывод `audit-user.sh kozlov` до offboarding |
| [`audit-after.txt`](audit-after.txt) | вывод `audit-user.sh kozlov` после offboarding |
| [`screenshots/`](screenshots/) | снимки из раздела 4.1 ТЗ |

## Как воспроизвести

Всё выполняется в виртуальной машине с Debian. Скрипты стенда и приёмки лежат в `~/Downloads`, остальные скрипты в корне репозитория.


### 1. Развернуть стенд заново
```bash
sudo bash ~/Downloads/offboarding-stand.sh
```

### 2. Аудит до изменений
```bash
sudo bash audit-user.sh kozlov | tee audit-before.txt
```

### 3. Закрыть доступ (решение, повторяет runbook.md)
```bash
sudo bash offboard-kozlov.sh
```

### 4. Аудит после изменений
```bash
sudo bash audit-user.sh kozlov | tee audit-after.txt
```

### 5. Приёмка
```bash
sudo bash ~/Downloads/offboarding-acceptance.sh | tee acceptance.txt
```

## Финальная проверка на чистой VM

![](screenshots/04-final-test.png)


Нейросеть использовалась для: 
* оформления таблиц
* сотавления команд поиска, особенно нахождения не найденных по setuid и по владельцу
* составления скриптов по командам из runbook
