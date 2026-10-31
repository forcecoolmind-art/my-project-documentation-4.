# INVENTORY RULES

## 1. Inventory dimensions
Stock is tracked by `variant_id + warehouse_id`. Batch-controlled stock is additionally tracked by `batch_id`. One warehouse is configured at launch, but schema permits more.

## 2. Weighted average cost
Maintain `inventory_levels.weighted_average_cost`.
When a posted receipt adds accepted quantity Q at landed unit cost C:
- old quantity = on_hand
- old value = on_hand * current WAC
- new WAC = (old value + Q*C) / (old quantity + Q)
- if old quantity is zero, new WAC = C
Round only for storage/display policy; retain sufficient precision in calculations.
Do not recalculate WAC for sales, returns to damaged stock, or manual corrections unless an approved valuation adjustment is recorded.

Landed unit cost should include allocated purchase cost components according to the accounting policy (purchase price, freight, duties and other directly attributable costs). Document allocation method.

## 3. FEFO
For products with `tracking_mode = 'batch'` / `requires_expiry = true`, allocate from eligible batches ordered by:
1. earliest `expiry_date`,
2. earliest `received_at`,
3. batch id as deterministic tie-breaker.
Exclude expired, quarantined, recalled, depleted and inactive batches.
For non-expiry clothing, allocate from aggregate available stock or FIFO receipt lots if lot tracking is enabled.

## 4. Reservations
- COD: reserve only after admin confirmation.
- Online bank gateway: reserve when a valid payment attempt/session is initiated.
- Unpaid online reservation TTL: 24 hours.
- Expiry worker releases only reservations still active and unpaid.
- Payment success and reservation expiry must serialize on the same order/reservation rows.
- Reservation release creates ledger/audit events and restores availability.
- Cancellation after confirmation releases active reservation.
- Dispatch consumes reservation and reduces on-hand stock atomically.

## 5. Stock ledger
`inventory_movements` is append-only. Corrections use compensating movements. Each movement should have a source reference (goods receipt, shipment, return, adjustment).
Never update historical movement rows to repair a mistake.

## 6. Returns
Returned items enter inspection/quarantine, not sellable stock automatically. Cosmetics opened/used or expired are not returned to sellable stock. Restock only after authorized inspection and policy approval.
