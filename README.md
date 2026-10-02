# Subbles

[Қазақша](README.kk.md) · **English**

A Flutter app for tracking subscriptions, payment schedules, and spending. Data is stored locally in SQLite. Internet access is used to retrieve exchange rates; subscriptions and saved data remain available offline.

The current project targets Android. Accounts, server synchronization, and bank integrations are not implemented.

## Interface

The app has three pages with icon-only bottom navigation.

- **Home:** active subscriptions as draggable bubbles, upcoming payments, a list of all subscriptions, and a `+` button to add a subscription. Each bubble shows the original price, currency, and subscription name.
- **Calendar:** historical and upcoming payments for a month, day selection, and a total in the chosen display currency.
- **Analytics:** monthly or yearly spending, a chart, subscription rankings, and category shares. Historical spending and projected spending are shown separately.

The design uses a light background, green accents, and glass surfaces built with transparency, gradients, light borders, and soft shadows. Background blur is not used. The primary font is Plus Jakarta Sans, bundled in `assets/fonts/`.

## Getting started

Use Flutter with a Dart version compatible with the `^3.11.4` constraint in `pubspec.yaml`, and a configured Android SDK. The Android project uses Java 17.

From the project root:

```sh
flutter pub get
flutter run
```

To assess animation smoothness on a physical device:

```sh
flutter run --profile
```

Build an APK:

```sh
flutter build apk --release
```

Release builds currently use the debug signing configuration in `android/app/build.gradle.kts`. Set up your own signing configuration before publishing.

## Languages

Localization uses `easy_localization`. The language selector is on Home, with this order:

1. Қазақша — `kk`.
2. English — `en`.
3. Russian — `ru`.

The selected language is saved between launches. On the first launch, the app uses a supported device language, with English as the fallback.

```text
assets/translations/
├── kk.json
├── en.json
└── ru.json
```

Interface text, built-in categories, recurrence labels, messages, and dates are localized. User-entered subscription names and notes are preserved. Translation keys must match across all three files; strings containing counts use plural forms.

Shared configuration and the `AppText` widget are in `lib/core/localization/app_text.dart`; the selector is in `language_selector.dart`. Add new strings to the JSON files and display them with `AppText('key')` or `context.tr('key')`.

After changing dependencies or asset declarations in `pubspec.yaml`, run `flutter pub get` and fully restart the app.

## Subscriptions and payment history

A subscription stores its name, icon, price, currency, category, notes, payment date, and recurrence. Weekly, monthly, yearly, and custom intervals are supported. Custom intervals range from 1 to 120 days, weeks, months, or years.

- Schedules use calendar dates, so time-zone offsets do not shift payment dates.
- Monthly billing on the 31st uses the last day of shorter months, then returns to the original day. Yearly billing on February 29 follows the same principle.
- Dates before today are historical; today and later are projected. A payment scheduled today becomes historical tomorrow.
- History follows the saved schedule. Entries represent assumed charges, without bank confirmation.
- Changes take effect today. Earlier payments retain their original amounts, currencies, and terms. Changing only the price preserves the original recurrence anchor.
- Adding a subscription with a past date creates history from that date using the entered terms.
- Deactivation stops future payments and retains history. Deletion also retains historical payments in Calendar and Analytics.
- Future payments are calculated for the selected period and are not stored as completed payments.

Missing historical entries are added on startup, day rollover, app resume, and before subscription changes. Reprocessing does not create duplicates.

## Currencies and calculations

Supported currencies are **KZT, USD, and EUR**. Amounts are stored as integer minor units. Conversion never changes the original subscription price.

The display currency can be selected in Calendar and Analytics. This shared preference persists between launches. Bubble sizes on Home are compared using converted amounts, while bubble labels retain the original currencies.

Rates come from the [Currency API](https://github.com/fawazahmed0/exchange-api), using jsDelivr as the primary endpoint and Cloudflare as the fallback. No API key is required.

- The latest rate is considered fresh for 24 hours after retrieval and is used for projections.
- Historical payments use the saved rate for their payment date. Historical rates must exactly match the requested date.
- If a rate is missing, the original amount remains visible and converted totals are marked incomplete. Today's rate is never substituted for a missing historical rate.
- Requests for the same date are deduplicated. At most three historical rates are downloaded concurrently. Failed requests have a 15-minute retry cooldown.

## Data storage

The database is `subbles.db`, schema version 1. Records contain JSON payloads, with identifiers and dates also represented by SQL columns and indexes.

| Table | Contents |
| --- | --- |
| `subscriptions` | Current subscription terms |
| `revisions` | Changes to subscription terms |
| `payments` | Independent historical payment snapshots |
| `fx_cache` | Latest and historical exchange rates |
| `preferences` | Display currency and history reconciliation date |
| `categories` | Subscription categories |

Writes are serialized through one transaction queue. Changed state is published only after successful persistence. The language preference is saved separately by `easy_localization`.

## App icon and splash screen

The source logo is `assets/logo.png`. Prepared Android resources are in `android/app/src/main/res/`:

- `mipmap-mdpi` … `mipmap-xxxhdpi`: launcher icons for different screen densities and adaptive foreground images.
- `mipmap-anydpi-v26/ic_launcher.xml`: adaptive launcher icon.
- `drawable-mdpi` … `drawable-xxxhdpi`: splash logo images.
- `drawable/launch_background.xml` and `drawable-v21/launch_background.xml`: launch screens for older Android versions.
- `values-v31/styles.xml` and `values-night-v31/styles.xml`: Android 12+ system splash configuration.

The light background uses `brand_background` from `values/colors.xml`. Prepared images include padding for the system icon mask.

The app uses these prepared resources. Replacing only `assets/logo.png` does not update them automatically: regenerate the corresponding images when changing the logo. Check the icon and native splash after building and installing a new version; hot reload does not update them.

## Project structure

```text
lib/
├── main.dart
├── app/                    # startup, MaterialApp, navigation, lifecycle
├── core/
│   ├── domain/             # calendar dates, currencies, recurrence
│   ├── format/             # amount and date formatting
│   ├── localization/       # languages, translations, selector
│   ├── theme/              # palette and theme
│   └── widgets/            # shared interface components
└── features/
    ├── subscriptions/      # models, SQLite, controller, editor, details
    ├── fx/                 # exchange rate retrieval and caching
    ├── home/               # Home, bubbles, collision physics
    ├── calendar/           # payment calendar
    └── analytics/          # spending calculations and visualization
```

`SubscriptionsController` owns the data and write queue. `FxController` manages exchange rate retrieval and display currency selection, persisting changes through the same subscriptions controller. `Spending` calculates spending; `Timeline` handles schedules and history.

Tabs are created on first use and retain their state. Bubble animation stops when motion settles, the tab is hidden, or the app is in the background. The bubble field and bubble contents have separate repaint boundaries. Long lists create rows lazily; period calculations and formatters are cached.

