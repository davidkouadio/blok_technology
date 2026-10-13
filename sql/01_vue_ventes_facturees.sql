-- Règles 1 à 5 : lignes facturées au S1 2026
CREATE VIEW ventes_facturees AS
WITH lignes AS (
    SELECT oi.order_item_id, oi.order_id, o.client_id, oi.variant_id, oi.quantity,
           DATE_TRUNC('month', oi.invoiced_date)                       AS mois,
           COALESCE(NULLIF(oi.discounted_price_ht, 0), oi.price_ht)    AS prix_vente,       -- règle 2
           oi.purchase_price_ht                                        AS prix_achat,
           COALESCE(LOWER(o.tax_regime), LOWER(cli.tax_regime), 'rsi') AS regime_vente,     -- règle 3
           COALESCE(LOWER(fou.tax_regime), 'rsi')                      AS regime_fournisseur -- règle 4
    FROM order_items oi
    JOIN orders o             ON o.order_id = oi.order_id
    JOIN organizations cli    ON cli.organization_id = o.client_id
    JOIN organizations fou    ON fou.organization_id = oi.supplier_id
    WHERE oi.active_status = 'invoiced'                                                    -- règle 1
      AND oi.invoiced_date BETWEEN DATE '2026-01-01' AND DATE '2026-06-30'
      AND o.status <> 'cancelled'
      AND NOT o.is_deleted AND NOT oi.is_deleted
)
SELECT *,
       quantity * prix_vente                                                     AS ca_ht,
       quantity * prix_vente * IF(regime_vente = 'tee', 1, 1.18)                 AS ca_ttc,
       quantity * prix_achat * IF(regime_fournisseur = 'rsi', 1.18, 1)           AS achats_ttc,
       quantity * prix_achat                                                     AS achats_ht,
       -- règle 5 : coût majoré de 18 % si client TEE et fournisseur RSI
       quantity * prix_achat * IF(regime_vente = 'tee' AND regime_fournisseur = 'rsi', 1.18, 1) AS cout_marge
FROM lignes;
