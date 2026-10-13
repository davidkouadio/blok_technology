-- Règle 6 : dernière version de chaque devis, lignes actives, hors annulés et supprimés
CREATE VIEW devis_retenus AS
WITH versions AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY quote_number ORDER BY version DESC) AS rang,
           COUNT(*) OVER (PARTITION BY quote_number)                           AS nb_versions,
           MIN(creation_date) OVER (PARTITION BY quote_number)                 AS date_creation_devis
    FROM quotes
),
montants AS (
    SELECT qi.quote_id, COUNT(*) AS nb_lignes,
           -- prix saisis x1000 corrigés
           SUM(qi.quantity * IF(qi.unit_price_ht > 100 * pv.list_price_ht, qi.unit_price_ht / 1000, qi.unit_price_ht)) AS montant_ht,
           ARG_MAX(pv.category, qi.quantity * pv.list_price_ht) AS categorie_principale
    FROM quote_items qi JOIN product_variants pv USING (variant_id)
    WHERE qi.is_active
    GROUP BY qi.quote_id
),
commandes AS (
    SELECT quote_number, MIN(created_at) AS date_commande
    FROM orders WHERE status <> 'cancelled' AND NOT is_deleted GROUP BY quote_number
)
SELECT v.quote_number, v.quote_id, v.client_id, v.salesman, v.status, v.nb_versions,
       v.date_creation_devis, v.creation_date AS date_derniere_version, v.sent_date,
       m.nb_lignes, m.montant_ht, m.categorie_principale,
       c.date_commande IS NOT NULL AS converti, c.date_commande
FROM versions v
JOIN montants m USING (quote_id)
LEFT JOIN commandes c USING (quote_number)
WHERE v.rang = 1 AND v.status <> 'cancelled' AND NOT v.is_deleted;
