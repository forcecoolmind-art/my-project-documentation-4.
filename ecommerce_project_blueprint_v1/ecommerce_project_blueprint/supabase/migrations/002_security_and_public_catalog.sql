-- 002_security_and_public_catalog.sql
-- RLS is enabled by default on all application tables created in migration 001.
do $$
declare t record;
begin
  for t in
    select tablename from pg_tables
    where schemaname = 'public'
  loop
    execute format('alter table public.%I enable row level security', t.tablename);
  end loop;
end $$;

-- Minimal self-service policies. Sensitive writes (orders, payments, inventory)
-- must be performed through trusted server-side endpoints / narrowly scoped RPCs.
create policy "profile_select_own" on public.profiles
for select to authenticated using (id = (select auth.uid()));

create policy "profile_update_own" on public.profiles
for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy "address_select_own" on public.customer_addresses
for select to authenticated using (user_id = (select auth.uid()));

create policy "address_insert_own" on public.customer_addresses
for insert to authenticated with check (user_id = (select auth.uid()));

create policy "address_update_own" on public.customer_addresses
for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "address_delete_own" on public.customer_addresses
for delete to authenticated using (user_id = (select auth.uid()));

-- Public catalog views deliberately omit cost, inventory, private notes and supplier data.
create view public.public_categories
with (security_invoker = true) as
select id, parent_id, name, slug, description, image_url, sort_order
from public.categories where is_active = true;

create view public.public_products
with (security_invoker = true) as
select id, name, slug, description, short_description, brand_name, featured
from public.products where status = 'published';

-- No anonymous grants on base catalog tables are made here. Configure explicit
-- grants and public SELECT policies only after verifying the exact public columns.
-- Do not expose product_variants directly because it contains cost_price.
