# Guide Utilisateur — Équipe Studium (Dashboard)
**Version :** 1.1 | **Date :** 2026-09-20 | **Public :** Admin, Agent Admissions, Manager, Support

---

## 1. Connexion

Rendez-vous sur l'URL du dashboard, saisissez votre email professionnel et votre mot de passe. Si vous venez d'être invité·e, vous avez reçu un email pour définir votre mot de passe avant votre première connexion.

En cas de mot de passe oublié, utilisez le lien "Mot de passe oublié ?" sur l'écran de connexion.

**Rôles disponibles :**
| Rôle | Ce qu'il peut faire |
|---|---|
| **Admin** | Accès complet, y compris la gestion de l'équipe (inviter, changer un rôle, désactiver un compte) |
| **Manager** | Vue d'ensemble, reporting, validation des candidatures et programmes |
| **Admissions** | Gestion quotidienne des candidatures, documents, programmes, envoi aux universités |
| **Support** | Messagerie et tickets étudiants |

Seul un **Admin** voit et utilise la page "Équipe" (section 7).

---

## 2. Vue d'ensemble (Tableau de bord)

*Réservé à Admin et Manager.*

La page **Tableau de bord**, accessible dès la connexion, affiche en un coup d'œil les indicateurs clés : nombre de candidatures par statut, corrections requises, taux de validation, score de complétude moyen, taux d'acceptation, délai moyen de validation. C'est le point de départ pour repérer rapidement ce qui nécessite une action.

Pour l'analyse détaillée (graphiques mensuels, top pays/programmes, exports), voir la page **Rapports** (section 9).

---

## 3. Gérer les candidatures

### 3.1 Vue pipeline (Kanban)
La page **Candidatures** présente les dossiers sous forme de colonnes correspondant à leur statut : Brouillon, Soumise, À corriger, Vérifiée, Envoyée, En attente décision, Acceptée, Refusée, Archivée.

Vous pouvez faire glisser une carte d'une colonne à l'autre pour changer son statut — **sauf vers "Envoyée"**, qui n'est jamais un simple déplacement manuel (voir 3.3).

### 3.2 Traiter un dossier
Cliquez sur une candidature pour ouvrir sa fiche détaillée :
- **Résumé** : informations étudiant et programme.
- **Documents** : liste des pièces jointes, avec boutons "Voir" (ouvre le document dans un nouvel onglet), "Approuver" ou "Rejeter" (avec motif obligatoire).
- **Historique des statuts** : traçabilité complète des changements.
- **Notes internes** : visibles uniquement par l'équipe, jamais par l'étudiant.
- **Formations / Expériences** : parcours académique et professionnel déclaré par l'étudiant.

### 3.3 Envoyer une candidature à l'université
Une fois le dossier complet et tous les documents approuvés :
1. Ouvrez la fiche candidature.
2. Renseignez (ou vérifiez) l'email de contact de l'université et les éventuels destinataires en copie.
3. Cliquez sur **"Envoyer à l'université"**.

