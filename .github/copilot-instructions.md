# Ayla — Copilot Prompt File
# Women's cycle tracking app for Uzbekistan
# Stack: Flutter + Supabase + Riverpod

---

## 1. Project Identity

- **App name**: Ayla (means "moonlight" in Turkic/Arabic)
- **Tagline**: Your cycle, your way.
- **Target market**: Uzbekistan — adult women 18+
- **Platform**: Flutter (iOS + Android, cross-platform)
- **Min SDK**: Android 21 (5.0), iOS 13
- **Backend**: Supabase (PostgreSQL + Auth + Realtime + Storage)
- **State management**: Riverpod only
- **Languages**: Uzbek Latin (uz), Uzbek Cyrillic (uz_CY), Russian (ru), English (en)
- **Default language**: Uzbek Latin
- **Business model**: Freemium (B2C) + Clinic partnerships (B2B)

---

## 2. Folder Structure

```
lib/
  core/
    constants/         # app colors, text styles, spacing
    errors/            # custom exceptions, failure classes
    extensions/        # Dart extensions (DateTime, String, etc.)
    router/            # GoRouter setup
    supabase/          # Supabase client singleton, RLS helpers
    theme/             # ThemeData, light theme only
  features/
    auth/
      data/            # Supabase auth repository
      domain/          # auth models, interfaces
      presentation/    # login, register, onboarding screens
    cycle/
      data/            # cycle log repository
      domain/          # CycleLog model, prediction engine
      presentation/    # home screen, calendar, log entry
    pregnancy/
      data/            # pregnancy log repository
      domain/          # pregnancy week calculator, milestone model
      presentation/    # pregnancy mode screens
    partner/
      data/            # partner link repository
      domain/          # partner invite model
      presentation/    # partner sharing screens
    health/
      data/            # weight, water, sleep log repository
      domain/          # health log models
      presentation/    # health tracking screens
    ai_assistant/
      data/            # AI chat repository (Supabase edge function)
      domain/          # chat message model
      presentation/    # AI assistant chat screen
    articles/
      data/            # articles repository (Supabase DB)
      domain/          # article model
      presentation/    # article list, article detail screens
    community/
      data/            # post, comment repository
      domain/          # post model, comment model
      presentation/    # feed, post detail, create post screens
    reports/
      data/            # report generator
      domain/          # report model
      presentation/    # report preview, export screen
    profile/
      data/            # profile repository
      domain/          # Profile model
      presentation/    # profile screen, settings
    notifications/
      data/            # notification scheduler
      presentation/    # notification settings screen
    paywall/
      data/            # plan repository
      domain/          # Plan model, plan status checker
      presentation/    # paywall screen, plan expired screen
  shared/
    widgets/           # reusable UI components
    l10n/              # ARB localization files
  main.dart
  app.dart
```

---

## 3. Architecture Rules

- **Never** put business logic inside widgets. Widgets are dumb — they read state and dispatch events only.
- **Always** use Riverpod providers for state. No `setState` except for trivial local UI (e.g. password show/hide toggle).
- **Always** use `AsyncNotifierProvider` for data that comes from Supabase.
- **Never** call Supabase directly from a widget. Always go through a repository class.
- Use `GoRouter` for navigation. Define all routes in `core/router/`.
- Localization via Flutter's built-in `l10n` (ARB files). **Never** hardcode user-facing strings in Dart files.
- All Supabase credentials come from `--dart-define` at build time, never hardcoded.
- Use `--dart-define-from-file` for environment config.

---

## 4. Supabase Schema

### Table: `profiles`
```sql
id                uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
created_at        timestamptz DEFAULT now()
updated_at        timestamptz DEFAULT now()
birth_year        int2
cycle_length      int2 DEFAULT 28
period_length     int2 DEFAULT 5
language          text DEFAULT 'uz'           -- 'uz', 'uz_CY', 'ru', 'en'
plan_expires_at   timestamptz DEFAULT NULL    -- NULL = free tier
mode              text DEFAULT 'cycle'        -- 'cycle' | 'pregnancy'
pregnancy_start   date DEFAULT NULL           -- LMP date if in pregnancy mode
partner_code      text UNIQUE                 -- short code for partner to link
```

