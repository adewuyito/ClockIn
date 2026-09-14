# Judging Criteria Plan — CLOCK IN Hackathon Submission

Working doc, built one judging criterion at a time rather than all at once — each section below gets filled in as it's actually discussed and a plan is locked in, not guessed at in advance. Don't add a section for a criterion that hasn't been given yet.

Status key: 🔴 not started · 🟡 discussed, not yet acted on · 🟢 locked in (plan executed or deliberately deferred with a clear reason)

---

## Core Novelty & Creativity

**Status: 🟡 discussed, not yet acted on**

### What we found

- **Raw novelty is low-to-moderate, and that's honest, not a knock.** "Portable, on-chain reputation for gig/freelance work" is a well-worn Web3 idea pattern — Ethereum Attestation Service (EAS), Gitcoin Passport, Braintrust, and a steady stream of hackathon "on-chain resume"/"soulbound reputation" projects have all covered close variants of this. A judge with any breadth of exposure has likely seen a version of this pitch before. The on-chain mechanism itself (`register_worker` + `submit_review`, signature-based self-review block, one review per job ID) is close to the minimum viable version of the idea — no stake-weighting, no reviewer-reputation, no dispute path — which is the right MVP scoping call, but doesn't push past what "on-chain reputation" usually looks like.
- **The real, defensible differentiation is a specific combination, not any single piece:** mobile-native (Mobile Wallet Adapter, zero key custody, no seed phrases/browser extension) + deliberately pseudonymous (no name/photo — a documented, considered stance in `ARCHITECTURE.md`, not an oversight) + zero backend (the program *is* the database) + offline-first (Drift local cache, usable with a flaky connection). Individually unremarkable; the combination, aimed specifically at physical/gig workers rather than DAO/GitHub-contributor reputation (the usual Web3-reputation target audience), is narrower and more defensible.
- **The most Solana-native, least-copied angle isn't reputation storage — it's composability.** The actual differentiated claim is "any other app can permissionlessly read this PDA and gate on it, no API key, no partnership required" (e.g. a marketplace requiring >4.5 rating + 10 reviews to list, reading straight off the program). That story is true of the architecture today but isn't said anywhere in the pitch — costs a sentence, not new code.
- **Critical factual issue found while reviewing a third-party evaluation of the project:** a proposed pitch reframe ("Proof-of-Shift protocol," "shift timestamps," "hours logged," "140 shifts completed," "instant attestation handoffs directly on-site") describes a product that isn't built. The actual program has **no time-tracking concept at all** — `WorkerProfile` has `total_jobs`/`rating_sum`/`created_at`/`bump`; `Review` has `worker`/`reviewer`/`job_id`/`rating`/`timestamp`/`bump`. `total_jobs` is a review counter, not a shift counter. This is the same trap the Stitch-generated UI designs repeatedly fell into this build (see every screen's fidelity notes in `app/lib/features/*/*.dart`) — the app's *name* evokes clocking in/out, but the mechanism underneath was never redesigned around time-tracking. Adopting "shift"/"hours logged" language in the pitch without building it would relocate the exact fabrication problem this whole build has been disciplined about avoiding from the UI into the demo script — higher stakes, since a judge asking "show me the shift log" live has nothing to point to.
- **Sybil resistance is genuinely weak, and worth naming before a judge finds it.** `ARCHITECTURE.md` currently frames this as "collusion between two real accounts" — understated. In reality one person can generate five free Solflare wallets and review "themselves" from each; the program only checks `worker != reviewer` pubkeys, nothing about real-world identity. Judges respect an acknowledged limit with a stated roadmap far more than a limit they discover themselves.
- **The evaluator's "Phase 2" ideas are already-scoped Non-goals, independently arrived at** — escrow-linked reviews and reviewer-reputation-weighting are both already listed in `ARCHITECTURE.md`'s Non-goals section. Good validation that the project's own scoping already anticipated this; safe to present as "here's our documented Phase 2," not something improvised under pressure.
- **QR/Blink handoff idea maps to already-logged issue #1** (screen 4: QR scan + deep link) — good direction, but real scope (camera permission, a scanner dependency, and Solana Actions/Blinks means hosting an action endpoint), not a quick pre-deadline add.

### Plan to lock this in

- [ ] **Decide the shift/hours question deliberately** — either (a) reframe the pitch to "job/gig completion attestation," no shift/hours claims, matching what's actually built, or (b) commit to building a minimal real "hours worked" field before Oct 8 (a real program change: new field, more rent, longer tx — not a copy edit). Don't leave this implicit.
- [ ] Rewrite the pitch hook / README opening to lead with the composability + physical-workforce/offline-first/zero-custody combination, not a generic "portable reputation" headline.
- [ ] Explicitly name the Sybil limitation in the pitch/demo script, framed as an acknowledged MVP boundary with a stated roadmap (ties into the already-documented Non-goals).
- [ ] Sharpen `ARCHITECTURE.md`'s Sybil paragraph to describe the actual attack (one person, several free wallets) rather than "collusion between two real accounts," which undersells how trivial it is.
- [ ] If (a) is chosen above: audit README.md, CLAUDE.md, and any future devpost/demo copy for leftover shift/clock-in-out language and correct it, the same discipline already applied to the in-app screens.
- [ ] If (b) is chosen above: scope the actual program + app change (new account field or separate `Shift`-type account, migration, UI to capture it) as a real task before touching the pitch copy.

---

*(Further sections added below as each judging criterion is given and a plan is worked out for it.)*
