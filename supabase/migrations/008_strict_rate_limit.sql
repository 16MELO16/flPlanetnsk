-- ════════════════════════════════════════════════════════════════
-- 008_strict_rate_limit.sql
-- Усиление защиты после отключения Cloudflare:
--   • Жёсткий rate-limit на заказы (30 сек cooldown, 3 заказа/час).
--   • Жёсткий rate-limit на заявки доступа (3 заявки/сутки — уже было).
--   • Таблица security_log для логирования подозрительных событий.
--   • Триггер, фиксирующий попытки превышения лимитов.
--
-- Запуск: Supabase → SQL Editor → New query → вставить → Run.
-- Безопасно перезапускать.
-- ════════════════════════════════════════════════════════════════

-- ─── 1. Таблица для логирования подозрительной активности ─────
create table if not exists security_log (
  id          uuid        primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  event       text        not null,      -- тип события: 'rate_limit_too_fast', 'rate_limit_hourly', и т.п.
  table_name  text        not null,      -- какая таблица была затронута
  identifier  text,                       -- телефон, email или другой идентификатор
  details     jsonb       default '{}'   -- дополнительная информация
);

create index if not exists security_log_created_at_idx on security_log (created_at desc);
create index if not exists security_log_event_idx      on security_log (event);

alter table security_log enable row level security;

-- Логи может смотреть только админ
drop policy if exists "Authenticated read security log" on security_log;
create policy "Authenticated read security log"
  on security_log for select
  to authenticated using (true);

-- Писать в лог — только триггер (через security definer), напрямую нельзя
drop policy if exists "No direct insert security log" on security_log;

-- ─── 2. Обновлённый rate-limit на orders ───────────────────────
create or replace function check_order_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recent_count int;
  last_at      timestamptz;
begin
  -- Анти-флуд: между двумя заказами с одного номера ≥ 30 секунд (раньше было 10)
  select max(created_at) into last_at
  from orders
  where customer_phone = new.customer_phone;

  if last_at is not null and now() - last_at < interval '30 seconds' then
    -- Логируем попытку
    insert into security_log (event, table_name, identifier, details)
    values ('rate_limit_too_fast', 'orders', new.customer_phone,
            jsonb_build_object('last_at', last_at, 'attempted_at', now()));

    raise exception 'rate_limit_too_fast'
      using errcode = '22023',
            hint    = 'Подождите 30 секунд перед следующим заказом.';
  end if;

  -- Анти-спам: не более 3 заказов с одного номера за час (раньше было 5)
  select count(*) into recent_count
  from orders
  where customer_phone = new.customer_phone
    and created_at > now() - interval '1 hour';

  if recent_count >= 3 then
    insert into security_log (event, table_name, identifier, details)
    values ('rate_limit_hourly', 'orders', new.customer_phone,
            jsonb_build_object('count', recent_count));

    raise exception 'rate_limit_hourly'
      using errcode = '22023',
            hint    = 'Превышен лимит заказов с этого номера. Попробуйте через час или позвоните нам.';
  end if;

  return new;
end;
$$;

drop trigger if exists orders_rate_limit on orders;
create trigger orders_rate_limit
  before insert on orders
  for each row execute function check_order_rate_limit();

-- ─── 3. Логирование для admin_requests (если таблица есть) ────
do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'admin_requests'
  ) then
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
        insert into security_log (event, table_name, identifier, details)
        values ('rate_limit_daily', 'admin_requests', new.email,
                jsonb_build_object('count', recent_count));

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

    raise notice 'admin_requests: rate-limit обновлён с логированием';
  end if;
end $$;

-- ─── 4. Проверка ──────────────────────────────────────────────
-- Должен показать все триггеры и новую таблицу
select 'security_log table exists' as status, count(*) as columns_count
from information_schema.columns
where table_name = 'security_log';
