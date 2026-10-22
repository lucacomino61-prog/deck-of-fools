# Deck of Fools — game spec (approved 2026-10-21)

Name history: Zanni → Cheating Fate → **Deck of Fools** (all 2026-10-21). The joker cards
are called **Jesters** in the game, because few players know the word "zanni". The code
keeps its internal names (kind "zanni", ids like z_arlecchino, the folder LC/zanni).

A poker-hand roguelike for iPhone and Android with the same gameplay loop, depth and
rewards as Balatro, but its own name, theme, art, card names and card text. Nothing is
copied from Balatro's art, names, text or look (copyright, and App Store guideline 4.1
rejects copycats).

**Theme:** a travelling commedia dell'arte troupe. You lead the Jesters (the masked servant
clowns) from town to town and win each crowd with poker hands.
**Look:** retro pixel art behind a CRT glow, in our own palette, with a slowly scrolling
harlequin-diamond backdrop (not Balatro's paint swirl).

## 1. Your decisions

| Topic | Decision |
|---|---|
| Look | Retro pixel + CRT glow |
| Engine | Godot 4 (best fit for 2D, text-based project files I can build and test, plus a web build I can preview) |
| Orientation | Landscape |
| Sign-in | Email + password, Sign in with Apple, Google, guest play |
| When to ask for an account | After the first run (guest until then) |
| Content | Full depth at launch |
| Money | Free + one-time unlock at **$4.99**; free players get **3 full runs per day** |
| Account features | Cloud save, leaderboards, daily seeded run, profile and stats |
| Languages | English, Italian, Albanian; text system ready for more |
| iPhone builds | No Mac, so a cloud Mac build service (Codemagic) |
| Card roster | Designed together in batches of ~20 |
| Art | Drawn by me in code (pixel sprites) |
| Backend | Cloudflare Workers + D1 on your account |
| Name | **Deck of Fools**; no game with this name found (web check 2026-10-21) |
| Card word | **Jesters** (each keeps its commedia name, e.g. Arlecchino) |

## 2. Theme names (proposed: change any)

| Genre term (Balatro) | Deck of Fools | Why |
|---|---|---|
| Joker | **Jesters** (the commedia masks: Arlecchino, Pulcinella…) | The cards you collect are the troupe; "Jester" is a word every player knows |
| Ante (8 per run) | **Town** (8 towns per tour) | The troupe tours |
| Small / Big / Boss blind | **Matinee / Evening show / Patron** | The boss is a noble patron with a whim (debuff) |
| Chips × Mult | **Points × Mult** | Avoids casino words |
| $ | **Ducats** | Avoids casino imagery; period-correct |
| Planet cards (level a hand) | **Signs**: 12 zodiac signs, one per poker hand | 12 hands = 12 signs (renamed from "Stars" in batch 2 to avoid clashing with La Stella) |
| Tarot cards | **Tarocchi** (the 22 Major Arcana, Italian tarot) | Public domain, Italian |
| Spectral cards | **Omens** | Rare, powerful, risky |
| Vouchers | **Warrants** (royal permits) | Permanent upgrades for the run |
| Tags (for skipping a blind) | **Favors** | A reward for skipping a show |
| Stakes | **Stakes** (8 difficulty seals) | Keeps the familiar word |

Ratings note: PEGI rated Balatro 18+ for "gambling imagery" in 2024. So: no casino felt,
no chip stacks, no slot-machine reels, no loot boxes, no real-money prizes.

## 3. Gameplay (same rules as the genre)

**Run:** 8 towns. Each town has a matinee, an evening show and a patron. Beat all 8 patrons
to win; endless mode continues after that.

**Each show:** 52-card deck, 8 cards in hand, **4 hands and 3 discards**. Play 1 to 5 cards.
**Score = (hand points + card points + bonuses) × (hand mult + bonuses) × each ×Mult.**
Card points: 2–10 = face value, J/Q/K = 10, A = 11.

**Poker hands:** 12, including three secret ones (Five of a Kind, Flush House, Flush Five).
Starting values sit in the same range as the genre (Pair 10 × 2 up to Flush Five 160 × 16)
and are confirmed in batch 1.

**Score targets:** base per town 300 · 800 · 2,000 · 5,000 · 11,000 · 20,000 · 35,000 ·
50,000. Matinee ×1, evening ×1.5, patron ×2 (some patrons change this). Stakes raise the curve.

**Jester order:** they trigger left to right. +Mult before ×Mult is the core skill.

**Economy:**
- Start with 4 ducats.
- Show rewards: 3 / 4 / 5 ducats, +1 per unused hand.
- Interest: 1 ducat per 5 held, up to 5.
- You can skip a matinee or an evening show to take a Favor.

**Shop after each show:**
- 2 card slots.
- 2 booster packs: Tarocchi, Signs, Omens, Jesters and playing-card packs.
- 1 Warrant.
- Reroll for 5 ducats, rising by 1 each time.
- Sell cards for half their price.

**Card upgrades:**
- 8 enhancements, e.g. bonus, mult, wild, glass, steel, stone, gold, lucky.
- 4 editions: foil, holographic, polychrome, negative.
- 4 seals.

**Jester slots:** 5 to start. 2 slots for Tarocchi, Signs and Omens.

### Content at launch (full depth)

| Type | Count |
|---|---|
| Jesters | ~150 (common, uncommon, rare, legendary) |
| Tarocchi | 22 |
| Signs | 12 |
| Omens | ~18 |
| Warrants | ~32 (16 base + 16 upgrades) |
| Patrons (boss blinds) | ~28 (incl. 5 finale patrons for town 8) |
| Favors | ~24 |
| Decks | 15 |
| Stakes | 8 |
| Challenges | ~20 |

Every card gets its own name, effect text and pixel art, designed with you in batches.

### Rewards and progression

- **In a run:** ducats, interest, Favors, card packs.
- **Between runs:** unlocks for new Jesters, decks and stakes via achievements; a
  completion badge on each Jester for the highest stake won with it; the collection
  book; stats.
- **No permanent power upgrades:** every run starts equal, as in the genre.

## 4. Phone experience (landscape)

**Screen:**
- Internal pixel resolution 640×360, scaled up sharp, widening to fill 19.5:9–20:9 phones.
- Respects notch and home-bar safe areas.
- Cards 64×88 pixels: about 70×95 points on a phone, comfortable to tap.

**Layout:**
- Jester row at the top.
- Score, target and hands/discards counters in the centre-left column.
- Hand fanned along the bottom.
- Play and Discard buttons bottom-right, within thumb reach.

**Touch:**
- Tap to select a card; drag to reorder the hand or Jesters.
- Drag a card onto Sell / Use areas.
- Long-press to inspect a card at 2× size with large text. Pixel text stays at least ~11 pt.

**Feel:**
- Haptics on select, deal and each scoring step.
- Score counts up while the screen shakes.
- CRT scanlines with a soft glow.
- A Reduce motion setting turns off shake, CRT curvature and the moving backdrop.

**Performance:** 60fps target on mid-range Android; build size kept small.

## 5. Accounts and online (Cloudflare Workers + D1)

- **Guest:** the first launch creates a guest account silently. After the first run the
  game offers "Save your progress": email, Apple or Google. Linking keeps everything.
- **Email + password:**
  - Hashed with PBKDF2 (Workers WebCrypto).
  - Verification email and password reset (needs an email provider; see open items).
- **Sign in with Apple / Google:**
  - Native sign-in sheets through Godot plugins.
  - The Worker verifies the identity token against Apple's and Google's public keys.
- **Account deletion inside the app:** Apple requires it.
- **Cloud save:** profile, unlocks, stats and the run in progress. If two devices changed
  the same data, the game asks which one to keep.
- **Leaderboards:** best score per hand and highest town per stake. Each run is submitted
  as seed + action log; the server checks plausibility and rate-limits.
- **Daily run:** the same seed for everyone each day (UTC). One ranked attempt, practice
  unlimited. It doesn't count toward the free player's 3 runs.
- **Profile and stats:** win rate per deck and stake, favourite Jester, best hand, collection %.

## 6. Money

- Free download.
- **Free tier:** 3 full runs per day, reset at midnight local time. The daily run is
  always free.
- **"Full Troupe" unlock:** $4.99 one-time in-app purchase gives unlimited runs.
  - Apple StoreKit / Google Play Billing through Godot's official store plugins.
  - "Restore purchases" button.
  - The Worker verifies the receipt and stores the unlock on the account, so it follows
    the player across devices and platforms.
- No ads, no other purchases.

## 7. Project layout

```
zanni/
  SPEC.md            this file
  cards/             card batches for review (one file per batch)
  game/              Godot 4 project
    core/            pure rules: seeded RNG, deck, hand evaluator, scoring, run state, shop (no UI)
    content/         card data (zanni, tarocchi, signs, omens, warrants, patrons, favors, decks, stakes)
    ui/              scenes: title, sign-in, run, shop, collection, profile, leaderboards, settings
    shaders/         CRT glow, harlequin backdrop
    art/             pixel sprites (generated by tools/)
    i18n/            en / it / sq string tables
    tests/           headless rules tests
  tools/             sprite generator (draws the pixel art from code)
  server/            Cloudflare Worker + D1: auth, saves, leaderboards, daily seed, purchases
```

## 8. Build order

| # | Milestone | Done when |
|---|---|---|
| M0 | Setup: Godot 4 (official download), project skeleton, test runner, web export for previews | Empty project builds; tests run |
| M1 | Rules core: deck, 12-hand evaluator, scoring pipeline, towns and shows, economy, shop, seeded RNG | Headless tests prove scoring and economy |
| M2 | Playable loop with placeholder cards in landscape | A full run playable in the web preview |
| M3 | Content batches with you: hand values, then Jesters (8 batches), tarocchi, signs, omens, warrants, patrons, favors, decks, stakes, challenges | Every card approved and tested |
| M4 | Feel: CRT shader, backdrop, score count-up, shake, particles, haptics, sound hooks | Feels right on a phone |
| M5 | Pixel art: about 300 sprites drawn in code | No placeholders left |
| M6 | Online: Worker + D1, guest to account, email/Apple/Google, cloud save, leaderboards, daily run, profile, deletion | Works end to end against a local Worker |
| M7 | Money: 3 runs/day, $4.99 unlock, restore, server-side receipt check | Sandbox purchases pass on both stores |
| M8 | Languages: EN, IT, SQ | All text translated; no overflow |
| M9 | Release prep: Android build (local), iOS build (Codemagic), store listings, privacy policy, age ratings | Test builds on real phones. **No store submission until you say so.** |

## 9. Open items (needed later, not now)

1. **Music and sound:** I can make placeholder sound effects; music needs a composer, a
   licensed pack, or generated music. Your call.
2. **Email sender** for verification and reset emails (e.g. Resend or Postmark), plus
   the domain it sends from.
3. **Accounts you'll need:**
   - Apple Developer Program ($99/yr, needed even with a cloud build).
   - Google Play Console ($25 once).
   - Codemagic.
   - Store payout and tax details. These are yours to enter.
4. **Domain** for the server API, privacy policy and support page.
5. **Cloudflare plan:** password hashing may need the Workers Paid plan ($5/mo) for CPU time.

## 10. What makes it its own game (chosen 2026-10-22)

Luca asked what to add to make the game more unique and picked all 16 ideas. He then chose
how each should work. They're built in four groups, gameplay first, with a stop after each
group for him to play. Each group's content goes to him as a card batch before it's coded
(group 1 is cards/batch-12.md, built; group 2 is cards/batch-13.md, built 2026-10-22:
Maestro at 120 fame, 1.25×, scudi, full 8-town campaign chapters climbing Stake 1 to 4, one
Jester carried, rematch 1 in 5, lists kept).

| Group | Feature | His choice |
|---|---|---|
| 1 Gameplay | **Scenarios** (commedia scripts) | Risky: three beats; hitting them pays a lot, missing one gives a penalty |
| 1 Gameplay | **Map of Italy** | Branching route, real cities, each with a twist and shop flavour |
| 1 Gameplay | **Lazzi** (Jester duos) | Owning both lets you merge them into one stronger card in one slot |
| 1 Gameplay | **Live audience** | Painted theatre boxes reacting to every hand |
| 1 Gameplay | **Crowd mood** | Bonus when full and a penalty when empty |
| 1 Gameplay | **Encore** | Offered when the crowd demands it (high mood) |
| 2 Progression | **Jester fame** | Permanent across runs: a Jester that reaches 3 stars becomes its Maestro version for good |
| 2 Progression | **Troupe wagon** | Spend between runs on cosmetics, small starting perks, earlier unlocks, and the wagon on the map |
| 2 Progression | **Story campaign** | Long tour: 15+ chapters, one per city |
| 2 Progression | **Patron rivalry** | Both: a beaten Patron can return later in the run, and the one that beat you returns next run as a nemesis; Patrons get lines |
| 3 Show feel | **Critic's review** | La Gazzetta reviews every show at cash-out |
| 3 Show feel | **Jester voices** | Synthesized Italian babble per Jester, with a speech bubble |
| 3 Show feel | **Hecklers** | Appear when the crowd is angry; a tomato splats a card in hand |
| 4 Social | **Playbill share** | A painted playbill of the run to save or share |
| 4 Social | **Weekly tour** | A weekly seeded tour with a random special rule and its own leaderboard |
| 4 Social | **Friend duel** | Both: challenge links (play my seed) and live duels by room code |
| 4 Social | **Ghost troupes** | In the daily run, see other players' troupes from the same town |

**Change to §3:** Maestro fame and wagon perks are permanent power, which §3 "Rewards and
progression" ruled out. Luca decided (2026-10-22): they're on in normal runs and the
campaign, and off in daily, weekly, duel and ranked runs, so leaderboards stay equal. As
built, seeded runs and challenges are off too, and a normal run that used them is sent as
"assisted" and stays off the best-hand and town boards. The online parts stay local until he
says deploy.
