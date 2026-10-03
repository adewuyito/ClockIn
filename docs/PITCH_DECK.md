# ClockIn — Pitch Deck

> **Tagline:** Lock funds. Do the work. Get paid and reviewed — atomically.
> **Category:** Solana Mobile · Web3 Gig Economy · DePIN Reputation
> **Brand:** `#0B1518` Dark Space · `#14F195` Mint · `#9945FF` Solana Purple · `#FFFFFF` White
> **Typography:** Display: Space Grotesk · Body: Inter

---

## Slide 1 — Cover

### ClockIn

**The Mobile-First P2P Work Contract & Escrow Protocol on Solana**

> *"Lock funds. Do the work. Get paid and reviewed — atomically."*

**Visual Direction:** Full-bleed dark space background. Angled 3D Solana Seeker phone displaying ClockIn's contract dashboard. Four mint-green status badges:

| Badge | |
|---|---|
| `LIVE ON SOLANA DEVNET` | `SOLANA MOBILE STACK NATIVE` |
| `ARWEAVE / IRYS PERMAWEB PROVENANCE` | `ZERO KEY CUSTODY · MWA v2.0` |

**Footer:** Timothy Adewuyi · CLOCK IN Hackathon 2026 · `github.com/adewuyi/ClockIn`

---

## Slide 2 — The Problem

### Freelancers are paying a 20% tax to companies that own their reputation.

The global gig economy processes **$516 billion** in annual contracts. Centralized platforms capture most of that value — and keep all of the leverage.

**Three structural failures, unsolved for 20 years:**

**① The Middleman Tax**
Upwork and Fiverr charge **10–20% of every payment**. A $10,000 contract costs the worker $2,000 in fees — paid to a platform that owns none of the risk.

**② Counterparty Risk**
Workers deliver work before payment clears. Clients pay before delivery is confirmed. Both parties rely entirely on a corporate intermediary holding the money — who can freeze accounts without recourse.

**③ Trapped Reputation**
A freelancer with 200 five-star reviews on Upwork has **zero proof of those reviews** outside Upwork's database. Every time they move — to a new platform, a DAO, or a direct client — their reputation resets to zero.

---

## Slide 3 — The Solution

### Trustless escrow. Permanent reputation. Zero platform tax.

ClockIn replaces the middleman with a Solana smart contract and the reputation silo with the Arweave permaweb.

| | Upwork / Fiverr | **ClockIn** |
|---|---|---|
| **Platform Fee** | 10–20% per job | **0%** (0.5–1% at scale) |
| **Payment Speed** | 5–14 business days | **< 2 seconds** |
| **Reputation Owner** | The platform | **The worker's wallet** |
| **Escrow Custody** | Corporate account | **Solana PDA vault** |
| **Review Permanence** | Deletable database row | **Arweave permaweb** |

**Three pillars, one atomic transaction:**

1. **Programmatic Escrow** — Funds lock into a `EscrowVault` PDA the moment a contract is created. No human holds the money.
2. **Atomic Settlement** — One Solana instruction simultaneously releases payment, mints a reputation record, and updates the worker's aggregate score. Neither happens without the other.
3. **Permaweb Provenance** — Every review note and deliverable hash is inscribed to Arweave via Irys before the on-chain instruction fires. The feedback is permanent, timestamped, and cryptographically linked to the settled escrow.

---

## Slide 4 — The Innovation

### Reputation without skin in the game is just noise.

Every review platform on the internet has the same problem: **anyone can write a review without consequence.** ClockIn makes fake reviews economically impossible.

**How atomic settlement works:**

```
STEP 1  Employer approves deliverable and taps "Release & Review"
        ↓
STEP 2  ClockIn inscribes the review note + deliverable hash to Arweave via Irys
        → Permanent receipt: gateway.irys.xyz/<arweave_tx_id>
        ↓
STEP 3  Single Solana instruction fires: release_and_review
        → SOL / $SKR transfers from EscrowVault PDA to worker's wallet
        → Immutable ReviewRecord PDA minted on Solana
        → Worker's aggregate reputation score incremented
        ↓
STEP 4  Contract status: COMPLETED — fully settled in one block
```

**Why this is a moat, not a feature:**

- A review requires a real, settled escrow — no money on the line, no review possible.
- The Solana PDA enforces economic finality. The Arweave layer preserves the human context forever, off-chain, without paying Solana rent.
- The two layers are cryptographically linked — the Arweave Tx ID is stored in the on-chain `ReviewRecord`. Either layer proves the other.

---

## Slide 5 — Why Now

### Three inflection points are converging in 2026.

**① The Solana Mobile Hardware Wave**
Solana Seeker has **140,000+ pre-orders across 57 countries**. For the first time, a crypto-native smartphone with a built-in dApp store is reaching mainstream distribution. ClockIn is purpose-built for this hardware.

**② Mobile Wallet Adapter v2.0**
Users sign Solana transactions using their phone's native biometrics — Face ID, fingerprint. No seed phrases in-app. No private key custody. No browser extensions. This is the UX unlock that makes non-custodial crypto feel like Apple Pay.

**③ The Borderless Talent Explosion**
**1.57 billion gig workers** operate globally. Tech, AI, and Web3 freelancing has gone fully cross-border. International bank transfers take days and cost 3–5%. Stablecoins and SOL settle in 2 seconds with sub-cent fees. The infrastructure gap is closing — ClockIn captures the moment it does.

---

## Slide 6 — Product: Live on Devnet

### Production-grade, hardware-tested, fully automated.

**Built and shipped — not prototyped:**

