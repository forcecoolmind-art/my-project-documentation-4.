# E-commerce Platform — Project Blueprint

Version: 1.0  
Market: Pakistan  
Currency: PKR  
Timezone: Asia/Karachi  
Stack: Next.js + TypeScript + Supabase (PostgreSQL, Auth, Storage)

## Business decisions
- Own inventory; ready-made sourcing.
- Categories: men's fashion, women's fashion, cosmetics, skincare, personal care.
- Budget pricing.
- One warehouse initially; schema supports multiple warehouses.
- Guest and registered checkout.
- COD, bank transfer, and bank online gateway.
- Manual courier operations initially.
- English storefront and admin; PKR currency.
- Category-specific returns.
- FEFO batch dispatch for expiry-controlled products.
- Weighted-average inventory valuation.
- COD stock reservation begins only after admin confirmation.
- Unpaid online reservations expire after 24 hours.

## Package contents
- `docs/PROJECT_MASTER_SPEC.md`: business and functional specification.
- `docs/DATABASE_SCHEMA.md`: tables, columns, relationships, constraints and implementation notes.
- `docs/SECURITY_RULES.md`: RLS, roles, trust boundaries and payment security.
- `docs/INVENTORY_RULES.md`: weighted average, FEFO, reservations and stock ledger.
- `docs/ORDER_WORKFLOW.md`: checkout, payment, fulfillment and returns.
- `docs/DEVELOPMENT_ROADMAP.md`: staged Cursor development plan.
- `supabase/migrations/`: ordered PostgreSQL migrations.

## Apply migrations
Use a development Supabase project first. Review each SQL file, then apply in filename order with Supabase CLI:
`supabase db push`

Do not place Supabase `service_role` keys in browser code. Configure secrets in the server environment.

## Important implementation boundary
This is a production-oriented foundation, not a substitute for integration testing, bank-gateway certification, legal review of consumer policies, or a restore-tested backup plan. Complete the TODO items in the docs before public launch.
