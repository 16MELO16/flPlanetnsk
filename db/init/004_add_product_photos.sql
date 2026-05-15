-- 004_add_product_photos.sql

alter table products add column if not exists photo_url text;
