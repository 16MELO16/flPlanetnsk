-- 003_create_admin_requests.sql

create table if not exists admin_requests (
  id           uuid        primary key default gen_random_uuid(),
  created_at   timestamptz not null default now(),
  full_name    text        not null,
  email        text        not null,
  reason       text        default '',
  status       text        not null default 'pending'
               check (status in ('pending','approved','rejected')),
  reviewed_at  timestamptz,
  reviewed_by  text,
  admin_notes  text        default ''
);

create index if not exists admin_requests_status_idx on admin_requests (status);
create index if not exists admin_requests_created_idx on admin_requests (created_at desc);
