-- ============================================================
-- ZEROHUBUI APPS — Supabase Schema
-- Ин файлро дар Supabase Dashboard → SQL Editor гузошта, "Run" кун
-- ============================================================

create extension if not exists pgcrypto;

-- ---------- ҶАДВАЛИ АСОСИИ БАРНОМАҲО ----------
create table if not exists apps (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,                 -- ID-и беназир барои URL (масалан: telegram-x-a1b2)
  section text not null check (section in ('app','game','moding')), -- Барнома / Бозӣ / MODING

  -- Матн (дузабона)
  name_tj text not null,
  name_ru text,
  description_tj text,
  description_ru text,

  category text,                             -- категорияи дохилӣ (Игры, Инструменты, ...)
  tags text[] default '{}',                  -- калидвожаҳо барои ҷустуҷӯ

  -- Медиа
  icon_url text,
  screenshots text[] default '{}',
  trailer_embed text,                        -- <iframe> embed code (на линк!)

  -- Зеркашӣ
  download_url text not null,                -- линки бевосита
  version text,
  size_mb numeric,
  min_android text,
  developer text,

  -- Ҳолат
  featured boolean default false,
  published boolean default false,           -- draft/published
  downloads_count integer default 0,
  rating numeric default 0,
  changelog text,

  -- SEO (барои Google Search Console)
  seo_title text,
  seo_description text,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_apps_section on apps(section);
create index if not exists idx_apps_published on apps(published);
create index if not exists idx_apps_slug on apps(slug);

-- ---------- ФУНКСИЯИ АВТОМАТИИ SLUG/ID ----------
create or replace function generate_slug()
returns trigger as $$
begin
  if new.slug is null or new.slug = '' then
    new.slug := lower(regexp_replace(new.name_tj, '[^a-zA-Z0-9]+', '-', 'g'))
                || '-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 6);
  end if;
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_generate_slug on apps;
create trigger trg_generate_slug
before insert or update on apps
for each row execute function generate_slug();

-- ---------- ХАВФСИЯТӢ (Row Level Security) ----------
alter table apps enable row level security;

-- Ҳама метавонанд барномаҳои "published" -ро бинанд
create policy "public_read_published"
on apps for select
using (published = true);

-- ⚠️ ИНРО ИВАЗ КУН: почтаи электронии худатро гузор
-- Танҳо ту (бо ин email воридшуда) метавонӣ илова/тағйир/нест кунӣ
create policy "admin_full_access"
on apps for all
using (auth.jwt() ->> 'email' = 'YOUR_EMAIL@gmail.com')
with check (auth.jwt() ->> 'email' = 'YOUR_EMAIL@gmail.com');

-- ---------- STORAGE (барои иконка/скриншот) ----------
insert into storage.buckets (id, name, public)
values ('app-media', 'app-media', true)
on conflict (id) do nothing;

create policy "public_read_media"
on storage.objects for select
using (bucket_id = 'app-media');

create policy "admin_upload_media"
on storage.objects for insert
with check (bucket_id = 'app-media' and auth.jwt() ->> 'email' = 'YOUR_EMAIL@gmail.com');

create policy "admin_delete_media"
on storage.objects for delete
using (bucket_id = 'app-media' and auth.jwt() ->> 'email' = 'YOUR_EMAIL@gmail.com');

-- ---------- ОМОР (барои дашборди админ) ----------
create or replace view stats_summary as
select
  count(*) filter (where section = 'app') as total_apps,
  count(*) filter (where section = 'game') as total_games,
  count(*) filter (where section = 'moding') as total_moding,
  count(*) filter (where published = true) as total_published,
  count(*) filter (where published = false) as total_drafts,
  coalesce(sum(downloads_count), 0) as total_downloads
from apps;
