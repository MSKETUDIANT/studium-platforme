# Cahier de Recette — Studium Platform
**Version :** 1.2 | **Date de création :** 2026-06-06 | **Dernière mise à jour :** 2026-09-20 | **Statut :** En cours

---

## Légende
- OK — fonctionnel, vérifié
- KO — bug ou absent
- PARTIEL — fonctionne avec réserve (voir note)
- NON TESTÉ

---

## MODULE 1 — Authentification Mobile

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 1.1 | Inscription | Remplir email + mdp + valider CGU | Compte créé, email de confirmation envoyé | OK |
| 1.2 | Confirmation email | Cliquer lien dans l'email | App affiche "email confirmé", redirection login | OK |
| 1.3 | Connexion valide | Email + mdp corrects | Accès au dashboard étudiant | OK |
| 1.4 | Connexion invalide | Mauvais mdp | Message d'erreur clair, pas de crash | NON TESTÉ |
| 1.5 | Reset password | Cliquer "Mot de passe oublié" → email | Email de reset reçu, nouveau mdp fonctionne | NON TESTÉ |
| 1.6 | Déconnexion | Appuyer "Se déconnecter" | Retour à l'écran login, session effacée | NON TESTÉ |
| 1.7 | Session persistante | Fermer et rouvrir l'app | Utilisateur toujours connecté | NON TESTÉ |

---

## MODULE 2 — Profil Étudiant

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 2.1 | Compléter infos personnelles | Remplir tous les champs obligatoires | Sauvegarde OK, % complétude augmente | OK |
| 2.2 | Ajouter parcours académique | Ajouter un diplôme | Item dans la liste, score mis à jour | OK |
| 2.3 | Ajouter expérience | Ajouter une expérience pro | Item dans la liste | OK |
| 2.4 | Lettre de motivation | Écrire > 300 mots | Sauvegarde OK | OK |
| 2.5 | Lettre de motivation courte | Écrire < 300 mots et sauvegarder | Avertissement min. mots | NON TESTÉ |
| 2.6 | Photo de profil | Uploader une photo | Photo affichée dans le header | NON TESTÉ |
| 2.7 | Profil 100% complet | Remplir toutes les sections | Badge "Profil complet" affiché | OK |
| 2.8 | Auto-save | Fermer l'app en cours de saisie | Données retrouvées à la réouverture | NON TESTÉ |

---

## MODULE 3 — Documents

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 3.1 | Upload CV PDF | Sélectionner un PDF < 10MB | Document uploadé, visible dans la liste | OK |
| 3.2 | Upload image | Sélectionner un JPG/PNG | Document uploadé correctement | OK |
| 3.3 | Fichier trop lourd | Upload > 10MB | Message d'erreur taille | NON TESTÉ |
| 3.4 | Voir un document | Taper sur un document | Ouverture via URL signée (bucket privé) | OK |
| 3.5 | Supprimer un document | Confirmer suppression | Document retiré de la liste | NON TESTÉ |
| 3.6 | Document approuvé | Dashboard approuve le doc | Badge vert "Approuvé" affiché côté mobile | NON TESTÉ |
| 3.7 | Document rejeté | Dashboard rejette avec motif | Badge rouge + motif visible côté mobile | NON TESTÉ |

---

## MODULE 4 — Programmes

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 4.1 | Liste programmes | Ouvrir l'onglet Programmes | Liste chargée (depuis cache si disponible) | NON TESTÉ |
| 4.2 | Recherche | Taper "Master" dans la barre | Filtrage en temps réel | NON TESTÉ |
| 4.3 | Filtre pays | Sélectionner "France" | Seuls les programmes français affichés | NON TESTÉ |
| 4.4 | Filtre niveau | Sélectionner "Master" | Seuls les Masters affichés | NON TESTÉ |
| 4.5 | Réinitialiser filtres | Appuyer "Réinitialiser" | Tous les programmes réaffichés | NON TESTÉ |
| 4.6 | Détail programme | Taper sur un programme | Fiche détail (université, deadline, coût...) | NON TESTÉ |
| 4.7 | Ajouter favori | Appuyer sur l'icône cœur d'un programme | Icône pleine, programme dans Mes Favoris | NON TESTÉ |
| 4.8 | Retirer favori | Appuyer sur l'icône cœur d'un favori | Retiré de la liste favoris | NON TESTÉ |
| 4.9 | Cache offline | Couper le réseau, ouvrir Programmes | Liste affichée depuis le cache | NON TESTÉ |

---

