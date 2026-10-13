-- Q3 : devis créés au S1, montant HT et taux de conversion par commercial
WITH s1 AS (
    SELECT *, NOT converti AND (sent_date IS NULL OR sent_date > DATE '2026-06-15') AS encore_ouvert
    FROM devis_retenus
    WHERE date_creation_devis BETWEEN DATE '2026-01-01' AND DATE '2026-06-30'
)
SELECT COALESCE(salesman, 'TOTAL')                                                 AS commercial,
       COUNT(*)                                                                     AS nb_devis,
       SUM(montant_ht)                                                              AS montant_ht,
       ROUND(100 * AVG(converti::INT), 1)                                           AS conversion_pct,
       ROUND(100 * SUM(montant_ht) FILTER (WHERE converti) / SUM(montant_ht), 1)     AS conversion_valeur_pct,
       SUM(encore_ouvert::INT)                                                      AS encore_ouverts,
       ROUND(100 * AVG(converti::INT) FILTER (WHERE NOT encore_ouvert), 1)           AS conversion_issue_connue_pct
FROM s1 GROUP BY ROLLUP (salesman) ORDER BY salesman NULLS LAST;
