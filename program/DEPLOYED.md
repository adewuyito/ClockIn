# Deployment — Devnet

| | |
|---|---|
| **Program ID** | `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9` |
| **Cluster** | Solana Devnet (`https://api.devnet.solana.com`) |
| **ProgramData account** | `GmfYDR7SLX8ZRhErkKnD5gt8pTzzbuaH21WUi1ueCnRH` |
| **Upgrade authority** | `GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P` |
| **Last deployed in slot** | `496365466` |
| **Deploy transaction** | [`44bV3b9MimDm2Q7GrhyyEEUGSsmJFAzj4JAYb5YfzjrkJqooHr2NBH4XP1FySKthcMwQDYUBW6A3XLJWvFzai1Nk`](https://explorer.solana.com/tx/44bV3b9MimDm2Q7GrhyyEEUGSsmJFAzj4JAYb5YfzjrkJqooHr2NBH4XP1FySKthcMwQDYUBW6A3XLJWvFzai1Nk?cluster=devnet) |
| **On-chain size** | 171,232 bytes |
| **Rent balance** | 0.8707374 SOL |

All figures above were re-confirmed live against devnet RPC on 2026-09-11 (`solana program show FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9 --url devnet`, plus a direct `getAccountInfo`/`getSignaturesForAddress` call against the ProgramData account) — not copied from an old note. The deploy transaction signature above is the one whose slot (`496365466`) matches `solana program show`'s "Last Deployed In Slot" exactly.

Deployed via `cargo build-sbf --arch v1 --sbf-out-dir target/deploy` followed by `solana program deploy` — see `docs/ARCHITECTURE.md`'s "Known-bad default build" note for why `anchor build`'s own default build step is bypassed (it silently produces an unexecutable binary in this environment).

## Verified on-chain behavior

- **`register_worker`** — signed via Solflare on a physical Android device (Samsung SM-A515F), confirmed by reading both the transaction and the resulting `WorkerProfile` PDA back from devnet RPC directly (not just trusting the app's own UI). The exact transaction signature from that test session wasn't captured — worth recording the next time this is re-run, rather than reconstructing it after the fact.
- **`submit_review`** — exercised in the Anchor test suite (`program/tests/reputation.ts`, 10 passing cases, including self-review rejection, duplicate-review rejection, invalid-rating rejection, and the `getProgramAccounts` + `memcmp` read path), but **not yet separately confirmed via a physical-device wallet round-trip** — only `register_worker` has a confirmed real-wallet signature so far.
- **Phantom** has not been re-tested since finding that a wallet's own active network setting (not anything this app requests via MWA) governs whether devnet transactions are accepted — see `docs/ARCHITECTURE.md`'s "MWA on-device findings" section. Only Solflare has been confirmed with the corrected network setting.

## Known caveats

- The upgrade authority (`GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P`) is a local dev keypair, not a multisig or a burned authority — fine for a devnet hackathon build, but would need to change before any mainnet deployment.
- `program/reputation-keypair.json` (the program's own keypair, distinct from the upgrade authority above) is gitignored — devnet only. If it's ever regenerated, `declare_id!` in `program/programs/reputation/src/lib.rs` and every value in this file must be updated together, or this record goes stale.
