-- Q4 bis : montant échu par client, ancienneté et avoir non imputé
SELECT c.client,
       SUM(c.reste_du) FILTER (WHERE c.jours_retard > 0)  AS echu_ttc,
       MAX(c.jours_retard)                                AS retard_max_j,
       COALESCE(SUM(a.total_ttc), 0)                      AS avoir_non_impute
FROM creances c
LEFT JOIN invoices a ON a.order_id = c.order_id AND a.type = 'credit_note'
GROUP BY c.client
HAVING echu_ttc > 0
ORDER BY echu_ttc DESC;
