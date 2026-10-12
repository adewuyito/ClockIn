# Verifying ClockIn

This page lets a reviewer check every claim the project makes against the source, at a fixed commit. Each section says where the code is, what command to run, and what result to expect.

## The commit

| | |
|---|---|
| Repository | https://github.com/adewuyito/ClockIn |
| Commit to audit | `00a58b70bc5f853583e759c53e69a4b11c2158c8` |
| Date | 12 October 2026 |

The test runs and the bytecode comparison below were made on the code at that commit. This file, the saved test output in `docs/test-evidence/` and the CI workflow were added in the commit that follows it (`35787ca`); that commit changes documentation and CI only, not program or app code.

One detail for exactness: the runs were made locally before the commit was rebased onto a README edit made on GitHub, so the local commit had a different hash. The two differ only in `README.md`. The app, program, rules and test files are identical, and the public CI run linked below repeated the app and rules tests on the published history.

To check out the same code:

```bash
git clone https://github.com/adewuyito/ClockIn.git
cd ClockIn
git checkout 00a58b70bc5f853583e759c53e69a4b11c2158c8
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

## Transactions on Devnet

Real, finalized transactions for each path through the program, by currency. Every link opens the transaction on Solana Explorer. The same list is in machine-readable form in [`test-evidence/devnet-transactions.json`](test-evidence/devnet-transactions.json).

**How the paths map to instructions.** Creating a contract and funding it are one instruction (`create_and_fund`, or `create_and_fund_token` for tokens), so they share a transaction. Delivering work has no transaction: deliverables are encrypted on the worker's phone and stored off-chain, and only the release that follows is on-chain. Releasing payment and recording the review are also one instruction (`release_and_review`).

**About $SKR on Devnet.** There is no official $SKR on Devnet. The token rows below use the project's own Devnet test token, mint `Gd1eTEXDt1D9uyTqCrVTKtaumz7XmZKvfThVEX9856N9`. USDC rows use Circle's Devnet USDC, mint `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU`. Both go through the same token instructions.

### Coverage

| Path | SOL | USDC | Test $SKR |
|---|---|---|---|
| Create and fund | Yes | Yes | Yes |
| Accept | Yes | Yes | Yes |
| Release and review | Yes | Yes | Yes |
| Cancel and refund | Yes | Not yet (see note) | Yes |
| Dispute and agreed split | Yes | Not yet (see note) | Yes |

**USDC cancel and USDC dispute are not linked yet.** The wallet that ran the scripted paths holds no Devnet USDC. The same two instructions (`cancel_token_contract`, `resolve_token_dispute`) are shown above for the test $SKR token; they do not depend on which mint is used, and the program's test suite covers them. To add USDC examples, send 2 Devnet USDC to the script wallet and run `CLOCKIN_ONLY=USDC npx ts-node --transpile-only scripts/devnet_path_evidence.ts` from `program/`.

### The transactions

**SOL: Create and fund, accept, release and review** (contract `ctr-869393`, made in the app; this is the contract in the demo video)

| Step | Instruction | Transaction | Date |
|---|---|---|---|
| 1 | `create_and_fund` | [`MnMeojpf…`](https://explorer.solana.com/tx/MnMeojpftEbvMT8iZU43Snqh1ciGWEsPCwd8g623NYzvNXuPiT8sPWsQ7wcxHZ9hVKrTfQ4PqAqFjxEV1tYakTZ?cluster=devnet) | 2026-10-11 |
| 2 | `accept_contract` | [`2HLMZcKq…`](https://explorer.solana.com/tx/2HLMZcKqBJ1T64vdJ1PYRiB8GLkjGft38BGZSVkvnxxbUefdYkxCyghtdXfFZyBTLcY66sn1HMhbTw7dY7mvA2fP?cluster=devnet) | 2026-10-11 |
| 3 | `release_and_review` | [`5w7hMKp2…`](https://explorer.solana.com/tx/5w7hMKp2dWsLaTeyZUd6xZcvHn2jq5ZfcBNRxYTVXiWiiKYQRWvRGXuvAKzM3cYAZWWzztwNvUUQaExA4o1xgGG5?cluster=devnet) | 2026-10-11 |

**SOL: Dispute settled by an agreed 50/50 split** (contract `ctr-369987`, made in the app)

| Step | Instruction | Transaction | Date |
|---|---|---|---|
| 1 | `create_and_fund` | [`3XoqeDbw…`](https://explorer.solana.com/tx/3XoqeDbwD7L3ukCTb9JRKeTTDPk9xa4Ujp7yLcVNiJ4w3h4VESJj1K7sXj5VLQ1TFYLzPwpNgbFXbFmPXqom9Cfa?cluster=devnet) | 2026-10-08 |
| 2 | `accept_contract` | [`3gMhwzaY…`](https://explorer.solana.com/tx/3gMhwzaYMP17soZNqZYVnLFyJyfc6BZk1gCgU5EJgGQvrLKti7VKjengTpLVwaymMnmcAcqFpVE3LtF6nUNVwKXj?cluster=devnet) | 2026-10-08 |
| 3 | `raise_dispute` | [`4JvjVUAB…`](https://explorer.solana.com/tx/4JvjVUABaP7SsqYdRjrjPmRSnTkdMiRRZRVzZcYFAU4T7MQTKeWfAL3LBxfyjNT4hikBxnbtKpQF2mXyjMVsnxMR?cluster=devnet) | 2026-10-08 |
| 4 | `propose_split` | [`4tafwBsL…`](https://explorer.solana.com/tx/4tafwBsL9ryqm8PPnn9eZoc6sJ5rQv8jxtsyTt3RyoBHxnEbZvpHJzAUWbPAvdtr3f3CF4BnH9b3BWoJRDn5Wn8y?cluster=devnet) | 2026-10-08 |
| 5 | `resolve_dispute` (50/50 split) | [`2ceojGrJ…`](https://explorer.solana.com/tx/2ceojGrJYMA7LotXXgkECUiUkKo41FKiBv63g1LnuKsHw9Xw7yVKsk7v77HdevEnK1wbK5gTPZv4usXW93cow3v9?cluster=devnet) | 2026-10-08 |

**SOL: Dispute settled by releasing to the worker** (contract `ctr-295356`, made in the app)

| Step | Instruction | Transaction | Date |
|---|---|---|---|
| 1 | `create_and_fund` | [`47s42qpC…`](https://explorer.solana.com/tx/47s42qpCz8R7kiCQsQE7aXt9q13JcRg5yCc8c2X4vB74FGfX2y6FoTgx9H21bH8umv1HsUAi1odBJ7s3JpPFAVbP?cluster=devnet) | 2026-09-30 |
| 2 | `accept_contract` | [`U3k3SgwU…`](https://explorer.solana.com/tx/U3k3SgwUSNyD1bSozesNpUSMYN2agcCadX9mbw9GHmV9JuzSAtDJo7KX1WFmm8VqNqZq11RJNG4GYoLGiFGQNgr?cluster=devnet) | 2026-09-30 |
| 3 | `raise_dispute` | [`24V9C3Ww…`](https://explorer.solana.com/tx/24V9C3Wwy5Yr8ijQFDLXBoDn6ErqE1hP5RyyhWo4oNo1SGuzYuG4SMrkgn7gdQpsR5pTQVzyYm56ZPmKw9QpHsF8?cluster=devnet) | 2026-09-30 |
| 4 | `resolve_dispute` (release to worker) | [`4XxaTey9…`](https://explorer.solana.com/tx/4XxaTey9V7SRmuzMKUjW4RjiqpZKEUzN6mCXHjujX37qGfBW9hNn3zuayGjxiesEHd7jjosRPM97D88haKaVRBj1?cluster=devnet) | 2026-10-02 |

**SOL: Create and fund, then cancel and refund** (contract `ev-sol-cx-5siami`, made in the script (program/scripts/devnet_path_evidence.ts))

| Step | Instruction | Transaction | Date |
|---|---|---|---|
| 1 | `create_and_fund` | [`2HpkcZ5T…`](https://explorer.solana.com/tx/2HpkcZ5TBDNMt4hkx8iCF5tGcSCSZUo3MkZkU4dEu9wG84K4qfQKzae93ZL2H85qYSQfssDMAyU7a2p2iEoVeNJt?cluster=devnet) | 2026-10-12 |
| 2 | `cancel_contract` | [`KHdReuQJ…`](https://explorer.solana.com/tx/KHdReuQJPYZAaUcJe4GEQiXg3sH7anL8TxifLjgJZSmZT3e7V3h71eai65ToGNoet1ejhjXQBnF4dhHv51kaDzQ?cluster=devnet) | 2026-10-12 |

**USDC: Create and fund, accept, release and review** (contract `ctr-321723`, made in the app)

| Step | Instruction | Transaction | Date |
|---|---|---|---|
| 1 | `create_and_fund_token` | [`4uDEoQv7…`](https://explorer.solana.com/tx/4uDEoQv7nWSnbzJmTfsVKzPxyaooAsWSmerF6hbNsS6hQfuxizg1SGXjXsswq1TFsYYqTigr9FaMSyWUGU5xZYsj?cluster=devnet) | 2026-10-06 |
| 2 | `accept_contract` | [`4kKLjKCj…`](https://explorer.solana.com/tx/4kKLjKCjgcBejWCdsF5Yb6Mm1pST6Xv6qMkPig9AVwYqPUREkyW7fsRQD6rYMwedgKqRD9HEiiLF6DhqCNWpcDAD?cluster=devnet) | 2026-10-06 |
| 3 | `release_and_review_token` | [`epHAbyEb…`](https://explorer.solana.com/tx/epHAbyEbwWh4iJ2tsgC5XkA8So1sdaRSp58J9oBEMg2eRRq5doatU8a55kLbHY2DFXpDCY9GgjhrHNHpNuZm7h1?cluster=devnet) | 2026-10-06 |

**test $SKR: Create and fund, accept, release and review** (contract `ctr-985669`, made in the app)

| Step | Instruction | Transaction | Date |
|---|---|---|---|
| 1 | `create_and_fund_token` | [`4jW4G9zK…`](https://explorer.solana.com/tx/4jW4G9zKGGNkXBnuGmsSWcsYMrdFEiDCFSA6z8xuFv67pY7oprUXif143SXxoLSZK5BmmZttzssmvxYvX3vHXHeV?cluster=devnet) | 2026-09-30 |
| 2 | `accept_contract` | [`2NRvQjtX…`](https://explorer.solana.com/tx/2NRvQjtXhvvvdFWPgbqj6aArtSC8WPzbKFEZikDrQyN7Na7ZEDhJv2EYcCx7aQPxcy28qeyE4xrYCqykgU4ayDwe?cluster=devnet) | 2026-09-30 |
| 3 | `release_and_review_token` | [`3jUqcqY5…`](https://explorer.solana.com/tx/3jUqcqY5Wh8p1Ko9ZEbpN9Y2mU6Rtv7EG2cEcCXZAs8zwZWhTmT97QyLYGDFpuEPPvDnX1qhgKuCBf8BS75tG4sy?cluster=devnet) | 2026-09-30 |

**test $SKR: Create and fund, then cancel and refund** (contract `ev-skr-cx-5siami`, made in the script (program/scripts/devnet_path_evidence.ts))

| Step | Instruction | Transaction | Date |
|---|---|---|---|
| 1 | `create_and_fund_token` | [`35FBMrKP…`](https://explorer.solana.com/tx/35FBMrKPhZhy8m4R6Yt1MLRgsTcPCq9VEWQoQET8iwcrVP92kkLdWa79fGUg3rGJf31R3GajWziYRA6bdwJFMnoe?cluster=devnet) | 2026-10-12 |
| 2 | `cancel_token_contract` | [`5DNDaAco…`](https://explorer.solana.com/tx/5DNDaAcoMRrkAF4EPVENRkwiRCiQRbrBZkKNfw8VhrV736cwKzFdM3ZQ1zYMDuJPtszfYbShWYtxexwyWtej1nHE?cluster=devnet) | 2026-10-12 |

**test $SKR: Dispute settled by an agreed 50/50 split** (contract `ev-skr-sp-5siami`, made in the script (program/scripts/devnet_path_evidence.ts))

| Step | Instruction | Transaction | Date |
|---|---|---|---|
| 1 | `create_and_fund_token` | [`462maHdF…`](https://explorer.solana.com/tx/462maHdFiAWRAVSNw6wYTaKsFcDydrp9KSFHBj32D6NnZjMAvTVWEu6iqHyxojSLti9qZNcuVgoHvW61pXAuSSN2?cluster=devnet) | 2026-10-12 |
| 2 | `accept_contract` | [`2Vviz68Y…`](https://explorer.solana.com/tx/2Vviz68YyNyqp3XzxRJ1b33AJqcwfN1QZAdTSpnat3vPXhCuJu7gqnTUu1S1a5HewhgbRM91UwT4Gz1CdCRevnLF?cluster=devnet) | 2026-10-12 |
| 3 | `raise_dispute` | [`5NNoyEDg…`](https://explorer.solana.com/tx/5NNoyEDgUMbG11Jgm1SJdJa6iKi9FbRCvvrYKQmykmLayEXaHCz8baackY1U2dxT7aL59xHheZ6jkuoCZ7HYoW6x?cluster=devnet) | 2026-10-12 |
| 4 | `propose_split` | [`5eK8oJga…`](https://explorer.solana.com/tx/5eK8oJgaNj3GyTK7EC4qJ47v5e7AaqctZXonHoD5LALLPV2Nj1rKGkRrWSgUKUJB4Nwij9sRSNFURzhgQbJauvpc?cluster=devnet) | 2026-10-12 |
| 5 | `resolve_token_dispute` (50/50 split) | [`5zKuzB9j…`](https://explorer.solana.com/tx/5zKuzB9j4UuQ15fU7GBRm5wP1PpkP7VBJud3hz4zmdJb1AzzxpTg9eSihcmzp8qzpLvqE12XTFSaszP1Jp8nNsKo?cluster=devnet) | 2026-10-12 |

**Worker registration** (`register_worker`): [`fs5NeaMU…`](https://explorer.solana.com/tx/fs5NeaMUwi4CdmwzskffKFH7TzPNX7TkUjCknjccY8SCNdGjXq8JdjonG8vuZ6YJTfAJzhGiq6JtxHrqq8g4hAS?cluster=devnet)

Contracts made "in the app" were signed on a phone through Mobile Wallet Adapter. Contracts made by the script were signed by the Devnet deployer wallet (`GBZqh…vfh8P`) as the client and a throwaway wallet as the worker; they exist to show the cancel and token-dispute paths, and use amounts of 0.01 SOL or 1 token.

## Tests

| Suite | Tests | Result at `00a58b7` | Saved output |
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

`.github/workflows/tests.yml` runs the Flutter analyzer and tests and the Firestore rules tests on every push to `main`. The results are on the repository's [Actions tab](https://github.com/adewuyito/ClockIn/actions). The first run, on commit `35787ca`, passed: [run 38311680048](https://github.com/adewuyito/ClockIn/actions/runs/38311680048). The Anchor suite is not run in CI because it needs the Solana and Anchor toolchains and a local validator; its saved output and the commands above cover it.

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
