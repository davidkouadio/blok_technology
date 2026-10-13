-- Q3 ter : conversion selon le délai entre création et envoi
SELECT CASE WHEN delai <= 3 THEN '0-3 j' WHEN delai <= 5 THEN '4-5 j' WHEN delai <= 7 THEN '6-7 j' ELSE '8 j et +' END AS delai_envoi,
       COUNT(*) AS nb_devis, ROUND(100 * AVG(converti::INT), 1) AS conversion_pct
FROM (SELECT *, DATE_DIFF('day', date_derniere_version, sent_date) AS delai FROM devis_retenus)
WHERE date_creation_devis BETWEEN DATE '2026-01-01' AND DATE '2026-06-30'
  AND sent_date <= DATE '2026-06-15'
GROUP BY 1 ORDER BY 1;
