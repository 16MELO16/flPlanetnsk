-- ════════════════════════════════════════════════════════════════
-- 001_create_products.sql
-- Создаёт таблицу products, RLS-политики и заливает начальный каталог.
-- Запуск: Supabase → SQL Editor → New query → вставить → Run.
-- Безопасно перезапускать (использует if not exists / on conflict).
-- ════════════════════════════════════════════════════════════════

-- ─── 1. Таблица ─────────────────────────────────────────────────
create table if not exists products (
  id           text        primary key,
  section      text        not null check (section in ('cut','pot','cuttings','bouquets')),
  emoji        text        default '',
  bg           text        default '',
  badge        text        check (badge is null or badge in ('hit','rare','new')),
  name1        text        not null,
  name2        text        default '',
  latin        text        default '',
  description  text        default '',
  comp         text        default '',
  price        text        default '',
  unit         text        default '',
  sort_order   integer     default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists products_section_sort_idx
  on products (section, sort_order);

-- ─── 2. Auto-update updated_at ─────────────────────────────────
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists products_updated_at on products;
create trigger products_updated_at
  before update on products
  for each row execute function set_updated_at();

-- ─── 3. Row Level Security ─────────────────────────────────────
alter table products enable row level security;

-- Каталог читают все (включая анонимных посетителей сайта)
drop policy if exists "Public read products" on products;
create policy "Public read products"
  on products
  for select
  using (true);

-- Менять каталог могут только авторизованные пользователи (админы)
drop policy if exists "Authenticated insert products" on products;
create policy "Authenticated insert products"
  on products
  for insert
  to authenticated
  with check (true);

drop policy if exists "Authenticated update products" on products;
create policy "Authenticated update products"
  on products
  for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Authenticated delete products" on products;
create policy "Authenticated delete products"
  on products
  for delete
  to authenticated
  using (true);

-- ─── 4. Начальный каталог ──────────────────────────────────────
-- Срезанные цветы
insert into products (id, section, emoji, bg, badge, name1, name2, latin, description, price, unit, sort_order) values
  ('cut-1','cut','🌹','🌹','hit', 'Роза','садовая','Rosa × hybrida','Классика флористики. Бархатные лепестки, устойчивый аромат, стебель 60–70 см.','220 ₽','/ шт',1),
  ('cut-2','cut','🌸','🌸','rare','Пион','садовый','Paeonia lactiflora','Сезонный фаворит с пышными махровыми цветами и сладким ароматом.','380 ₽','/ шт',2),
  ('cut-3','cut','🌷','🌷',null,  'Тюльпан','','Tulipa gesneriana','Весенний символ. Доступен в 12+ сортах: махровые, попугайные, бахромчатые.','95 ₽','/ шт',3),
  ('cut-4','cut','🌺','💐','hit', 'Лилия','восточная','Lilium orientalis','Роскошный аромат, крупные цветы до 25 см. Стебель с 3–5 бутонами.','310 ₽','/ шт',4),
  ('cut-5','cut','🌼','🌼',null,  'Хризантема','кустовая','Chrysanthemum morifolium','Долговечная срезка до 3-х недель. Пышный куст, идеальна для объёмных букетов.','145 ₽','/ шт',5),
  ('cut-6','cut','🪷','🌸','rare','Орхидея','Цимбидиум','Cymbidium sp.','Экзотическая срезка. Одна ветка несёт 8–12 цветков, стоит до 4 недель.','650 ₽','/ шт',6),
  ('cut-7','cut','🌻','🌻',null,  'Гербера','','Gerbera jamesonii','Яркие солнечные цветы. Более 50 оттенков, стебель 50 см, в наличии весь год.','130 ₽','/ шт',7),
  ('cut-8','cut','🌷','💜','new', 'Ирис','голландский','Iris × hollandica','Нежная фиолетовая гамма. Изысканная геометрия лепестков, лёгкий аромат.','175 ₽','/ шт',8)
on conflict (id) do nothing;

-- Горшечные растения
insert into products (id, section, emoji, bg, badge, name1, name2, latin, description, price, unit, sort_order) values
  ('pot-1','pot','🌿','🌿','hit', 'Монстера','деликатная','Monstera deliciosa','Тропическая икона с резными листьями. Горшок Ø17 см, высота 55 см.','1 490 ₽','',1),
  ('pot-2','pot','🌸','🌸',null,  'Спатифиллум','','Spathiphyllum wallisii','«Женское счастье» — цветёт белыми парусами, очищает воздух. Горшок Ø14.','690 ₽','',2),
  ('pot-3','pot','🌱','🌱','hit', 'Замиокулькас','','Zamioculcas zamiifolia','«Долларовое дерево» — суперустойчив к засухе, глянцевые тёмно-зелёные листья.','1 150 ₽','',3),
  ('pot-4','pot','🌴','🌴',null,  'Драцена','окаймлённая','Dracaena marginata','Стройная пальма с красно-зелёными листьями. Высота 80 см, горшок Ø19 см.','2 200 ₽','',4),
  ('pot-5','pot','🍃','🍃',null,  'Хлорофитум','хохлатый','Chlorophytum comosum','Каскадные пёстрые листья и дочерние розетки. Идеален для ампелей.','390 ₽','',5),
  ('pot-6','pot','🌺','🌺','rare','Антуриум','','Anthurium andraeanum','Лаковые ало-красные соцветия круглый год. Горшок Ø13 см.','1 890 ₽','',6),
  ('pot-7','pot','🪴','🌿',null,  'Фикус','Бенджамина','Ficus benjamina','Классическое деревце с воздушной кроной. Высота 90 см, горшок Ø21 см.','3 100 ₽','',7),
  ('pot-8','pot','🌵','🌵',null,  'Сансевиерия','','Sansevieria trifasciata','«Тёщин язык» — почти нетребователен к уходу, мощный очиститель воздуха.','550 ₽','',8)
on conflict (id) do nothing;

-- Черенки и саженцы
insert into products (id, section, emoji, bg, badge, name1, name2, latin, description, price, unit, sort_order) values
  ('cut2-1','cuttings','🌸','🌸','hit', 'Бегония','черенок','Begonia rex hybrid','Укоренённый черенок в стакане. Пёстрые листья-картины, быстрый рост.','250 ₽','',1),
  ('cut2-2','cuttings','🍃','🍃','hit', 'Потос','золотой','Epipremnum aureum','Классика для новичков. Черенок с 3–4 листьями, корни уже развиты.','180 ₽','',2),
  ('cut2-3','cuttings','🪴','🌿','rare','Хойя','kerrii','Hoya kerrii','Суккулентные сердечки-листья. Черенок в грунте, укоренён, редкий вид.','450 ₽','',3),
  ('cut2-4','cuttings','🌳','🌳',null,  'Фикус','лировидный','Ficus lyrata','Трендовый крупнолистный фикус. Саженец 30–40 см, горшок Ø10 см.','1 100 ₽','',4),
  ('cut2-5','cuttings','🌱','🌱','rare','Пахира','водная','Pachira aquatica','«Денежное дерево» с плетёным стволом. Саженец 25 см, плетёный.','890 ₽','',5),
  ('cut2-6','cuttings','🌸','🌸',null,  'Стрептокарпус','','Streptocarpus hybrida','Листовой черенок с детками. Цветёт обильно и долго — 9 месяцев в году.','320 ₽','',6),
  ('cut2-7','cuttings','🪷','💜','new', 'Глоксиния','','Sinningia speciosa','Бархатные колокольчики крупных цветов. Черенок листовой, уже укоренён.','280 ₽','',7),
  ('cut2-8','cuttings','🪨','🌵','hit', 'Эхеверия','розетка','Echeveria elegans','Каменная роза из суккулентов. Детка с корнями, 5–7 см в диаметре.','190 ₽','',8)
on conflict (id) do nothing;

-- Букеты и композиции
insert into products (id, section, emoji, bg, badge, name1, name2, comp, description, price, unit, sort_order) values
  ('bouq-1','bouquets','💍','💐','hit', 'Свадебный','букет невесты','белые пионы, эустома, гринери, лента атласная','Нежная классика для особенного дня. Индивидуальная сборка под платье.','6 500 ₽','',1),
  ('bouq-2','bouquets','🌸','🌸','rare','Монобукет','из пионов','25 пионов сортовых, упаковка крафт, рафия','Роскошный объём из одного цветка — эффект максимальный, вкус безупречный.','9 500 ₽','',2),
  ('bouq-3','bouquets','🪴','🪴',null,  'Корзина','с суккулентами','12 видов суккулентов, мох, декоративные камни, ивовая корзина','Живой подарок, который будет радовать годами. Идеально для дома и офиса.','4 200 ₽','',3),
  ('bouq-4','bouquets','🎁','🌹','hit', 'Коробка','с розами','25 роз сорта «Джулия», флористическая пена, шляпная коробка','Безупречная классика в элегантной упаковке. Выбор цвета — на ваше усмотрение.','7 800 ₽','',4),
  ('bouq-5','bouquets','🌷','🌷',null,  'Весенний','микс','тюльпаны, нарциссы, мускари, веточки сирени, зелень','Ароматная весна в руках. Сборный букет из лучших сезонных цветов.','3 400 ₽','',5),
  ('bouq-6','bouquets','🌿','🎨','new', 'Авторская','композиция','подбор флориста по сезону и вашему запросу','Уникальная работа нашего флориста: от концепции до каждого стебля. Нет двух одинаковых.','от 5 000 ₽','',6)
on conflict (id) do nothing;

-- ─── 5. Проверка ──────────────────────────────────────────────
-- Должно вернуть 30 (8 + 8 + 8 + 6)
select section, count(*) from products group by section order by section;
