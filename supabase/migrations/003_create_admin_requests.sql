-- ════════════════════════════════════════════════════════════════
-- 003_create_admin_requests.sql
-- Заявки на доступ в админку + автоматическое уведомление в Telegram.
--
-- ВАЖНО: перед запуском миграции нужно сохранить два секрета в Supabase Vault.
-- См. раздел 10 в SUPABASE_SETUP.md (создание бота, получение chat_id).
--
-- Запуск: Supabase → SQL Editor → New query → вставить → Run.
-- ════════════════════════════════════════════════════════════════

-- ─── 1. Расширения ─────────────────────────────────────────────
-- pg_net нужен для отправки HTTP-запросов из БД (в Telegram API).
create extension if not exists pg_net with schema extensions;

-- ─── 2. Таблица заявок ─────────────────────────────────────────
create table if not exists admin_requests (
  id           uuid        primary key default gen_random_uuid(),
  created_at   timestamptz not null default now(),
  full_name    text        not null,
  email        text        not null,
  reason       text        default '',
  status       text        not null default 'pending'
               check (status in ('pending','approved','rejected')),
  reviewed_at  timestamptz,
  reviewed_by  uuid        references auth.users(id) on delete set null,
  admin_notes  text        default ''
);

create index if not exists admin_requests_status_idx on admin_requests (status);
create index if not exists admin_requests_created_idx on admin_requests (created_at desc);

-- ─── 3. RLS ────────────────────────────────────────────────────
alter table admin_requests enable row level security;

-- Любой может оставить заявку
drop policy if exists "Anyone can submit access request" on admin_requests;
create policy "Anyone can submit access request"
  on admin_requests for insert
  to anon, authenticated
  with check (true);

-- Видеть/менять/удалять — только админы
drop policy if exists "Authenticated read access requests" on admin_requests;
create policy "Authenticated read access requests"
  on admin_requests for select
  to authenticated
  using (true);

drop policy if exists "Authenticated update access requests" on admin_requests;
create policy "Authenticated update access requests"
  on admin_requests for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Authenticated delete access requests" on admin_requests;
create policy "Authenticated delete access requests"
  on admin_requests for delete
  to authenticated
  using (true);

-- ─── 4. Функция отправки уведомления в Telegram ────────────────
-- Использует pg_net и читает токен/chat_id из Supabase Vault.
-- Если секреты не настроены — функция просто не падает (warning в логах).
create or replace function notify_admin_request_telegram()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token   text;
  v_chat_id text;
  v_message text;
begin
  -- Достаём секреты из Vault
  begin
    select decrypted_secret into v_token
      from vault.decrypted_secrets where name = 'telegram_bot_token' limit 1;
    select decrypted_secret into v_chat_id
      from vault.decrypted_secrets where name = 'telegram_admin_chat_id' limit 1;
  exception when others then
    raise warning 'Vault недоступен или секреты не настроены: %', sqlerrm;
    return NEW;
  end;

  if v_token is null or v_chat_id is null then
    raise warning 'Telegram-секреты не найдены в Vault. Заявка сохранена, но уведомление не отправлено.';
    return NEW;
  end if;

  -- Формируем текст сообщения
  v_message := E'🌸 *Новая заявка на доступ к админке*\n\n' ||
               E'👤 *Имя:* ' || NEW.full_name || E'\n' ||
               E'📧 *Email:* `' || NEW.email || E'`\n' ||
               case when NEW.reason <> '' then E'💬 *Причина:* ' || NEW.reason || E'\n' else '' end ||
               E'\n' ||
               E'_Чтобы одобрить:_ Supabase → Authentication → Users → Add user (укажите тот же email).\n' ||
               E'_Чтобы отклонить:_ удалите заявку в Table Editor → admin\_requests.';

  -- Отправляем в Telegram (асинхронно, не ждём ответа)
  perform net.http_post(
    url     := 'https://api.telegram.org/bot' || v_token || '/sendMessage',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body    := jsonb_build_object(
                 'chat_id', v_chat_id,
                 'text', v_message,
                 'parse_mode', 'Markdown',
                 'disable_web_page_preview', true
               )
  );

  return NEW;
exception when others then
  -- Если что-то пошло не так с уведомлением — заявка всё равно сохранится
  raise warning 'Не удалось отправить Telegram-уведомление: %', sqlerrm;
  return NEW;
end;
$$;

-- ─── 5. Триггер ────────────────────────────────────────────────
drop trigger if exists admin_request_telegram_notify on admin_requests;
create trigger admin_request_telegram_notify
  after insert on admin_requests
  for each row execute function notify_admin_request_telegram();

-- ─── 6. Проверка ───────────────────────────────────────────────
-- Должен показать таблицу со столбцами
select column_name, data_type
from information_schema.columns
where table_name = 'admin_requests'
order by ordinal_position;
