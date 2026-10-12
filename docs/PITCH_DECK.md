# ClockIn — Pitch Deck Prompt

Use this document as the full brief for generating the ClockIn deck. It is written for the **CLOCK IN hackathon (Solana Mobile, RadiantsDAO)**: the audience is judges and ecosystem partners, not investors. There is **no fundraising ask and no use-of-funds slide**. The closing ask is for distribution, pilots and feedback.

---

## Brand (match the app, not a generic crypto look)

| Token | Value |
|---|---|
| Primary teal | `#00556D` (deep), `#0F6F8C` (container) |
| Accent mint | `#5FE3A1` (the "In" in the wordmark) |
| Success emerald | `#1F9D5B` |
| Canvas / card | `#F8F9FB` / `#FFFFFF`, hairline borders `#E1E2E4` |
| Text | `#191C1E` primary, `#3F484D` secondary |
| Type | Plus Jakarta Sans (headlines, body) · JetBrains Mono (addresses, amounts, metrics) |
| Wordmark | "Clock" white + "In" mint on teal, as in the app icon |

Cover and closing slides: deep-teal background, white text. All other slides: light canvas with white cards, teal headlines, mint or emerald only for emphasis. No purple, no neon gradients.

---


## Deck rules (apply to every slide)

- **9 slides plus an appendix.** A 3-minute pitch cannot carry more. Detail lives in the appendix and the speaker notes, not on the slides.
- **One idea per slide.** The headline states the point as a full sentence; a judge who reads only the headlines should get the whole story.
- **At most ~30 words of body copy per slide.** No paragraphs. No code identifiers (`SplitProposal`, `PDA`, `X25519`) on main slides; they belong in the appendix.
- **Show the product.** Slides 1, 3, 4 and 5 use real screenshots from the app, not illustrations.
- **Every number must be true today.** Use only the figures in "Numbers we can stand behind" below. Anything in "Do not claim" stays out.
- **No demo slide.** The demo video is submitted separately, so the deck does not repeat it. If the deck is ever shared on its own, add a "Watch the demo" link to the closing slide.
- **Lead with what is live, be plain about what is not.** Slide 8 states the limits. Judges trust a team that names its own gaps.


## Slide 1 — Cover

**Headline:** ClockIn
**Subhead:** Escrow, encrypted collaboration and portable reputation for freelance work — on your phone, on Solana.
**Tagline:** Lock funds. Do the work. Get paid and reviewed in one transaction.

**Visual:** One phone, straight on, showing the Contract Detail screen with funds locked. Wordmark top left.
**Footer (mono, small):** Timothy Adewuyi · CLOCK IN Hackathon, October 2026 · Live on Solana Devnet

**Say:** "ClockIn is a mobile app where a client locks payment before work starts, and the worker's review is created by the same transaction that pays them."

---

## Slide 2 — Problem

**Headline:** Freelancers do the work first, pay 10–20% to a platform, and still don't own their reputation.

**On slide (three short blocks):**
- **Payment risk.** Someone always goes first. Either the worker delivers unpaid, or the client pays unseen.
- **The platform cut.** Upwork takes 10% from freelancers; Fiverr takes 20%.
- **Locked reputation.** Hundreds of reviews, and none of them leave the platform that holds them.

**Visual:** One persona card: "Ada, designer, Lagos. 214 five-star reviews on one platform. 0 anywhere else."

**Say:** "A new client outside the platform has no way to check Ada's history, and Ada has no way to know she'll be paid. That is the gap."

---

## Slide 3 — Solution

**Headline:** ClockIn replaces the middleman with a contract both sides can verify.

**On slide (three pillars, one line each):**
1. **Escrow you can see.** The client locks SOL, USDC or $SKR in an on-chain vault before work starts. Nobody holds the money.
2. **Private collaboration.** Chat and deliverables are end-to-end encrypted between the two parties.
3. **Reputation that travels.** Each settled contract writes a review to the worker's wallet, readable by any app.

**Visual:** Three app screenshots side by side: funded contract, chat thread, worker profile with rating.

**Say:** "Three things a platform normally does — hold the money, carry the conversation, keep the reviews — each moved to something the users control."

---

## Slide 4 — The core idea

**Headline:** Payment and review happen in the same transaction, so every review is backed by a settled payment.

**On slide (horizontal flow, five steps):**
Lock funds → Accept → Deliver (encrypted) → **Release & review** → Reputation updated

Callout on step 4: "One signature. Funds move to the worker and the review is recorded together, or neither happens."

**Visual:** The flow as five connected nodes, step 4 highlighted in mint. Below it, the Release & Review sheet screenshot.

