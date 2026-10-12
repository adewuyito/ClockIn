# ClockIn app

The Android app for ClockIn: escrow, encrypted collaboration and portable reputation for freelance work, on Solana Mobile.

A client locks payment in an on-chain vault before work starts. The worker delivers, and a single wallet signature both releases the payment and records the worker's review on-chain. This folder holds the Flutter app. The on-chain program is in [`../program`](../program/README.md), and the project overview is in the [root README](../README.md).

The app runs on **Solana Devnet only**. No real funds are involved.

| | |
|---|---|
| Install | [Latest release](https://github.com/adewuyito/ClockIn/releases/latest) (`ClockIn.apk`, Android, 64-bit ARM) |
| Demo video | https://youtu.be/23zOQ4CJjik |
| What works today and what is planned | [`../docs/STATUS.md`](../docs/STATUS.md) |
| Verify the claims | [`../docs/VERIFICATION.md`](../docs/VERIFICATION.md) |

## What the app does

- **Wallet sign-in with no key custody.** Every action is signed in the user's own wallet app (Solflare, Phantom) through Mobile Wallet Adapter. The app never holds a private key.
- **Escrow contracts** in SOL, USDC or $SKR: create and fund, accept, cancel, release and review. On Devnet the $SKR is the project's own test token, because there is no official Devnet $SKR. A contract has one amount and one release; there are no staged milestone payments.
- **Encrypted chat and deliverables** inside each contract. Messages and files are encrypted on the device, and only the two wallets on the contract can read them. Deliverables and review notes are uploaded through Irys's Devnet node, which does not keep data permanently.
- **Disputes** settled between the two parties, including a 50/50 split that both must agree to.
- **Reputation profiles** read from chain, with a QR pass for sharing and a lookup screen for checking someone else.
- **Seeker verification.** Reads a wallet's real $SKR Guardian stake from Solana Mobile's staking program (read-only) and detects Seeker hardware.
- **Offline support.** A local database caches contracts and profiles, saves drafts, and the app checks the network before any transaction.
- **QR scanning** for wallet addresses, Solana Pay codes and contract links.

## Requirements

- Flutter 3.44 or newer (Dart 3.12). The project is developed with Flutter 3.44.8.
- Android SDK, and an Android phone or emulator. Android is the only supported target; the other platform folders are Flutter's defaults and are not maintained.
- A wallet app on the phone that supports Mobile Wallet Adapter, set to **Devnet**.
- Devnet SOL in that wallet for fees. Devnet USDC or $SKR if you want to fund contracts in those.

## Run it

```bash
cd app
flutter pub get
flutter run            # on a connected Android device
```

To try the full flow you need two wallets, one as the client and one as the worker. Two phones are easiest.

## Build an APK

```bash
# One APK per CPU type (recommended, about 30 MB each)
flutter build apk --release --split-per-abi

# A single universal APK (about 84 MB)
flutter build apk --release
```

The APKs are written to `build/app/outputs/flutter-apk/`. `app-arm64-v8a-release.apk` suits almost every current phone, including Solana Seeker.

### Signing

Without `android/key.properties`, release builds are signed with the local **debug key**. That is fine for installing directly on a phone, but such a build cannot be published to the Solana dApp Store or Google Play, and cannot be updated in place by a build signed with a different key.

To sign properly, create a keystore and copy `android/key.properties.example` to `android/key.properties` with your values. Keep both out of git and back them up; a lost keystore means you can never update the published app.

## Configuration

Settings are passed at build time with `--dart-define`. All are optional.

| Define | Default | What it does |
|---|---|---|
| `CLOCKIN_SKR_STAKE_RPC` | `https://api.mainnet-beta.solana.com` | RPC used for the read-only $SKR stake lookup. Use a private RPC if the public one rate-limits you. |
| `CLOCKIN_SKR_STAKE_CLUSTER` | mainnet | Set to `devnet` to read stake from the staking program's devnet deployment instead. |
| `CLOCKIN_SKR_FAUCET_SEED` | unset | Enables the in-app Devnet $SKR faucet. Without it the faucet reports itself unavailable. Never ship this in a public build. |
| `CLOCKIN_ENABLE_JURY` | `false` | Shows the juror arbitration screens. The on-chain side is disabled too, so leave this off. |

Example:

```bash
flutter build apk --release --split-per-abi \
  --dart-define=CLOCKIN_SKR_STAKE_RPC=https://your-rpc.example
```

Other fixed settings, including the program ID and the Devnet token mints, are in `lib/core/solana/network_config.dart`.

### Firebase

Chat, deliverable sync and push notifications use Firebase (Firestore and Cloud Messaging). The Android config is `android/app/google-services.json`. To use your own Firebase project, replace that file and deploy the rules in [`../firestore.rules`](../firestore.rules). There is no Firebase Auth: identity is the wallet address, and privacy comes from encryption on the device, not from the rules.

## Project layout

```
lib/
├── main.dart
├── core/
│   ├── solana/      Wallet adapter, program instructions, contract and reputation services, $SKR stake reader
│   ├── database/    Drift (SQLite) schema and repositories for the local cache
│   ├── services/    Encryption, chat, Firebase sync, storage uploads, network check, SOL price
│   ├── providers/   Riverpod providers
│   ├── models/      Contract, review, dispute and profile models
│   ├── theme/       Colours and type scale
│   ├── widgets/     Shared widgets (header, QR scanner, sheets)
│   └── config/      Feature flags
└── features/
    ├── wallet_connect/   Connect screen
    ├── contracts/        List, create, detail, chat, deliverables, release and review, disputes
    ├── profile/          My profile, Seeker staking sheet
    ├── search/           Look up a worker, worker profile
    ├── reviews/          Standalone review
    └── settings/         Network and encryption key settings
```

State is managed with Riverpod. The local database is Drift, schema version 13.

## Tests and checks

```bash
flutter analyze lib/ test/    # analyze these paths; a bare `flutter analyze` also walks build/
flutter test                  # 176 tests
```

The tests cover the database and its migrations, transaction building, encryption and key attestation, chat, the $SKR stake reader, disputes, the network check, and widget tests for the main screens. They run without a device or network.

After changing the database schema in `lib/core/database/app_database.dart`, regenerate the Drift code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Wallet setup for Devnet

1. Install Solflare or Phantom on the phone.
2. Switch the wallet's network to **Devnet** in its settings.
3. Get Devnet SOL from a faucet such as [faucet.solana.com](https://faucet.solana.com).
4. Open ClockIn and connect. The first time you use chat or encrypted deliverables, the app asks for one extra signature that links your wallet to an encryption key on the device. It is a message signature, not a transaction, and costs nothing.

## Known limits

- Devnet only. There is no mainnet deployment.
- Release builds here are debug-signed unless you add a keystore.
- Tested on two Samsung phones (Galaxy A51 and a 5-inch J-series). Seeker hardware detection is implemented but has not been tested on a Seeker.
- Juror arbitration is built but switched off, in the app and on-chain. There is no protocol fee and no milestone payment schedule.
- Chat has no push notifications yet, and messages are not individually signed, so chat is not dispute evidence.
- Wallet apps show the app's icon by looking up the favicon of its identity site (`adewuyito.github.io`). Until search services have indexed that site, a wallet may show a placeholder icon.

## More documentation

- [`../docs/STATUS.md`](../docs/STATUS.md): what works today, what is switched off and what is planned.
- [`../docs/VERIFICATION.md`](../docs/VERIFICATION.md): pinned commit, test evidence and Devnet transaction links.
- [`../program/README.md`](../program/README.md): the on-chain program, how to build and test it.
- [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md): how the app, program, encryption and storage fit together.
- [`../docs/APP_SPEC.md`](../docs/APP_SPEC.md): screen-by-screen app spec.
- [`../docs/PROGRAM_SPEC.md`](../docs/PROGRAM_SPEC.md): the on-chain program.
- [`../program/DEPLOYED.md`](../program/DEPLOYED.md): the Devnet deployment record.
