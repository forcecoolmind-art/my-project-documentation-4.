# Cursor Project Instructions

Before implementing any feature, read:
- `README.md`
- relevant files in `docs/`

Non-negotiable rules:
1. Do not change business decisions without asking.
2. Never trust client-submitted price, totals, stock, payment state, role or permissions.
3. Every schema change requires a new ordered Supabase migration and tests.
4. Keep RLS enabled; never solve an RLS issue by disabling RLS.
5. Never expose service_role keys or bank gateway secrets in browser code.
6. Use weighted-average costing for inventory valuation and FEFO for expiry-controlled dispatch. They are separate concepts.
7. COD stock is reserved only after authorized admin confirmation.
8. Unpaid online reservations expire after 24 hours, with payment/expiry race protection.
9. Preserve order-time snapshots and append-only stock/payment audit records.
10. Run lint, typecheck and relevant tests; report exact outcomes and remaining TODOs.
