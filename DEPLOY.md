# Развертывание на сервере

1. Установить Docker и Docker Compose.
2. Скопировать проект на сервер.
3. В корне проекта создать `.env` по примеру:

```bash
cp .env.example .env
nano .env
```

В корневом `.env` достаточно поменять `POSTGRES_PASSWORD`. Compose сам передаст эти же данные в backend как `DB_NAME`, `DB_USER`, `DB_PASSWORD`.

4. Запустить:

```bash
docker compose up -d
```

Сайт будет доступен на порту из `HTTP_PORT`, по умолчанию `80`.

Если Docker не пересобрал backend после обновления кода, запустить:

```bash
docker compose up -d --build
```

Проверка:

```bash
docker compose ps
curl http://localhost/api/health
```

Логи:

```bash
docker compose logs -f
```

Остановить:

```bash
docker compose down
```

Данные Postgres хранятся в docker volume `db_data`.
