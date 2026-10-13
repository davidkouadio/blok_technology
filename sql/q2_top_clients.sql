-- Q2 : top 5 clients par CA TTC, part du CA et de la marge
WITH par_client AS (
    SELECT client_id, SUM(ca_ttc) AS ca_ttc, SUM(ca_ht - cout_marge) AS marge_ht
    FROM ventes_facturees GROUP BY client_id
)
SELECT org.name AS client, org.segment, p.ca_ttc,
       ROUND(100 * p.ca_ttc / SUM(p.ca_ttc) OVER (), 1)     AS part_ca_ttc_pct,
       ROUND(100 * p.marge_ht / SUM(p.marge_ht) OVER (), 1) AS part_marge_pct
FROM par_client p JOIN organizations org ON org.organization_id = p.client_id
ORDER BY p.ca_ttc DESC LIMIT 5;
