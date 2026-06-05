-- Manual run only. Do NOT auto-run from agent.
-- Purpose:
-- 1) Repair inventory adjustment account_transactions rows where debit=0 and credit=0.
-- 2) Rebuild accounting rows from inventory_adjustment_account_entries first.
-- 3) Fallback to computed rows from inventory_adjustment_items / inventory_adjustment_value_items when account entries are missing.
-- 4) Keep org_id/entity_id aligned with current schema constraints.

-- Safety check preview: adjustments currently having zero/zero account transactions.
SELECT
  atx.source_id AS adjustment_id,
  COUNT(*) AS zero_rows
FROM public.account_transactions atx
WHERE atx.source_type = 'inventory_adjustment'
  AND COALESCE(atx.debit, 0) = 0
  AND COALESCE(atx.credit, 0) = 0
GROUP BY atx.source_id
ORDER BY zero_rows DESC;

BEGIN;

-- Affected adjustment ids (any existing zero/zero row for inventory_adjustment source).
WITH affected_adjustments AS (
  SELECT DISTINCT atx.source_id AS adjustment_id
  FROM public.account_transactions atx
  WHERE atx.source_type = 'inventory_adjustment'
    AND COALESCE(atx.debit, 0) = 0
    AND COALESCE(atx.credit, 0) = 0
),
existing_txn_context AS (
  SELECT
    atx.source_id AS adjustment_id,
    MAX(atx.org_id) AS org_id,
    MAX(atx.reference_number) AS reference_number,
    MAX(atx.transaction_date) AS transaction_date
  FROM public.account_transactions atx
  JOIN affected_adjustments aa
    ON aa.adjustment_id = atx.source_id
  WHERE atx.source_type = 'inventory_adjustment'
  GROUP BY atx.source_id
),
entry_based_rows AS (
  SELECT
    iae.adjustment_id,
    iae.entity_id,
    iae.account_id,
    COALESCE(iae.debit, 0)::numeric AS debit,
    COALESCE(iae.credit, 0)::numeric AS credit,
    COALESCE(iae.description, ia.notes, 'Inventory adjustment') AS description,
    COALESCE(etc.transaction_date, ia.adjustment_date, now()) AS transaction_date,
    COALESCE(etc.reference_number, ia.reference_number) AS reference_number,
    COALESCE(
      acc.org_id,
      etc.org_id,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS org_id,
    CASE
      WHEN ia.adjustment_type::text = 'value' THEN 'Inventory Adjustment By Value'
      ELSE 'Inventory Adjustment By Quantity'
    END AS transaction_type
  FROM public.inventory_adjustment_account_entries iae
  JOIN affected_adjustments aa
    ON aa.adjustment_id = iae.adjustment_id
  JOIN public.inventory_adjustments ia
    ON ia.id = iae.adjustment_id
  LEFT JOIN public.accounts acc
    ON acc.id = iae.account_id
  LEFT JOIN existing_txn_context etc
    ON etc.adjustment_id = iae.adjustment_id
  WHERE (COALESCE(iae.debit, 0) <> 0 OR COALESCE(iae.credit, 0) <> 0)
),
entry_covered_adjustments AS (
  SELECT DISTINCT adjustment_id
  FROM entry_based_rows
),
fallback_quantity_rows AS (
  SELECT
    ia.id AS adjustment_id,
    ia.entity_id,
    ia.account_id,
    CASE WHEN qty.qty_signed < 0 THEN ABS(qty.amount) ELSE 0::numeric END AS debit,
    CASE WHEN qty.qty_signed >= 0 THEN ABS(qty.amount) ELSE 0::numeric END AS credit,
    'Auto quantity-adjustment entry (fallback repair)'::text AS description,
    COALESCE(etc.transaction_date, ia.adjustment_date, now()) AS transaction_date,
    COALESCE(etc.reference_number, ia.reference_number) AS reference_number,
    COALESCE(
      acc.org_id,
      etc.org_id,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS org_id,
    'Inventory Adjustment By Quantity'::text AS transaction_type
  FROM public.inventory_adjustments ia
  JOIN affected_adjustments aa
    ON aa.adjustment_id = ia.id
  LEFT JOIN entry_covered_adjustments eca
    ON eca.adjustment_id = ia.id
  LEFT JOIN existing_txn_context etc
    ON etc.adjustment_id = ia.id
  LEFT JOIN public.accounts acc
    ON acc.id = ia.account_id
  CROSS JOIN LATERAL (
    SELECT
      COALESCE(SUM(COALESCE(i.adjustment_value, 0)), 0)::numeric AS item_adjustment_value,
      COALESCE(SUM(ABS(COALESCE(i.quantity_adjusted, 0)) * ABS(COALESCE(i.cost_price, 0))), 0)::numeric AS computed_magnitude,
      COALESCE(SUM(COALESCE(i.quantity_adjusted, 0)), 0)::numeric AS quantity_signed
    FROM public.inventory_adjustment_items i
    WHERE i.adjustment_id = ia.id
      AND i.entity_id = ia.entity_id
  ) calc
  CROSS JOIN LATERAL (
    SELECT
      CASE
        WHEN COALESCE(ia.adjustment_value, 0) <> 0 THEN COALESCE(ia.adjustment_value, 0)
        WHEN calc.item_adjustment_value <> 0 THEN calc.item_adjustment_value
        WHEN calc.computed_magnitude <> 0 AND calc.quantity_signed >= 0 THEN -calc.computed_magnitude
        WHEN calc.computed_magnitude <> 0 AND calc.quantity_signed < 0 THEN calc.computed_magnitude
        ELSE 0::numeric
      END AS amount,
      calc.quantity_signed AS qty_signed
  ) qty
  WHERE eca.adjustment_id IS NULL
    AND ia.account_id IS NOT NULL
    AND ia.adjustment_type::text = 'quantity'
    AND qty.amount <> 0
),
fallback_value_rows AS (
  SELECT
    ia.id AS adjustment_id,
    ia.entity_id,
    ia.account_id,
    CASE WHEN vals.net_value > 0 THEN ABS(vals.net_value) ELSE 0::numeric END AS debit,
    CASE WHEN vals.net_value < 0 THEN ABS(vals.net_value) ELSE 0::numeric END AS credit,
    'Auto value-adjustment entry (fallback repair)'::text AS description,
    COALESCE(etc.transaction_date, ia.adjustment_date, now()) AS transaction_date,
    COALESCE(etc.reference_number, ia.reference_number) AS reference_number,
    COALESCE(
      acc.org_id,
      etc.org_id,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) AS org_id,
    'Inventory Adjustment By Value'::text AS transaction_type
  FROM public.inventory_adjustments ia
  JOIN affected_adjustments aa
    ON aa.adjustment_id = ia.id
  LEFT JOIN entry_covered_adjustments eca
    ON eca.adjustment_id = ia.id
  LEFT JOIN existing_txn_context etc
    ON etc.adjustment_id = ia.id
  LEFT JOIN public.accounts acc
    ON acc.id = ia.account_id
  CROSS JOIN LATERAL (
    SELECT COALESCE(SUM(COALESCE(v.adjusted_value, 0)), 0)::numeric AS net_value
    FROM public.inventory_adjustment_value_items v
    WHERE v.adjustment_id = ia.id
      AND v.entity_id = ia.entity_id
  ) vals
  WHERE eca.adjustment_id IS NULL
    AND ia.account_id IS NOT NULL
    AND ia.adjustment_type::text = 'value'
    AND vals.net_value <> 0
),
repaired_rows AS (
  SELECT * FROM entry_based_rows
  UNION ALL
  SELECT * FROM fallback_quantity_rows
  UNION ALL
  SELECT * FROM fallback_value_rows
),
delete_old AS (
  DELETE FROM public.account_transactions atx
  USING affected_adjustments aa
  WHERE atx.source_type = 'inventory_adjustment'
    AND atx.source_id = aa.adjustment_id
  RETURNING atx.id
)
INSERT INTO public.account_transactions (
  account_id,
  transaction_date,
  transaction_type,
  reference_number,
  description,
  debit,
  credit,
  source_id,
  source_type,
  contact_id,
  contact_type,
  entity_id,
  org_id
)
SELECT
  rr.account_id,
  rr.transaction_date,
  rr.transaction_type,
  rr.reference_number,
  rr.description,
  rr.debit,
  rr.credit,
  rr.adjustment_id,
  'inventory_adjustment'::text,
  NULL::uuid,
  NULL::text,
  rr.entity_id,
  rr.org_id
FROM repaired_rows rr
WHERE (COALESCE(rr.debit, 0) <> 0 OR COALESCE(rr.credit, 0) <> 0);

COMMIT;

-- Post-check: remaining zero/zero rows for inventory adjustment source.
SELECT
  atx.source_id AS adjustment_id,
  COUNT(*) AS zero_rows
FROM public.account_transactions atx
WHERE atx.source_type = 'inventory_adjustment'
  AND COALESCE(atx.debit, 0) = 0
  AND COALESCE(atx.credit, 0) = 0
GROUP BY atx.source_id
ORDER BY zero_rows DESC;