### Table: `cycle_logs`
```sql
id          uuid PRIMARY KEY DEFAULT gen_random_uuid()
user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE
log_date    date NOT NULL
log_type    text NOT NULL
value       text
intensity   int2                              -- 1-3 scale, nullable
created_at  timestamptz DEFAULT now()
UNIQUE(user_id, log_date, log_type, value)
```

### Table: `health_logs`
```sql
id          uuid PRIMARY KEY DEFAULT gen_random_uuid()
user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE
log_date    date NOT NULL
metric      text NOT NULL                     -- 'weight', 'water', 'sleep_hours'
value       numeric NOT NULL
unit        text                              -- 'kg', 'ml', 'hours'
created_at  timestamptz DEFAULT now()
UNIQUE(user_id, log_date, metric)
```

### Table: `partner_links`
```sql
id              uuid PRIMARY KEY DEFAULT gen_random_uuid()
user_id         uuid REFERENCES auth.users(id) ON DELETE CASCADE   -- woman's account
partner_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE   -- partner's account
status          text DEFAULT 'active'         -- 'active' | 'revoked'
created_at      timestamptz DEFAULT now()
UNIQUE(user_id, partner_user_id)
```

### Table: `articles`
```sql
id           uuid PRIMARY KEY DEFAULT gen_random_uuid()
title_uz     text NOT NULL
title_uz_cy  text
title_ru     text
title_en     text
body_uz      text NOT NULL
body_uz_cy   text
body_ru      text
body_en      text
category     text     -- 'cycle', 'pregnancy', 'nutrition', 'mental_health'
is_paid      boolean DEFAULT false
published_at timestamptz DEFAULT now()
cover_url    text     -- Supabase Storage URL
```

### Table: `community_posts`
```sql
id           uuid PRIMARY KEY DEFAULT gen_random_uuid()
user_id      uuid REFERENCES auth.users(id) ON DELETE CASCADE
body         text NOT NULL
category     text     -- 'general', 'pregnancy', 'symptoms', 'advice'
is_anonymous boolean DEFAULT true
likes_count  int4 DEFAULT 0
created_at   timestamptz DEFAULT now()
```

### Table: `community_comments`
```sql
id           uuid PRIMARY KEY DEFAULT gen_random_uuid()
post_id      uuid REFERENCES community_posts(id) ON DELETE CASCADE
user_id      uuid REFERENCES auth.users(id) ON DELETE CASCADE
body         text NOT NULL
is_anonymous boolean DEFAULT true
created_at   timestamptz DEFAULT now()
```

### Table: `notification_settings`
```sql
user_id               uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
period_reminder       boolean DEFAULT true
period_reminder_days  int2 DEFAULT 2
ovulation_reminder    boolean DEFAULT true
pregnancy_reminder    boolean DEFAULT true
reminder_time         time DEFAULT '09:00'
```

### Table: `ai_chat_messages`
```sql
id          uuid PRIMARY KEY DEFAULT gen_random_uuid()
user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE
role        text NOT NULL     -- 'user' | 'assistant'
content     text NOT NULL
created_at  timestamptz DEFAULT now()
```

### Table: `payment_requests`
```sql
id          uuid PRIMARY KEY DEFAULT gen_random_uuid()
user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE
email       text NOT NULL
status      text DEFAULT 'pending'   -- 'pending' | 'approved' | 'rejected'
created_at  timestamptz DEFAULT now()
```

### Enums (enforce in app, not DB)

