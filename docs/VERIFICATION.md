# Verifying ClockIn

How to check the project's claims against the source, at a fixed commit. What works today and what is only planned is in [`STATUS.md`](STATUS.md).

## Commit

| | |
|---|---|
| Repository | https://github.com/adewuyito/ClockIn |
| Commit to audit | `00a58b70bc5f853583e759c53e69a4b11c2158c8` |
| Evidence produced | 12 October 2026 |

```bash
git clone https://github.com/adewuyito/ClockIn.git && cd ClockIn
git checkout 00a58b70bc5f853583e759c53e69a4b11c2158c8
```

Later commits change documentation and CI only, not the program or the app.

## Source

| Part | Path |
|---|---|
| Anchor program (Rust, 20 instructions) | `program/programs/reputation/src/lib.rs` |
| Program tests | `program/tests/` |
| Flutter app | `app/lib/` |
| App tests | `app/test/` |
| Firestore rules and their tests | `firestore.rules`, `firestore-tests/rules.test.js` |

## Deployed program

| | |
|---|---|
| Network | Solana Devnet (no mainnet deployment) |
| Program ID | [`FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9`](https://explorer.solana.com/address/FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9?cluster=devnet) |
| Upgrade authority | `GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P` |
| Last deployed slot | `508848800` |
| Size | 565,296 bytes |
| SHA-256 | `e35e388a8b6a4d4a6f7948df3e292924e2930783dc5672d353dcd4cf10750ade` |

The deployed bytes match the build the program tests ran against. To repeat the comparison (the on-chain account is zero-padded after the program, so compare the first 565,296 bytes):

```bash
solana program dump FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9 /tmp/deployed.so --url devnet
head -c 565296 /tmp/deployed.so | shasum -a 256
```

This is a direct byte comparison, not the explorer's "Verified Build" badge, which the program does not have. The build is not pinned to a Docker image, so a fresh build on another machine may hash differently.

## Tests

| Suite | Tests | Result | Saved output |
|---|---|---|---|
| Anchor program | 39 | all passing | [`anchor-test.log`](test-evidence/anchor-test.log) |
| Flutter app | 176 | all passing | [`flutter-test.log`](test-evidence/flutter-test.log) |
| Firestore rules | 33 | all passing | [`firestore-rules-test.log`](test-evidence/firestore-rules-test.log) |
| **Total** | **248** | | |

The app and rules suites also run in CI on every push: [Actions](https://github.com/adewuyito/ClockIn/actions), first passing run [38311680048](https://github.com/adewuyito/ClockIn/actions/runs/38311680048). Earlier material quotes 239 tests; that was the count before 9 app tests were added.

To reproduce:

```bash
# Program (needs Solana CLI and Anchor 1.2.0; about 3 minutes)
cd program && npm install
cargo build-sbf --arch v1
anchor idl build -o target/idl/reputation.json -t target/types/reputation.ts
anchor test --skip-build --validator legacy        # expect: 39 passing

# App (needs Flutter 3.44+)
cd app && flutter pub get
flutter analyze lib/ test/                          # expect: No issues found!
flutter test                                        # expect: +176: All tests passed!

# Firestore rules (needs Node, Java, Firebase CLI; run from the repo root)
(cd firestore-tests && npm install)
CI=true firebase emulators:exec --only firestore --project clockin-rules-test \
  "node firestore-tests/node_modules/mocha/bin/mocha.js --timeout 20000 firestore-tests/rules.test.js"   # expect: 33 passing
```

`anchor test` exits 0 even when tests fail, so read its summary line.

## Transactions on Devnet

Finalized transactions for each path, by currency. Each link opens Solana Explorer. The same list is in [`test-evidence/devnet-transactions.json`](test-evidence/devnet-transactions.json).

| Path | SOL | USDC | Test $SKR |
|---|---|---|---|
| Create and fund | Yes | Yes | Yes |
| Accept | Yes | Yes | Yes |
| Release and review | Yes | Yes | Yes |
| Cancel and refund | Yes | Not yet | Yes |
| Dispute and agreed split | Yes | Not yet | Yes |

| Currency | Contract | Made in | Transactions |
|---|---|---|---|
| SOL | `ctr-295356` | app | create + fund [`47s42q…`](https://explorer.solana.com/tx/47s42qpCz8R7kiCQsQE7aXt9q13JcRg5yCc8c2X4vB74FGfX2y6FoTgx9H21bH8umv1HsUAi1odBJ7s3JpPFAVbP?cluster=devnet) → accept [`U3k3Sg…`](https://explorer.solana.com/tx/U3k3SgwUSNyD1bSozesNpUSMYN2agcCadX9mbw9GHmV9JuzSAtDJo7KX1WFmm8VqNqZq11RJNG4GYoLGiFGQNgr?cluster=devnet) → raise dispute [`24V9C3…`](https://explorer.solana.com/tx/24V9C3Wwy5Yr8ijQFDLXBoDn6ErqE1hP5RyyhWo4oNo1SGuzYuG4SMrkgn7gdQpsR5pTQVzyYm56ZPmKw9QpHsF8?cluster=devnet) → resolve: release to worker [`4XxaTe…`](https://explorer.solana.com/tx/4XxaTey9V7SRmuzMKUjW4RjiqpZKEUzN6mCXHjujX37qGfBW9hNn3zuayGjxiesEHd7jjosRPM97D88haKaVRBj1?cluster=devnet) |
| SOL | `ctr-369987` | app | create + fund [`3XoqeD…`](https://explorer.solana.com/tx/3XoqeDbwD7L3ukCTb9JRKeTTDPk9xa4Ujp7yLcVNiJ4w3h4VESJj1K7sXj5VLQ1TFYLzPwpNgbFXbFmPXqom9Cfa?cluster=devnet) → accept [`3gMhwz…`](https://explorer.solana.com/tx/3gMhwzaYMP17soZNqZYVnLFyJyfc6BZk1gCgU5EJgGQvrLKti7VKjengTpLVwaymMnmcAcqFpVE3LtF6nUNVwKXj?cluster=devnet) → raise dispute [`4JvjVU…`](https://explorer.solana.com/tx/4JvjVUABaP7SsqYdRjrjPmRSnTkdMiRRZRVzZcYFAU4T7MQTKeWfAL3LBxfyjNT4hikBxnbtKpQF2mXyjMVsnxMR?cluster=devnet) → propose split [`4tafwB…`](https://explorer.solana.com/tx/4tafwBsL9ryqm8PPnn9eZoc6sJ5rQv8jxtsyTt3RyoBHxnEbZvpHJzAUWbPAvdtr3f3CF4BnH9b3BWoJRDn5Wn8y?cluster=devnet) → resolve: 50/50 split [`2ceojG…`](https://explorer.solana.com/tx/2ceojGrJYMA7LotXXgkECUiUkKo41FKiBv63g1LnuKsHw9Xw7yVKsk7v77HdevEnK1wbK5gTPZv4usXW93cow3v9?cluster=devnet) |
| SOL | `ctr-869393` | app | create + fund [`MnMeoj…`](https://explorer.solana.com/tx/MnMeojpftEbvMT8iZU43Snqh1ciGWEsPCwd8g623NYzvNXuPiT8sPWsQ7wcxHZ9hVKrTfQ4PqAqFjxEV1tYakTZ?cluster=devnet) → accept [`2HLMZc…`](https://explorer.solana.com/tx/2HLMZcKqBJ1T64vdJ1PYRiB8GLkjGft38BGZSVkvnxxbUefdYkxCyghtdXfFZyBTLcY66sn1HMhbTw7dY7mvA2fP?cluster=devnet) → release + review [`5w7hMK…`](https://explorer.solana.com/tx/5w7hMKp2dWsLaTeyZUd6xZcvHn2jq5ZfcBNRxYTVXiWiiKYQRWvRGXuvAKzM3cYAZWWzztwNvUUQaExA4o1xgGG5?cluster=devnet) |
| SOL | `ev-sol-cx-5siami` | script | create + fund [`2HpkcZ…`](https://explorer.solana.com/tx/2HpkcZ5TBDNMt4hkx8iCF5tGcSCSZUo3MkZkU4dEu9wG84K4qfQKzae93ZL2H85qYSQfssDMAyU7a2p2iEoVeNJt?cluster=devnet) → cancel [`KHdReu…`](https://explorer.solana.com/tx/KHdReuQJPYZAaUcJe4GEQiXg3sH7anL8TxifLjgJZSmZT3e7V3h71eai65ToGNoet1ejhjXQBnF4dhHv51kaDzQ?cluster=devnet) |
| USDC | `ctr-321723` | app | create + fund [`4uDEoQ…`](https://explorer.solana.com/tx/4uDEoQv7nWSnbzJmTfsVKzPxyaooAsWSmerF6hbNsS6hQfuxizg1SGXjXsswq1TFsYYqTigr9FaMSyWUGU5xZYsj?cluster=devnet) → accept [`4kKLjK…`](https://explorer.solana.com/tx/4kKLjKCjgcBejWCdsF5Yb6Mm1pST6Xv6qMkPig9AVwYqPUREkyW7fsRQD6rYMwedgKqRD9HEiiLF6DhqCNWpcDAD?cluster=devnet) → release + review [`epHAby…`](https://explorer.solana.com/tx/epHAbyEbwWh4iJ2tsgC5XkA8So1sdaRSp58J9oBEMg2eRRq5doatU8a55kLbHY2DFXpDCY9GgjhrHNHpNuZm7h1?cluster=devnet) |
| Test $SKR | `ctr-985669` | app | create + fund [`4jW4G9…`](https://explorer.solana.com/tx/4jW4G9zKGGNkXBnuGmsSWcsYMrdFEiDCFSA6z8xuFv67pY7oprUXif143SXxoLSZK5BmmZttzssmvxYvX3vHXHeV?cluster=devnet) → accept [`2NRvQj…`](https://explorer.solana.com/tx/2NRvQjtXhvvvdFWPgbqj6aArtSC8WPzbKFEZikDrQyN7Na7ZEDhJv2EYcCx7aQPxcy28qeyE4xrYCqykgU4ayDwe?cluster=devnet) → release + review [`3jUqcq…`](https://explorer.solana.com/tx/3jUqcqY5Wh8p1Ko9ZEbpN9Y2mU6Rtv7EG2cEcCXZAs8zwZWhTmT97QyLYGDFpuEPPvDnX1qhgKuCBf8BS75tG4sy?cluster=devnet) |
| Test $SKR | `ev-skr-cx-5siami` | script | create + fund [`35FBMr…`](https://explorer.solana.com/tx/35FBMrKPhZhy8m4R6Yt1MLRgsTcPCq9VEWQoQET8iwcrVP92kkLdWa79fGUg3rGJf31R3GajWziYRA6bdwJFMnoe?cluster=devnet) → cancel [`5DNDaA…`](https://explorer.solana.com/tx/5DNDaAcoMRrkAF4EPVENRkwiRCiQRbrBZkKNfw8VhrV736cwKzFdM3ZQ1zYMDuJPtszfYbShWYtxexwyWtej1nHE?cluster=devnet) |
| Test $SKR | `ev-skr-sp-5siami` | script | create + fund [`462maH…`](https://explorer.solana.com/tx/462maHdFiAWRAVSNw6wYTaKsFcDydrp9KSFHBj32D6NnZjMAvTVWEu6iqHyxojSLti9qZNcuVgoHvW61pXAuSSN2?cluster=devnet) → accept [`2Vviz6…`](https://explorer.solana.com/tx/2Vviz68YyNyqp3XzxRJ1b33AJqcwfN1QZAdTSpnat3vPXhCuJu7gqnTUu1S1a5HewhgbRM91UwT4Gz1CdCRevnLF?cluster=devnet) → raise dispute [`5NNoyE…`](https://explorer.solana.com/tx/5NNoyEDgUMbG11Jgm1SJdJa6iKi9FbRCvvrYKQmykmLayEXaHCz8baackY1U2dxT7aL59xHheZ6jkuoCZ7HYoW6x?cluster=devnet) → propose split [`5eK8oJ…`](https://explorer.solana.com/tx/5eK8oJgaNj3GyTK7EC4qJ47v5e7AaqctZXonHoD5LALLPV2Nj1rKGkRrWSgUKUJB4Nwij9sRSNFURzhgQbJauvpc?cluster=devnet) → resolve: 50/50 split [`5zKuzB…`](https://explorer.solana.com/tx/5zKuzB9j4UuQ15fU7GBRm5wP1PpkP7VBJud3hz4zmdJb1AzzxpTg9eSihcmzp8qzpLvqE12XTFSaszP1Jp8nNsKo?cluster=devnet) |

Notes:

- Create and fund are one transaction; so are release and review. Delivering work has no transaction, because deliverables are encrypted and stored off-chain.
- There is no official $SKR on Devnet. "Test $SKR" is the project's own Devnet token, mint `Gd1eTEXDt1D9uyTqCrVTKtaumz7XmZKvfThVEX9856N9`. USDC is Circle's Devnet USDC, mint `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU`.
- USDC cancel and USDC dispute are not linked because the script wallet holds no Devnet USDC. They use the same token instructions shown for test $SKR, and the program tests cover them.
- "app" contracts were signed on a phone through Mobile Wallet Adapter; `ctr-869393` is the contract in the demo video. "script" contracts were made with the Devnet deployer wallet (`GBZqh…vfh8P`) as the client and a throwaway wallet as the worker, to show the cancel and token-dispute paths.
