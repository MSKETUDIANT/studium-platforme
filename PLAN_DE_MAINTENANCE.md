# Plan de Maintenance — Studium Platform
**Version :** 1.1 | **Date :** 2026-09-20

---

## 1. Sauvegardes

La base de données Postgres est hébergée sur Supabase, qui effectue des **sauvegardes quotidiennes automatiques** au niveau de l'infrastructure (rétention selon le plan Supabase souscrit). Ce mécanisme est natif à la plateforme et ne nécessite pas de configuration applicative — il n'existe cependant, à ce jour, aucune procédure documentée de **restauration testée** (voir section 6, actions recommandées).

**Recommandation :** effectuer un test de restauration au moins une fois avant la mise en production, et documenter la procédure exacte (export manuel via `pg_dump` en complément, si une sauvegarde hors-plateforme est souhaitée).

---

## 2. Migrations de base de données

**Point d'attention majeur, constaté à plusieurs reprises durant le développement :** l'historique des migrations locales (`supabase/migrations/`) peut diverger de l'état réel de la base de production. Plusieurs migrations ont été retrouvées absentes de la base réelle alors que leur fichier existait dans le dépôt (fonctions manquantes, colonnes manquantes, policies RLS non appliquées).

**Procédure recommandée avant toute nouvelle migration :**
1. Toujours écrire les migrations de façon **idempotente** (`CREATE OR REPLACE FUNCTION`, `ADD COLUMN IF NOT EXISTS`, `DROP POLICY IF EXISTS` avant `CREATE POLICY`) — ne jamais supposer qu'une migration précédente a réellement été appliquée.
2. Après écriture, exécuter la migration manuellement dans le SQL Editor Supabase et vérifier le résultat (pas de suppose que `supabase db push` a fonctionné sans vérification).
3. Tenir à jour une trace des migrations appliquées manuellement en dehors du flux standard.

---

## 3. Monitoring et tâches planifiées (cron)

Deux Edge Functions assurent une surveillance automatisée :

| Fonction | Rôle | Fréquence |
|---|---|---|
| `health-check` | Vérifie l'état des tables critiques (programmes, profils, candidatures, documents) | À la demande / cron à configurer |
| `health-check-alert` | Envoie une alerte si `health-check` détecte un problème | Cron actif |

En plus de la surveillance technique, quatre fonctions SQL tournent quotidiennement via `pg_cron` :

| Job (`cron.job.jobname`) | Fonction SQL | Rôle | Horaire |
|---|---|---|---|
| `health-check-alert` | — (Edge Function) | Alerte si `health-check` détecte un problème | Cron actif |
| `purge-expired-documents-daily` | `purge_expired_documents` | Purge des documents > 24 mois (voir §4) | 3h00 |
| `generate-relances-daily` | `generate_relance_tasks` | Crée les tâches de relance J+7/J+14 pour les candidatures envoyées sans décision | 8h00 |
| `notify-approaching-deadlines-daily` | `notify_approaching_deadlines` | Notifie un étudiant si un programme lié à une candidature `draft`/`needsfix` arrive à échéance sous 7 jours | 7h00 |

**Recommandation :** vérifier périodiquement (mensuel) l'ensemble de ces crons via `SELECT * FROM cron.job;` dans le SQL Editor, et que les alertes `health-check-alert` arrivent bien à un canal surveillé par l'équipe technique.

---

## 4. Rétention et purge des données

Conformément au CDC (§7), les documents étudiants sont soumis à une politique de rétention de **24 mois**, purgée automatiquement :

- Fonction : `purge-expired-documents`
- Cron : `purge-expired-documents-daily`, actif, exécuté chaque jour à 3h du matin
- Action : suppression du fichier de stockage + de la ligne en base, avec journalisation dans `audit_logs` (action `documents_purged`)

**Recommandation :** vérifier périodiquement (trimestriel) le contenu de `audit_logs` filtré sur `documents_purged` pour confirmer que la purge s'exécute normalement et qu'aucune erreur ne s'accumule silencieusement.

---

## 5. Emails — limitation connue

