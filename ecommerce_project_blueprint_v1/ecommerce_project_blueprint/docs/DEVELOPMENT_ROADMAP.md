# DEVELOPMENT ROADMAP FOR CURSOR AI

## Phase 0 — Repository foundation
- Create Git repository and Next.js App Router TypeScript project.
- Configure Tailwind and shadcn/ui.
- Add linting, formatting, type-check and test scripts.
- Add `.env.example`; never commit `.env.local`.
- Add docs to repository and instruct Cursor to read them before code changes.

## Phase 1 — Supabase foundation
- Create development Supabase project.
- Configure Auth, Storage buckets and local Supabase CLI.
- Apply SQL migrations in order.
- Verify RLS with anon, customer and each staff role.
- Seed roles, permissions, initial warehouse and store settings.

## Phase 2 — Admin access
- Login/logout, protected routes, role-aware navigation.
- Staff management and permission assignment.
- Audit logging.

## Phase 3 — Catalog
- Category CRUD and hierarchy.
- Attribute definition and category mapping.
- Product CRUD, images, variants, SKU and barcode.
- Publish workflow and public catalog views.

## Phase 4 — Procurement and inventory
- Supplier management and purchase orders.
- Goods receipt posting.
- Weighted average cost update.
- Batch entry, expiry alerts and FEFO allocation.
- Stock adjustments and append-only movements.

## Phase 5 — Storefront
- Homepage, category pages, search, filters and product detail.
- Variant selection, cart and wishlist.
- SEO metadata and responsive layouts.

## Phase 6 — Checkout and orders
- Guest and customer checkout.
- Server-calculated totals and snapshots.
- COD confirmation and reservation.
- Online payment session and 24-hour reservation.
- Order history and status timeline.

## Phase 7 — Payments and shipping
- Bank gateway adapter for selected bank.
- Bank transfer verification workflow.
- Webhook signature/idempotency tests.
- Manual courier, tracking and COD settlements.

## Phase 8 — Returns and finance
- Category policy snapshots.
- Return inspection and refunds.
- Expenses, weighted-average inventory valuation and reports.

## Phase 9 — QA and launch
- Unit, integration, RLS and end-to-end tests.
- Concurrent checkout / oversell tests.
- Payment webhook replay and race-condition tests.
- Backup restore test, monitoring, SEO and production deployment.

## Cursor working protocol
For each task:
1. Read relevant docs first.
2. State the files and database objects to be changed.
3. Implement the smallest complete vertical slice.
4. Add migration and tests with every schema change.
5. Run lint, typecheck and relevant tests.
6. Report changed files, migration name, test results and unresolved TODOs.
7. Do not silently change business rules or add dependencies.