**Say:** "On most platforms a review is a form anyone can fill in. Here a review cannot exist without a funded contract that actually paid out, and anyone can check the amount on-chain."

---

## Slide 5 — Why Solana Mobile

**Headline:** Built for the phone in a freelancer's hand, not ported from a browser extension.

**On slide (four tiles):**
- **Mobile Wallet Adapter.** Every action is signed in the user's own wallet app. ClockIn never holds a key.
- **Seeker-aware.** Detects Seeker hardware and reads a wallet's real $SKR Guardian stake to show a proof-of-stake badge.
- **Works on a bad connection.** Local cache, offline drafts, queued chat messages.
- **QR everywhere.** Scan a wallet, a Solana Pay code or a contract link; share your reputation pass in person.

**Visual:** Seeker verification card and the wallet-signing handoff screenshot.

**Say:** "Solana Seeker has more than 150,000 pre-orders across 57 countries, and its dApp Store charges no platform fee. Freelancers in those markets work from their phones. This is the audience."

---

## Slide 6 — What's built

**Headline:** A deployed program and a tested app, not a prototype.

**On slide (metric grid, mono numerals):**

| | |
|---|---|
| **20** on-chain instructions, live on Devnet | **3** currencies: SOL · USDC · $SKR |
| **248** automated tests passing (39 program · 176 app · 33 security rules) | **11** app screens, built from one design system |
| **0** private keys held by the app | **2** Android phones tested, down to a 5-inch screen |

Footer (mono): Program `FKicZK…dEt9` · deployed bytecode matches the tested build, byte for byte

**Visual:** The grid, with a small Solana Explorer screenshot of the program page.

**Say:** "Everything on this slide can be checked from the repo or the explorer link."

---

## Slide 7 — Who it's for and how it sustains itself

**Headline:** Start where crypto-native work already happens, then widen.

**On slide (left: who; right: model):**
- **First users:** Solana builders, bounty hunters and DAO contributors already paid in SOL and USDC.
- **Next:** cross-border freelancers for whom stablecoin settlement beats a 3–5 day wire.
- **Context:** online gig work is a ~$500B-a-year market with 150–435 million workers (World Bank).

- **Planned.** A 1–3% protocol fee on each settled contract. Compare 10–20%.
- **How it's collected.** The program takes it in the same transaction that pays the worker. No payment processor, no invoicing.
- **Later:** paid reputation lookups for hiring platforms and DAOs.

**Visual:** Two columns. A single bar comparing "10–20% platform" with "1–3% protocol".

**Say:** "We are not asking for funding. This slide is here to show the protocol can pay for itself: a fee a fraction of the incumbents', taken by the program itself with no payment processor in the middle."

---

## Slide 8 — Honest scope and what's next

**Headline:** What's live, what isn't yet, and the order we'll fix it.

**On slide (two columns):**

**Not yet**
- Devnet only; no real funds.
- Disputes settle between the two parties. Community jurors are built but switched off until juror selection is fair.
- Reviews are payment-backed, not yet weighted against a user paying themselves.
- Review notes are stored on Irys's test network; permanent storage comes with mainnet.

**Next**
1. Solana dApp Store submission (signed release build).
2. Security audit and multisig upgrade authority.
3. Juror selection from $SKR Guardian stakers.
4. Milestone contracts and the protocol fee.
5. Mainnet.

**Visual:** Plain two-column list. No timeline graphic; the order matters more than dates.

**Say:** "The escrow is the part that has to be right, and it is tested and deployed. These are the edges we know about."

---

## Slide 9 — Close and ask

**Headline:** Help us put ClockIn in front of the people it's for.

**On slide (three asks, no money):**
1. **Try it.** Scan to install the APK and settle a contract on Devnet.
2. **Pilot it.** Run one real bounty or grant through ClockIn escrow — Superteam, RadiantsDAO, hackathon organisers.
3. **List it.** Guidance on the Solana dApp Store submission for Seeker.

**Visual:** One QR code, for the APK download, because the deck is read on a laptop and the app installs on a phone. Next to it: "Scan to install", the download link and the GitHub link as clickable text. Wordmark and tagline. This is the only QR code in the deck.
**Footer (mono):** `github.com/adewuyito/ClockIn` · Program `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9` · Timothy Adewuyi

**Say:** "Lock funds. Do the work. Get paid and reviewed in one transaction. Thank you."

---

## Appendix (backup slides, shown only if asked)

### A1 — ClockIn vs. platforms

