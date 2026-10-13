-- Partie 2 : variables par devis, connues au moment de l'envoi (prérequis : 02_vue_devis_retenus.sql)
CREATE VIEW features_devis AS
SELECT d.*, org.segment,
       DATE_DIFF('day', d.date_derniere_version, d.sent_date) AS delai_envoi_j,
       -- commandes passées avant la création du devis
       (SELECT COUNT(*) FROM orders o
         WHERE o.client_id = d.client_id AND o.status <> 'cancelled' AND NOT o.is_deleted
           AND o.created_at < d.date_creation_devis)            AS client_nb_commandes_avant,
       CASE WHEN d.sent_date IS NULL OR d.sent_date > DATE '2026-06-30' THEN 'non envoyé au 30/06'
            WHEN d.sent_date > DATE '2026-06-15'                           THEN 'récent : à scorer'
            ELSE 'issue connue : apprentissage' END              AS population
FROM devis_retenus d
JOIN organizations org ON org.organization_id = d.client_id;
