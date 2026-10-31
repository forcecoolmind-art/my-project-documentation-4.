# DATABASE SCHEMA — IMPLEMENTATION SPECIFICATION

## Conventions
- UUID primary keys using `gen_random_uuid()`.
- `TIMESTAMPTZ` stored in UTC; display using `Asia/Karachi`.
- Money: `NUMERIC(12,2)`, quantities: `NUMERIC(12,3)`.
- Use foreign keys and CHECK constraints; avoid hard deletes for financial and stock history.
- All user-facing identifiers (order number, SKU, tracking number) are not primary keys.
- Use `archived_at` / status transitions rather than deleting records referenced by orders.

## Core tables in migrations
### Identity and authorization
- `profiles`: one row per `auth.users` user; id references auth.users.
- `roles`, `permissions`, `user_roles`, `role_permissions`: staff authorization.
- `customer_addresses`: customer-owned shipping/billing addresses.

### Catalog
- `categories`: hierarchical categories via nullable `parent_id`.
- `products`: product master, publish state, tracking mode and expiry flag.
- `product_categories`: many-to-many product/category mapping.
- `product_variants`: sellable SKU, barcode, cost and price.
- `product_attributes`: typed attribute definitions and scope.
- `category_attribute_mappings`: attributes assigned to categories.
- `attribute_options`: controlled options for select attributes.
- `product_attribute_values`: product-scope typed values.
- `variant_attribute_values`: variant-scope typed values.
- `product_images`: product or variant images.

### Inventory and procurement
- `warehouses`: one initial warehouse; supports expansion.
- `inventory_levels`: on-hand, reserved and weighted-average cost per variant/warehouse.
- `suppliers`: supplier master.
- `purchase_orders`, `purchase_order_items`: procurement.
- `goods_receipts`, `goods_receipt_items`: accepted goods and batch receipt.
- `inventory_batches`: received lot, expiry, remaining quantity and unit landed cost.
- `inventory_movements`: append-only stock ledger.
- `inventory_reservations`, `inventory_reservation_batches`: order reservations and FEFO batch allocations.

### Commerce
- `orders`, `order_items`, `order_status_history`.
- `payment_providers`, `payments`, `payment_transactions`, `refunds`.
- `couriers`, `shipments`, `shipment_status_history`.
- `return_policies`, `return_requests`, `return_request_items`.
- `wishlists`, `wishlist_items`.

### Operations
- `expenses`, `expense_categories`.
- `coupons`, `coupon_usages`, `reviews`, `banners`, `promotions`.
- `store_settings`, `activity_logs`, `notification_logs`.

## Important constraints and indexes
- SKU unique; slug unique; barcode unique when not null.
- Product prices and costs cannot be negative.
- Variant stock cannot be negative; reserved cannot exceed on-hand.
- Batch remaining quantity cannot be negative or exceed received quantity.
- Order quantity must be positive; monetary amounts cannot be negative.
- One active policy per category and effective period (enforce with exclusion/partial indexes or transactional validation).
- Index foreign keys and common filters: product status/category, order customer/status/date, inventory variant/warehouse, batch expiry, payment order/status, shipment tracking.
- Use partial indexes for active/published rows where useful.

## Critical implementation notes
1. Weighted average is stored on `inventory_levels` and recalculated only when a goods receipt is posted:
   new average = (old on-hand value + accepted receipt landed value) / (old on-hand quantity + accepted receipt quantity).
2. FEFO is an allocation rule, not a costing method. Allocate eligible batches by earliest expiry first, then received date and id for deterministic tie-breaking.
3. Batch-controlled products must not allocate batches with expiry before current Pakistan business date, depleted quantity, or quarantine/expired status.
4. Stock allocation and decrement must use row locks (`SELECT ... FOR UPDATE`) in a database transaction.
5. Reservation records are the source of truth for reserved stock. Inventory summary counters must be updated atomically with reservation rows.
6. COD reservation starts on admin confirmation. Online reservation starts on valid payment-session initiation and expires after 24 hours if still unpaid.
7. On payment success, extend/convert reservation into confirmed fulfillment reservation; do not release merely because the 24-hour timer passed if a verified payment event is being processed. Serialize payment and expiry operations.
8. Keep order-time product, price, discount, tax and cost snapshots.
9. Do not allow a browser client to set order totals, payment status, stock quantity or role assignments.
10. Use server-side RPCs / trusted API routes for order placement, reservation, payment webhooks, goods receipt posting, shipment dispatch and returns.

## Data type policy
- Status fields may use PostgreSQL enums or constrained TEXT. Prefer constrained TEXT initially to ease evolving workflows, but centralize allowed values in CHECK constraints.
- Attribute values must be validated against `product_attributes.data_type`; application validation alone is insufficient.
- JSONB is for snapshots/configuration, not a replacement for relational fields used in joins and reporting.
