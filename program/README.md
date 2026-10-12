# ClockIn program

The on-chain program for ClockIn: escrow for freelance work contracts, with the worker's rating recorded in the same transaction that pays them. Written in Rust with Anchor, deployed on **Solana Devnet only**.

The Android app that uses it is in [`../app`](../app). The project overview is in the [root README](../README.md).

| | |
|---|---|
| Program ID (Devnet) | [`FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9`](https://explorer.solana.com/address/FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9?cluster=devnet) |
| Source | `programs/reputation/src/lib.rs` (one file, 20 instructions) |
| Framework | `anchor-lang` and `anchor-spl` 1.2.0 |
| Tests | 39, in `tests/` |
| Deployment record | [`DEPLOYED.md`](DEPLOYED.md) |

## What it does

**Reputation**

| Instruction | What it does |
|---|---|
| `register_worker` | Creates a worker's profile: job count and rating total. |
| `submit_review` | Records a standalone review, not tied to an escrow contract. |

**Escrow in SOL**

| Instruction | What it does |
|---|---|
| `create_and_fund` | The client creates a contract and locks SOL in its vault, in one transaction. |
| `create_contract`, `fund_contract` | The same in two steps. |
| `accept_contract` | The worker accepts; the contract becomes In Progress. |
| `release_and_review` | The client releases the funds to the worker and records a 1–5 rating, together. |
| `cancel_contract` | The client takes the funds back, before the worker has accepted. |

**Escrow in SPL tokens** (USDC, and the project's Devnet test $SKR)

| Instruction | What it does |
|---|---|
| `create_and_fund_token` | Creates a contract and moves tokens into the vault's token account. |
| `release_and_review_token` | Pays the worker in tokens, closes the vault's token account, and records the rating. |
| `cancel_token_contract` | Returns the tokens to the client, before the worker has accepted. |

`accept_contract` is shared by SOL and token contracts.

**Disputes**

| Instruction | What it does |
|---|---|
| `raise_dispute` | Either party freezes an In Progress contract. |
| `propose_split` | Either party offers a 50/50 split. |
| `cancel_split_proposal` | The proposer withdraws the offer. |
| `resolve_dispute`, `resolve_token_dispute` | Settles the dispute. The client may release everything to the worker; the worker may refund everything to the client; a 50/50 split executes only as acceptance of the other party's open proposal. |

**Juror arbitration: built, switched off**

`initialize_dispute_case`, `cast_juror_vote`, `execute_dispute_ruling` and `execute_token_dispute_ruling` exist, but opening a juror case is refused while `JURY_ENABLED` is `false`. It stays off until jurors can be selected by the protocol. See [`../docs/STATUS.md`](../docs/STATUS.md).

There is no protocol fee and no milestone schedule in the program. A contract has one amount and one release.

## Accounts

| Account | Address derived from | Holds |
|---|---|---|
| `WorkerProfile` | `"worker"`, worker wallet | Job count, rating total |
| `Review` | `"review"`, worker wallet, contract ID | Reviewer, rating, time |
| `EscrowContract` | `"escrow"`, contract ID | Parties, amount, terms hash, status, deadline, token mint |
| `EscrowVault` | `"vault"`, contract ID | The locked SOL, or authority over the vault's token account |
| `SplitProposal` | `"split_proposal"`, contract ID | Who proposed the split |
| `DisputeCase` | `"dispute_case"`, contract ID | Juror panel and votes (unused while the jury is off) |

Contract IDs are strings of up to 32 bytes. A contract's status is one of Created, Funded, In Progress, Completed, Disputed or Cancelled. The contract's terms are stored as a SHA-256 hash, not as text.

## Build

Requirements: Rust, the Solana CLI (Agave) and Anchor CLI 1.2.0. Check which Solana version is active with `solana --version`; the tests were last run with 3.1.10.

```bash
cd program
cargo build-sbf --arch v1
```

`--arch v1` is required. The output is `target/deploy/reputation.so`.

`cargo build-sbf` does not write the IDL, and the tests and the app's instruction encoding depend on it. Regenerate it after any change to the program:

```bash
anchor idl build -o target/idl/reputation.json -t target/types/reputation.ts
```

## Test

```bash
npm install
anchor test --skip-build --validator legacy
```

Expected last line: `39 passing`. The run starts a local validator and takes about three minutes.

`anchor test` exits with status 0 even when tests fail, so read the summary line. The saved output of the last run is in [`../docs/test-evidence/anchor-test.log`](../docs/test-evidence/anchor-test.log).

| File | Covers |
|---|---|
| `tests/reputation.ts` | Worker registration and standalone reviews |
| `tests/escrow.ts` | The SOL lifecycle, wrong-signer and wrong-state rejections, disputes and split proposals, the jury being off |
| `tests/token_escrow.ts` | The token lifecycle, cancellation, token disputes and splits |

## Deploy to Devnet

```bash
solana config set --url devnet
solana program deploy target/deploy/reputation.so \
  --program-id reputation-keypair.json
```

Things to know:

- **Use a private RPC for the upload.** The program is about 565 KB, which is roughly 1,100 write transactions, and the public Devnet RPC rate-limits partway through. The last upgrade completed only through a private RPC.
- **Write to a named buffer** (`solana program write-buffer target/deploy/reputation.so --buffer <keypair>`) so an interrupted upload can be resumed or its SOL reclaimed.
- **The program keypair** is `reputation-keypair.json`. It is gitignored and for Devnet only. `anchor build` expects a copy at `target/deploy/reputation-keypair.json`.
- **The upgrade authority** is a single developer wallet, `GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P`, not a multisig.

After deploying, update the slot and hash in [`DEPLOYED.md`](DEPLOYED.md) and [`../docs/VERIFICATION.md`](../docs/VERIFICATION.md).

## Scripts

| Script | What it does |
|---|---|
| `scripts/verify_devnet_lifecycle.ts` | Runs one create, accept and release on Devnet with the local wallet. |
| `scripts/seed_devnet_contracts.ts` | Creates sample contracts on Devnet in several states. |

Both send real Devnet transactions from `~/.config/solana/id.json`.

## Known limits

- Devnet only. No mainnet deployment, no audit.
- No reproducible "Verified Build" and no `security.txt`; the explorer shows the program as not verified. [`../docs/VERIFICATION.md`](../docs/VERIFICATION.md) gives a direct byte comparison instead.
- The jury switch blocks opening a case; the vote and ruling instructions are not gated individually.
- The juror path has no tests beyond the check that a case cannot be opened.

## More

- [`../docs/PROGRAM_SPEC.md`](../docs/PROGRAM_SPEC.md): the full specification.
- [`../docs/VERIFICATION.md`](../docs/VERIFICATION.md): pinned commit, test evidence and Devnet transaction links for each path.
- [`../docs/STATUS.md`](../docs/STATUS.md): what works today and what is planned.
