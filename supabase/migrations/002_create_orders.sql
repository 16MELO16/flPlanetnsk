-- ════════════════════════════════════════════════════════════════
-- 002_create_orders.sql
-- Таблица заказов из корзины + RLS-политики.
-- Запуск: Supabase → SQL Editor → New query → вставить → Run.
-- Безопасно перезапускать (использует if not exists).
-- ════════════════════════════════════════════════════════════════

-- ─── 1. Таблица ────────────────────────────────────────────────
create table if not exists orders (
  id                uuid        primary key default gen_random_uuid(),
  created_at        timestamptz not null default now(),
  customer_name     text        not null,
  customer_phone    text        not null,
  customer_comment  text        default '',
  items             jsonb       not null,                  -- массив объектов: [{id,name,emoji,price,priceStr,unit,qty}]
  total_amount      integer     not null default 0,        -- ₽ без копеек
  has_approx_price  boolean     not null default false,    -- true если в корзине было «от X ₽»
  status            text        not null default 'new'
                    check (status in ('new','in_progress','ready','delivered','cancelled')),
  admin_notes       text        default ''
);

create index if not exists orders_created_at_idx
  on orders (created_at desc);

create index if not exists orders_status_idx
  on orders (status);

-- ─── 2. Row Level Security ─────────────────────────────────────
alter table orders enable row level security;

-- Любой посетитель может оформить заказ (insert)
drop policy if exists "Anyone can create orders" on orders;
create policy "Anyone can create orders"
  on orders
  for insert
  to anon, authenticated
  with check (true);

-- Видеть/менять/удалять заказы могут только авторизованные (админы)
drop policy if exists "Authenticated read orders" on orders;
create policy "Authenticated read orders"
  on orders
  for select
  to authenticated
  using (true);

drop policy if exists "Authenticated update orders" on orders;
create policy "Authenticated update orders"
  on orders
  for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Authenticated delete orders" on orders;
create policy "Authenticated delete orders"
  on orders
  for delete
  to authenticated
  using (true);

-- ─── 3. Проверка ───────────────────────────────────────────────
-- Должен вернуть структуру таблицы
select column_name, data_type
from information_schema.columns
where table_name = 'orders'
order by ordinal_position;
