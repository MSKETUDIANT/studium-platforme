# Documentation Technique — Studium Platform
**Version :** 1.0 | **Date :** 2026-09-20

---

## 1. Vue d'ensemble

Le projet est composé de trois parties indépendantes, connectées à un unique projet Supabase :

| Composant | Répertoire | Stack | Rôle |
|---|---|---|---|
| App mobile étudiant | `studium_mobile/` | Flutter, Riverpod, GoRouter | Parcours étudiant : profil, candidatures, documents, messagerie |
| Dashboard interne | `studium-dashboard/` | React + TypeScript, Vite | Outil de l'équipe : validation, envoi, reporting, administration |
| Backend | `supabase/` | Postgres, Auth, Storage, Edge Functions (Deno) | Base de données, authentification, stockage, logique serveur |

Les trois s'appuient sur le **même projet Supabase** (mêmes tables, mêmes RLS, mêmes Edge Functions) — il n'y a qu'un seul backend, pas d'API intermédiaire.

---

## 2. Structure des dossiers

```
studium-platform/
├── studium_mobile/          # App Flutter
│   └── lib/
│       ├── core/             # constantes, thème, validators, services partagés
│       ├── features/         # un dossier par domaine métier (auth, profile,
│       │                     # documents, applications, programs, messaging,
│       │                     # notifications, settings, ambassador, dashboard)
│       │   └── <feature>/
│       │       ├── data/         # datasources (Supabase) + repositories
│       │       ├── domain/       # entités + interfaces repository
│       │       └── presentation/ # pages, providers (Riverpod), widgets
│       ├── router/           # GoRouter (routes nommées, shell de nav)
│       └── shared/           # widgets réutilisés (bottom nav, etc.)
│   └── test/                 # tests unitaires, widgets, intégration
│
├── studium-dashboard/        # Dashboard React
│   └── src/
│       ├── app/layouts/      # AppLayout (sidebar, routing par rôle)
│       ├── features/         # un dossier par domaine (applications, students,
│       │                     # programs, messaging, reporting, settings, audit,
│       │                     # ambassadors, notifications, tasks, auth)
│       │   └── <feature>/
│       │       ├── pages/        # écrans
│       │       ├── components/   # sous-composants propres à la feature
│       │       └── services/     # appels Supabase
│       └── shared/           # composants (Button, Badge, StatCard, Pagination…),
│                              # constants/theme.ts (design tokens), utils
│
└── supabase/
    ├── migrations/           # fichiers SQL horodatés (voir §5 et Plan de maintenance)
    └── functions/            # une Edge Function Deno par dossier
```

---

## 3. Variables d'environnement

Aucune valeur réelle n'est donnée ici — uniquement les clés attendues par chaque composant.

### Dashboard (`studium-dashboard/.env`, préfixe `VITE_` obligatoire pour être exposé au build Vite)
| Variable | Usage |
|---|---|
| `VITE_SUPABASE_URL` | URL du projet Supabase |
| `VITE_SUPABASE_ANON_KEY` | Clé publique (anon) Supabase |

> Une clé `RESEND_API_KEY` est présente dans `.env` mais n'est **pas utilisée** côté dashboard (aucun `import.meta.env.VITE_RESEND_API_KEY` dans le code) — Resend n'est appelé que depuis les Edge Functions, jamais depuis le navigateur. Résidu à nettoyer si confirmé inutile.

### Mobile (`studium_mobile/`)
L'app **ne lit pas automatiquement** un fichier `.env` au runtime : les identifiants sont injectés via `--dart-define` au lancement (`lib/main.dart` utilise `String.fromEnvironment(...)`).

| Variable (`--dart-define`) | Usage |
|---|---|
| `SUPABASE_URL` | URL du projet Supabase |
| `SUPABASE_ANON_KEY` | Clé publique (anon) Supabase |

Un fichier `studium_mobile/.env` existe (avec en plus `GOOGLE_WEB_CLIENT_ID`, `RESEND_API_KEY`) mais sert de **référence pour l'équipe**, pas d'entrée automatique — voir §6 pour la commande réelle de lancement.

### Edge Functions (configurées dans Supabase → Project Settings → Edge Functions → Secrets, jamais dans un fichier du dépôt)
| Variable | Usage |
|---|---|
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Accès service role (bypass RLS) depuis les functions |
| `RESEND_API_KEY` | Envoi d'emails (candidatures, rappels, invitations) |
| `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT` | Envoi de notifications push (FCM) |

---

## 4. Installation

