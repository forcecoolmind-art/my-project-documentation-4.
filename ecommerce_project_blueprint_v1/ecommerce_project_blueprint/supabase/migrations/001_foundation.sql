-- 001_foundation.sql
create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone varchar(20),
  avatar_url text,
  account_status text not null default 'active'
    check (account_status in ('active','blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  name varchar(50) not null unique,
  description text
);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  permission_key varchar(120) not null unique,
  description text
);

create table public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete restrict,
  assigned_at timestamptz not null default now(),
  primary key (user_id, role_id)
);

create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);

create table public.customer_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  full_name varchar(150) not null,
  phone varchar(20) not null,
  city varchar(100) not null,
  province varchar(100) not null,
  area varchar(150),
  address_line text not null,
  postal_code varchar(20),
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
create index customer_addresses_user_idx on public.customer_addresses(user_id);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories(id) on delete restrict,
  name varchar(150) not null,
  slug varchar(180) not null unique,
  description text,
  image_url text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  name varchar(255) not null,
  slug varchar(255) not null unique,
  description text,
  short_description varchar(500),
  brand_name varchar(150),
  status text not null default 'draft'
    check (status in ('draft','published','archived')),
  tracking_mode text not null default 'simple'
    check (tracking_mode in ('none','simple','batch')),
  requires_expiry boolean not null default false,
  featured boolean not null default false,
  seo_title varchar(255),
  seo_description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (not requires_expiry or tracking_mode = 'batch')
);

create table public.product_categories (
  product_id uuid not null references public.products(id) on delete restrict,
  category_id uuid not null references public.categories(id) on delete restrict,
  is_primary boolean not null default false,
  primary key (product_id, category_id)
);
create index product_categories_category_idx on public.product_categories(category_id);

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete restrict,
  sku varchar(100) not null unique,
  barcode varchar(100) unique,
  variant_name varchar(150) not null,
  cost_price numeric(12,2) not null default 0 check (cost_price >= 0),
  selling_price numeric(12,2) not null check (selling_price >= 0),
  sale_price numeric(12,2) check (sale_price is null or sale_price >= 0),
  weight numeric(10,3) check (weight is null or weight >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (sale_price is null or sale_price <= selling_price)
);
create index product_variants_product_idx on public.product_variants(product_id);

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  variant_id uuid references public.product_variants(id) on delete set null,
  image_url text not null,
  alt_text varchar(255),
  sort_order integer not null default 0,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.product_attributes (
  id uuid primary key default gen_random_uuid(),
  name varchar(100) not null,
  slug varchar(120) not null unique,
  data_type text not null check (data_type in ('text','number','boolean','date','select','multi_select')),
  scope text not null check (scope in ('product','variant','batch')),
  is_filterable boolean not null default false,
  is_required boolean not null default false,
  unit varchar(30)
);

create table public.attribute_options (
  id uuid primary key default gen_random_uuid(),
  attribute_id uuid not null references public.product_attributes(id) on delete cascade,
  label varchar(150) not null,
  value varchar(150) not null,
  sort_order integer not null default 0,
  unique(attribute_id, value)
);

create table public.category_attribute_mappings (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories(id) on delete cascade,
  attribute_id uuid not null references public.product_attributes(id) on delete restrict,
  is_required boolean not null default false,
  display_order integer not null default 0,
  unique(category_id, attribute_id)
);

create table public.product_attribute_values (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  attribute_id uuid not null references public.product_attributes(id) on delete restrict,
  value_text text,
  value_number numeric(12,3),
  value_boolean boolean,
  value_date date,
  value_json jsonb,
  unique(product_id, attribute_id),
  check (num_nonnulls(value_text,value_number,value_boolean,value_date,value_json) = 1)
);

create table public.variant_attribute_values (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants(id) on delete cascade,
  attribute_id uuid not null references public.product_attributes(id) on delete restrict,
  value_text text,
  value_number numeric(12,3),
  value_json jsonb,
  unique(variant_id, attribute_id),
  check (num_nonnulls(value_text,value_number,value_json) = 1)
);

