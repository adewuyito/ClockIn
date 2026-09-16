# Deployment — Devnet

| | |
|---|---|
| **Program ID** | `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9` |
| **Cluster** | Solana Devnet (`https://api.devnet.solana.com`) |
| **ProgramData account** | `GmfYDR7SLX8ZRhErkKnD5gt8pTzzbuaH21WUi1ueCnRH` |
| **Upgrade authority** | `GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P` |
| **Last deployed in slot** | `499476909` |
| **Upgrade transaction** | [`4KYwnZ1B7M2PYVrPZuj67a4P436hP9RnsHwk8EatJGaT2yLJXUJUDeG19c1R5fZQYLxJ9uaARDLUvgWMbx9gDdkp`](https://explorer.solana.com/tx/4KYwnZ1B7M2PYVrPZuj67a4P436hP9RnsHwk8EatJGaT2yLJXUJUDeG19c1R5fZQYLxJ9uaARDLUvgWMbx9gDdkp?cluster=devnet) |
| **On-chain size** | 293,736 bytes |
| **Rent balance** | 1.49305772 SOL |

All figures above re-confirmed live against devnet RPC on 2026-09-16 (`solana program show FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9 --url devnet`).

Built via `cargo build-sbf --arch v1 --sbf-out-dir target/deploy` followed by `solana program deploy` (see `docs/ARCHITECTURE.md` for build toolchain specifications).

## Verified on-chain behavior

1. **`register_worker`** — Worker registers profile PDA (`workerProfile`), initialized with 0 jobs and 0 rating sum.
2. **`create_and_fund`** — Employer creates `EscrowContract` PDA and deposits funds into `Vault` PDA.
   - Sample Devnet Tx: [`2tvjD8XQezFBbzQXyD2VtR5vzae2ynLdCs6XLb4hAkyEqRbFGr5PexYtNPoi8xSojktbbLA9rSmdib7DUNSyZ2TT`](https://explorer.solana.com/tx/2tvjD8XQezFBbzQXyD2VtR5vzae2ynLdCs6XLb4hAkyEqRbFGr5PexYtNPoi8xSojktbbLA9rSmdib7DUNSyZ2TT?cluster=devnet)
   - Contract ID: `ctr-mu4o1bhi`
   - Escrow PDA: `ANnhzTYXCNoeGiBLbL6tsc3vWgZ34CEnjiFkUzXFkGdy`
   - Vault PDA: `8pKKziEKAciNMYRwkALaJ6GnQh3eMYgEht6pABtLcSek`
3. **`accept_contract`** — Worker signs acceptance, transitioning contract state from `Funded` to `InProgress`.
   - Sample Devnet Tx: [`3r7Uy2WgmAqPWE6PebJr8pQGWyrnMpNR7FCSnzqYbeq51CvERCB5WjJEA7WFvGxk6qj4TDiaVZem5yc4h58X4HJo`](https://explorer.solana.com/tx/3r7Uy2WgmAqPWE6PebJr8pQGWyrnMpNR7FCSnzqYbeq51CvERCB5WjJEA7WFvGxk6qj4TDiaVZem5yc4h58X4HJo?cluster=devnet)
4. **`release_and_review`** — Atomic settlement: Vault transfers lamports to worker, Review PDA is created with employer rating (1–5), WorkerProfile stats increment, and contract state transitions to `Completed`.
   - Sample Devnet Tx: [`3MrtD2X6LNpoinCic5rhcQRuCRnXdjF9FYrVDT7k6ES51zZQTYCymwL79UPF2boqJ7G1sjb525815Uu6kk6TjF7j`](https://explorer.solana.com/tx/3MrtD2X6LNpoinCic5rhcQRuCRnXdjF9FYrVDT7k6ES51zZQTYCymwL79UPF2boqJ7G1sjb525815Uu6kk6TjF7j?cluster=devnet)
   - Review PDA: `2busELa3QLiDczW5cU9GM5PXm67eYwZ39vNJxt87Yk6j` (Rating: 5, Job: `ctr-mu4o1bhi`)
   - WorkerProfile PDA: `7z36uYsrE3UwbDEVQEgyL6YCEqnfCYMEgUeJF2CdDZsz` (`total_jobs`: 1, `rating_sum`: 5)

## Known caveats

- The upgrade authority (`GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P`) is a local dev keypair, not a multisig or burned authority — suitable for devnet hackathon evaluation.
- `program/reputation-keypair.json` (the program's own keypair) is gitignored (devnet only).
