-- Q3 bis : réactivité et suivi par commercial
SELECT salesman                                                                        AS commercial,
       ROUND(AVG(DATE_DIFF('day', date_derniere_version, sent_date)), 1)               AS delai_envoi_moyen_j,
       COUNT(*) FILTER (WHERE status = 'sent' AND NOT converti AND sent_date <= DATE '2026-06-15') AS sans_reponse,
       SUM(montant_ht) FILTER (WHERE status = 'sent' AND NOT converti AND sent_date <= DATE '2026-06-15') AS montant_sans_reponse,
       COUNT(*) FILTER (WHERE montant_ht > 5e6)                                        AS devis_plus_5M,
       COUNT(*) FILTER (WHERE montant_ht > 5e6 AND converti)                           AS convertis_plus_5M,
       COUNT(*) FILTER (WHERE sent_date IS NULL OR sent_date > DATE '2026-06-30')      AS non_envoyes_30_06,
       SUM(montant_ht) FILTER (WHERE sent_date IS NULL OR sent_date > DATE '2026-06-30') AS montant_non_envoye
FROM devis_retenus
WHERE date_creation_devis BETWEEN DATE '2026-01-01' AND DATE '2026-06-30'
GROUP BY 1 ORDER BY 1;