create table public.warehouses (
  id uuid primary key default gen_random_uuid(),
  name varchar(150) not null,
  code varchar(50) not null unique,
  address text,
  city varchar(100),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.inventory_levels (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  quantity_on_hand numeric(12,3) not null default 0 check (quantity_on_hand >= 0),
  quantity_reserved numeric(12,3) not null default 0 check (quantity_reserved >= 0),
  weighted_average_cost numeric(12,4) not null default 0 check (weighted_average_cost >= 0),
  reorder_level numeric(12,3) not null default 0 check (reorder_level >= 0),
  updated_at timestamptz not null default now(),
  unique(variant_id, warehouse_id),
  check (quantity_reserved <= quantity_on_hand)
);

create table public.inventory_batches (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  batch_number varchar(100) not null,
  manufacturing_date date,
  expiry_date date,
  received_at timestamptz not null default now(),
  quantity_received numeric(12,3) not null check (quantity_received > 0),
  quantity_remaining numeric(12,3) not null check (quantity_remaining >= 0),
  unit_landed_cost numeric(12,4) not null check (unit_landed_cost >= 0),
  status text not null default 'active'
    check (status in ('active','quarantined','expired','depleted','recalled')),
  created_at timestamptz not null default now(),
  unique(variant_id, warehouse_id, batch_number),
  check (quantity_remaining <= quantity_received),
  check (manufacturing_date is null or expiry_date is null or expiry_date > manufacturing_date)
);
create index inventory_batches_fefo_idx
on public.inventory_batches(variant_id, warehouse_id, expiry_date, received_at)
where status = 'active' and quantity_remaining > 0;

create table public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  batch_id uuid references public.inventory_batches(id) on delete restrict,
  movement_type text not null check (movement_type in
    ('receipt','sale','reservation_release','return','adjustment','damage','transfer_in','transfer_out')),
  quantity_delta numeric(12,3) not null check (quantity_delta <> 0),
  unit_cost numeric(12,4),
  reference_type varchar(50),
  reference_id uuid,
  notes text,
  performed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create index inventory_movements_variant_date_idx
on public.inventory_movements(variant_id, created_at desc);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number varchar(50) not null unique,
  customer_id uuid references public.profiles(id) on delete set null,
  guest_name varchar(150),
  guest_email varchar(255),
  guest_phone varchar(20) not null,
  guest_access_token_hash text,
  shipping_address_snapshot jsonb not null,
  billing_address_snapshot jsonb,
  subtotal numeric(12,2) not null check (subtotal >= 0),
  discount_total numeric(12,2) not null default 0 check (discount_total >= 0),
  shipping_total numeric(12,2) not null default 0 check (shipping_total >= 0),
  tax_total numeric(12,2) not null default 0 check (tax_total >= 0),
  grand_total numeric(12,2) not null check (grand_total >= 0),
  currency char(3) not null default 'PKR' check (currency = 'PKR'),
  order_status text not null default 'pending_confirmation'
    check (order_status in ('pending_confirmation','pending_payment','confirmed','processing','packed','shipped','delivered','cancelled','expired','failed_delivery','partially_returned','returned')),
  payment_status text not null default 'pending'
    check (payment_status in ('pending','authorized','paid','partially_refunded','refunded','failed','cancelled')),
  fulfillment_status text not null default 'unfulfilled'
    check (fulfillment_status in ('unfulfilled','partially_fulfilled','fulfilled','returned')),
  customer_note text,
  internal_note text,
  placed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (customer_id is not null or guest_access_token_hash is not null)
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  product_id uuid references public.products(id) on delete set null,
  variant_id uuid references public.product_variants(id) on delete set null,
  product_name_snapshot varchar(255) not null,
  variant_name_snapshot varchar(150) not null,
  sku_snapshot varchar(100) not null,
  quantity numeric(12,3) not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  unit_cost_snapshot numeric(12,4) not null check (unit_cost_snapshot >= 0),
  discount_amount numeric(12,2) not null default 0 check (discount_amount >= 0),
  tax_amount numeric(12,2) not null default 0 check (tax_amount >= 0),
  line_total numeric(12,2) not null check (line_total >= 0),
  created_at timestamptz not null default now()
);
create index orders_customer_date_idx on public.orders(customer_id, created_at desc);
create index orders_status_date_idx on public.orders(order_status, created_at desc);
create index order_items_order_idx on public.order_items(order_id);

