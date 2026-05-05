-- ════════════════════════════════════════════════════════════════
-- 005_remove_bouquets_section.sql
-- Удаляем все товары из раздела «Букеты и композиции».
-- На сайте раздел уже скрыт, но БД нужно почистить, чтобы:
--   • эти строки не загружались каждый раз при открытии сайта;
--   • не висели в Storage связанные с ними фото.
--
-- Запуск: Supabase → SQL Editor → New query → вставить → Run.
-- Безопасно перезапускать.
-- ════════════════════════════════════════════════════════════════

-- 1. Сначала смотрим, что у нас есть в этом разделе (для логов)
select id, name1, photo_url
from products
where section = 'bouquets';

-- 2. Удаляем все товары раздела «bouquets».
--    Связанные фото в Storage придётся удалить отдельно (см. п. 4).
delete from products where section = 'bouquets';

-- 3. Проверка: должно вернуть 0
select count(*) as bouquets_left from products where section = 'bouquets';

-- 4. Опционально: удалить из Storage оставшиеся «осиротевшие» фото букетов
--    (если вы успели загрузить хоть одно фото для букета).
--    Это нужно сделать вручную через Supabase Dashboard → Storage → product-photos
--    (или раскомментировать запрос ниже — он удалит только файлы, которые начинаются с 'bouq-').
-- delete from storage.objects
-- where bucket_id = 'product-photos'
--   and name like 'bouq-%';
