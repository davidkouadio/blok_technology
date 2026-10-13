-- Q1 : indicateurs par mois, avec et sans la commande exceptionnelle 265
SELECT COALESCE(STRFTIME(mois, '%Y-%m'), 'TOTAL S1')                                AS mois,
       SUM(ca_ht)                                                                   AS ca_ht,
       SUM(ca_ttc)                                                                  AS ca_ttc,
       SUM(achats_ttc)                                                              AS achats_ttc,
       SUM(ca_ht - cout_marge)                                                      AS marge_ht,
       ROUND(100 * SUM(ca_ht - cout_marge) / SUM(cout_marge), 1)                    AS marge_pct,
       SUM(ca_ht) FILTER (WHERE order_id <> 265)                                    AS ca_ht_hors_265,
       ROUND(100 * SUM(ca_ht - cout_marge) FILTER (WHERE order_id <> 265)
                 / SUM(cout_marge) FILTER (WHERE order_id <> 265), 1)               AS marge_pct_hors_265,
       ROUND(100 * SUM(ca_ht) FILTER (WHERE regime_vente = 'tee' AND regime_fournisseur = 'rsi')
                 / SUM(ca_ht), 1)                                                   AS part_ca_tee_rsi_pct
FROM ventes_facturees
GROUP BY ROLLUP (mois) ORDER BY mois NULLS LAST;
