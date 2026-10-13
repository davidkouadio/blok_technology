-- Q4 : encours et échu par tranche d'ancienneté
SELECT COALESCE(tranche, 'TOTAL') AS tranche, COUNT(*) AS nb_factures, SUM(reste_du) AS montant_ttc
FROM (SELECT *, CASE WHEN jours_retard <= 0 THEN '0. à échoir' WHEN jours_retard <= 30 THEN '1. 1-30 j'
                     WHEN jours_retard <= 60 THEN '2. 31-60 j' WHEN jours_retard <= 90 THEN '3. 61-90 j'
                     ELSE '4. 90+ j' END AS tranche FROM creances)
GROUP BY ROLLUP (tranche) ORDER BY tranche NULLS LAST;