create table public.inventory_reservations (
  id uuid primary key default gen_random_uuid(),
  order_item_id uuid not null references public.order_items(id) on delete restrict,
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  quantity numeric(12,3) not null check (quantity > 0),
  status text not null default 'active' check (status in ('active','consumed','released','expired')),
  reservation_reason text not null check (reservation_reason in ('cod_confirmed','online_payment')),
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create index active_reservations_expiry_idx
on public.inventory_reservations(expires_at)
where status = 'active';

create table public.inventory_reservation_batches (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references public.inventory_reservations(id) on delete restrict,
  batch_id uuid not null references public.inventory_batches(id) on delete restrict,
  quantity numeric(12,3) not null check (quantity > 0)
);

create table public.payment_providers (
  id uuid primary key default gen_random_uuid(),
  name varchar(150) not null,
  provider_code varchar(100) not null unique,
  provider_type text not null check (provider_type in ('bank','gateway','cod')),
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  provider_id uuid references public.payment_providers(id) on delete restrict,
  payment_method text not null check (payment_method in ('cod','bank_transfer','bank_gateway')),
  amount numeric(12,2) not null check (amount >= 0),
  currency char(3) not null default 'PKR' check (currency = 'PKR'),
  status text not null default 'pending' check (status in ('pending','authorized','paid','failed','refunded','cancelled')),
  paid_at timestamptz,
  created_at timestamptz not null default now()
);
create index payments_order_status_idx on public.payments(order_id, status);

create table public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id) on delete restrict,
  provider_reference varchar(255),
  transaction_type text not null check (transaction_type in ('charge','refund','verification')),
  amount numeric(12,2) not null check (amount >= 0),
  status text not null check (status in ('pending','success','failed')),
  idempotency_key varchar(255) unique,
  response_reference varchar(255),
  created_at timestamptz not null default now()
);

create table public.couriers (
  id uuid primary key default gen_random_uuid(),
  name varchar(150) not null,
  contact_phone varchar(20),
  tracking_url_template text,
  is_active boolean not null default true
);

create table public.shipments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  courier_id uuid references public.couriers(id) on delete restrict,
  tracking_number varchar(150),
  shipping_cost numeric(12,2) not null default 0 check (shipping_cost >= 0),
  cod_amount numeric(12,2) not null default 0 check (cod_amount >= 0),
  status text not null default 'pending'
    check (status in ('pending','booked','picked_up','in_transit','out_for_delivery','delivered','failed','returned','cancelled')),
  shipped_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default now()
);
create index shipments_tracking_idx on public.shipments(tracking_number);

create table public.return_policies (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories(id) on delete restrict,
  policy_name varchar(150) not null,
  return_allowed boolean not null default true,
  exchange_allowed boolean not null default false,
  return_window_days integer not null default 0 check (return_window_days >= 0),
  conditions text,
  effective_from date not null,
  effective_until date,
  is_active boolean not null default true,
  check (effective_until is null or effective_until >= effective_from)
);

create table public.return_requests (
  id uuid primary key default gen_random_uuid(),
  return_number varchar(50) not null unique,
  order_id uuid not null references public.orders(id) on delete restrict,
  customer_id uuid references public.profiles(id) on delete set null,
  request_type text not null check (request_type in ('return','exchange')),
  reason text not null,
  status text not null default 'pending'
    check (status in ('pending','approved','rejected','received','completed')),
  requested_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table public.return_request_items (
  id uuid primary key default gen_random_uuid(),
  return_request_id uuid not null references public.return_requests(id) on delete restrict,
  order_item_id uuid not null references public.order_items(id) on delete restrict,
  quantity numeric(12,3) not null check (quantity > 0),
  product_condition text not null check (product_condition in ('sealed','opened','damaged','unused')),
  inspection_notes text,
  approved_quantity numeric(12,3) not null default 0 check (approved_quantity >= 0),
  check (approved_quantity <= quantity)
);

create table public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  name varchar(100) not null unique,
  is_active boolean not null default true
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  expense_category_id uuid not null references public.expense_categories(id) on delete restrict,
  description text not null,
  amount numeric(12,2) not null check (amount > 0),
  expense_date date not null,
  reference_number varchar(100),
  attachment_url text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.store_settings (
  id uuid primary key default gen_random_uuid(),
  setting_key varchar(150) not null unique,
  setting_value jsonb not null,
  is_public boolean not null default false,
  updated_at timestamptz not null default now()
);

create table public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  action varchar(100) not null,
  entity_type varchar(100) not null,
  entity_id uuid,
  old_values jsonb,
  new_values jsonb,
  created_at timestamptz not null default now()
);
create index activity_logs_user_date_idx on public.activity_logs(user_id, created_at desc);
