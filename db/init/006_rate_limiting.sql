-- 006_rate_limiting.sql

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

alter table orders add constraint items_size
  check (jsonb_array_length(items) between 1 and 100);

create or replace function check_order_rate_limit()
returns trigger
language plpgsql
as $$
declare
  recent_count int;
  last_at timestamptz;
begin
  select max(created_at) into last_at
  from orders
  where customer_phone = new.customer_phone;

  if last_at is not null and now() - last_at < interval '10 seconds' then
    raise exception 'rate_limit_too_fast'
      using errcode = '22023',
            hint    = 'Подождите 10 секунд перед следующим заказом.';
  end if;

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

do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'admin_requests'
  ) then
    alter table admin_requests drop constraint if exists req_name_length;
    alter table admin_requests drop constraint if exists req_email_format;
    alter table admin_requests drop constraint if exists req_reason_length;

    alter table admin_requests add constraint req_name_length
      check (char_length(full_name) between 1 and 100);

    alter table admin_requests add constraint req_email_format
      check (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(email) <= 200);

    alter table admin_requests add constraint req_reason_length
      check (char_length(reason) <= 1000);

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
