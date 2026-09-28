# Stitch Prompt Guide — ClockIn (Escrow Protocol & $SKR Seeker Integration)

> **Stitch Project:** `2859884629275757623` ("Clock-In Screen Refinement")  
> **Platform:** Android Mobile Portrait (390px × 844px)  
> **Theme:** Light mode, clean consumer finance (Revolut / Cash App aesthetic)  
> **Color Tokens:** Surface `#F8F9FB`, Primary Teal `#00556D` / `#0F6F8C`, Success/Verified Emerald `#1F9D5B`, Warning Amber `#C97A0A`, Error `#BA1A1A`  
> **Typography:** Plus Jakarta Sans (Primary UI), JetBrains Mono (Cryptographic public keys, balances, hashes)

---

## CONTEXT BLOCK (Apply to all screens)

```
You are designing mobile screens for "ClockIn" on Android. The design system is established — maintain exact visual harmony, color tokens, typography, spacing, and component styling.

WHAT CLOCKIN IS:
ClockIn is a mobile-first P2P Work Contract & Escrow Protocol on Solana, native to the Solana Seeker ecosystem. It enables freelancers and clients to formalize agreements, lock payments safely in smart contract escrow vaults (SOL or $SKR tokens), and release payments with atomic 5-star reputation generation at the moment of settlement.

KEY DIFFERENTIATORS IN THIS UPDATE:
1. $SKR Token Escrow: Users can fund contracts in either native SOL or $SKR tokens (the native Seeker utility token).
2. Seeker Attested Staking Badge: Workers and employers who stake $SKR to Seeker Guardians receive a verified "Economic Proof-of-Human" badge on their profile with a 48-hour unstake cooldown indicator, proving they are a real human with capital on the line (zero bot risk).
3. Zero Platform Fee: Pure peer-to-peer on Solana; zero middleman cut vs Web2's 20%.

DESIGN LANGUAGE:
- Background: Clean off-white (#F8F9FB), elevated white cards (#FFFFFF) with 16px rounded corners and subtle hairline borders (#E4E7EC).
- Primary Action: Deep Trustworthy Teal (#0F6F8C / #00556D).
- Accents & Status: Emerald green (#1F9D5B) for completed/verified, amber (#C97A0A) for pending/Devnet chip, red (#BA1A1A) for errors/disputes.
- Cryptographic data: Truncated addresses ("7Fki…dEt9") in JetBrains Mono.
- Top Bar: Always includes back arrow (where applicable), screen title, and persistent "DEVNET" amber pill badge.
```

---

## SCREEN SPECIFICATIONS

### Screen 1: Worker Profile (Loaded) with "Seeker Attested" Staking Badge
*Reference Screen: `4a. Worker Profile (Loaded)` (`c71b1c1c4f454408992cf0aaab322376`)*

```
SCREEN: WORKER PROFILE WITH SEEKER STAKING ATTESTATION

TOP APP BAR:
- Back button ("<"), Title: "Worker Profile", Right: "DEVNET" amber pill chip

IDENTITY HEADER:
- Generated Identicon circle
- Truncated Solana Address: "7Fki…dEt9" with copy icon
- "Active Contributor • Registered on-chain"

HERO BADGE: "SEEKER ATTESTED • HUMAN VERIFIED" (New prominent card)
- Background: Soft emerald tint (#E8F8F0), 1.5px border (#1F9D5B), 16px rounded corners
- Top Row: Emerald shield/security icon + "SEEKER ATTESTED" in bold uppercase + green checkmark
- Subtitle: "Economic Proof-of-Human via 250 $SKR Guardian Stake"
- Three metadata chips inside the card:
  1. "250 $SKR Staked" (bold)
  2. "Guardian: Helius"
  3. "48h Cooldown Active"
- Trust note: "Guaranteed non-bot. Counterparty has capital locked in the Seeker network."

REPUTATION & WORK METRICS CARD:
- Large rating: "4.9" with 5 filled emerald stars (#1F9D5B)
- Subtitle: "18 Verified Escrows Completed"
- Volume Row: "Total Settled: 42.5 SOL • 1,500 $SKR"

RECENT ESCROW REVIEWS:
- List of reviews showing client avatar, truncated address, 5 stars, relative date ("2d ago")
- Badge on row: "Settled in $SKR • Atomic Release"

STICKY BOTTOM CTA:
- Primary full-width button: "Create Escrow Contract" (Deep Teal #0F6F8C)
  Caption: "Hire this worker with zero platform fee"
- Secondary button: "Share Profile"
```

---

### Screen 2: My Profile (Loaded) with Staking Status & Loyalty CTA
*Reference Screen: `2. My Profile (Loaded)` (`79abb9d7dd83467686cfa20373b5bfc8`)*

```
SCREEN: MY PROFILE (LOADED) WITH STAKING STATUS

TOP BAR:
- "ClockIn" wordmark, "DEVNET" amber chip, connected wallet icon

HERO CARD:
- Rating: "5.0" with 5 stars
- "24 Escrow Contracts Completed • 0 Disputed"
- "Personal Solana QR Card" toggle button

STAKING STATUS MODULE (Two States):
- State A (When Staked):
  Card showing "🛡️ You are Seeker Attested" with "250 $SKR Staked to Guardian: Helius" + "48h Unstake Cooldown Active".
- State B (When Unstaked):
  Tonal card (#E4F1F5) with info icon: "Boost Your Hiring Trust: Stake 50 $SKR to earn the Seeker Verified badge & unlock top search placement." Button: "Stake $SKR".

RECENT CONTRACTS & SETTLEMENTS:
- Segmented history showing both SOL and $SKR escrow completions
- "Synced 2m ago" transparent indicator
```

