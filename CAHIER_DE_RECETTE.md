# Cahier de Recette  Studium Platform
**Version :** 1.0 | **Date :** 2026-06-06 | **Statut :** À valider

---

## Légende
-  OK  fonctionnel
-  KO  bug ou absent
- ️ Partiel  fonctionne avec réserve
-  Non testé

---

## MODULE 1  Authentification Mobile

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 1.1 | Inscription | Remplir email + mdp + valider CGU | Compte créé, email de confirmation envoyé |  |
| 1.2 | Confirmation email | Cliquer lien dans l'email | App affiche "email confirmé", redirection login |  |
| 1.3 | Connexion valide | Email + mdp corrects | Accès au dashboard étudiant |  |
| 1.4 | Connexion invalide | Mauvais mdp | Message d'erreur clair, pas de crash |  |
| 1.5 | Reset password | Cliquer "Mot de passe oublié"  email | Email de reset reçu, nouveau mdp fonctionne |  |
| 1.6 | Déconnexion | Appuyer "Se déconnecter" | Retour à l'écran login, session effacée |  |
| 1.7 | Session persistante | Fermer et rouvrir l'app | Utilisateur toujours connecté |  |

---

## MODULE 2  Profil Étudiant

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 2.1 | Compléter infos personnelles | Remplir tous les champs obligatoires | Sauvegarde OK, % complétude augmente |  |
| 2.2 | Ajouter parcours académique | Ajouter un diplôme | Item dans la liste, score mis à jour |  |
| 2.3 | Ajouter expérience | Ajouter une expérience pro | Item dans la liste |  |
| 2.4 | Lettre de motivation | Écrire > 300 mots | Sauvegarde OK |  |
| 2.5 | Lettre de motivation courte | Écrire < 300 mots et sauvegarder | Avertissement min. mots |  |
| 2.6 | Photo de profil | Uploader une photo | Photo affichée dans le header |  |
| 2.7 | Profil 100% complet | Remplir toutes les sections | Badge "Profil complet" affiché |  |
| 2.8 | Auto-save | Fermer l'app en cours de saisie | Données retrouvées à la réouverture |  |

---

## MODULE 3  Documents

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 3.1 | Upload CV PDF | Sélectionner un PDF < 10MB | Document uploadé, visible dans la liste |  |
| 3.2 | Upload image | Sélectionner un JPG/PNG | Document uploadé correctement |  |
| 3.3 | Fichier trop lourd | Upload > 10MB | Message d'erreur taille |  |
| 3.4 | Voir un document | Taper sur un document | Détails affichés (nom, taille, statut) |  |
| 3.5 | Supprimer un document | Confirmer suppression | Document retiré de la liste |  |
| 3.6 | Document approuvé | Dashboard approuve le doc | Badge vert "Approuvé" affiché côté mobile |  |
| 3.7 | Document rejeté | Dashboard rejette avec motif | Badge rouge + motif visible côté mobile |  |

---

## MODULE 4  Programmes

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 4.1 | Liste programmes | Ouvrir l'onglet Programmes | Liste chargée (depuis cache si disponible) |  |
| 4.2 | Recherche | Taper "Master" dans la barre | Filtrage en temps réel |  |
| 4.3 | Filtre pays | Sélectionner "France" | Seuls les programmes français affichés |  |
| 4.4 | Filtre niveau | Sélectionner "Master" | Seuls les Masters affichés |  |
| 4.5 | Réinitialiser filtres | Appuyer "Réinitialiser" | Tous les programmes réaffichés |  |
| 4.6 | Détail programme | Taper sur un programme | Fiche détail (université, deadline, coût...) |  |
| 4.7 | Ajouter favori | Appuyer  sur un programme | Icône pleine, programme dans Mes Favoris |  |
| 4.8 | Retirer favori | Appuyer  sur un favori | Retiré de la liste favoris |  |
| 4.9 | Cache offline | Couper le réseau, ouvrir Programmes | Liste affichée depuis le cache |  |

---

## MODULE 5  Candidatures Mobile

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 5.1 | Créer candidature | Appuyer "+ Nouvelle candidature" | Wizard lancé |  |
| 5.2 | Step 1 : Sélectionner programme | Choisir un programme | Passage au step 2 |  |
| 5.3 | Step 2 : Documents | Sélectionner des documents | Documents joints |  |
| 5.4 | Step 3 : Récapitulatif | Vérifier résumé | Toutes les infos correctes |  |
| 5.5 | Soumettre candidature | Appuyer "Soumettre" | Statut  "Soumise", notification envoyée |  |
| 5.6 | Brouillon | Fermer avant soumission | Candidature en statut "Brouillon" |  |
| 5.7 | Liste candidatures | Ouvrir l'onglet Dossiers | Toutes les candidatures listées |  |
| 5.8 | Filtres candidatures | Filtrer par "Acceptée" | Seules les acceptées affichées |  |
| 5.9 | Détail candidature | Taper sur une candidature | Timeline + documents + statut actuel |  |
| 5.10 | Générer PDF | Appuyer "Télécharger PDF" | PDF généré et téléchargé |  |
| 5.11 | Correction demandée | Dashboard met statut NeedsFix | Notif push reçue + message visible |  |

---

## MODULE 6  Messagerie Mobile

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 6.1 | Ouvrir messagerie | Onglet Messages | Conversation "Équipe Studium" visible |  |
| 6.2 | Envoyer message | Écrire et envoyer | Message affiché instantanément |  |
| 6.3 | Recevoir message | Dashboard répond | Message reçu en temps réel |  |
| 6.4 | Notification message | App fermée, message reçu | Notification push affichée |  |
| 6.5 | Indicateur non-lu | Nouveau message reçu | Badge sur l'onglet Messages |  |

