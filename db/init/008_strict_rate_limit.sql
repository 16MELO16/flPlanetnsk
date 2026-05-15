-- 008_strict_rate_limit.sql

create table if not exists security_log (
  id          uuid        primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  event       text        not null,
  table_name  text        not null,
  identifier  text,
  details     jsonb       default '{}'
);

create index if not exists security_log_created_at_idx on security_log (created_at desc);
create index if not exists security_log_event_idx      on security_log (event);

create or replace function check_order_rate_limit()
returns trigger
language plpgsql
as $$
declare
  recent_count int;
  last_at      timestamptz;
begin
  select max(created_at) into last_at
  from orders
  where customer_phone = new.customer_phone;

  if last_at is not null and now() - last_at < interval '30 seconds' then
    insert into security_log (event, table_name, identifier, details)
    values ('rate_limit_too_fast', 'orders', new.customer_phone,
            jsonb_build_object('last_at', last_at, 'attempted_at', now()));

    raise exception 'rate_limit_too_fast'
      using errcode = '22023',
            hint    = 'Подождите 30 секунд перед следующим заказом.';
  end if;

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

do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'admin_requests'
  ) then
    create or replace function check_admin_request_rate_limit()
    returns trigger
    language plpgsql
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
  end if;
end $$;
