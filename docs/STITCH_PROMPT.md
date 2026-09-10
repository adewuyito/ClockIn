# Stitch Prompt — ClockIn UI

A paste-ready prompt for [Stitch](https://stitch.withgoogle.com) to generate the ClockIn app screens.

**Design direction chosen:** clean mainstream consumer-app feel (Revolut / Cash App), light theme, trustworthy, wallet layer present-but-not-shouty, core loop + key states.

It leads with a global design system so every screen comes out consistent, then specifies each screen and its states. It's derived from the functional spec in `PROGRAM_SPEC.md` / `ARCHITECTURE.md` / `APP_SPEC.md` — keep it in sync if those change.

```
Design a mobile app called "ClockIn" — Android, portrait phone screens.

WHAT IT IS
ClockIn gives gig and freelance workers a portable reputation record: star
ratings and job counts that live on a public ledger instead of being locked
inside one marketplace. A worker builds up reviews from people they've worked
with; anyone can look up an address before hiring. Users are everyday gig
workers, not crypto enthusiasts — the blockchain is a trust feature in the
background, not the headline.

DESIGN LANGUAGE (apply to every screen)
- Feel: modern consumer finance / work app — think Revolut, Cash App, or a
  clean banking app. Approachable, calm, credible. Generous whitespace.
- Theme: light. Off-white / very light grey app background (#F7F8FA-ish),
  white cards with soft rounded corners (16px) and very subtle shadows or
  hairline dividers — not heavy.
- Primary colour: a deep, trustworthy teal-blue (around #0F6F8C / #12667F)
  for primary buttons, links, and active states.
- Semantic colour: green (#1F9D5B) for positive ratings, success, and
  "verified" marks; amber (#C97A0A) for cautions; red used sparingly only
  for hard errors.
- Typography: clean system sans-serif. Strong hierarchy — large bold numbers
  for the headline rating and job count, comfortable body text, quiet
  secondary/caption text in mid-grey.
- Components: full-width rounded primary buttons; large tap targets; star
  ratings shown as filled/outline stars; list rows with an avatar circle
  (generated from the address), a rating, a relative date, and an optional
  one-line note.
- Iconography: simple line icons. The app's motif is "clocking in / checking
  in to work" — a subtle clock or check-in glyph is fine for the logo and
  empty states, nothing literal or skeuomorphic.

CRYPTO / WALLET TREATMENT (balanced — visible but not jargon-heavy)
- Wallet connection is clearly present. Say "Connect wallet" and "Connected
  wallet", not raw technical terms.
- Show wallet/worker addresses truncated everywhere: "7Fki…dEt9", with a
  copy icon where the user's own address appears.
- Use a small "Verified on-chain" pill (green check) near reputation numbers
  as a trust signal.
- A small, unobtrusive "Devnet" chip in the top bar on every screen so it's
  always clear this is a test network — muted styling, not alarming.
- No seed phrases, no gas/fee talk, no hex. When an action needs the wallet,
  say "You'll approve this in your wallet app."

SCREENS

1. CONNECT WALLET / WELCOME
   - App logo + name. One-line value prop: "A work reputation that follows
     you between gigs."
   - Three or four tiny benefit lines with line icons (e.g. "Ratings you
     own", "Check anyone before you hire", "Verified on a public ledger").
   - Primary button: "Connect wallet". Helper caption under it: "You'll
     approve this in your wallet app."
   - Secondary text link: "How does this work?"
   - Variant of this screen: NO WALLET APP FOUND — same layout but the button
     becomes "Install a wallet" with a short line explaining a wallet app is
     needed, and a muted list of options.

2. MY PROFILE (home screen after connecting)
   - Top bar: "ClockIn" wordmark, the Devnet chip, and the user's truncated
     address with a copy icon.
   - Hero card: very large rating number (e.g. "4.8") with 5 stars beneath,
     and "23 jobs reviewed" as secondary text. A green "Verified on-chain"
     pill.
   - Section: "Recent reviews" — a list of review rows (reviewer avatar +
     truncated address, star rating, relative date like "3d ago", optional
     one-line note).
   - Bottom navigation: Profile (active), Look Up, and a prominent centre
     action for "Review someone" (leads to Submit Review).
   - STATE — NOT REGISTERED YET: replace the hero card with a friendly card:
     "You haven't started your reputation record yet" + short line that this
     is a one-time step + primary button "Create my record". Recent reviews
     section hidden.
   - STATE — LOADING: skeleton placeholders for the hero card and 3 review
     rows.
   - STATE — NO REVIEWS: hero card shows "No rating yet", and an empty state
     under it: "No reviews yet — share your address with someone you've
     worked with" + a "Share address" button.

3. LOOK UP AN ADDRESS
   - Title: "Look up a worker". Subtitle: "Check someone's reputation before
     you work together."
   - A large search field for pasting a Solana address, with a paste button
     inside the field and a "Search" button.
   - Below: "Recent lookups" — a short list of previously viewed addresses
     (truncated address + their rating + stars), tappable.
   - STATE — INVALID ADDRESS: inline error under the field: "That doesn't
     look like a valid address."

4. WORKER PROFILE (viewing someone else)
   - Same visual structure as My Profile's hero card and review list, but
     read-only and clearly someone else: their truncated address as the
     screen title with a copy icon, their big rating, job count, "Verified
     on-chain" pill.
   - Full reviews list with a "Load more" affordance at the bottom.
   - Sticky primary button at the bottom: "Leave a review".
   - STATE — ADDRESS NOT REGISTERED: instead of the hero card, an empty
     state: "This address hasn't started a reputation record yet." The
     "Leave a review" button is disabled with a caption explaining they need
     a record first.

5. SUBMIT REVIEW
   - Title: "Leave a review".
   - Field 1: "Worker's address" — pre-filled and read-only when arriving
     from a profile; otherwise an editable field with a paste button.
   - Field 2: "Job reference" — short text input, helper text: "A short ID or
     name for the job you're reviewing."
   - Rating: 5 large tappable stars, prominent, centred, with the numeric
     value shown.
   - Field 3: "Note (optional)" — a small multiline text area.
   - Caption near the submit button: "You'll approve this in your wallet.
     Reviews are permanent."
   - Primary button: "Submit review".
   - STATE — SELF REVIEW BLOCKED: if the worker address equals the user's own
     address, an inline warning replaces the button area: "You can't review
     yourself."
   - STATE — SUBMITTING: button becomes a progress state, cycling through
     "Waiting for wallet approval…" then "Confirming on the network…".
   - STATE — SUCCESS (separate confirmation screen): large green check,
     "Review submitted", a summary card showing the stars given + the worker
     address truncated, a subtle "View on explorer" text link, and a "Done"
     button that returns to the previous profile.
   - STATE — ERROR (inline on the form): a red banner with a clear message
     ("You've already reviewed this job." / "Couldn't reach the network.")
     and a "Try again" button.

Produce all screens as a coherent set that share the same header, spacing,
colour system, and component styles.
```

---

## How to use it in Stitch

1. Set the mode to **mobile** and theme to **Light** in Stitch's controls.
2. Paste the whole thing for the app-level generation, or feed the **DESIGN LANGUAGE + CRYPTO/WALLET** blocks first, then each numbered screen block one at a time if you want tighter control per screen.
3. When refining, reference the screen by name — e.g. *"On MY PROFILE, make the rating number bigger and move the Devnet chip…"*. Stitch keeps context within a project.
4. Generate the state variants (NOT REGISTERED, LOADING, SUCCESS, ERROR, etc.) as their own screens so you have them all as design references before building the Flutter UI.

## Mapping to the build

| Stitch screen | Backs onto | Notes |
|---|---|---|
| Connect Wallet / Welcome | `solana_mobile_client` `authorize()` | "No wallet app found" is a real MWA failure mode — see `ARCHITECTURE.md` Phase 4 |
| My Profile | `WorkerProfile` PDA fetch + `getProgramAccounts` for reviews | "Not registered yet" = the `register_worker` CTA |
| Look Up an Address | client-side address validation, then a `WorkerProfile` fetch | no wallet interaction — reads are free |
| Worker Profile | same as My Profile, read-only | "Leave a review" pre-fills Submit Review with this address |
| Submit Review | `submit_review` instruction, MWA-signed | self-review guard is client-side *and* program-enforced (`SelfReview`); "already reviewed" = the `review` PDA `init` failure |
