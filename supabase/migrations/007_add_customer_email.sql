-- ════════════════════════════════════════════════════════════════
-- 007_add_customer_email.sql
-- Опциональное поле email в заказах. Если клиент его указал —
-- сайт отправит ему подтверждение заказа на этот адрес.
--
-- Запуск: Supabase → SQL Editor → New query → вставить → Run.
-- Безопасно перезапускать.
-- ════════════════════════════════════════════════════════════════

-- 1. Добавить колонку (если нет)
alter table orders add column if not exists customer_email text default '';

-- 2. Снять старые констрейнты (для повторных запусков)
alter table orders drop constraint if exists customer_email_format;

-- 3. Жёсткая валидация формата: либо пусто, либо корректный email
alter table orders add constraint customer_email_format
  check (
    customer_email = '' or
    (customer_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(customer_email) <= 200)
  );

-- 4. Проверка: должно показать колонки orders включая customer_email
select column_name, data_type
from information_schema.columns
where table_name = 'orders' and column_name = 'customer_email';
