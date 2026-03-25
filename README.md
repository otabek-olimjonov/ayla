# Ayla — Women's Cycle Tracking App

> **Your cycle, your way.**  
> Built for Uzbekistan. Powered by Flutter + Supabase.

---

## Stack

| Layer | Technology |
|---|---|
| UI | Flutter (iOS + Android) |
| State | Riverpod 2 |
| Backend | Supabase (Auth, PostgreSQL, Storage, Edge Functions) |
| Navigation | GoRouter |
| Localization | Flutter l10n (uz, uz_CY, ru, en) |

---

## Getting started

### 1. Prerequisites

- Flutter SDK ≥ 3.19 (`flutter --version`)
- Dart SDK ≥ 3.3
- A Supabase project (free tier works)

### 2. Clone & install

```bash
git clone <repo>
cd ayla
flutter pub get
```

### 3. Environment setup

Copy the env template and fill in your Supabase credentials:

```bash
cp assets/env.json.example assets/env.json
# Edit assets/env.json with your SUPABASE_URL and SUPABASE_ANON_KEY
```

> `assets/env.json` is git-ignored. **Never commit credentials.**

### 4. Generate code

```bash
# Generate Riverpod providers + l10n
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

### 5. Run

```bash
flutter run --dart-define-from-file=assets/env.json
```

---

## Project structure

```
lib/
  core/          # Colors, theme, router, Supabase client, errors, extensions
  features/      # auth, cycle, pregnancy, partner, health, ai_assistant,
                 # articles, community, reports, profile, notifications, paywall
  shared/        # Reusable widgets, l10n barrel
  l10n/          # ARB files (app_en, app_uz, app_ru, app_uz_CY)
  main.dart
  app.dart
assets/
  pregnancy_milestones.json
  env.json.example
  fonts/         # Nunito, Source Sans 3 (add TTF files here)
  images/        # App images / logo
```

---

## Supabase setup

Apply the schema from [copilot-instructions.md](.github/copilot-instructions.md).  
Enable RLS on **all** tables. See Section 5 of the instructions for policy details.

---

## Feature flags

Free vs. paid features are gated via `UserProfile.isPaidPlanActive`.  
Payment is handled manually: user submits a `payment_request`, admin activates plan via:

```sql
UPDATE profiles
SET plan_expires_at = now() + interval '1 month'
WHERE id = '<user_id>';
```

---

## Contributing

- No hardcoded strings — always use ARB keys
- No Supabase calls in widgets — always through a Repository class
- No `setState` for shared state — use Riverpod `AsyncNotifierProvider`
- Run `flutter analyze` and `flutter test` before every PR
