-- Règle 7 : factures (hors avoirs) non soldées au 30/06/2026
CREATE VIEW creances AS
SELECT i.*, org.name AS client,
       i.total_ttc - i.amount_paid                                          AS reste_du,
       DATE_DIFF('day', COALESCE(i.due_date, i.invoice_date + 60), DATE '2026-06-30') AS jours_retard
FROM invoices i JOIN organizations org ON org.organization_id = i.client_id
WHERE i.type = 'invoice' AND NOT i.is_deleted
  AND i.invoice_date <= DATE '2026-06-30'
  AND i.total_ttc - i.amount_paid > 0;