| | Upwork / Fiverr | ClockIn |
|---|---|---|
| Fee | 10–20% | 0% today; 1–3% planned |
| Settlement | Days, after a holding period | Seconds, on release |
| Currencies | Fiat | SOL · USDC · $SKR |
| Who holds the money | The platform | An on-chain vault controlled by the program |
| Messages and files | Readable by the platform | End-to-end encrypted |
| Disputes | Platform decides | Both parties must agree to a split |
| Reviews | A row in a private database | A public on-chain record tied to the worker's wallet |

### A2 — How the encryption works
- Each wallet signs a one-time message that binds it to a device encryption key (X25519). Counterparties verify that signature before trusting the key.
- Chat: both phones derive the same per-contract key; messages are AES-256-GCM with the contract, sender and time authenticated. The server stores ciphertext only.
- Deliverables: encrypted on the worker's phone; the key is wrapped for the client alone. A SHA-256 hash proves the file wasn't changed.
- Limit: chat messages are not individually signed yet, so chat is not dispute evidence.

### A3 — How disputes work
- Either party can raise a dispute; funds stay locked.
- Outcomes: release to worker, refund to client, or a 50/50 split. A split executes only if the other party accepts the proposal; the proposer can withdraw it.
- Juror arbitration (3-juror quorum) exists on-chain behind a flag, disabled until jurors are selected by the protocol rather than by the parties.

### A4 — Reputation and fake reviews
- An escrow-linked review requires a funded contract that settled. The amount and both wallets are public.
- Known gap: with no fee, someone can pay their own second wallet cheaply. Planned defences: the protocol fee (makes it cost money), weighting by amount and counterparty diversity, and the Seeker stake badge as a proof-of-person signal.

### A5 — Architecture at a glance
- Anchor program (Rust) on Solana Devnet: profiles, reviews, SOL and SPL-token escrow, disputes.
- Flutter app for Android: Mobile Wallet Adapter signing, Riverpod state, Drift SQLite cache (schema v13).
- Firestore as untrusted transport for encrypted chat, deliverable envelopes and the key directory; 33 rule tests.
- Irys for review notes and deliverable ciphertext; live SOL price from Jupiter with CoinGecko fallback.
- One mainnet read only: the wallet's $SKR Guardian stake, for the Seeker badge. No mainnet writes, no keys.

### A6 — Full metrics

| Metric | Value |
|---|---|
| Program ID (Devnet) | `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9` |
| Last deployed | Slot `508848800`, 565,296 bytes, byte-identical to the tested build |
| Instructions | 20 |
| Tests | 39 Anchor · 176 Flutter · 33 Firestore rules |
| APK | 30.7 MB (arm64) · 26.7 MB (32-bit ARM) · 83.7 MB universal |
| Devices tested | Samsung Galaxy A51 · Samsung Galaxy J-series (SM-G570F, 5-inch) |
| Demo contract | `ctr-mu4o1bhi` on Solana Explorer (Devnet) |

---

## Numbers we can stand behind

| Claim | Basis |
|---|---|
| Upwork 10% freelancer fee; Fiverr 20% | Published platform fee schedules. Re-check Upwork's pricing page before presenting; it has changed before. |
| Online gig work ~$500B a year | Market reports for 2025 range from $455B to $646B. Say "about half a trillion", not a precise figure. |
| 154–435 million online gig workers | World Bank estimate. |
| Seeker: 150,000+ pre-orders, 57 countries | Solana Mobile's announcement when shipping began in August 2025. Pre-orders, not devices in use. |
| 20 instructions, slot 508848800, 248 tests | Repo, `solana program show` and `docs/VERIFICATION.md`, checked 12 Oct 2026. |

## Do not claim

- **"Fake reviews are impossible."** They are payment-backed, not self-dealing-proof (see A4).
- **"Permanent Arweave storage."** Uploads go to Irys's devnet node, which is not permanent.
- **"The on-chain review stores the Arweave hash."** It does not; notes are found by contract-ID tags.
- **"Tested on Seeker."** Tested on two Samsung phones. Seeker hardware detection is implemented but unverified on a device.
- **"Production build ready for the dApp Store."** The release APK is debug-signed until a release keystore exists.
- **"1.57 billion gig workers."** That figure is all self-employed people worldwide, not online freelancers.
- **"Biometric / Face ID signing."** Signing happens in the user's wallet app; how it authenticates is the wallet's business.
- **"DePIN."** ClockIn is not a physical-infrastructure network.
- **"Verified program."** The explorer's "Verified Build" badge is a separate reproducible-build registry, and the program is not registered there. Say the deployed bytecode *matches* the tested build.
- **A revenue forecast.** There is no fee switch in the program yet; show the model, not a number.
