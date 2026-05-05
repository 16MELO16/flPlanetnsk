-- ════════════════════════════════════════════════════════════════
-- 004_add_product_photos.sql
-- Поле products.photo_url + публичный bucket product-photos в Supabase Storage.
-- После миграции фото товаров становятся общими для всех посетителей,
-- больше не зависят от браузера/устройства, на котором их загружали.
--
-- Запуск: Supabase → SQL Editor → New query → вставить → Run.
-- Безопасно перезапускать.
-- ════════════════════════════════════════════════════════════════

-- ─── 1. Колонка photo_url в products ───────────────────────────
alter table products add column if not exists photo_url text;

-- ─── 2. Создать публичный bucket для фото товаров ──────────────
-- public: true означает, что любой посетитель может скачать файл по URL.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-photos',
  'product-photos',
  true,
  3145728,                       -- 3 MB лимит на файл (с запасом, фото у нас сжимаются)
  array['image/jpeg','image/png','image/webp','image/gif']
)
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ─── 3. RLS-политики на storage.objects ────────────────────────
-- Чтение публичное (даже без INSERT-политики оно работает у public bucket,
-- но добавляем явно для надёжности).
drop policy if exists "Public read product photos" on storage.objects;
create policy "Public read product photos"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'product-photos');

-- Загружать/менять/удалять фото — только авторизованные (админы)
drop policy if exists "Admin upload product photos" on storage.objects;
create policy "Admin upload product photos"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'product-photos');

drop policy if exists "Admin update product photos" on storage.objects;
create policy "Admin update product photos"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'product-photos')
  with check (bucket_id = 'product-photos');

drop policy if exists "Admin delete product photos" on storage.objects;
create policy "Admin delete product photos"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'product-photos');

-- ─── 4. Проверка ───────────────────────────────────────────────
-- Должен показать одну строку: bucket product-photos существует и публичен
select id, name, public, file_size_limit
from storage.buckets
where id = 'product-photos';
