# ClockIn — Demo Video Script

**Length:** 80–90 seconds. **Format:** phone screen recording with voice-over added afterwards. **Audience:** CLOCK IN hackathon judges.

**The one thing the video must prove:** a client locks payment, the worker delivers, and a single signature both pays the worker and writes their review on-chain.

Button labels below are the exact text in the app, so you can find them while recording.

---

## 1. Setup (do all of this off camera)

| Item | Detail |
|---|---|
| Build | Install the latest release APK. Older installs lack the new icon, layout fixes, live SOL price and network messages. |
| Wallets | Two wallets, both set to **Devnet**. **Client** and **Worker**. Two phones is cleanest; with one phone, record each role separately and cut. |
| Funds | Client: devnet SOL for fees and at least 20 devnet USDC. Worker: a little devnet SOL. |
| Chat | Firestore rules deployed. Each wallet has already tapped **Sign & enable chat** once, so the chat opens straight to the thread. |
| Worker profile | Worker wallet is registered and already has one or two reviews, so the rating visibly changes at the end. Note the rating and job count before you start. |
| Clean data | New contract ID (for example `ctr-landing01`). Terms text: "Landing page redesign: 3 sections, Figma file and exported assets." |
| Phone | Do Not Disturb on, battery above 50%, stable Wi-Fi, brightness up, notifications cleared from the status bar. |

Have ready to paste: the worker's wallet address, the terms text, and a deliverable link (for example a Figma or GitHub URL).

---

## 2. Shot list and narration

Read the narration at a normal pace; each line fits its time slot. Trim wallet-approval waits in the edit, but keep every tap visible.

### Shot 1 — Open and connect · 0:00–0:08
**Screen:** App icon on the home screen → tap → Connect Wallet → wallet approves → Contracts list.
**Say:** "This is ClockIn, running on a real Android phone. I sign in with my own wallet. The app never holds a key."

### Shot 2 — Lock the payment · 0:08–0:24
**Screen (Client):** Tap **New Contract** → paste the worker address → choose **USDC** → amount `20` → paste terms → pick a deadline → review sheet → **Sign & Lock 20 USDC** → approve in wallet → Contract Detail shows the funds locked.
**Say:** "I'm the client. Before any work starts, I lock twenty USDC. It goes into an on-chain vault that only the contract controls. No company is holding it."

### Shot 3 — Worker accepts · 0:24–0:32
**Screen (Worker):** Contracts list → open the new contract → **Accept Contract & Begin Work** → approve → status changes to In Progress.
**Say:** "The worker can see the money is really there, and accepts."

### Shot 4 — Encrypted chat · 0:32–0:44
**Screen:** Worker taps the chat icon → the thread shows the "Escrow funded" marker → worker sends "Starting today, first draft by Friday." → cut to Client's chat showing it arrive → client replies "Great, thanks."
**Say:** "They talk inside the contract. Messages are end-to-end encrypted, so only these two wallets can read them."

### Shot 5 — Encrypted delivery · 0:44–0:58
**Screen (Worker):** **Submit Deliverables** → paste the link and a short note → **Submit Deliverables & Notify Employer**.
**Screen (Client):** Contract Detail → the deliverables card shows **Decrypted & Integrity Verified** with the link readable.
**Say:** "The worker submits the work encrypted. Only the client can open it, and a hash proves it hasn't been changed."

### Shot 6 — Release and review · 0:58–1:14
**Screen (Client):** **Accept Deliverables & Rate Worker** → choose 5 stars → **Release & Review** → approve in wallet → celebration animation → status Completed.
**Say:** "Now the key step. One signature releases the payment and writes the review. Both happen in the same transaction, or neither does."

*Record this shot as one continuous take. Do not cut inside it.*

### Shot 7 — Proof · 1:14–1:28
**Screen:** Worker's profile → the rating and job count have gone up, **VERIFIED ON-CHAIN** badge visible → open the settlement transaction on Solana Explorer (Devnet) → hold for two seconds.
**Say:** "The worker's rating now lives on-chain, tied to their wallet, and anyone can check the payment behind it. That's ClockIn: lock funds, do the work, get paid and reviewed in one transaction."

---

## 3. Full narration (for recording the voice-over in one go)

> This is ClockIn, running on a real Android phone. I sign in with my own wallet. The app never holds a key.
>
> I'm the client. Before any work starts, I lock twenty USDC. It goes into an on-chain vault that only the contract controls. No company is holding it.
>
> The worker can see the money is really there, and accepts.
>
> They talk inside the contract. Messages are end-to-end encrypted, so only these two wallets can read them.
>
> The worker submits the work encrypted. Only the client can open it, and a hash proves it hasn't been changed.
>
> Now the key step. One signature releases the payment and writes the review. Both happen in the same transaction, or neither does.
>
> The worker's rating now lives on-chain, tied to their wallet, and anyone can check the payment behind it. That's ClockIn: lock funds, do the work, get paid and reviewed in one transaction.

About 150 words, roughly 70 seconds spoken, which leaves room for the taps.

---

## 4. Recording

- **Capture the screen silently, add voice afterwards.** Wallet handoffs pause unpredictably, and a separate voice track lets you trim them.
- **Clean capture over USB:** `adb shell screenrecord --bit-rate 8000000 /sdcard/clockin-demo.mp4`, stop with Ctrl+C, then `adb pull /sdcard/clockin-demo.mp4`. It stops by itself after 3 minutes, so record each role's shots as separate files. It does not capture the wallet app if the wallet blocks screenshots; if a shot comes out black, use the phone's own recorder for that shot.
- **Portrait, full resolution.** Do not crop the status bar; it shows this is a real device.
- **If a transaction fails on camera,** stop, fix the cause, and re-record that shot. Do not leave an error in the final cut.

## 5. Editing

- Cut waiting time; never speed up footage of a tap.
- Add a short caption per shot, bottom of frame, matching the deck's five beats: "Lock 20 USDC", "Worker accepts", "Encrypted chat", "Encrypted delivery", "Release & review", "On-chain proof".
- Label whose phone is on screen ("Client" / "Worker") in a corner. With two roles on one screen size, viewers lose track quickly.
- End card, 3 seconds: ClockIn wordmark, the tagline, the GitHub URL and the program ID.
- Export 1080×1920 (or 1080p landscape with the phone centred on the deck's teal `#00556D`), H.264, under 100 MB.

## 6. Do not say

Keep the voice-over to what the app does today (see "Do not claim" in `PITCH_DECK.md`):
- Not "fake reviews are impossible"; say reviews are backed by a real payment.
- Not "permanent storage" or "Arweave"; the deliverable is encrypted and hash-verified, which is what the video shows.
- Not "mainnet" or "real money"; this is Devnet.
- Not "tested on Seeker" unless you record on one.

## 7. After recording

Save the settlement transaction signature from Shot 7. The pitch deck's demo slide and closing QR code point at it.