**log_type**: `period_start`, `period_end`, `spotting`, `cramp`, `headache`, `bloating`, `mood_happy`, `mood_sad`, `mood_anxious`, `mood_calm`, `mood_irritable`, `note`, `temperature`, `discharge_normal`, `discharge_unusual`

**intensity**: `1` = mild, `2` = moderate, `3` = severe

**mode**: `cycle`, `pregnancy`

---

## 5. Row Level Security (RLS)

Enable RLS on ALL tables. Policies:

- `profiles`: SELECT, INSERT, UPDATE own row only (`auth.uid() = id`)
- `cycle_logs`: SELECT, INSERT, UPDATE, DELETE own rows only (`auth.uid() = user_id`)
- `health_logs`: SELECT, INSERT, UPDATE, DELETE own rows only (`auth.uid() = user_id`)
- `partner_links`:
  - Women can INSERT, UPDATE, DELETE their own links (`auth.uid() = user_id`)
  - Partners can SELECT links where they are `partner_user_id`
  - Partners can SELECT limited fields from `cycle_logs` and `profiles` of linked user — only if active link exists
- `articles`: all authenticated users can SELECT; `is_paid` articles require active plan
- `community_posts`: authenticated users can SELECT all, INSERT own, DELETE own
- `community_comments`: authenticated users can SELECT all, INSERT own, DELETE own
- `notification_settings`: own row only
- `ai_chat_messages`: own rows only
- `payment_requests`: users can INSERT own, SELECT own only

**Never** expose another user's health data except through an explicit active partner link.

---

## 6. Cycle Prediction Logic

Lives in `features/cycle/domain/cycle_prediction_service.dart`.

```
Next period date      = last period start date + cycle_length
Fertile window start  = next period date - 18
Fertile window end    = next period date - 11
Ovulation day         = next period date - 14
Current cycle day     = today - last period start date + 1
```

- No period logged yet → show onboarding prompt
- Last period > `cycle_length + 14` days ago → show "cycle may be irregular" warning
- Never show negative cycle day numbers
- Always show disclaimer: predictions are estimates only
- Never store predictions in DB — compute on the fly

---

## 7. Pregnancy Mode Logic

Lives in `features/pregnancy/domain/pregnancy_calculator.dart`.

```
Gestational age (weeks) = (today - pregnancy_start) / 7
Trimester               = weeks < 13 → first | weeks < 27 → second | else → third
Due date                = pregnancy_start + 280 days
Days remaining          = due date - today
```

- User switches to pregnancy mode from Profile screen
- Requires entering LMP date → stored as `profiles.pregnancy_start`
- Home screen changes completely in pregnancy mode:
  - Week number, trimester, days until due date
  - Weekly milestone card (baby size, development update)
  - Pregnancy-relevant symptom logging (nausea, back pain, swelling)
- Cycle predictions hidden in pregnancy mode
- User can switch back to cycle mode at any time
- Weekly milestone content stored as static JSON in `assets/pregnancy_milestones.json`

---

## 8. Partner Sharing

- Woman generates unique 6-character `partner_code` from Profile screen
- Partner downloads Ayla, creates account, enters the code
- System creates a row in `partner_links`
- Partner gets read-only dashboard showing:
  - Current cycle phase label only
  - Next period prediction (days remaining)
  - Mood of the day if logged
  - Contextual tip (e.g. "She may need more rest this week")
- Partner cannot see: specific symptoms, notes, temperature, health logs, community activity
- Woman can revoke partner access anytime
- Partner account has limited UI — no tracking, no logging features

---

## 9. Feature Specs

### 9.1 Onboarding
1. Welcome screen — app name, tagline, language selector
2. Sign up / Sign in (email + password via Supabase Auth)
3. Mode selection: Cycle tracking or Pregnancy mode
4. Profile setup — cycle length + period length sliders OR LMP date for pregnancy
5. Notification permission request
6. Home screen

