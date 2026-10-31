# PROJECT MASTER SPECIFICATION

## 1. Product vision
Build a secure, mobile-responsive, budget-positioned Pakistani e-commerce store selling clothing, cosmetics, skincare and personal-care products. The platform includes a customer storefront and a responsive administration system.

## 2. User types
- Visitor: browse published catalog, search/filter, use cart and guest checkout.
- Customer: manage profile/addresses, orders, wishlist and eligible returns.
- Staff: access only modules granted by role permissions.
- Super Admin: administer catalog, staff, settings, operations and reporting.

## 3. Functional modules
1. Authentication and customer profiles.
2. Roles and permission-based admin access.
3. Category hierarchy and product catalog.
4. Dynamic category attributes and product variants.
5. Product image management.
6. Suppliers and purchasing.
7. Goods receipt and inventory.
8. Weighted-average inventory costing.
9. Batch and expiry tracking with FEFO allocation.
10. Cart and checkout.
11. Order confirmation and lifecycle.
12. COD, bank transfer and bank gateway payments.
13. Manual courier and COD settlements.
14. Category-based returns and exchanges.
15. Coupons, promotions, reviews and banners.
16. Expenses, inventory valuation and financial reporting.
17. Audit logs, notifications and store settings.

## 4. Product model
A product is the catalog-level item. A variant is the sellable SKU (e.g. black / medium T-shirt or 100 ml face wash). Inventory, barcode, price and cost are variant-level. Attributes are category-driven and typed. Batch/expiry data belongs to received inventory lots, not the product master.

### Clothing examples
Gender, garment type, fabric, fit, size, colour, pattern, sleeve, season and care instructions. Size/colour combinations that affect stock are variant options.

### Cosmetics and personal care examples
Product type, skin/hair type, concerns, net content and unit, ingredients, key ingredients, usage instructions, manufacturer, country of origin, batch number, manufacturing date and expiry date. Batch number and dates are receipt-lot data.

## 5. Pricing and financial rules
- Store monetary values as `NUMERIC(12,2)` and currency as ISO code `PKR`.
- Persist order-time name, SKU, price, discount, tax and cost snapshots.
- Never recalculate historical order totals from current catalog prices.
- Weighted average cost is maintained per variant and warehouse.
- Purchase receipt changes weighted average cost using accepted quantities and landed cost.
- Revenue, gross profit, contribution and net profit are distinct metrics.
- COD delivered does not mean COD cash has been remitted by the courier; settlement is separate.

## 6. Order rules
- Guest and registered checkout are supported.
- Guest orders are created only through trusted server-side functions; store only a hash of a high-entropy tracking token.
- COD order stock is reserved after an authorized admin confirms the order.
- Online payment stock is reserved when a valid payment attempt/session is initiated; unpaid reservation expires after 24 hours.
- A verified successful payment must be reconciled against expected amount, currency, provider reference and signature.
- Order creation, stock reservation and payment state transitions must be transactional and idempotent.
- Shipment can be split into multiple packages.
- Returns are evaluated against the policy snapshot captured for the order.

## 7. Non-functional requirements
- RLS enabled on all exposed tables.
- No secret keys in browser bundles or public tables.
- Server-side validation for prices, discounts, stock, order totals and permissions.
- Database migrations are version-controlled.
- Responsive admin and storefront.
- Accessible forms, useful error states and audit trails.
- Automated tests for inventory concurrency, payments, RLS and order transitions.
- Backups and restore tests before launch.

## 8. Out of scope for initial release
- Marketplace / third-party sellers.
- Automated courier API booking.
- Multi-currency checkout.
- Native mobile apps.
- Automated supplier bank payments.
- Multi-warehouse operations UI (database supports future expansion).