---

### Screen 3: Create Contract (Form) — Dual-Currency SOL & $SKR
*Reference Screen: `8. Create Contract (Form)` (`3856938a40a647c88d8f3c72709a7440`)*

```
SCREEN: CREATE CONTRACT (FORM) — MULTI-CURRENCY ESCROW

TOP BAR:
- Back arrow + "New Escrow Contract" + DEVNET pill

FORM FIELDS:

1. WORKER ADDRESS:
   - Text input with "Paste" button
   - Live validation card below:
     - Worker avatar + truncated address
     - If Seeker Staked: Green shield badge "🛡️ Seeker Attested Worker (250 $SKR Staked)"
     - Rating: "★ 4.9 (18 jobs)"

2. CURRENCY & PAYMENT AMOUNT (New dual-currency selector):
   - Segmented Pill Toggle: [ SOL ] | [ $SKR ]
   - When [ SOL ] is active:
     - Input field: "Amount (SOL)" e.g. "1.50"
     - Subtitle: "≈ $210.00 USD"
     - Wallet balance: "Balance: 4.82 SOL"
   - When [ $SKR ] is active:
     - Input field: "Amount ($SKR)" e.g. "500"
     - Subtitle: "Seeker Ecosystem Utility Token"
     - Wallet balance: "Balance: 2,500 $SKR"

3. DEADLINE (OPTIONAL):
   - Date picker field: "Set milestone deadline"

4. TERMS / JOB DESCRIPTION:
   - Multiline description text area
   - Caption: "A client-side SHA-256 hash of these terms will be stored on-chain. Text remains private to your device."

TRANSACTION & COST BREAKDOWN:
- Escrow Deposit: "500 $SKR" (or "1.50 SOL")
- Vault Account Rent: "~0.002 SOL" (refundable on completion)
- Platform Fee: "0.00 SOL (0% Free P2P)"
- Estimated Total: "500 $SKR + ~0.002 SOL gas"

STICKY BOTTOM CTA:
- Primary button: "Review & Fund Escrow"
- Caption: "You'll approve this in your wallet app via MWA v2.0."
```

---

### Screen 4: Contract Detail ($SKR Escrow & Vault ATA Tracking)
*Reference Screen: `9. Contract Detail (Employer View)` (`1bbaa1c0da054eada1136ef6d22ab0af`)*

```
SCREEN: CONTRACT DETAIL ($SKR ESCROW IN PROGRESS)

TOP BAR:
- Back arrow + "ctr_9xKw…492b" in JetBrains Mono + DEVNET pill

ROLE BANNER:
- "YOU ARE THE EMPLOYER" (Teal banner)

CONTRACT HERO CARD:
- Status Pill: "IN PROGRESS" (amber with pulsing dot)
- Large Amount: "500 $SKR" (48pt bold JetBrains Mono) with purple/mint $SKR token glyph
- Subtitle: "Locked in Program Token Vault ATA"
- Security note: "Funds are protected by smart contract PDA authority. Irreversible until completed or mutually cancelled."

PARTIES SECTION:
- Employer (you): Truncated address + "Connected"
- Worker: Truncated address + "🛡️ Seeker Attested" badge

CONTRACT METADATA:
- Terms Hash: "e3b0c442…98fc" (with copy button)
- Vault ATA: "Tokenkeg…Vault" (with copy button)
- Token Mint: "SKRbvo…ZhW3 ($SKR)"

STATUS TIMELINE:
- ✅ Contract Created
- ✅ 500 $SKR Funded into Vault
- ✅ Worker Accepted Terms
- ⏳ Awaiting Work Completion (Current active step)
- ○ Atomic Release & Rating (Next step)

STICKY BOTTOM ACTIONS:
- Primary button: "Release 500 $SKR & Review" (leads to Settlement Screen)
- Secondary outline button: "Raise Dispute"
```

---

### Screen 5: Release & Rate ($SKR Atomic Settlement)
*Reference Screen: `11. Release & Rate (Settlement)` (`d92c9d4b2af34dd1b1287a9ef536e5f4`)*

```
SCREEN: RELEASE & RATE ($SKR ATOMIC SETTLEMENT)

TOP BAR:
- Back arrow + "Complete Contract" + DEVNET pill

SETTLEMENT CONFIRMATION CARD:
- Header pill: "ATOMIC SETTLEMENT"
- Large Release Amount: "500 $SKR"
- Recipient: "→ 7Fki…dEt9 (Worker ATA)"
- Notice: "500 $SKR will transfer immediately to the worker and your rating will be permanently minted on Solana."

RATING SELECTION:
- 5 large interactive gold/emerald stars (36px)
- Dynamic tier label: "★ ★ ★ ★ ★ — Exceptional Quality"
- Haptic tactile feedback note

WHAT HAPPENS ATOMICALLY (Single Transaction Box):
1. 500 $SKR transfers from Vault ATA to Worker's ATA
2. Program closes Vault ATA and refunds rent lamports back to you
3. An immutable Review PDA is created on Solana
4. Worker's aggregate reputation score increments

STICKY BOTTOM CTA:
- Primary button: "Sign & Release 500 $SKR"
- Caption: "Approved via Mobile Wallet Adapter. Zero platform fees."
```