---

## MODULE 7  Notifications Mobile

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 7.1 | Centre notifications | Ouvrir cloche | Liste des notifications in-app |  |
| 7.2 | Marquer comme lu | Taper sur une notif | Disparaît des non-lues |  |
| 7.3 | Tout marquer lu | Appuyer "Tout marquer" | Badge cloche  0 |  |
| 7.4 | Push statut changé | Dashboard change statut | Push reçu sur Android |  |

---

## MODULE 8  Paramètres Mobile

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 8.1 | Changer langue | FR  EN | Interface en anglais |  |
| 8.2 | Retour français | EN  FR | Interface en français |  |
| 8.3 | Mode sombre | Activer dark mode | Toute l'app passe en sombre |  |
| 8.4 | Changer mot de passe | Email de reset envoyé | Email reçu |  |
| 8.5 | Persistance settings | Fermer/rouvrir app | Langue et thème conservés |  |

---

## MODULE 9  Dashboard : Candidatures

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 9.1 | Vue kanban | Ouvrir la page | Colonnes par statut affichées |  |
| 9.2 | Déplacer candidature | Changer statut | Carte déplacée dans la bonne colonne |  |
| 9.3 | Valider candidature | Cliquer "Valider" | Statut  Verified, notif push étudiant |  |
| 9.4 | Demander correction | Mettre statut NeedsFix + note | Message envoyé + push reçu |  |
| 9.5 | Envoyer email université | Cliquer "Envoyer à l'université" | Email envoyé, log créé, statut  Sent |  |
| 9.6 | Voir logs email | Ouvrir historique email | Date, destinataire, statut affiché |  |
| 9.7 | Export CSV | Cliquer "Export CSV" | Fichier téléchargé avec toutes les colonnes |  |

---

## MODULE 10  Dashboard : Documents

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 10.1 | Voir document étudiant | Cliquer sur un doc | Aperçu ou lien d'ouverture |  |
| 10.2 | Approuver document | Cliquer "Approuver" | Statut  Approuvé côté mobile aussi |  |
| 10.3 | Rejeter avec motif | Saisir motif + rejeter | Statut  Rejeté, motif visible mobile |  |
| 10.4 | Générer PDF pack | Cliquer "Générer PDF" | PDF créé, lien de téléchargement |  |

---

## MODULE 11  Dashboard : Étudiants

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 11.1 | Liste étudiants | Ouvrir la page | Tous les étudiants avec score |  |
| 11.2 | Recherche | Taper un nom | Filtrage en temps réel |  |
| 11.3 | Voir profil détaillé | Cliquer sur un étudiant | Infos + documents + candidatures |  |
| 11.4 | Export CSV | Cliquer "Export CSV" | Fichier avec tous les étudiants |  |

---

## MODULE 12  Dashboard : Messagerie

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 12.1 | Liste conversations | Ouvrir messagerie | Toutes les conversations visibles |  |
| 12.2 | Répondre à un étudiant | Écrire + envoyer | Message reçu côté mobile |  |
| 12.3 | Notification push | Répondre depuis dashboard | Push reçu sur le téléphone étudiant |  |

---

## MODULE 13  Dashboard : Tâches & Relances

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 13.1 | Voir tâches | Ouvrir Tâches | Liste tâches en cours |  |
| 13.2 | Créer tâche manuelle | Cliquer "+ Nouvelle tâche" | Tâche ajoutée |  |
| 13.3 | Marquer terminée | Cliquer la checkbox | Tâche passée en "terminée" |  |
| 13.4 | Relance J+7 auto | 7 jours après envoi email | Tâche créée automatiquement |  |

---

## MODULE 14  Non-Fonctionnel

| # | Scénario | Action | Résultat attendu | Statut |
|---|---|---|---|---|
| 14.1 | Splash screen | Lancer l'app | Logo Studium sur fond bleu foncé |  |
| 14.2 | Icône app | Voir l'icône sur l'écran d'accueil | Logo Studium visible |  |
| 14.3 | Health check | GET /functions/v1/health-check | `{"status":"healthy"}` |  |
| 14.4 | RLS sécurité | Étudiant A essaie voir données B | Accès refusé, 0 données retournées |  |
| 14.5 | Dark mode complet | Activer dark mode | Tous les écrans en sombre sans bug |  |
| 14.6 | Langue EN | Passer en anglais | Tous les textes traduits |  |
| 14.7 | Performance liste | 50+ candidatures | Scroll fluide, pas de lag |  |

---

## Résumé

| Module | Total tests |  OK |  KO | ️ Partiel |  Non testé |
|---|---|---|---|---|---|
| Auth | 7 | | | | 7 |
| Profil | 8 | | | | 8 |
| Documents | 7 | | | | 7 |
| Programmes | 9 | | | | 9 |
| Candidatures | 11 | | | | 11 |
| Messagerie | 5 | | | | 5 |
| Notifications | 4 | | | | 4 |
| Paramètres | 5 | | | | 5 |
| Dashboard Candidatures | 7 | | | | 7 |
| Dashboard Documents | 4 | | | | 4 |
| Dashboard Étudiants | 4 | | | | 4 |
| Dashboard Messagerie | 3 | | | | 3 |
| Dashboard Tâches | 4 | | | | 4 |
| Non-Fonctionnel | 7 | | | | 7 |
| **TOTAL** | **85** | **0** | **0** | **0** | **85** |

---

## Critères de validation avant release

- [ ] 0 test  KO
- [ ] < 5 tests ️ Partiel (tous documentés)
- [ ] Health check en production  `healthy`
- [ ] APK signé et installable
- [ ] Push notifications fonctionnelles (test réel)
