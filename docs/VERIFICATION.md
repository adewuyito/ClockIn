# Verifying ClockIn

This page lets a reviewer check every claim the project makes against the source, at a fixed commit. Each section says where the code is, what command to run, and what result to expect.

## The commit

| | |
|---|---|
| Repository | https://github.com/adewuyito/ClockIn |
| Commit the evidence was produced at | `54c34ef7906d560ee3813c160f6dccd3bb5f7b08` |
| Date | 12 October 2026 |

All test runs and the bytecode comparison below were made on a clean checkout of that commit. This file, the saved test output in `docs/test-evidence/` and the CI workflow were added in the commit that follows it; that commit changes documentation and CI only, not program or app code.

To check out the same code:

```bash
git clone https://github.com/adewuyito/ClockIn.git
cd ClockIn
git checkout 54c34ef7906d560ee3813c160f6dccd3bb5f7b08
```

## Where the source is

| Part | Path | Notes |
|---|---|---|
| Anchor program (Rust) | `program/programs/reputation/src/lib.rs` | One program, 20 instructions |
| Program tests (TypeScript) | `program/tests/` | `reputation.ts`, `escrow.ts`, `token_escrow.ts` |
| Flutter app (Dart) | `app/lib/` | Android target |
| App tests | `app/test/` | 23 test files |
| Firestore security rules | `firestore.rules` | |
| Rules tests | `firestore-tests/rules.test.js` | Run against the Firestore emulator |

## Deployed program

