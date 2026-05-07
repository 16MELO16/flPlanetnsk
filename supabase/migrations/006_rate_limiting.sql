-- ════════════════════════════════════════════════════════════════
-- 006_rate_limiting.sql
-- Защита от спама и атак: триггеры rate-limit на orders и admin_requests,
-- CHECK-констрейнты на длину/формат полей.
--
-- Запуск: Supabase → SQL Editor → New query → вставить → Run.
-- Безопасно перезапускать.
-- ════════════════════════════════════════════════════════════════

-- ─── 1. Констрейнты на orders ──────────────────────────────────
-- Снимаем старые если они есть, чтобы можно было перезапускать
alter table orders drop constraint if exists customer_name_length;
alter table orders drop constraint if exists customer_phone_format;
alter table orders drop constraint if exists customer_comment_length;
alter table orders drop constraint if exists items_size;

alter table orders add constraint customer_name_length
  check (char_length(customer_name) between 1 and 100);

alter table orders add constraint customer_phone_format
  check (customer_phone ~ '^[+0-9 ()\-]{6,30}$');

alter table orders add constraint customer_comment_length
  check (char_length(customer_comment) <= 2000);

-- Корзина не может быть гигантским JSON (защита от DoS)
alter table orders add constraint items_size
  check (jsonb_array_length(items) between 1 and 100);

-- ─── 2. Rate-limit триггер на orders ───────────────────────────
create or replace function check_order_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recent_count int;
  last_at timestamptz;
begin
  -- Анти-флуд: между двумя заказами с одного номера ≥ 10 секунд
  select max(created_at) into last_at
  from orders
  where customer_phone = new.customer_phone;

  if last_at is not null and now() - last_at < interval '10 seconds' then
    raise exception 'rate_limit_too_fast'
      using errcode = '22023',
            hint    = 'Подождите 10 секунд перед следующим заказом.';
  end if;

  -- Анти-спам: не более 5 заказов с одного номера за час
  select count(*) into recent_count
  from orders
  where customer_phone = new.customer_phone
    and created_at > now() - interval '1 hour';

  if recent_count >= 5 then
    raise exception 'rate_limit_hourly'
      using errcode = '22023',
            hint    = 'Превышен лимит заказов с одного номера. Попробуйте через час или позвоните нам.';
  end if;

  return new;
end;
$$;

drop trigger if exists orders_rate_limit on orders;
create trigger orders_rate_limit
  before insert on orders
  for each row execute function check_order_rate_limit();

-- ─── 3-4. Защита для admin_requests (если таблица существует) ─
-- Если миграция 003 ещё не запускалась — этот блок просто пропускается
-- и не валит всю миграцию.
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'admin_requests'
  ) then
    -- 3. Констрейнты на admin_requests
    alter table admin_requests drop constraint if exists req_name_length;
    alter table admin_requests drop constraint if exists req_email_format;
    alter table admin_requests drop constraint if exists req_reason_length;

    alter table admin_requests add constraint req_name_length
      check (char_length(full_name) between 1 and 100);

    alter table admin_requests add constraint req_email_format
      check (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(email) <= 200);

    alter table admin_requests add constraint req_reason_length
      check (char_length(reason) <= 1000);

    -- 4. Rate-limit функция и триггер на admin_requests
    create or replace function check_admin_request_rate_limit()
    returns trigger
    language plpgsql
    security definer
    set search_path = public
    as $func$
    declare
      recent_count int;
    begin
      select count(*) into recent_count
      from admin_requests
      where email = new.email
        and created_at > now() - interval '1 day';

      if recent_count >= 3 then
        raise exception 'rate_limit_daily'
          using errcode = '22023',
                hint    = 'С этого email уже отправлено несколько заявок. Попробуйте через 24 часа.';
      end if;
      return new;
    end;
    $func$;

    drop trigger if exists admin_requests_rate_limit on admin_requests;
    create trigger admin_requests_rate_limit
      before insert on admin_requests
      for each row execute function check_admin_request_rate_limit();

    raise notice 'admin_requests: ограничения и rate-limit триггер установлены';
  else
    raise notice 'Таблица admin_requests не найдена — пропускаем эту часть. Запустите миграцию 003, если нужна функция «Запросить доступ».';
  end if;
end $$;

-- ─── 5. Проверка ───────────────────────────────────────────────
-- Список всех триггеров на наших таблицах
select event_object_table as table_name, trigger_name, event_manipulation, action_timing
from information_schema.triggers
where event_object_table in ('orders', 'admin_requests', 'products')
order by event_object_table, trigger_name;
