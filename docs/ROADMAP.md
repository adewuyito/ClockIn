# Roadmap

Eight phases, paced for a ~1-month hackathon (CLOCK IN: Sept 8 – Oct 8) rather than StellarRep's longer Wave Program timeline — fewer, denser phases, and Mobile Wallet Adapter gets pulled forward early (Phase 4, before full program integration) because it's the highest-risk, highest-differentiation piece: a submission where MWA doesn't actually work end-to-end on a real device is a much weaker submission than one with a slightly less polished program, for *this specific* hackathon's judging criteria. Each phase still has a goal, a checklist, and a definition of done — don't move on until done is actually true.

---

## Phase 0 — Tooling & Repo Setup

**Goal:** a working dev environment and a correct-but-empty repo skeleton, single-repo (see `CLAUDE.md` on why this differs from StellarRep's 4-repo split).

- [x] Fork StellarRep into this repo, `app/` reset to a fresh Flutter project with `solana`, `solana_mobile_client`, `drift`/`drift_flutter` dependencies already added.
- [x] Drift schema started (`WorkerProfiles`, `Reviews`, `DraftReviews`) with unit tests.
- [x] Toolchain installed and verified: Solana CLI, `cargo-build-sbf`/platform-tools, Anchor CLI 1.2.0 (via `avm`), `anchor-lang` 1.2.0 — multiple Solana/Agave releases coexist on this machine and which one is active can drift between sessions, so don't trust a hardcoded version number here; re-check with `solana --version`. Quirks (AVM proxy hang, `anchor test` vs Rust-native, the `--arch` build requirement) documented in `docs/ARCHITECTURE.md`.
- [ ] Create a funded devnet keypair for deploying/testing (`solana-keygen new`, `solana airdrop`, confirm on a devnet explorer).
- [x] Anchor program scaffolded by hand under `program/` (plain Cargo workspace, `anchor-lang` dep, no `anchor init`). `register_worker` + `submit_review` written per `docs/PROGRAM_SPEC.md`; program keypair generated, `declare_id!` set.
- [x] Program builds — `cargo build-sbf --arch v1` produces a real, genuinely-executable `target/deploy/reputation.so` (plain `cargo build-sbf`/`anchor build` without the explicit `--arch` flag silently produces an unexecutable binary in this environment — see `docs/ARCHITECTURE.md`).
- [x] `Anchor.toml` in place so `anchor build`/`anchor test`/`anchor deploy` have a workspace — this is also the prerequisite for the TS test harness, which now runs and passes (10/10, see Phase 1/2 below).
- [x] Confirm Android build tooling: `flutter analyze` (0 issues) and `flutter build apk --debug` both succeed (`build/app/outputs/flutter-apk/app-debug.apk`), confirming the whole Gradle/Android SDK chain is wired up correctly. One harmless deprecation warning (the `solana_mobile_client` plugin still applies Kotlin Gradle Plugin directly rather than Flutter's built-in Kotlin support) — not a blocker, nothing to act on yet. Still open: an Android emulator or physical device available for later MWA testing (**MWA requires a real device or an emulator with a compatible wallet app installed — the iOS Simulator equivalent doesn't exist for MWA flows**, this is a real constraint to plan around for Phase 4).
- [x] `docs/PROGRAM_SPEC.md` and `docs/APP_SPEC.md` rewritten for Anchor/Flutter (PROGRAM_SPEC renamed from `CONTRACT_SPEC.md`).
- [x] Repo hygiene: `.gitignore` covers Flutter/Dart build artifacts, Anchor's `target/`, `.anchor/`, `test-ledger/`, and keypair files; `CLAUDE.md` + `docs/` rewritten and committed.

**Definition of done:** program builds to a deployable `.so` (done, via `cargo build-sbf --arch v1` — see `docs/ARCHITECTURE.md`'s "Known-bad default build" note), `flutter build apk --debug` succeeds (done) on the real Flutter app, and there's a funded devnet keypair with a confirmable balance. Only remaining item: the funded devnet keypair — public devnet faucet has been rate-limited on every attempt so far; retry later or use the web faucet at faucet.solana.com against `GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P`. This doesn't block Phase 1/2 (already done, local-validator tests don't need devnet funds) — it blocks Phase 3 (devnet deploy).

---

## Phase 1 — Program: Data Model & `register_worker`

**Done.** `docs/PROGRAM_SPEC.md` has the account model (PDA seeds decided, no on-chain review-index list), `program/programs/reputation/src/lib.rs` implements `register_worker` creating the `WorkerProfile` PDA via `init`, and `program/tests/reputation.ts` covers it end-to-end via `anchor test` (TS client + local validator, `--validator legacy` — see `docs/ARCHITECTURE.md`). Both registration tests pass genuinely (not vacuously — verified by reading the actual assertion, not just the exit code): a fresh registration reads back a correctly-initialized account, and re-registration fails with Anchor's own account-already-in-use error (not a custom `AlreadyRegistered` — the spec's own error variant of that name is unused by `register_worker` for this reason, confirmed rather than assumed).

Getting these tests to actually pass (as opposed to appearing to pass) took real debugging — `docs/ARCHITECTURE.md`'s "Known-bad default build" note covers it: `anchor build`'s own implicit build step silently produces an unexecutable program binary in this environment, which reads as every instruction failing with a generic "Program is not deployed" error indistinguishable, at a glance, from a real program bug. The fix is a manual `cargo build-sbf --arch v1` pre-build step before `anchor test --skip-build`.

**Done when:** a fresh test run registers a worker and reads back a correctly-initialized account, with no manual steps. ✅ (manual steps remain in the *build*, not the test itself — see the toolchain note above.)

## Phase 2 — Program: Reviews & Reputation Read Path