| | |
|---|---|
| Network | Solana Devnet |
| Program ID | [`FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9`](https://explorer.solana.com/address/FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9?cluster=devnet) |
| Program data account | `GmfYDR7SLX8ZRhErkKnD5gt8pTzzbuaH21WUi1ueCnRH` |
| Upgrade authority | `GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P` |
| Last deployed slot | `508848800` |
| Program size | 565,296 bytes (580,592 allocated) |
| SHA-256 of the program | `e35e388a8b6a4d4a6f7948df3e292924e2930783dc5672d353dcd4cf10750ade` |

There is no mainnet deployment. The only mainnet access anywhere in the project is a read-only lookup of a wallet's $SKR Guardian stake in Solana Mobile's staking program, `SKRskrmtL83pcL4YqLWt6iPefDqwXQWHSw9S9vz94BZ`. The app sends no mainnet transactions and holds no keys.

### Check that the deployed program matches the source

Read the live deployment:

```bash
solana program show FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9 --url devnet
```

Download the deployed bytes and compare them with a local build. The on-chain account is padded with zeros after the program, so compare only the first 565,296 bytes:

```bash
cd program
cargo build-sbf --arch v1
solana program dump FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9 /tmp/deployed.so --url devnet
head -c 565296 /tmp/deployed.so | shasum -a 256
shasum -a 256 target/deploy/reputation.so
```

Result on 12 October 2026: the dump's first 565,296 bytes are identical to the build that the 39 program tests ran against, the remaining bytes are all zero, and both hash to `e35e388a…0ade`.

Two limits on this check, stated plainly:

- **It is not the explorer's "Verified Build".** The explorer shows "Program Not Verified" because the program is not registered with the reproducible-build service. The comparison above is a direct byte comparison, which anyone can repeat, but it is a different thing from that badge.
- **A fresh build may not hash the same.** The build is not pinned to a Docker image, so a different machine or toolchain version can produce different bytes from the same source. The comparison was made against the build produced on the developer's machine on 8 October 2026 from the program source last changed in commit `311ab02`.

## Tests

| Suite | Tests | Result at `54c34ef` | Saved output |
|---|---|---|---|
| Anchor program | 39 | 39 passing | [`test-evidence/anchor-test.log`](test-evidence/anchor-test.log) |
| Flutter app | 176 | 176 passing | [`test-evidence/flutter-test.log`](test-evidence/flutter-test.log) |
| Firestore rules | 33 | 33 passing | [`test-evidence/firestore-rules-test.log`](test-evidence/firestore-rules-test.log) |
| **Total** | **248** | **248 passing** | |

The static analyzer also reports no issues: [`test-evidence/flutter-analyze.log`](test-evidence/flutter-analyze.log).

### About the figure 239

Some project material (the pitch deck and earlier versions of the README) says 239 tests. That was the count at commit `3f0b92c`: 39 program, 167 app and 33 rules. Commit `0b6de4c` added 9 app tests for the network check, which brings the app suite to 176 and the total to 248. Both figures are correct for their commit; 248 is the current one.

To confirm the earlier figure, check out `3f0b92c` and run the app tests; the last line reads `+167: All tests passed!`.

### Reproduce: Anchor program (39 tests)

Needs the Solana CLI (Agave), Anchor CLI 1.2.0, Node and Yarn or npm. The run in the saved log used `solana-cli 3.1.10` and `anchor-cli 1.2.0`.

```bash
cd program
npm install
cargo build-sbf --arch v1
# cargo build-sbf does not write the IDL; the TypeScript tests need it.
anchor idl build -o target/idl/reputation.json -t target/types/reputation.ts
anchor test --skip-build --validator legacy
```

Expected last lines: `39 passing`. The run takes about three minutes because it starts a local validator.

`anchor test` exits with status 0 even when tests fail, so read the summary line rather than relying on the exit code.

### Reproduce: Flutter app (176 tests)

Needs Flutter 3.44 or newer. The saved run used Flutter 3.44.8.

```bash
cd app
flutter pub get
flutter analyze lib/ test/
flutter test
```

Expected: `No issues found!` and `+176: All tests passed!`. The tests need no device and no network.

Analyze the two paths as shown. A bare `flutter analyze` also walks `build/`, where plugin sources produce unrelated errors.

### Reproduce: Firestore rules (33 tests)

Needs Node, Java and the Firebase CLI.

```bash
cd firestore-tests && npm install && cd ..
CI=true firebase emulators:exec --only firestore --project clockin-rules-test \
  "node firestore-tests/node_modules/mocha/bin/mocha.js --timeout 20000 firestore-tests/rules.test.js"
```

Expected: `33 passing`.

### Continuous integration

`.github/workflows/tests.yml` runs the Flutter analyzer and tests and the Firestore rules tests on every push to `main`. The results are on the repository's Actions tab. The Anchor suite is not run in CI because it needs the Solana and Anchor toolchains and a local validator; its saved output and the commands above cover it.

## What the tests cover

- **Program (39):** worker registration and reviews; the SOL escrow lifecycle (create and fund, accept, release and review, cancel); the same lifecycle for SPL tokens; dispute settlement between the two parties, including split proposals that need both to agree; wrong-signer and wrong-state rejections; the check that juror arbitration is switched off.
- **App (176):** the local database and its migrations; transaction and instruction building; account decoding; encryption of deliverables and chat, and wallet-signed key attestation; the $SKR stake reader; split proposals; the network check; the SOL price service; widget tests for the main screens.
- **Rules (33):** document shapes and size limits, append-only notifications and chat messages, no deletes, unreadable push tokens, and the catch-all deny.

## Claims and where to check them

| Claim | Check |
|---|---|
| 20 on-chain instructions | Count the `pub fn` entries in the `#[program]` module of `program/programs/reputation/src/lib.rs` |
| Three currencies: SOL, USDC, $SKR | `EscrowCurrency` in `app/lib/core/models/escrow_contract.dart`; token instructions in the program |
| The app holds no private key | `app/lib/core/solana/wallet_adapter.dart`: all signing goes through Mobile Wallet Adapter |
| Payment and review happen in one transaction | `release_and_review` and `release_and_review_token` in the program; covered by the escrow tests |
| A split needs both parties | `propose_split`, and `resolve_dispute` requiring the counterparty's proposal; covered by the dispute tests |
| Juror arbitration is switched off | `JURY_ENABLED = false` in the program; `CLOCKIN_ENABLE_JURY` unset in the app |
| Chat and deliverables are end-to-end encrypted | `app/lib/core/services/contract_chat_crypto.dart`, `deliverable_encryption_service.dart`, `key_attestation_service.dart`, with their tests |
| $SKR stake is read, never moved | `app/lib/core/solana/skr_staking.dart`: RPC reads only |

## Known limits

These are stated in the project's own material and repeated here so a reviewer does not have to find them:

- Devnet only. The $SKR used in escrow on Devnet is a test token created by the project, because there is no official Devnet $SKR.
- The published APK is signed with a development key, not a store release key.
- The app has been tested on two Samsung phones. Seeker hardware detection is implemented but has not been run on a Seeker.
- Written review notes and deliverable files are stored on Irys's Devnet node, which does not keep data permanently.
- The $SKR stake reader relies on an interface worked out from Solana Mobile's staking site, not on published documentation.
- The program has no reproducible "Verified Build" registration and no `security.txt`.
