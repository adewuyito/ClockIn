# App Spec — Flutter (Android-First Mobile Client)

**Platform:** Android (Primary, Mobile Wallet Adapter target)  
**Framework:** Flutter 3.29.x / Dart 3.7.x  
**State Management:** Riverpod 2.6.1 (`flutter_riverpod`)  
**Local Database:** Drift 2.34.4 (SQLite offline-first reactive cache)  
**Wallet Integration:** Solana Mobile Wallet Adapter (MWA) v2.0 (`solana_mobile_client`)  

---

## 1. Directory Structure

```
app/
├── lib/
│   ├── main.dart                      # Shell, Riverpod ProviderScope, NavigationBar router
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart      # Drift schema: WorkerProfiles, Reviews, DraftReviews, RecentLookups, EscrowContracts
│   │   │   ├── contract_repository.dart    # High-level reactive repository for Escrow Contracts
│   │   │   └── reputation_repository.dart  # High-level reactive repository for Profiles & Reviews
│   │   ├── models/
│   │   │   ├── escrow_contract.dart   # Domain model with ContractStatus and role helpers
│   │   │   ├── worker_profile.dart    # Domain model for worker aggregate stats
│   │   │   └── review.dart            # Domain model for on-chain review records
│   │   ├── providers/
│   │   │   └── app_providers.dart     # Riverpod providers streaming wallet state, contracts, & cache
│   │   ├── solana/
│   │   │   ├── network_config.dart    # RPC URL (Devnet) & Program ID (Single Source of Truth)
│   │   │   ├── wallet_adapter.dart    # MWA connection, session management, and transaction signing
│   │   │   ├── contract_service.dart  # Anchor instruction builder & deserializer for Escrow
│   │   │   ├── reputation_service.dart# Anchor instruction builder for Reputation
│   │   │   └── reputation_errors.dart # Typed error parsing & UI classification
│   │   ├── theme/
│   │   │   ├── app_colors.dart        # Stitch-aligned design tokens (Light Fintech palette)
│   │   │   └── app_theme.dart         # Material 3 typography and component styling
│   │   └── widgets/
│   │       ├── app_header.dart        # Reusable app bar with address chip & disconnect menu
│   │       ├── devnet_badge.dart      # Ambient devnet status indicator
│   │       └── devnet_setup_sheet.dart# Bottom sheet guide for Phantom & Solflare network configuration
│   └── features/
│       ├── contracts/                 # Escrow feature module
│       │   ├── contracts_list_screen.dart   # Screen 7: Segmented list & metric cards
│       │   ├── create_contract_screen.dart  # Screen 8: Contract creation form & preview
│       │   ├── contract_detail_screen.dart  # Screen 9: Full state timeline & role actions
│       │   ├── contract_share_screen.dart   # Screen 10: Contract ID QR sharing
│       │   └── release_and_review_modal.dart# Screen 11: Atomic settlement modal
│       ├── profile/
│       │   ├── my_profile_screen.dart       # Screen 2: User reputation & contract summary
│       │   ├── worker_profile_screen.dart   # Screen 3b: Counterparty profile detail
│       │   └── lookup_screen.dart           # Screen 3: Base58 address search & recent lookups
│       ├── reviews/
│       │   └── submit_review_screen.dart    # Screen 5: Review authoring with offline drafts sheet
│       ├── settings/
│       │   └── settings_screen.dart         # Screen 6: Network diagnostics & security architecture
│       └── wallet_connect/
│           └── connect_wallet_screen.dart   # Screen 1: Zero-custody MWA authorization
```

---

## 2. Navigation & User Flows

The main application shell (`main.dart`) hosts a Material 3 `NavigationBar` with 5 primary destinations:

```
[Contracts] (Home)  |  [My Profile]  |  [Look Up]  |  [Submit Review]  |  [Settings]
```

### 2.1 Contracts Flow (Screen 7, 8, 9, 10, 11)
- **`ContractsListScreen`**: Summarizes active contracts count, total SOL locked in vault, and completed contracts. Filter tabs: *All*, *As Employer*, *As Worker*.
- **`CreateContractScreen`**: Client enters worker public key (with live address validation), escrow amount in SOL, terms text (hashed client-side via SHA-256 into `terms_hash`), and optional deadline. Signs via MWA to invoke `create_and_fund`.
- **`ContractShareScreen`**: Displays contract ID with QR code rendering and quick copy action for counterparty sharing.
- **`ContractDetailScreen`**: Displays contract status timeline and renders contextual action buttons based on user role and state:
  - Employer on `Funded`: Cancel
  - Worker on `Funded`: Accept Contract
  - Employer on `InProgress`: Release & Rate (opens `ReleaseAndReviewModal`) OR Raise Dispute
  - Worker on `InProgress`: Raise Dispute
- **`ReleaseAndReviewModal`**: Employer selects 1–5 star rating with tactile haptic feedback. Submits atomic settlement transaction via MWA.

### 2.2 Offline Drafts Flow (Screen 5)
- **`SubmitReviewScreen`**: If network is unavailable or user authoring is interrupted, tapping "Save as offline draft" persists the review in Drift SQLite.
- A "Drafts (N)" pill button opens the drafts modal, allowing the user to resume editing or delete saved drafts.
- On confirmed on-chain settlement, the associated draft is automatically removed from SQLite.

### 2.3 Wallet Connection & Network Safety Flow (Screen 1 & 6)
- **`ConnectWalletScreen`**: Initiates MWA session with installed wallet. Displays prominent Devnet guidance notice with one-tap link to `DevnetSetupSheet`.
- While connecting, displays an active MWA handoff prompt advising the user to switch back to ClockIn after approving in Phantom or Solflare.

---

## 3. Drift Local SQLite Schema

Defined in `app_database.dart`:
- **`WorkerProfiles`**: Caches on-chain worker stats (`worker`, `totalJobs`, `ratingSum`, `syncedAt`).
- **`Reviews`**: Caches individual review records (`worker`, `reviewer`, `jobId`, `rating`, `timestamp`).
- **`DraftReviews`**: Offline-first drafts (`id`, `workerAddress`, `jobId`, `rating`, `notes`, `createdAt`, `status`).
- **`RecentLookups`**: Recency pointer table for recently searched worker addresses.
- **`EscrowContracts`**: Local mirror of on-chain escrow contracts (`contractId`, `employer`, `worker`, `amountLamports`, `status`, `deadline`, `createdAt`, `fundedAt`, `completedAt`, `rating`, `syncedAt`).

---

## 4. State Management (Riverpod)

- **`walletStateProvider`**: Notifier tracking MWA connection status, public key, account label, and errors.
- **`myContractsProvider`**: `StreamProvider<List<EscrowContract>>` continuously streaming the user's contracts from the Drift cache with background RPC refresh.
- **`contractDetailProvider(contractId)`**: Streams single contract state reactively.
- **`draftReviewsProvider`**: `StreamProvider<List<DraftReview>>` streaming offline drafts.
- **`workerProfileProvider(address)`**: Watches on-chain / cached profile for any base58 address.
- **`networkDiagnosticsProvider`**: Periodically measures RPC latency, current epoch progress, and finalized slot.

---

## 5. Verification & Testing Standards

- **16 Unit & Widget Tests**: Tests Drift database CRUD operations, reactive provider streaming, PDA derivation utilities, and UI smoke tests without requiring an active device.
- **`flutter analyze`**: Zero errors, zero warnings, enforced linting (`flutter_lints`).