**Done.** `submit_review` is in `lib.rs` (reviewer-signed, rating bounds, self-review blocked, duplicate blocked structurally via the `review` PDA's `init`). The review-history question is **decided**: no on-chain list; the client uses `getProgramAccounts` + a `memcmp` filter on the `worker` field (see `docs/PROGRAM_SPEC.md`). All 8 remaining test cases in `program/tests/reputation.ts` pass genuinely: valid review submission (twice, from different reviewers), self-review rejection, invalid rating (0 and 6), duplicate `(worker, job_id)` rejection, oversized `job_id` rejection, and reading reviews back via `getProgramAccounts`+`memcmp` (confirmed against the real offset, not hand-counted — offset 8, past the Anchor discriminator, matching `docs/PROGRAM_SPEC.md`).

**Done when:** every failure path has a test that actually triggers it, and a full register → review → read-reputation loop passes locally. ✅ 10/10 tests passing, `anchor test --skip-build --validator legacy` (after the manual `--arch v1` build step).

## Phase 3 — Devnet Deployment & Manual Verification

The program has been live and callable on devnet at `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9` throughout Phase 4's testing below — confirmed via a real `register_worker` call succeeding on-chain, not just simulation. What's formally left:

- [ ] Run `anchor deploy` explicitly and record the result in `program/DEPLOYED.md` (program ID, deploy tx signature) — a durable, non-secret record for the submission, separate from the fact that it already works.
- [x] Manually invoke register against the deployed instance and confirm on-chain state actually changes: done, via the real Phase 4 test below (tx `fs5NeaMUwi4CdmwzskffKFH7TzPNX7TkUjCknjccY8SCNdGjXq8JdjonG8vuZ6YJTfAJzhGiq6JtxHrqq8g4hAS`, `WorkerProfile` PDA confirmed to exist by reading it back from devnet RPC directly).
- [ ] Same manual verification for `submit_review` specifically (only `register_worker` has been exercised on a real device so far).

**Done when:** a real devnet program ID and a transaction signature for each instruction having been called successfully. Mostly done — `register_worker` proven; `submit_review` and the formal `DEPLOYED.md` record remain.

## Phase 4 — App: Mobile Wallet Adapter Integration

**Pulled forward deliberately — see the note at the top of this file. Done — verified against a real physical Android device.**

- [x] `solana_mobile_client` wired to request a wallet connection (`authorize`); confirmed it round-trips to Phantom and to Solflare on a physical device (SM A515F, Android 13).
- [x] Requested a real signature (`register_worker`, not a no-op — a stronger proof than the roadmap's original bar) and confirmed it landed on devnet: tx `fs5NeaMUwi4CdmwzskffKFH7TzPNX7TkUjCknjccY8SCNdGjXq8JdjonG8vuZ6YJTfAJzhGiq6JtxHrqq8g4hAS`, confirmed by reading both the transaction and the resulting on-chain account directly from devnet RPC.
- [x] Real failure modes hit and understood along the way (see `docs/ARCHITECTURE.md`'s "MWA on-device findings"): wallets not reliably returning focus to the app after an MWA flow (wallet-side behavior, not fixable from here), and transactions being declined because a freshly-installed wallet defaults to Mainnet rather than Devnet (fixed by switching the wallet's own network setting — this needs to become an explicit in-app instruction, not just a debugging footnote, before submission). `ReputationService._signAndSendWithRetry` also added for the separate, real blockhash-expiry case (retries once with a fresh blockhash on rejection).
- [ ] Distinct UI for these failure modes (no wallet installed, user rejects connection/signature, wrong-network wallet) — currently they mostly surface as the same generic error state; worth revisiting for Phase 6/7 polish now that the real failure modes are known concretely rather than hypothetically.

**Done when:** a real signature, requested via MWA and approved in an actual wallet app, lands as a confirmed transaction on devnet. ✅ Screenshot/recording for the submission still needed.

## Phase 5 — App: Program Integration

- Wrap the program calls behind a `ReputationService` (same shape as StellarRep's, adapted): `registerWorker`, `submitReview`, `getReputation`, `getReviews`.
- Handle pending/simulating and failed (network vs. program-rejected) states distinctly — same principle as StellarRep's `ContractCallState`, worth porting the pattern even though the underlying SDK differs.
- One real integration test/script: register → submit_review → read reputation, end-to-end against devnet, through this service (not a bypassed raw call).

**Done when:** that end-to-end test passes against live devnet, unattended.

## Phase 6 — Core UI Flows

- Profile screen — look up any address, aggregate rating + job count + review list.
- Submit Review flow — decide the handoff mechanism explicitly (see the note in `docs/ARCHITECTURE.md`'s data-flow section) rather than leaving it vague.
- Wire the Drift local cache in per the trust-model decision made in `docs/ARCHITECTURE.md`.
- Basic empty/error/loading states throughout.

**Done when:** two devices (or a device + emulator with two different wallets) complete a full register → review → view-reputation loop against devnet, with real MWA signing at each write step.

## Phase 7 — Hardening, Docs, Submission

- Real top-level `README.md` — what it is, how to run it, a testnet/devnet-only warning, and (per most hackathon judging norms) a link to a short demo video showing the real MWA-signed flow.
- Seed a small demo dataset on devnet so the app isn't empty on first open for a judge.
- Open well-scoped GitHub issues for the Non-goals in `docs/ARCHITECTURE.md` — mirrors StellarRep's ground rule 4, still worth doing even for a hackathon: it signals the project is thought through past the demo.
- Re-check https://solanamobile.radiant.nexus/ for the actual current submission mechanics (form, required assets, deadline specifics) before the deadline — don't assume the details captured when this roadmap was written are still current.

**Done when:** the repo is submitted per whatever the hackathon's actual submission flow turns out to require.