## MODULE 5 — Candidatures Mobile

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 5.1 | Créer candidature | Appuyer "+ Nouvelle candidature" | Wizard lancé | OK |
| 5.2 | Step 1 : Sélectionner programme | Choisir un programme | Passage au step 2 | OK |
| 5.3 | Step 2 : Documents | Sélectionner des documents | Documents joints | OK |
| 5.4 | Step 3 : Récapitulatif | Vérifier résumé | Toutes les infos correctes | NON TESTÉ |
| 5.5 | Soumettre candidature | Appuyer "Soumettre" | Statut → "Soumise", notification envoyée | OK |
| 5.6 | Brouillon | Fermer avant soumission | Candidature en statut "Brouillon" | NON TESTÉ |
| 5.7 | Liste candidatures | Ouvrir l'onglet Dossiers | Toutes les candidatures listées | NON TESTÉ |
| 5.8 | Filtres candidatures | Filtrer par "Acceptée" | Seules les acceptées affichées | NON TESTÉ |
| 5.9 | Détail candidature | Taper sur une candidature | Timeline + documents + statut actuel | NON TESTÉ |
| 5.10 | Générer PDF | Appuyer "Télécharger PDF" | PDF généré et téléchargé | OK |
| 5.11 | Correction demandée | Dashboard met statut NeedsFix | Notif push reçue + message visible | NON TESTÉ |

---

## MODULE 6 — Messagerie Mobile

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 6.1 | Ouvrir messagerie | Onglet Messages | Conversation "Équipe Studium" visible | NON TESTÉ |
| 6.2 | Envoyer message | Écrire et envoyer | Message affiché instantanément | NON TESTÉ |
| 6.3 | Recevoir message | Dashboard répond | Message reçu en temps réel | NON TESTÉ |
| 6.4 | Notification message | App fermée, message reçu | Notification push affichée | NON TESTÉ |
| 6.5 | Indicateur non-lu | Nouveau message reçu | Badge sur l'onglet Messages | NON TESTÉ |

---

## MODULE 7 — Notifications Mobile

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 7.1 | Centre notifications | Ouvrir cloche | Liste des notifications in-app | OK |
| 7.2 | Marquer comme lu | Taper sur une notif | Disparaît des non-lues | NON TESTÉ |
| 7.3 | Tout marquer lu | Appuyer "Tout marquer" | Badge cloche → 0 | NON TESTÉ |
| 7.4 | Push statut changé | Dashboard change statut | Push reçu sur Android | NON TESTÉ |

> **7.1** : vérifié en conditions réelles — soumission d'une candidature de test, notification "Candidature reçue" apparue dans le centre de notifications mobile avec le bon libellé et le bon programme. Un correctif a aussi été nécessaire côté trigger SQL (`notify_application_status`) : il ne se déclenchait qu'en `UPDATE`, donc une candidature soumise directement (sans brouillon préalable) ne générait jamais cette notification. Une notification "Deadline approche" a également été ajoutée (candidature `draft`/`needsfix` dont le programme arrive à échéance sous 7 jours) et vérifiée par déclenchement manuel de la fonction SQL correspondante.

---

## MODULE 8 — Paramètres Mobile

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 8.1 | Changer langue | FR → EN | Interface en anglais | NON TESTÉ |
| 8.2 | Retour français | EN → FR | Interface en français | NON TESTÉ |
| 8.3 | Mode sombre | Activer dark mode | Toute l'app passe en sombre | NON TESTÉ |
| 8.4 | Changer mot de passe | Email de reset envoyé | Email reçu | NON TESTÉ |
| 8.5 | Persistance settings | Fermer/rouvrir app | Langue et thème conservés | NON TESTÉ |

---

## MODULE 9 — Dashboard : Candidatures

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 9.1 | Vue kanban | Ouvrir la page | Colonnes par statut affichées | NON TESTÉ |
| 9.2 | Déplacer candidature | Changer statut | Carte déplacée dans la bonne colonne | NON TESTÉ |
| 9.3 | Valider candidature | Cliquer "Valider" | Statut → Verified, notif push étudiant | NON TESTÉ |
| 9.4 | Demander correction | Mettre statut NeedsFix + note | Message envoyé + push reçu | NON TESTÉ |
| 9.5 | Envoyer email université | Cliquer "Envoyer à l'université" | Email envoyé (pack + docs), log créé, statut → Sent | OK |
| 9.6 | Voir logs email | Ouvrir historique email | Date, destinataire, statut affiché | NON TESTÉ |
| 9.7 | Export CSV | Cliquer "Export CSV" | Fichier téléchargé avec toutes les colonnes | NON TESTÉ |

