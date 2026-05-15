-- 002_create_orders.sql

create table if not exists orders (
  id                uuid        primary key default gen_random_uuid(),
  created_at        timestamptz not null default now(),
  customer_name     text        not null,
  customer_phone    text        not null,
  customer_comment  text        default '',
  items             jsonb       not null,
  total_amount      integer     not null default 0,
  has_approx_price  boolean     not null default false,
  status            text        not null default 'new'
                    check (status in ('new','in_progress','ready','delivered','cancelled')),
  admin_notes       text        default ''
);

create index if not exists orders_created_at_idx
  on orders (created_at desc);

create index if not exists orders_status_idx
  on orders (status);
