# App Spec — Flutter (Android-first)

This is a spec and reference skeleton for what the app should become, not a retrospective of what's built — only the Drift schema exists so far (see `CLAUDE.md`'s Current status). Written the way StellarRep's *original* `APP_SPEC.md` was before any phase touched it: several real decisions below are deliberately left open for whichever phase actually gets there, rather than pre-decided here.

## Dependency setup

Already in `app/pubspec.yaml` as of the fork:

```yaml
dependencies:
  drift: ^2.34.4
  drift_flutter: ^0.3.1
  solana: ^0.31.2+1
  solana_mobile_client: ^0.1.2

dev_dependencies:
  drift_dev: ^2.34.5
  build_runner: ^2.4.15
```

These were current as of the fork — confirm against [pub.dev](https://pub.dev) before adding anything new or bumping a version; this ecosystem (especially `solana_mobile_client`, a thinner/newer package than the Stellar SDK StellarRep depended on) moves fast and has fewer users to catch breakage early.

- [`solana`](https://pub.dev/packages/solana) — RPC client, transaction building, keypair/pubkey types. Route all Solana RPC calls through this; don't hand-roll JSON-RPC.
- [`solana_mobile_client`](https://pub.dev/packages/solana_mobile_client) — Mobile Wallet Adapter. This is the actual mechanism for wallet connection and every signature; see `docs/ARCHITECTURE.md`'s security model. **This package is Android-only** — confirm its current platform support before assuming any codepath through it works on iOS/other platforms Flutter also scaffolds.
- `drift`/`drift_flutter` — local SQLite-backed cache; schema in `app/lib/core/database/app_database.dart`.

## Folder structure

No decision recorded yet on the internal `lib/` layout beyond what exists (`lib/core/database/`). Suggested shape, following StellarRep's Core/Features split (adapt as it turns out to fit Flutter/Dart conventions better than a mechanical port):

```
app/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart      ← Drift schema: WorkerProfiles, Reviews, DraftReviews (exists)
│   │   │   └── app_database.g.dart    ← generated, not hand-edited
│   │   ├── solana/
│   │   │   ├── network_config.dart     ← devnet RPC URL, program ID — single source of truth, nothing hardcoded elsewhere
│   │   │   ├── wallet_adapter.dart     ← thin wrapper around solana_mobile_client's connect/sign calls
│   │   │   └── reputation_service.dart ← see Service layer below
│   │   └── models/
│   │       ├── worker_profile.dart     ← app-facing model, mirrors the on-chain WorkerProfile account
│   │       └── review.dart
│   └── features/
│       ├── wallet_connect/             ← MWA connection flow — the app's actual entry point (no Keychain-style create/import; connecting IS onboarding)
│       ├── registration/               ← register_worker
│       ├── profile/                    ← look up any address
│       └── submit_review/
├── android/                            ← the platform that actually matters for this hackathon
└── test/
```

## Service layer

Design, not yet built. Same shape as StellarRep's `ReputationServiceProtocol`, adapted:

```dart
abstract class ReputationService {
  Future<void> registerWorker({required Ed25519HDPublicKey worker});
  Future<void> submitReview({
    required Ed25519HDPublicKey worker,
    required Ed25519HDPublicKey reviewer,
    required String jobId,
    required int rating,
  });
  Future<WorkerProfile?> getReputation({required Ed25519HDPublicKey worker});
  Future<List<Review>> getReviews({required Ed25519HDPublicKey worker});
}
```

Key differences from StellarRep's version, not just a mechanical rename:

- **No `as reader` parameter on reads.** Unlike Soroban (where even a read needed a fee-paying `KeyPair` to build a simulated transaction envelope), Solana account reads are plain RPC calls (`getAccountInfo`/`getProgramAccounts`) — no signer, no transaction, no fee. See `docs/PROGRAM_SPEC.md`'s note on why there are no `get_reputation`/`get_reviews` instructions at all.
- **Signing goes through Mobile Wallet Adapter, not a held keypair.** `registerWorker`/`submitReview` don't take a `KeyPair` the way StellarRep's did — they need whatever `solana_mobile_client`'s authorize/sign-and-send flow actually requires (an active MWA session, most likely). Design this against the real package API once Phase 4 (Mobile Wallet Adapter Integration) actually happens, rather than guessing the shape here.
- **Error handling: confirm before assuming.** StellarRep found the hard way that `stellarsdk` had no structured type for a contract's own rejection — it surfaced as a diagnostic string that had to be regex-parsed. Anchor's `#[error_code]` errors are *supposed* to arrive structured (see `docs/PROGRAM_SPEC.md`'s Errors section) — verify this actually holds through the `solana` Dart package's error types during Phase 5, don't assume it's clean just because the Rust side is nicer than Soroban's was.

**Pending/failed state pattern — port the concept, not the code.** StellarRep's `ContractCallState<Success>` (`.idle`/`.pending`/`.succeeded`/`.failed`) is a good pattern regardless of language: whatever Flutter state-management approach gets picked (see below) should have an equivalent so pending and failed are never collapsed into one loading spinner — same principle, e.g. a Dart sealed class or enum with associated data.

## Screens

1. **Wallet Connect** — the app's actual entry point; there's no create/import flow the way StellarRep had, since Mobile Wallet Adapter means every wallet already exists in a separate app the user installed themselves. Connecting a wallet via MWA *is* onboarding. Handle "no compatible wallet app installed" as a distinct, actionable state (link to install one), not a generic error.
2. **Profile / Look Up** — search by any address; shows aggregate rating, job count, review list. Looking up an unregistered address should be a distinct state offering registration (if it's your own connected wallet's address) — same principle as StellarRep's `ProfileViewModel.isNotRegistered`, not yet built here.
3. **Submit Review** — the reviewer-side flow. **Handoff mechanism: not yet decided.** StellarRep settled on manual paste for MVP speed; worth deliberately revisiting here rather than defaulting to the same choice — Android + a same-device-class hackathon audience makes both a QR scan (`camera`/`mobile_scanner` packages) and an `Intent`-based deep link more natural than they were on iOS, and either could be a real differentiator for judges since "mobile-native handoff" is squarely in this hackathon's theme. Decide explicitly in whichever phase reaches this, and record the choice + reasoning here.
4. **Settings** — a persistent, hard-to-miss network indicator (must read "Devnet" throughout the hackathon build — this should not be a small label a judge could miss, especially since the whole point of MWA is that *this app itself* never shows key material, so the network indicator is one of the few trust signals left for the user to check).

## State management

**Not yet decided.** StellarRep locked in `ObservableObject`/`@Published` early (Phase 4) with reasoning recorded here once made; do the same for Flutter rather than defaulting silently. Real options, roughly StellarRep-equivalent in spirit:
- Plain `ChangeNotifier`/`ValueNotifier` + `provider` — minimal, matches StellarRep's "don't add a dependency you don't need" instinct.
- `riverpod` — more structure, better testability for async state, heavier.
- `flutter_bloc` — most ceremony, most explicit state-transition modeling (closest analog to `ContractCallState` as a first-class pattern).

Pick one, don't mix, and record the choice + reasoning here once a real ViewModel/controller gets built (the wallet-connect flow in Phase 4 is the natural first place this decision becomes unavoidable).

## Testing approach

Same philosophy as StellarRep, adapted to Flutter's tooling:
- **Fast, offline unit tests** for controllers/view-models against a mocked `ReputationService` — `flutter test`, no network, no device needed. The Drift schema already has tests (`app/test/`) in this spirit.
- **A small number of real integration tests** against live devnet — `integration_test` package (Flutter's on-device/emulator integration test runner) is the natural fit here, since Mobile Wallet Adapter fundamentally can't be tested any other way (it requires a real wallet app installed, so it can't be mocked out at the unit-test level and still prove anything about the actual submission-worthy flow). Keep these clearly separated from the fast unit suite, same reasoning as StellarRep's `*IntegrationTests.swift` files being split from the mocked ones.
