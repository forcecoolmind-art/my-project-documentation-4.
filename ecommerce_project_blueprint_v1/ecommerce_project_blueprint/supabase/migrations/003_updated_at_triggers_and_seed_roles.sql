-- 003_updated_at_triggers_and_seed_roles.sql
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

create trigger categories_set_updated_at before update on public.categories
for each row execute function public.set_updated_at();

create trigger products_set_updated_at before update on public.products
for each row execute function public.set_updated_at();

create trigger variants_set_updated_at before update on public.product_variants
for each row execute function public.set_updated_at();

insert into public.roles(name, description) values
('super_admin','Full system administration'),
('product_manager','Product catalog management'),
('inventory_manager','Purchasing and inventory management'),
('order_manager','Order and fulfillment management'),
('customer_support','Customer and return support'),
('accountant','Payments, expenses and reporting')
on conflict (name) do nothing;

insert into public.permissions(permission_key, description) values
('products.view','View products'),
('products.create','Create products'),
('products.update','Update products'),
('inventory.view','View inventory'),
('inventory.adjust','Adjust inventory'),
('orders.view','View orders'),
('orders.confirm','Confirm orders'),
('orders.manage','Manage order fulfillment'),
('payments.view','View payments'),
('payments.reconcile','Reconcile payments'),
('returns.manage','Manage returns'),
('expenses.manage','Manage expenses'),
('reports.view','View reports'),
('settings.manage','Manage store settings'),
('staff.manage','Manage staff and roles')
on conflict (permission_key) do nothing;

insert into public.warehouses(name, code, city)
values ('Main Warehouse','MAIN','Pakistan')
on conflict (code) do nothing;

-- TODO: Assign super_admin to a specifically provisioned auth user through a
-- trusted operator-only process. Never grant this role through public signup.