### 9.2 Home Screen
**Cycle mode (free):**
- Current cycle day badge
- Phase label: Menstrual / Follicular / Ovulation / Luteal
- Quick log: Period, Mood

**Cycle mode (paid adds):**
- Next period prediction
- Fertile window indicator
- Symptom quick log
- AI tip of the day (one sentence from AI assistant)

**Pregnancy mode (paid):**
- Week + trimester badge
- Days until due date
- Weekly milestone card
- Pregnancy symptom log

**Bottom nav**: Home | Calendar | Log | Articles | Profile

### 9.3 Calendar Screen (PAID)
- Monthly calendar via `table_calendar`
- Color coding: period (red), fertile (green), ovulation (yellow), today (primary)
- Tap day → logs for that day
- Free: calendar visible, future + insights blurred with upgrade prompt

### 9.4 Log Screen
**Free**: Period start/end only
**Paid adds**: Symptoms, Mood, Notes, Temperature, Weight, Water, Sleep

### 9.5 Health Tracking (PAID)
- Daily weight (kg) with trend chart
- Daily water intake (ml) with goal progress ring
- Sleep hours with weekly average
- Shown as cards on Log screen or dedicated Health tab

### 9.6 AI Health Assistant (PAID)
- Chat interface via Supabase Edge Function → LLM API
- System prompt includes: cycle phase, recent symptoms, mood, pregnancy week if applicable
- Scope: cycle health, pregnancy questions, symptom explanation only
- Always includes disclaimer: "This is not medical advice. Consult your doctor."
- Last 20 messages sent as context
- Responds in user's selected app language

### 9.7 Articles (Free + Paid)
- Category filter: All, Cycle, Pregnancy, Nutrition, Mental Health
- Free articles: basic cycle education, general health
- Paid articles: fertility, pregnancy week guides, nutrition plans, mental health
- Show in user's language, fallback: Russian → Uzbek Latin
- Admin publishes via Supabase Studio

### 9.8 Community Forum
- **Free**: read posts and comments
- **Paid**: create posts and comments
- Anonymous by default
- Categories: General, Pregnancy, Symptoms, Advice
- Like button on posts
- Report button → flags post for admin review
- Pull-to-refresh (no real-time in v1)

### 9.9 Doctor Report PDF Export (FREE for all)
- PDF of last 3 months: cycle dates, period lengths, symptoms, mood patterns, health metrics
- Generated client-side with `pdf` Flutter package
- Header: "Ayla Health Report — [Date Range]"
- Ayla logo prominently displayed — B2B marketing tool
- Available from Profile screen
- Share via OS share sheet (WhatsApp, email, etc.)

### 9.10 Notifications (PAID)
- Period reminder N days before predicted period
- Ovulation reminder on predicted ovulation day
- Pregnancy weekly milestone reminder
- Daily health log reminder (optional)
- Rescheduled on every app open

### 9.11 Profile Screen
- Edit cycle length, period length
- Switch mode: Cycle ↔ Pregnancy
- Language selector
- Notification settings
- Partner sharing: generate code, view linked partner, revoke
- Plan status + upgrade CTA
- Export health report
- Sign out

---

## 10. Paywall & Plan Logic

### Plan model
```dart
class UserPlan {
  final DateTime? expiresAt;
  bool get isActive => expiresAt != null && expiresAt!.isAfter(DateTime.now());
  bool get isFree => !isActive;
}
```

### Feature gating
| Feature | Free | Paid |
|---|---|---|
| Period logging | ✅ | ✅ |
| Basic cycle day + phase | ✅ | ✅ |
| Doctor report PDF export | ✅ | ✅ |
| Free articles | ✅ | ✅ |
| Community read | ✅ | ✅ |
| Next period prediction | ❌ | ✅ |
| Fertile window & ovulation | ❌ | ✅ |
| Full calendar | ❌ | ✅ |
| Symptom & mood logging | ❌ | ✅ |
| Health tracking (weight/water/sleep) | ❌ | ✅ |
| Pregnancy mode | ❌ | ✅ |
| Partner sharing | ❌ | ✅ |
| AI health assistant | ❌ | ✅ |
| Paid articles | ❌ | ✅ |
| Notifications & reminders | ❌ | ✅ |
| Community posting | ❌ | ✅ |

