# Judging Criteria Plan — CLOCK IN Hackathon Submission

Status key: 🔴 not started · 🟡 discussed, not yet acted on · 🟢 locked in (plan executed or deliberately deferred with a clear reason)

---

## 1. Core Novelty & Creativity

**Status: 🟢 locked in**

### What we found & Built
- **The Core Differentiator:** P2P Work Contract & Escrow Protocol on Solana. Rather than building a standalone reputation form (where anyone could theoretically review anyone), ClockIn couples on-chain reputation directly to locked escrow deposits.
- **The Atomic Settlement Innovation:** When an employer releases escrowed funds to a worker upon milestone completion, payment transfer and 5-star reputation generation occur **atomically in the same transaction block**. This prevents fake reputation inflation and eliminates payment non-delivery.
- **Composability & Zero Backend:** Public keys are the identity. Other Solana protocols, DAOs, or gig platforms can permissionlessly read `WorkerProfile` or `Review` PDAs with no API keys, centralized databases, or trusted intermediaries.
- **Sybil Resistance Stance:** Strictly tied to funded on-chain escrow contracts with real value locked in programmatic vaults (`EscrowVault` PDAs).

### Locked-in Execution
- [x] Reframed pitch hook: *"Lock funds. Do the work. Get paid and reviewed — atomically."*
- [x] Deployed 7-instruction Anchor escrow protocol to Solana Devnet (`FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9`).
- [x] Confirmed live on-chain lifecycle with real transactions on Solana Explorer.
- [x] Explicitly documented Sybil resistance boundaries and roadmap in `README.md` and `ARCHITECTURE.md`.

---

## 2. Stickiness & Product-Market Fit (PMF)

**Status: 🟢 locked in**

### What we found & Built
- **Infrastructure Over Churn:** Like an escrow engine or decentralized credit layer, ClockIn's primary value is serving as an unforgeable trust foundation across platforms. A worker carries one reputation record across DAOs, freelance platforms, and direct clients.
- **Dual Role Capability:** Any connected wallet can seamlessly act as both an Employer (locking funds, reviewing work) and a Worker (accepting contracts, building reputation), supported by segmented filtering on the home screen.
- **Offline-First Resilience:** Backed by a local Drift SQLite cache. Workers can view contracts, inspect recent profiles, and save review drafts offline without failing mid-interaction.

### Locked-in Execution
- [x] Dual-role home screen (`ContractsListScreen`) with metric cards (Active, Total SOL Locked, Completed) and segmented tabs (*All*, *As Employer*, *As Worker*).
- [x] Seeded realistic multi-party contracts on Devnet so judges experience a rich, populated environment upon first connection.
- [x] Positioned as critical Solana Mobile infrastructure ready for the Seeker dApp Store ecosystem.

---

## 3. User Experience & Design Polish

**Status: 🟢 locked in**

### What we found & Built
- **Stitch Design Alignment:** Pixel-level fidelity with Google Stitch UI specs, tailored for mobile ergonomics with dark-teal brand gradients and clean typography.
- **Zero Key Custody UX:** Native Android MWA v2.0 handshake. Transactions are signed in Phantom or Solflare without ClockIn ever touching private keys.
- **Judging Experience Protection:** Addressed every failure mode that could disrupt a live evaluation.

### Locked-in Execution
- [x] **Devnet Network Guidance Banner & Modal:** Prominent alert on Connect and Settings screens with step-by-step instructions for switching Phantom and Solflare to Devnet (`55de232`).
- [x] **MWA Focus-Return Guidance:** In-flight status prompt informing the user to return to ClockIn if their wallet does not auto-redirect (`55de232`).
- [x] **Tactile Haptic Feedback:** Micro-interactions (`selectionClick`, `lightImpact`, and `heavyImpact`) on star rating selections, release actions, and filter tabs (`a9bffe8`).
- [x] **Camera QR Code Scanner:** Viewfinder modal (`QrScannerSheet`) powered by `mobile_scanner` supporting raw base58 addresses, Solana Pay URIs, and contract deep links across all input screens.
- [x] **Celebratory Settlement Animation:** Elastic spring badge with custom radial particle burst (`CelebrationBadge`) when funds are released and reviews anchored.
- [x] **Offline Drafts Recovery Sheets:** Form restoration bottom sheets for both reviews and escrow contracts, backed by Drift SQLite persistence.
- [x] **Custom Android Launcher Icon:** Replaced Flutter default icon with ClockIn brand mark across all Android mipmap densities (`a97351d`).
- [x] **Contract Sharing with QR Codes:** Screen 10 (`ContractShareScreen`) renders scannable QR codes and one-tap copy buttons.
- [x] **Production Release APK:** Packaged standalone release APK (`app/build/app/outputs/flutter-apk/app-release.apk`, 78MB) with font asset tree-shaking (99% reduction).

---

## 4. Live Demo Walkthrough Script (60–90 Seconds)

1. **Step 1: Connect Wallet (10s)**
   - Open ClockIn. Note the custom launcher icon and ambient "DEVNET LIVE • MWA v2.0" badge.
   - Show the Devnet setup notice. Tap "Connect via Mobile Wallet" to authorize with Phantom/Solflare via MWA.
2. **Step 2: Contracts Dashboard (15s)**
   - Land on `My Contracts`. Showcase active contracts, total SOL locked in escrow, and filter between *As Employer* and *As Worker*.
3. **Step 3: Create & Fund Escrow Contract (20s)**
   - Tap `+ New Contract`. Enter counterparty address, specify 0.02 SOL, input job terms.
   - Point out client-side SHA-256 terms hashing and cost breakdown.
   - Tap "Create & Fund Escrow". Approve in wallet via MWA. Show newly generated contract with QR share card.
4. **Step 4: Worker Acceptance & Execution (10s)**
   - Switch to worker perspective. Open contract detail. Tap "Accept Contract". Status transitions to `InProgress`.
5. **Step 5: Atomic Settlement & Review (20s)**
   - Client reviews work. Taps "Release & Review".
   - Select 5 stars (triggering tactile haptic response).
   - Sign atomic release via MWA.
   - Show payment arriving in worker wallet, contract marked `Completed`, and permanent Review + updated reputation score appearing on worker's profile.
