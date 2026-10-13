-- A1  régime hors {rsi, tee}
SELECT COUNT(*) FROM (SELECT tax_regime FROM organizations UNION ALL SELECT tax_regime FROM orders) WHERE tax_regime NOT IN ('rsi', 'tee');

-- A2  organisation sans régime
SELECT COUNT(*) FROM organizations WHERE tax_regime IS NULL;

-- A3  prix remisé = 0
SELECT COUNT(*) FROM order_items WHERE discounted_price_ht = 0;

-- A4  ligne facturée sans date
SELECT COUNT(*) FROM order_items WHERE active_status = 'invoiced' AND invoiced_date IS NULL;

-- A5  ligne active, commande supprimée
SELECT COUNT(*) FROM order_items oi JOIN orders o USING (order_id) WHERE o.is_deleted AND NOT oi.is_deleted;

-- A6  facturation après le 30/06
SELECT COUNT(*) FROM order_items WHERE invoiced_date > DATE '2026-06-30';

-- A8  dernière version de devis supprimée
SELECT COUNT(*) FROM (SELECT * FROM quotes QUALIFY ROW_NUMBER() OVER (PARTITION BY quote_number ORDER BY version DESC) = 1) WHERE is_deleted;

-- A9  version créée avant la précédente
SELECT COUNT(*) FROM quotes a JOIN quotes b ON b.quote_number = a.quote_number AND b.version = a.version + 1 WHERE b.creation_date < a.creation_date;

-- A10 devis accepté sans commande valide
SELECT COUNT(*) FROM devis_retenus WHERE status = 'accepted' AND NOT converti;

-- A11 prix de devis > 100x catalogue
SELECT COUNT(*) FROM quote_items JOIN product_variants USING (variant_id) WHERE unit_price_ht > 100 * list_price_ht;

-- A12 remains <> total - payé
SELECT COUNT(*) FROM invoices WHERE remains <> total_ttc - amount_paid;

-- A13 overdue incohérent
SELECT COUNT(*) FROM invoices WHERE type = 'invoice' AND overdue <> (due_date < DATE '2026-06-30' AND total_ttc > amount_paid);

-- A14 facture sans échéance
SELECT COUNT(*) FROM invoices WHERE type = 'invoice' AND due_date IS NULL;

-- A17 client créé après son 1er devis
SELECT COUNT(*) FROM organizations o WHERE created_at > (SELECT MIN(creation_date) FROM quotes q WHERE q.client_id = o.organization_id);

-- A19 devis envoyé après le 30/06
SELECT COUNT(*) FROM quotes WHERE sent_date > DATE '2026-06-30';

