-- Q2 bis : concentration hors commande 265
WITH par_client AS (
    SELECT client_id, SUM(ca_ttc) AS ca_ttc FROM ventes_facturees WHERE order_id <> 265 GROUP BY client_id
), rangs AS (
    SELECT ca_ttc, ROW_NUMBER() OVER (ORDER BY ca_ttc DESC) AS rang FROM par_client
)
SELECT ROUND(100 * SUM(ca_ttc) FILTER (WHERE rang = 1) / SUM(ca_ttc), 1)  AS top1_pct,
       ROUND(100 * SUM(ca_ttc) FILTER (WHERE rang <= 5) / SUM(ca_ttc), 1) AS top5_pct,
       COUNT(*) AS clients_actifs
FROM rangs;
