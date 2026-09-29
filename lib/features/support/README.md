# NoteFlow — Support Feature Subsystem

Welcome to the **Support Feature** subsystem in NoteFlow!

This feature allows users to voluntarily support the open development of NoteFlow through **direct one-time tips ("buy me a coffee")** or **free opt-in rewarded video ads**.

---

## 🌟 Philosophy: Ethical, Local-First Monetization

NoteFlow is committed to an open, distraction-free, and privacy-respecting user experience:
- **No Subscriptions or Paywalls:** All core note-taking features (Markdown editing, outline folding, tags, backlinks, transclusion, Excalidraw drawing canvas, offline vaults) are 100% free and unlimited forever.
- **Zero Banner Ads or Popups:** No banner ads or unsolicited popups ever clutter your notes.
- **Opt-In Only:** Rewarded ads and tips only run on this dedicated support screen when explicitly invoked by the user.
- **Zero Telemetry:** NoteFlow does not track user behavior or send note content anywhere.

---

## 🏗️ Architectural Overview & File Map

The subsystem follows a clean layered architecture (Domain, Data, Presentation) adhering to Separation of Concerns:

```
lib/features/support/
├── domain/                                # Domain models & entities
│   └── support_tier.dart                  # SupportTier model & predefined tiers
│
├── data/                                  # Data access & platform integrations
│   ├── support_service.dart               # Abstract interface for support interactions
│   ├── play_billing_manager.dart          # Dedicated Google Play In-App Billing manager
│   ├── admob_rewarded_manager.dart        # Dedicated Google Mobile Ads (Rewarded Video) manager
│   └── production_support_service.dart    # Production orchestrator composing Billing & Ads
│
├── presentation/                          # UI views and modular components
│   ├── support_screen.dart                # Main dedicated support screen (/support)
│   └── widgets/
│       ├── support_hero_header.dart       # Glowing coffee badge and intro philosophy
│       ├── support_tier_card.dart         # Individual interactive tier selection card
│       ├── support_money_section.dart     # Tip section with tier list & checkout button
│       ├── support_ad_section.dart        # Free contribution card with AdMob player button
│       ├── support_faq_section.dart       # Transparency Q&A accordion items
│       ├── welcome_support_card.dart      # Entry-point card embedded on the Welcome screen
│       └── contribution_success_dialog.dart # Celebration modal with confetti & gratitude
│
├── support.dart                           # Public barrel export
└── README.md                              # Subsystem documentation (this file)
```

---

## 🧩 Component Breakdown

### 1. Domain Layer (`domain/`)
- [`SupportTier`](domain/support_tier.dart): Immutable model representing a contribution level (e.g. *Quick Espresso*, *Coffee & Croissant*, *Developer Lunch*, *NoteFlow Patron*). Defines price, currency display, emoji, and Google Play SKU.

### 2. Data Layer (`data/`)
- [`SupportService`](data/support_service.dart): Abstract interface specifying the support contract (`sendTip`, `showRewardedAd`, `initialize`, purchase and error streams). Provides pluggability so UI tests require zero mock SDKs.
- [`PlayBillingManager`](data/play_billing_manager.dart): Encapsulates all `in_app_purchase` logic—querying product pricing, listening to the purchase stream, acknowledging, and consuming products (so users can send multiple coffees).
- [`AdmobRewardedManager`](data/admob_rewarded_manager.dart): Encapsulates Google Mobile Ads `RewardedAd` preloading, loading timeouts, presentation callbacks, and reward handling.
- [`ProductionSupportService`](data/production_support_service.dart): Composes `PlayBillingManager` and `AdmobRewardedManager` into the unified `SupportService` implementation.

### 3. Presentation Layer (`presentation/`)
- [`SupportScreen`](presentation/support_screen.dart): Orchestrates state (selected tier, purchase progress, ad loading state) and composes the modular UI sections.
- [`SupportHeroHeader`](presentation/widgets/support_hero_header.dart): Visual header with glowing coffee icon and NoteFlow mission statement.
- [`SupportTierCard`](presentation/widgets/support_tier_card.dart): Modular card with selection animations, description, and localized price.
- [`SupportMoneySection`](presentation/widgets/support_money_section.dart): Groups tier selection with the primary "Send Tip" action button.
- [`SupportAdSection`](presentation/widgets/support_ad_section.dart): Highlights the 100% free option to watch a ~30-second sponsored video.
- [`SupportFaqSection`](presentation/widgets/support_faq_section.dart): Frequently asked questions addressing privacy, feature access, and fund utilization.
- [`WelcomeSupportCard`](presentation/widgets/welcome_support_card.dart): Discreet call-to-action placed on mobile welcome screens.
- [`ContributionSuccessDialog`](presentation/widgets/contribution_success_dialog.dart): Modal thanking the contributor after a tip or ad completion.

---

## 🧪 Testing & Mocking

To test the support feature or any widget that depends on it:
1. Implement or extend `SupportService` with a test fake (see [`FakeTestSupportService`](../../test/support/support_test.dart)).
2. Pass your mock/fake directly to `SupportScreen(supportService: myFake)`.
3. Verify tip triggers, ad completion flows, and dialog presentation without connecting to real app stores.

Run the test suite with:
```bash
flutter test test/support/support_test.dart
```

---

## ⚙️ Store Configuration

### Google Play Console (One-Time Consumables)
In **Monetize with Play > Products > One-time products**, configure products corresponding to `SupportTier.defaultTiers`:
- `noteflow_tip_espresso` ($2.99)
- `noteflow_tip_croissant` ($4.99)
- `noteflow_tip_lunch` ($9.99)
- `noteflow_tip_patron` ($24.99)

### Google AdMob (Rewarded Video & App ID)
AdMob credentials are kept private using `.env` (gitignored). In public code, NoteFlow automatically falls back to safe Google test IDs:
- Copy `.env.example` to `.env` and fill in your production IDs:
  ```properties
  ADMOB_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
  ADMOB_REWARDED_AD_UNIT_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
  ```
- Build production release using:
  ```bash
  flutter build appbundle --release --dart-define-from-file=.env
  ```