---

## MODULE 10 — Dashboard : Documents

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 10.1 | Voir document étudiant | Cliquer sur un doc | Ouverture via URL signée (bucket privé) | PARTIEL |
| 10.2 | Approuver document | Cliquer "Approuver" | Statut → Approuvé côté mobile aussi | NON TESTÉ |
| 10.3 | Rejeter avec motif | Saisir motif + rejeter | Statut → Rejeté, motif visible mobile | NON TESTÉ |
| 10.4 | Générer PDF pack | Cliquer "Générer PDF" | PDF créé, lien de téléchargement | OK |

> **10.1** : correctif appliqué (bucket `documents` passé privé, URL signée générée à la demande) et code vérifié, mais pas encore reconfirmé par un clic réel dans le dashboard après le changement.

---

## MODULE 11 — Dashboard : Étudiants

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 11.1 | Liste étudiants | Ouvrir la page | Tous les étudiants avec score | NON TESTÉ |
| 11.2 | Recherche | Taper un nom | Filtrage en temps réel | NON TESTÉ |
| 11.3 | Voir profil détaillé | Cliquer sur un étudiant | Infos + documents + candidatures | NON TESTÉ |
| 11.4 | Export CSV | Cliquer "Export CSV" | Fichier avec tous les étudiants | NON TESTÉ |

---

## MODULE 12 — Dashboard : Messagerie

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 12.1 | Liste conversations | Ouvrir messagerie | Toutes les conversations visibles | NON TESTÉ |
| 12.2 | Répondre à un étudiant | Écrire + envoyer | Message reçu côté mobile | NON TESTÉ |
| 12.3 | Notification push | Répondre depuis dashboard | Push reçu sur le téléphone étudiant | NON TESTÉ |

---

## MODULE 13 — Dashboard : Tâches & Relances

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 13.1 | Voir tâches | Ouvrir Tâches | Liste tâches en cours | OK |
| 13.2 | Créer tâche manuelle | Cliquer "+ Nouvelle tâche" | Tâche ajoutée | NON TESTÉ |
| 13.3 | Marquer terminée | Cliquer la checkbox | Tâche passée en "terminée" | NON TESTÉ |
| 13.4 | Relance J+7 auto | 7 jours après envoi email | Tâche créée automatiquement | PARTIEL |
| 13.5 | Inviter un membre d'équipe | Dashboard → Équipe → Inviter | Compte créé, rôle attribué, email reçu | OK |
| 13.6 | Changer le rôle d'un membre | Dashboard → Équipe → menu rôle | Rôle mis à jour, refusé si non-admin | OK |

> **13.4** : la génération des tâches de relance (détection candidature "sent" depuis ≥7/14 jours, dédoublonnage) est corrigée et vérifiée par déclenchement manuel (48 tâches générées correctement sur des candidatures réelles). Le déclenchement automatique quotidien (cron 8h) n'a pas encore été observé en conditions réelles, et l'envoi de l'email de rappel dépend de la limitation Resend sandbox (voir Plan de maintenance).
> **13.5/13.6** ajoutés à cette version : fonctionnalités absentes du cahier d'origine, développées et testées en session (email d'invitation réellement reçu, changement de rôle fonctionnel, refus correct pour un compte non-admin).

---

## MODULE 14 — Non-Fonctionnel

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 14.1 | Splash screen | Lancer l'app | Logo Studium sur fond bleu foncé | NON TESTÉ |
| 14.2 | Icône app | Voir l'icône sur l'écran d'accueil | Logo Studium visible | NON TESTÉ |
| 14.3 | Health check | GET /functions/v1/health-check | `{"status":"healthy"}` | NON TESTÉ |
| 14.4 | RLS sécurité | Étudiant A essaie voir données B | Accès refusé, 0 données retournées | PARTIEL |
| 14.5 | Dark mode complet | Activer dark mode | Tous les écrans en sombre sans bug | PARTIEL |
| 14.6 | Langue EN | Passer en anglais | Tous les textes traduits | NON TESTÉ |
| 14.7 | Performance liste | 50+ candidatures | Scroll fluide, pas de lag | NON TESTÉ |

