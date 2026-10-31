# SECURITY RULES

## Trust boundaries
- Browser is untrusted. Never trust submitted price, totals, discount, stock, role, payment state or shipment state.
- Next.js server routes/actions validate user input and call narrowly scoped database functions.
- Supabase `service_role` key is server-only and must never be exposed to the client.
- Bank gateway secrets and webhook secrets belong in server environment / managed secrets, never in `store_settings` or client-readable tables.

## RLS baseline
Enable RLS on every table in `public`. Grant `anon` read access only through deliberately public catalog views/tables. Authenticated customers can read/update only their own profile and addresses, read only their own orders and safe order details, and manage their own wishlist. Customer inserts for orders/payments are not direct table inserts; use trusted checkout endpoints.

## Roles
Seed roles: `super_admin`, `product_manager`, `inventory_manager`, `order_manager`, `customer_support`, `accountant`.
Seed permission keys such as `products.view`, `products.create`, `products.update`, `inventory.view`, `inventory.adjust`, `orders.view`, `orders.confirm`, `payments.view`, `payments.reconcile`, `returns.manage`, `expenses.manage`, `reports.view`, `settings.manage`, `staff.manage`.

Never accept a role id or permission key from a browser as proof of authorization. Verify the signed-in user's role in database policies or trusted server code. Protect role assignment so only a super admin can grant staff roles. Prevent a user from granting themselves elevated access.

## RLS policy matrix
- Public catalog: SELECT published products, active categories, public images and public attribute values only.
- Customer profiles: SELECT own; UPDATE own allowed non-sensitive fields only.
- Addresses: CRUD own rows.
- Orders: SELECT own registered orders; guest tracking uses a high-entropy token verified server-side and returns a restricted DTO.
- Order items: SELECT only if parent order belongs to current user.
- Wishlist: CRUD only where parent wishlist belongs to current user.
- Reviews: customer can create review only for an eligible purchased/delivered order item; moderation is staff-only.
- Inventory, batches, cost prices, purchase records: staff permissions only; never public.
- Payments/refunds: customer gets limited safe status information; mutation and reconciliation are server-only / authorized staff.
- Activity logs, expenses, settings secrets, supplier payments: restricted staff permissions.

## SECURITY DEFINER functions
If used:
- Set a fixed safe `search_path`.
- Revoke EXECUTE from PUBLIC by default.
- Grant EXECUTE only to required roles.
- Validate `auth.uid()` and permission inside the function.
- Avoid dynamic SQL; if unavoidable, quote identifiers and validate inputs.
- Ensure functions do not bypass tenant/ownership checks.
- Avoid recursive RLS policy calls.

## Bank gateway
- Verify webhook signature using provider's official algorithm.
- Verify merchant/order reference, expected amount, currency and final transaction state.
- Persist provider event/reference and enforce idempotency.
- Never mark paid from a browser redirect alone.
- Handle duplicate, delayed and out-of-order webhooks.
- Reconcile gateway reports against internal transactions.

## Operational security
- Rate-limit login, checkout, guest tracking and coupon validation.
- Validate and scan uploaded files; restrict MIME types and size.
- Use private storage buckets for invoices and sensitive attachments.
- Keep audit logs for privileged changes.
- Back up database and test restores.