### Prérequis
- Flutter SDK (voir `studium_mobile/pubspec.yaml` pour la contrainte de version Dart/Flutter)
- Node.js 18+ et npm
- [Deno](https://deno.land) — requis uniquement pour lancer les tests des Edge Functions (`supabase/functions/*/*.test.ts`), pas pour le fonctionnement de l'app
- Un projet Supabase (Auth + Postgres + Storage activés)

### Dashboard
```
cd studium-dashboard
npm install
cp .env.example .env   # si absent, créer .env avec les clés du §3
npm run dev             # démarre Vite en local
```

### Mobile
```
cd studium_mobile
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<clé anon>
```

### Backend (Supabase)
Le schéma complet est reconstitué en exécutant, dans l'ordre chronologique de leur nom de fichier, tous les scripts de `supabase/migrations/` dans le SQL Editor du projet Supabase (voir Plan de maintenance §2 pour la méthode et les pièges connus — l'historique local peut diverger de l'état réel de la base).

Les Edge Functions se déploient une par une via la CLI Supabase (`supabase functions deploy <nom>`) ou depuis le dashboard Supabase.

---

## 5. Base de données

- Le schéma de référence (dump complet à un instant donné) est `supabase/migrations/00000000000001_baseline_schema.sql`.
- Toutes les migrations postérieures sont nommées `YYYYMMDD_description.sql` et **doivent être idempotentes** (`CREATE OR REPLACE`, `ADD COLUMN IF NOT EXISTS`, `DROP POLICY IF EXISTS` avant `CREATE POLICY`) — voir Plan de maintenance §2 pour le contexte complet de cette règle.
- Aucune migration n'est appliquée automatiquement dans ce projet (pas de CI de déploiement DB) : chaque script doit être exécuté manuellement dans le SQL Editor Supabase, puis son exécution vérifiée par une requête de contrôle.

---

## 6. Tests

| Suite | Commande | Emplacement |
|---|---|---|
| Mobile (unitaires, widgets, intégration) | `flutter test` (depuis `studium_mobile/`) | `studium_mobile/test/` |
| Analyse statique mobile | `flutter analyze` | — |
| Dashboard (Vitest) | `npm run test` (depuis `studium-dashboard/`) | `src/**/*.test.ts` |
| Typecheck + build dashboard | `npm run build` (lance `tsc -b` puis `vite build`) | — |
| Edge Functions (Deno) | `deno test` depuis le dossier de la fonction (ex. `cd supabase/functions/send-application-email && deno test`) | `supabase/functions/*/*.test.ts` |

Les tests Deno couvrent uniquement la logique pure extraite des Edge Functions (templates email, calcul de péremption du pack PDF, classification des documents fusionnables…) — pas d'appel réseau réel vers Supabase ou Resend, qui demanderait une infrastructure de test dédiée non mise en place à ce jour.

---

## 7. Déploiement

- **Dashboard** : `npm run build` produit `studium-dashboard/dist/`, à héberger sur tout hébergeur de fichiers statiques (le projet n'impose pas de plateforme précise).
- **Mobile** : `flutter build apk` (Android) ou `flutter build ios` (iOS, nécessite macOS + Xcode), avec les mêmes `--dart-define` qu'en développement mais pointant vers le projet Supabase de production.
- **Edge Functions** : `supabase functions deploy <nom>` par fonction, ou déploiement groupé selon la CLI installée.
- **Base de données** : voir §5 — pas de pipeline automatisé, exécution manuelle des migrations en attente.

---

## 8. Points d'attention techniques connus

- **Désynchronisation migrations locales / base réelle** : documenté en détail dans le Plan de maintenance §2 — c'est le principal piège opérationnel du projet.
- **Resend en mode sandbox** : les emails ne partent de façon fiable qu'après vérification d'un domaine réel (Plan de maintenance §5).
- **Bucket `documents` privé** : tout accès à un fichier passe par une URL signée générée à la demande, jamais par une URL publique stockée en base (Plan de maintenance §6).
- **Trois générateurs PDF distincts et indépendants**, qui ne partagent aucun code : le résumé téléchargeable côté mobile (`package:pdf`, `application_pdf_builder.dart`), le résumé téléchargeable côté agent depuis le tableau de bord (`@react-pdf/renderer`, indépendant de l'envoi), et le **pack de soumission assemblé** envoyé à l'université (`pdf-lib` via Deno, `generate-application-pack` — couverture, profil, parcours, motivation, fusion des documents approuvés en PDF/image ; les formats non fusionnables comme `.doc`/`.docx` restent transmis séparément). Une modification de l'un n'affecte jamais les deux autres.
- **Pack de soumission persistant et réutilisé** : généré une seule fois par candidature (au premier envoi email), stocké dans le bucket public `application-packs`, puis réutilisé pour les envois suivants tant qu'il n'est pas périmé (`isPackStale` : profil ou documents approuvés modifiés après la génération → régénération automatique avec incrément de version).