> **14.4** : plusieurs policies RLS staff/étudiant ont été corrigées ou ajoutées en session (documents, academic_backgrounds, experiences, storage.objects) et vérifiées indirectement (le staff voit désormais bien les formations/expériences, l'étudiant garde l'accès à ses propres documents). Le scénario exact "étudiant A tente de lire les données de l'étudiant B et se voit refuser l'accès" n'a pas été rejoué explicitement.
> **14.5** : audit systématique du code (13 fichiers) pour un bug de contraste réel — texte/icônes/bordures/ombres/pistes de progression à couleur fixe posés sur un fond qui, lui, s'adapte au thème (rendant certains éléments quasi invisibles en mode sombre, capture d'écran à l'appui). Une vingtaine d'emplacements corrigés (dont un bouton dont le spinner de chargement était invisible même en mode clair), `flutter analyze` et la suite de tests restent au vert après chaque correctif. Reste non confirmé : un vrai parcours visuel écran par écran, l'audit ayant été fait par lecture de code et non par rendu réel.

---

## MODULE 15 — Ambassadeur (Parrainage & Commissions)

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 15.1 | Générer un code de parrainage | Ouvrir l'espace Parrainage (mobile) | Code/lien affiché | NON TESTÉ |
| 15.2 | Promouvoir un étudiant en ambassadeur | Dashboard → fiche étudiant → "Promouvoir ambassadeur" | Rôle mis à jour, accès parrainage débloqué côté mobile | OK |
| 15.3 | Renseigner les coordonnées de paiement | Espace Parrainage (mobile) → IBAN ou PayPal → Enregistrer | Coordonnées sauvegardées sur le profil | OK |
| 15.4 | Demander le paiement d'une commission | Commission au statut "payable" → "Demander" | Tâche créée côté dashboard avec les coordonnées de paiement incluses | NON TESTÉ |
| 15.5 | Consulter filleuls et commissions | Ouvrir l'espace Parrainage (mobile) / page Commissions (dashboard) | Listes affichées avec statuts corrects | NON TESTÉ |

> **15.2/15.3** : vérifiés en conditions réelles de bout en bout — promotion d'un étudiant de test depuis le dashboard, reconnexion côté mobile, apparition du bloc "Parrainage", saisie et sauvegarde des coordonnées de paiement. A révélé et corrigé au passage un bug RLS réel (voir Plan de maintenance §7) : le badge "Déjà ambassadeur" ne persistait pas après rafraîchissement de la page dashboard.

---

## Résumé

| Module | Total tests | OK | KO | Partiel | Non testé |
|---|---|---|---|---|---|
| Auth | 7 | 3 | 0 | 0 | 4 |
| Profil | 8 | 5 | 0 | 0 | 3 |
| Documents | 7 | 3 | 0 | 0 | 4 |
| Programmes | 9 | 0 | 0 | 0 | 9 |
| Candidatures | 11 | 5 | 0 | 0 | 6 |
| Messagerie | 5 | 0 | 0 | 0 | 5 |
| Notifications | 4 | 1 | 0 | 0 | 3 |
| Paramètres | 5 | 0 | 0 | 0 | 5 |
| Dashboard Candidatures | 7 | 1 | 0 | 0 | 6 |
| Dashboard Documents | 4 | 1 | 0 | 1 | 2 |
| Dashboard Étudiants | 4 | 0 | 0 | 0 | 4 |
| Dashboard Messagerie | 3 | 0 | 0 | 0 | 3 |
| Dashboard Tâches & Équipe | 6 | 3 | 0 | 1 | 2 |
| Non-Fonctionnel | 7 | 0 | 0 | 2 | 5 |
| Ambassadeur | 5 | 2 | 0 | 0 | 3 |
| **TOTAL** | **92** | **24** | **0** | **4** | **64** |

*(Total porté à 92 : ajout des scénarios 13.5, 13.6 et du module 15 — Ambassadeur, absents du cahier d'origine.)*

---

## Critères de validation avant release

- [ ] 0 test KO *(actuellement respecté : aucun KO constaté)*
- [ ] < 5 tests Partiel (tous documentés) *(actuellement respecté : 4 partiels, tous documentés ci-dessus)*
- [ ] Health check en production → `healthy`
- [ ] APK signé et installable
- [ ] Push notifications fonctionnelles (test réel)
- [ ] Domaine vérifié sur Resend (condition pour fiabiliser 13.4 et tous les envois email)

---

## Note méthodologique

Cette mise à jour (2026-09-19) reflète uniquement les scénarios **effectivement vérifiés en conditions réelles** durant les sessions de développement (voir historique du projet) — pas une estimation basée sur la simple existence du code. Un module marqué majoritairement "Non testé" ne signifie pas que la fonctionnalité est absente ou cassée : cela signifie que ce cahier de recette spécifique n'a pas encore été rejoué dessus. Se référer à l'audit fonctionnel du projet pour l'état d'implémentation réel de chaque fonctionnalité.
