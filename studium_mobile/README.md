# Studium Mobile

Application mobile Flutter pour la gestion des candidatures académiques internationales.

## Stack technique

- **Mobile** : Flutter 3.x + Riverpod + GoRouter
- **Backend** : Supabase (Auth, PostgreSQL, Storage, Realtime)
- **State management** : Flutter Riverpod
- **Navigation** : GoRouter

## Prérequis

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Compte Supabase configuré

## Installation

```bash
git clone <repo>
cd studium_mobile
flutter pub get
flutter run -d windows
```

## Variables d'environnement

Crée un fichier `.env` à la racine :
Lancer avec les variables :

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

## Architecture
lib/
├── core/          → constantes, thème, erreurs, utilitaires
├── features/      → modules fonctionnels (auth, profile, applications...)
│   └── auth/
│       ├── data/          → datasource, repository, models
│       ├── domain/        → models métier, usecases
│       └── presentation/  → screens, widgets, providers
├── shared/        → widgets et services réutilisables
├── router/        → configuration GoRouter
└── main.dart


## Conventions

- Fichiers : `snake_case` → `auth_service.dart`
- Classes : `PascalCase` → `AuthService`
- Variables : `camelCase` → `studentProfile`
- Providers : `camelCase + Provider` → `authStateProvider`

## Modules

| Module | Description |
|--------|-------------|
| auth | Inscription, connexion, reset password |
| profile | Profil étudiant, wizard |
| documents | Upload et gestion des documents |
| programs | Catalogue et recherche de programmes |
| applications | Création et suivi des candidatures |
| messaging | Messagerie équipe ↔ étudiant |
| notifications | Notifications push et in-app |
| ai | Intégrations IA (lettre motivation, score) |