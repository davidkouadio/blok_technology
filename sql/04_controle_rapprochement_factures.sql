-- Contrôle : TTC recalculé depuis les lignes vs total_ttc facturé
WITH ttc_lignes AS (
    SELECT oi.order_id,
           SUM(oi.quantity * COALESCE(NULLIF(oi.discounted_price_ht, 0), oi.price_ht)
               * IF(COALESCE(LOWER(o.tax_regime), LOWER(c.tax_regime), 'rsi') = 'tee', 1, 1.18)) AS ttc
    FROM order_items oi
    JOIN orders o USING (order_id)
    JOIN organizations c ON c.organization_id = o.client_id
    WHERE oi.active_status = 'invoiced' AND NOT oi.is_deleted AND oi.invoiced_date IS NOT NULL
    GROUP BY 1
)
SELECT COUNT(*) AS factures, COUNT(*) FILTER (WHERE ABS(i.total_ttc - t.ttc) <= 1) AS identiques
FROM invoices i JOIN ttc_lignes t USING (order_id)
WHERE i.type = 'invoice';