### Paywall screen
- Show benefits list
- Price: 15,000 UZS/month or 120,000 UZS/year
- Card transfer instructions + user email as comment
- "I've paid — notify us" → inserts into `payment_requests`
- Admin activates plan:
```sql
UPDATE profiles
SET plan_expires_at = now() + interval '1 month'
WHERE id = '[user_id]';
```

---

## 11. B2B Clinic Strategy

- Doctor report is free → doctors see Ayla-branded PDFs → recommend app to patients
- Track clinic referral via UTM parameters in app store links
- v2 plan: clinic dashboard where doctor views patient reports with consent

---

## 12. UI & Design Rules

### Colors
```dart
const Color primary        = Color(0xFF7C6FAB); // soft violet
const Color secondary      = Color(0xFFE8A598); // warm blush
const Color accent         = Color(0xFFF5C46E); // golden
const Color background     = Color(0xFFFAF8FF); // near-white violet tint
const Color surface        = Color(0xFFFFFFFF);
const Color textPrimary    = Color(0xFF2D2640);
const Color textSecondary  = Color(0xFF8A82A0);
const Color periodRed      = Color(0xFFE57373);
const Color fertileGreen   = Color(0xFF81C784);
const Color pregnancyBlue  = Color(0xFF90CAF9);
```

### Typography
- Headings: `Nunito` (Google Fonts) — rounded, friendly, Cyrillic support
- Body: `Source Sans 3` — clean, legible, multilingual

### Tone
- Warm, calm, trustworthy — not clinical, not stereotypically pink
- Rounded corners 12–16px, soft shadows, generous padding
- Icons: Phosphor Icons or Lucide Flutter packages
- Pregnancy mode: shift accent to `pregnancyBlue`

### Locked feature pattern
- Blur the feature with `BackdropFilter`
- Overlay soft lock card with upgrade CTA
- Never fully hide locked features

---

## 13. Localization

- ARB files: `app_en.arb`, `app_ru.arb`, `app_uz.arb`, `app_uz_cy.arb`
- Never hardcode strings in widgets
- Use `flutter_localizations` + `intl`
- Uzbek Cyrillic: custom locale delegate (`uz_CY`)
- Content fallback chain: selected language → Russian → Uzbek Latin

---

## 14. Packages

```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  supabase_flutter: ^2.x
  go_router: ^13.x
  table_calendar: ^3.x
  flutter_local_notifications: ^17.x
  google_fonts: ^6.x
  intl: ^0.19.x
  pdf: ^3.x
  printing: ^5.x
  shared_preferences: ^2.x
  cached_network_image: ^3.x
  fl_chart: ^0.x
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_lints: ^4.x
  build_runner: ^2.x
  riverpod_generator: ^2.x
```

---

## 15. What Copilot Must Never Do

- ❌ Never hardcode user IDs, API keys, or secrets
- ❌ Never skip RLS — always filter by `auth.uid()` at DB level
- ❌ Never store health data in SharedPreferences or unencrypted local storage
- ❌ Never mix business logic into widget classes
- ❌ Never call Supabase directly from a widget
- ❌ Never hardcode user-facing strings — always use localization keys
- ❌ Never use `setState` for shared or async state — use Riverpod
- ❌ Never compute predictions in the UI layer — use service classes
- ❌ Never expose partner's full health data — limited read-only fields only
- ❌ Never let AI assistant give definitive medical diagnoses — always include disclaimer
- ❌ Never show community author identity unless `is_anonymous = false`
- ❌ Never use deprecated Flutter APIs