- **Dual-Role Contract Dashboard** — Toggle instantly between Employer and Worker view, with live escrow value tracking per contract.
- **Dual-Currency Escrow** — Native SOL and Seeker's $SKR token, with automatic ATA (Associated Token Account) lifecycle management — workers don't need to pre-create token accounts.
- **Seeker Guardian Attestation** — 250 $SKR stake + 48h cooldown provides economic Sybil resistance, native to Seeker Genesis hardware.
- **Arweave Provenance Badges** — Every completed review displays a tappable permaweb badge. Tap to copy the permanent Arweave receipt URL.
- **Pretty QR Contract Sharing** — Rounded, high-contrast QR codes for instant counterparty discovery. Built-in scanner (`mobile_scanner`) supports base58 keys and Solana Pay URIs.
- **Offline-First Caching** — Drift SQLite (Schema v10) stores drafts and contract state locally with auto-recovery. Works on spotty mobile connections.

---

### Live Metrics

| Metric | Value |
|---|---|
| **Program ID (Devnet)** | `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9` |
| **Anchor Instructions** | 7 deployed and tested |
| **Test Coverage** | **28/28** Anchor · **44/44** Flutter — **100%** |
| **APK Size** | **28 MB** ARM64 Release (optimised) |
| **Tested Hardware** | Samsung Galaxy · Solana Seeker preview device |

---

## Slide 7 — Market Size

### Capturing the $516B shift to borderless, peer-to-peer labor.

| Market | Size | Definition |
|---|---|---|
| **TAM** | **$516B** | Global gig & freelance economy GMV (2026 projected) |
| **SAM** | **$28B** | Cross-border tech, design, crypto, and DAO freelance contracts |
| **SOM** | **$350M** | Solana ecosystem gigs, hackathon bounties, and Seeker device owners |

**SOM bottom-up:**
140,000 Seeker holders + 50,000 active Web3 builders × 4 milestones/year at avg. 2 SOL each = **$228M–$350M addressable GMV in Year 1–2.**

At a 0.5% protocol fee, that is **$1.1M–$1.75M in Year 1 protocol revenue** with zero marginal cost of settlement.

---

## Slide 8 — Business Model

### Free to use today. Self-sustaining at scale.

**Revenue architecture:**

**① Micro-Settlement Fee (Core)**
0.5–1% protocol fee on every settled contract. $1M GMV = $5,000–$10,000 net protocol revenue. Zero overhead — the Solana program collects the fee in the same instruction that settles the escrow.

**② Dispute Resolution Staking**
Decentralised juror pools stake $SKR to arbitrate disputes. Protocol earns fee share on resolved cases.

**③ Reputation Query API**
B2B API access for DAOs, credit scoring protocols, and on-chain hiring platforms to query verified `WorkerProfile` PDAs and Arweave review metadata. Priced per query or by subscription.

**The unit economics are on-chain by default** — there is no server bill for payments processing, no fraud team, no chargebacks.

---

## Slide 9 — The Moat

### Once a worker builds on-chain reputation, they never leave — and they bring every new client with them.

**The reputation flywheel:**

```
Worker earns 5★ review + Arweave receipt on ClockIn
          ↓
Profile gains unforgeable on-chain credit history
          ↓
Worker insists direct clients pay via ClockIn to keep building score
          ↓
Employers onboard with zero acquisition cost
          ↓
New employers bring their next hires → self-reinforcing viral loop
```

**Three structural defensibility layers:**

1. **High Switching Cost** — In Web2, leaving Upwork means abandoning proof of your livelihood. In ClockIn, workers build equity in their own wallet address. No one can delete or migrate it.

2. **Composability** — Any Solana dApp can permissionlessly read a worker's `WorkerProfile` PDA and Arweave metadata to offer undercollateralized loans, DAO governance access, or instant job offers. ClockIn becomes the trust primitive for all of Web3 freelancing.

3. **Protocol Neutrality** — ClockIn is a Solana program, not a company. Workers trust it for the same reason they trust Serum or Orca — the code is public, deterministic, and non-custodial.

---

## Slide 10 — Roadmap & The Ask

### Built in weeks. Production-ready today. Scaling tomorrow.

**Execution milestones:**

**✅ Q3 2026 — Completed**
- 7 Anchor escrow instructions deployed on Solana Devnet
- Dual-currency escrow (SOL + $SKR) with full ATA lifecycle management
- Atomic settlement with Arweave / Irys permaweb provenance (Drift Schema v10)
- Seeker Guardian 250 $SKR staking attestation
- Flutter MWA v2.0 mobile client tested on physical hardware
- 100% automated test coverage: 28 Anchor tests + 44 Flutter tests

**🔜 Q4 2026 — Post-Hackathon**
- Solana Seeker dApp Store release (0% distribution fee)
- USDC / USDT stablecoin escrow vaults
- Community dispute arbitration layer (juror staking)

**🗓 Q1 2027**
- Solana Mainnet deployment
- On-chain Reputation Query API for DAOs and hiring platforms
- DAO governance and protocol treasury launch

---

### The Ask

**Seeking $250K – $500K** — Pre-Seed / Ecosystem Grant

| Allocation | Use |
|---|---|
| **50%** | Formal Anchor security audit + protocol hardening |
| **30%** | Mobile engineering + Seeker dApp Store growth |
| **20%** | Ecosystem liquidity + freelancer seed grant program |

---

### Contact & Links

**GitHub:** `github.com/adewuyi/ClockIn`
**Program ID (Devnet):** `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9`
**Direct APK:** `app-arm64-v8a-release.apk` (~28 MB — download and test now)

---

> *Lock funds. Do the work. Get paid and reviewed — atomically.*
> **ClockIn — the trust layer for the borderless gig economy.**
