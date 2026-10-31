# ORDER WORKFLOW

## Guest / registered checkout
1. Client submits variant ids, quantities, address and selected payment method.
2. Server reloads active product/variant prices and checks publish status.
3. Server validates address, shipping charge, coupon, tax and availability.
4. Server calculates totals; browser totals are ignored.
5. Server creates order and order-item snapshots transactionally.
6. For COD, order enters `pending_confirmation`; no stock reservation yet.
7. For bank transfer, create pending payment instructions and apply the configured reservation rule if the payment is considered initiated.
8. For online gateway, create provider session server-side and reserve stock transactionally for 24 hours.
9. For COD, authorized admin confirms order; reservation happens atomically at confirmation.
10. On successful payment webhook, verify signature, amount, currency and reference; update payment idempotently.
11. Pack and dispatch; FEFO allocation is consumed atomically at shipment dispatch.
12. Mark delivered based on courier confirmation; reconcile COD separately.

## Reservation expiry
A scheduled server job identifies active online reservations whose 24-hour expiry has passed and whose payment remains unpaid. It locks order/reservation rows, rechecks payment state, releases batch and aggregate reservations, and expires/cancels the order according to policy. Payment webhook processing must lock the same records to avoid race conditions.

## Returns
1. Customer submits return request against order item.
2. Server loads policy snapshot captured at purchase and checks deadline/eligibility.
3. Staff approves/rejects and records approved quantity.
4. Returned parcel is received and inspected.
5. Approved refund is processed via original payment method where supported or recorded as manual bank refund.
6. Returned inventory is quarantined; only inspection-approved resalable items re-enter stock with a return movement.