Le système génère automatiquement un **pack PDF complet** (profil, parcours, motivation, documents fusionnés) et l'envoie par email avec preuve d'envoi (log conservé, visible dans l'historique). Le statut passe à "Envoyée" uniquement si l'envoi a réellement réussi.

> Le pack n'est régénéré que si le profil ou les documents ont changé depuis la dernière génération — sinon la version déjà générée est réutilisée pour ne pas dupliquer inutilement les fichiers stockés.

### 3.4 Demander une correction
Si un dossier est incomplet, passez son statut à "À corriger" en précisant le motif : l'étudiant reçoit automatiquement une notification et un message dans sa messagerie.

### 3.5 Télécharger un résumé PDF interne
Le bouton "Télécharger PDF" sur une fiche candidature génère un document de synthèse à usage interne (résumé, score, historique, documents) — différent du pack envoyé à l'université, qui lui inclut les fichiers fusionnés.

### 3.6 Export
Le bouton "Export CSV" en haut de la liste candidatures télécharge l'ensemble des dossiers filtrés au format tableur.

---

## 4. Gérer les documents

La page **Documents** (ou l'onglet équivalent dans la fiche candidature) permet de vérifier chaque pièce : format, nom du fichier, taille. Approuvez ou rejetez avec un motif clair — l'étudiant voit immédiatement le résultat côté mobile.

Les documents sont stockés de façon sécurisée : leur ouverture ("Voir") génère un lien d'accès temporaire, valable quelques dizaines de secondes, plutôt qu'un lien permanent.

---

## 5. Gérer les étudiants

La page **Étudiants** liste tous les comptes avec leur score de complétude de profil. Cliquez sur un nom pour voir son détail : informations, documents, historique de candidatures, et ajoutez des notes internes propres à cet étudiant (visibles uniquement par l'équipe).

### 5.1 Promouvoir un étudiant en ambassadeur *(Admin et Manager uniquement)*

Depuis la fiche détaillée d'un étudiant, le bouton **"Promouvoir ambassadeur"** (en haut à droite) donne à ce compte l'accès au parrainage côté mobile (code de parrainage, suivi des filleuls, commissions). Un étudiant déjà promu affiche un badge "Déjà ambassadeur" à la place du bouton. Cette action ne modifie ni ne supprime rien de son profil ou de ses candidatures — l'étudiant garde tous ses accès habituels, il gagne simplement une fonctionnalité en plus.

Le suivi des commissions et des demandes de paiement des ambassadeurs se fait depuis la page **Commissions** (section 11).

---

## 6. Messagerie

Chaque étudiant dispose d'une conversation unique avec "l'équipe Studium". Répondez directement depuis la page **Messagerie** — l'étudiant reçoit une notification push sur son téléphone. Des réponses-types sont disponibles pour gagner du temps sur les questions fréquentes.

---

## 7. Tâches & Relances

### 7.1 Tâches manuelles
Créez une tâche via "+ Nouvelle tâche" (titre, échéance, priorité, personne assignée). Cochez-la une fois terminée.

### 7.2 Relances automatiques
Le système crée automatiquement une tâche de relance si une candidature envoyée à une université reste **sans décision depuis 7 jours** (relance normale) ou **14 jours** (relance urgente). Ces tâches apparaissent dans les onglets "Relances J+7" / "Relances J+14" de la page Tâches, et un email de rappel est envoyé à l'équipe Admissions.

---

## 8. Gérer l'équipe *(Admin uniquement)*

Page **Paramètres → Équipe** :

- **Inviter un membre** : bouton en haut à droite, renseignez email + rôle. La personne reçoit un email pour définir son mot de passe.
- **Changer le rôle d'un membre existant** : cliquez sur le badge de rôle dans la colonne "Rôle" et choisissez le nouveau rôle dans le menu déroulant.
- **Désactiver / réactiver un compte** : bouton dans la colonne "Actions". Un compte désactivé ne peut plus se connecter.

> Ces actions sont réservées aux administrateurs : le serveur les refuse pour tout autre rôle, même en cas de manipulation technique de l'interface.

---

## 9. Reporting & Exports

La page **Reporting** affiche les indicateurs clés (nombre de candidatures par période, taux de complétude, délai moyen de validation, taux d'acceptation, top pays/universités) et permet de télécharger un rapport mensuel au format PDF, en plus des exports CSV disponibles sur les pages Candidatures et Étudiants.

---

## 10. Paramètres de la plateforme *(Admin uniquement)*

Depuis **Paramètres → Plateforme**, configurez : langue par défaut, limites d'upload (taille, formats acceptés), nombre minimum de mots pour la lettre de motivation, modèles d'email, taux de commission ambassadeur.

---

## 11. Commissions ambassadeurs *(Admin et Manager)*

La page **Commissions** liste les ambassadeurs actifs, leurs filleuls et le statut de chaque commission (en attente, payable, payée). Lorsqu'un ambassadeur demande le versement d'une commission `payable` depuis l'app mobile, une tâche est créée automatiquement dans **Tâches**, incluant les coordonnées de paiement renseignées par l'ambassadeur (IBAN ou email PayPal) pour que l'équipe puisse traiter le virement sans aller-retour.

---

## Besoin d'aide ?

En cas de comportement inattendu, notez l'heure exacte et l'action effectuée, puis contactez le support technique — les journaux d'audit (page **Audit**, Admin uniquement) permettent de retracer précisément qui a fait quoi et quand.
