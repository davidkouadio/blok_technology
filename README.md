# BLOK · Business case Stage Data & IA

Candidat : Kouadio Jean David Mathieu (Epitech, Master II Économie internationale, parcours Data/IA)

## Structure

```
.
├── data/        # les 8 CSV fournis (non versionnés : données confidentielles)
├── sql/         # requêtes exécutables telles quelles dans DuckDB
│   ├── 01_vue_ventes_facturees.sql   # règles 1 à 5
│   ├── 02_vue_devis_retenus.sql      # règle 6
│   ├── 03_vue_creances.sql           # règle 7
│   ├── 04_controle_rapprochement_factures.sql
│   ├── 05_vue_features_devis.sql     # variables du modèle
│   ├── q1_… à q4_….sql               # une requête par chiffre publié
│   └── q5_controles_qualite.sql      # 15 contrôles automatiques
├── notebooks/
│   ├── 01_partie1_sql_analyse.ipynb
│   ├── 02_partie2_modele_conversion.ipynb
│   └── 03_partie3_smart_rfq.ipynb
├── src/smart_rfq.py      # moteur Smart RFQ (règles + recherche floue sur le catalogue)
├── annotations/          # bonnes réponses annotées à la main (30 messages)
├── outputs/     # graphique Q1, scores des devis ouverts
└── requirements.txt
```

## Relancer

```bash
pip install -r requirements.txt
# copier les 8 CSV dans data/
jupyter nbconvert --to notebook --execute --inplace notebooks/01_partie1_sql_analyse.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/02_partie2_modele_conversion.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/03_partie3_smart_rfq.ipynb
```

Chaque requête des notebooks est aussi enregistrée dans `sql/`. Le notebook 2 lit directement `sql/02_vue_devis_retenus.sql` : la définition d'un devis est donc la même dans les deux parties. Testé avec Python 3.13, DuckDB 1.5, scikit-learn 1.9.

## Démarche

1. Profiler avant de calculer : 19 anomalies repérées dans les colonnes utilisées par les règles métier.
2. Écrire chaque règle une seule fois dans trois vues SQL commentées ; toutes les questions en partent.
3. Vérifier par une source indépendante : le TTC recalculé depuis les lignes de commande retrouve 232 factures sur 232.
4. Écrire les hypothèses et dire ce qui n'est pas fait.

## Résultats clés

Partie 1
- CA S1 : 274,0 M HT, 300,6 M TTC, marge 30,0 M (12,3 %) ; 16,0 % hors commande exceptionnelle.
- Avril (99 M HT) est gonflé par une commande de 12 000 sacs de ciment à 1,6 % de marge.
- La TVA non récupérable (client exonéré, fournisseur assujetti) touche 39 % du CA et a coûté 15,8 M de marge.
- Top 5 clients : 55 % du CA TTC, 43 % hors commande 265. Le risque est surtout sur la marge.
- Commercial à aider : S03 (conversion la plus basse, 59 M de devis restés sans relance).
- Encours au 30/06 : 48,3 M TTC, dont 32,0 M échus ; 3 clients font 90 % de l'échu.
- Trois anomalies auraient produit des chiffres faux mais crédibles : prix remisé à 0 (86 % du CA effacé), `overdue` (99 % de l'échu masqué), prix de devis x1000 (pipeline de S04 doublé).

Partie 2
- 352 devis à issue connue (toutes les conversions arrivent dans les 12 jours qui suivent l'envoi).
- Validation chronologique, régularisation choisie par validation croisée temporelle, test utilisé une fois.
- Régression logistique : AUC 0,64 [0,52 ; 0,75] contre 0,58 pour la meilleure règle naïve. Relancer le top 30 % donne 67 % de conversion contre 60 %. Gain réel mais fragile vu le volume de données.
- Ajouter le statut du devis donne une AUC de 0,96 : c'est la fuite que l'énoncé met en garde.
- Leviers : envoyer en moins de 3 jours (62 % contre 6 % au-delà de 8 jours), relancer avant J+12, appeler avant d'envoyer les gros devis aux nouveaux clients.

Partie 3
- Prototype à base de règles et de recherche floue sur le catalogue : chaque message donne des `variant_id`, une quantité, un indice de confiance, ou un statut explicite « absent du catalogue » / « ambigu, à faire préciser ». Environ 2 ms par message, coût nul, décisions explicables.
- Taux de bonnes réponses sur les 30 messages annotés à la main : 27/30 (90 %). Score optimiste : les règles ont été conçues avec ces messages sous les yeux.
- LLM en recours pour les messages à faible confiance (environ 10 % des cas) : coût estimé de l'ordre de 0,1 à 1 USD par mois pour 1 000 messages. Le coût n'est pas le frein ; la latence et le contrôle des réponses inventées le sont.

## Limites et ce qui n'est pas fait

- Avoirs non déduits du CA (effet maximal 0,9 M TTC).
- Pas d'historique daté des paiements ni des statuts : la situation au 30/06 est approchée.
- Le modèle n'a ni motif de refus, ni prix concurrents : ce serait la première donnée à collecter.

## Journal IA

- Outil : Claude (Anthropic).
- Parties 1 et 2 : le code a été généré en grande partie avec Claude, sous ma direction. Mon travail : cadrer la démarche, valider chaque choix de méthode, vérifier les chiffres (rapprochement avec les factures, recalcul indépendant des chiffres clés), rédiger les commentaires et comprendre chaque requête. 
- Partie 3 : moteur `src/smart_rfq.py` et notebook générés avec Claude. Annotation manuelle des 30 messages, analyse des erreurs et réflexion 3.B rédigées par moi.
- Erreurs de l'IA repérées et corrigées :
  - une affirmation non chiffrée (« la TVA non récupérable coûte environ 2 points de marge ») a été remplacée par le calcul : 15,8 M, soit 7,8 points ;
  - des devis envoyés en juillet étaient traités comme ouverts au 30 juin ; cela a révélé que les statuts reflètent la date d'extraction ;
  - la première population d'apprentissage gardait les devis récents déjà convertis et écartait les autres, ce qui biaisait le test.