Le projet utilise **Resend** comme fournisseur d'envoi d'emails (candidatures, rappels de tâches, invitations d'équipe). L'adresse d'envoi actuelle (`onboarding@resend.dev`) est une **adresse de test (sandbox)** : elle ne peut envoyer qu'à l'adresse email du propriétaire du compte Resend, pas à des destinataires arbitraires.

**Impact concret :** en configuration actuelle, les emails vers de vrais étudiants/universités/membres d'équipe ne partiront pas de façon fiable en production.

**Action requise avant mise en production :**
1. Vérifier un domaine réel sur [resend.com/domains](https://resend.com/domains) (ex. `studium.app`).
2. Mettre à jour l'adresse d'envoi dans le code (`FROM_EMAIL` dans les Edge Functions concernées : `send-application-email`, `send-task-reminders`) et dans la configuration SMTP de Supabase Auth (Authentication → Emails → SMTP Settings), en remplaçant `onboarding@resend.dev` par une adresse du domaine vérifié.
3. Confirmer l'activation réelle du toggle "Enable custom SMTP" dans les paramètres Supabase Auth (une configuration renseignée mais non activée ne produit aucun effet).

---

## 6. Sécurité — stockage des documents

Le bucket de stockage `documents` (passeports, relevés de notes, CV, etc.) a été passé en **mode privé** avec policies RLS (étudiant propriétaire + équipe). L'accès aux fichiers se fait désormais exclusivement via des **URLs signées à durée limitée**, générées à la demande, plutôt que par lien public permanent.

**Recommandation :** appliquer la même vigilance à tout futur bucket de stockage contenant des données sensibles (ne pas le créer en mode public par défaut).

---

## 7. Rôles et accès (RBAC)

Cinq rôles existent : Admin, Manager, Admissions, Support (équipe interne) et Ambassadeur (étudiant promu, voir §9 du Guide Utilisateur). La granularité des permissions reste volontairement simple à ce stade (accès par rôle global, pas encore de permissions fines par module). Les actions sensibles de gestion d'équipe (changer un rôle, désactiver un compte, promouvoir un ambassadeur) sont vérifiées **côté serveur** (pas seulement dans l'interface), pour éviter tout contournement.

**Point corrigé (2026-09-20) :** la table `user_roles` n'avait qu'une policy RLS `users_read_own_role` (chacun ne lit que son propre rôle) — un membre du staff qui relisait le rôle d'un *autre* utilisateur recevait silencieusement 0 ligne (pas une erreur), ce qui cassait tout affichage dépendant du rôle d'un tiers (ex. badge "Déjà ambassadeur" sur la fiche étudiant, qui redevenait invisible après rechargement de page). Policy `staff_read_all_user_roles` ajoutée pour que le staff puisse lire le rôle de n'importe quel utilisateur.

**Recommandation :** si le nombre de membres d'équipe ou la sensibilité des actions augmente, envisager une matrice de permissions plus fine par module (candidatures, messagerie, exports, étudiants) — c'est un chantier à part entière, à cadrer avec l'équipe avant implémentation.

---

## 8. Limite PostgREST — pagination des listes

Supabase (PostgREST) plafonne chaque réponse à **1000 lignes par défaut** (`db-max-rows`), même sans `.range()` explicite dans la requête : au-delà, une liste serait tronquée **silencieusement**, sans erreur visible. Les pages dashboard listant potentiellement beaucoup de lignes (Étudiants, Candidatures, Programmes) chargent désormais leurs données via un helper commun (`fetchAllRows`, `shared/utils/fetch_all_rows.ts` côté dashboard ; boucle équivalente côté mobile pour le catalogue programmes) qui pagine par lots de 1000 jusqu'à épuisement.

**Recommandation :** toute nouvelle page listant une table qui peut dépasser 1000 lignes à terme (étudiants, candidatures, documents, logs) doit réutiliser ce même helper plutôt qu'un `.select()` simple — sinon le risque de troncature silencieuse réapparaît.

---

## 9. Checklist de maintenance périodique

| Fréquence | Action |
|---|---|
| Quotidienne | Vérifier qu'aucune alerte `health-check-alert` n'a été déclenchée sans traitement |
| Hebdomadaire | Parcourir les tâches de relance J+7/J+14 en attente dans le dashboard |
| Mensuelle | Vérifier les crons actifs (`SELECT * FROM cron.job;`), contrôler les logs d'erreur des Edge Functions |
| Trimestrielle | Contrôler la purge des documents (`audit_logs`), revoir les accès équipe (comptes inactifs à nettoyer) |
| Avant chaque déploiement | Exécuter manuellement toute nouvelle migration SQL et vérifier son application réelle (voir section 2) |

---

## 10. Contacts et responsabilités

À compléter par l'équipe : nom du responsable technique, canal d'alerte (email/Slack), accès au dashboard Supabase et au compte Resend.
