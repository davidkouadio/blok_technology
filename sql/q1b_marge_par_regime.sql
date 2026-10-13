-- Q1 bis : marge par combinaison de régimes fiscaux
SELECT regime_vente || ' / ' || regime_fournisseur                         AS client_fournisseur,
       ROUND(100 * SUM(ca_ht) / (SELECT SUM(ca_ht) FROM ventes_facturees), 1) AS part_ca_pct,
       ROUND(100 * SUM(ca_ht - cout_marge) / SUM(cout_marge), 1)          AS marge_pct,
       ROUND(100 * SUM(ca_ht - achats_ht) / SUM(achats_ht), 1)            AS marge_pct_sans_tva_perdue,
       SUM(cout_marge - achats_ht)                                         AS tva_non_recuperable
FROM ventes_facturees GROUP BY 1 ORDER BY marge_pct;
