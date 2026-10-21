# Card batch 8: the last 22 Jesters (7 common, 13 uncommon, 2 rare)

Status: **approved 2026-10-21 as written, coded and tested.** Code:
game/content/zanni_batch_08.gd; tests: game/tests/test_batch_08.gd. All 150 Jesters are in.

## The full set after this batch

| Rarity | Jesters | Genre reference |
|---|---|---|
| Common | 61 | Balatro: 61 |
| Uncommon | 62 | Balatro: 64 |
| Rare | 22 | Balatro: 20 |
| Legendary | 5 | Balatro: 5 |
| **Total** | **150** | |

All are available from the first run until batch 11 decides which ones unlock later.

## A. Commons (7)

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 129 | **L'Orafo** | The goldsmith | Each scored **Gilt** card: +3 ducats | 4 |
| 130 | **Il Rattoppatore** | The patcher of costumes | Each scored **Motley** card: +8 Mult | 4 |
| 131 | **Il Gonfaloniere** | The standard-bearer | +6 ducats at cash-out after a **Patron** show | 4 |
| 132 | **Lo Scultore** | The sculptor | +25 Points for each **Marble** card in your full deck | 4 |
| 133 | **Il Mendicante** | The beggar at the stage door | +15 Mult while you have **0 ducats or less** | 3 |
| 134 | **Il Merciaio** | The haberdasher | Gains **+1 Mult** every time you **reroll** the shop | 4 |
| 135 | **Il Pescivendolo** | The fishmonger | Each scored **5, 6 or 7**: +3 Mult | 3 |

## B. Uncommons (13)

### Encores

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 136 | **Lo Smemorato** | The forgetful one, always repeating himself | Each scored **2, 3, 4 or 5** scores one extra time | 6 |
| 137 | **La Commedia** | Comedy itself | Each scored **face card** scores one extra time | 6 |

### Card types in your deck

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 138 | **Il Ritrattista** | The portrait painter: everyone looks noble | **Every card counts as a face card** | 5 |
| 139 | **Il Fabbro** | The blacksmith | ×1 Mult, plus **×0.2** for each **Iron** card in your full deck | 7 |
| 140 | **Il Gioielliere** | The jeweller | Each scored card **with an edition**: ×1.25 Mult | 6 |
| 141 | **L'Asceta** | The hermit-monk, owns almost nothing | ×1 Mult, plus **×0.05** for each card your deck is **below 52** | 6 |
| 147 | **Il Tipografo** | The printer of playbills | When a show starts, add a **copy** of a random card in your deck to your deck | 6 |

### Signs and Tarocchi

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 142 | **L'Astronomo** | The court astronomer | +2 Mult for each **level above 1** across all your hands | 6 |
| 143 | **Il Copista** | The copyist monk | The **first Tarocchi** you use each show is copied (if there's room) | 6 |

### Tricks

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 144 | **Il Buttafuori** | The bouncer | **Sell him** during a Patron show: the Patron loses its whim for that show | 5 |
| 145 | **La Ruffiana** | The matchmaker | After scoring a hand that contains a **Pair**, the paired cards take the **first card's suit** | 6 |
| 146 | **L'Avvocato** | The lawyer who finds loopholes | Once per show, discarding **exactly 1 card** doesn't use a discard | 5 |
| 148 | **La Nonna** | The troupe's grandmother | Gains **+2 Mult** at each cash-out | 5 |

## C. Rares (2)

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 149 | **La Cometa** | The comet | Each **Sign** you use also levels up your **second most played** hand | 8 |
| 150 | **La Prima Donna** | The leading lady, who hates sharing the stage | **×2 Mult**, or **×4** if she's your **only** Jester | 8 |

## Balance notes

- **Every enhancement now has a payoff Jester:**

  | Enhancement | Payoff Jesters |
  |---|---|
  | Lacquered | Smeraldina, Ottavio |
  | Masked | Smeraldina, Ottavio |
  | Motley | Il Rattoppatore |
  | Mirror | Lelio, Lo Specchiaio |
  | Iron | Corallina, Il Fabbro |
  | Marble | Lo Scultore |
  | Gilt | L'Orafo |
  | Charmed | Il Gobbo |

- **Deck-size strategies, opposite on purpose:**
  - **Thin deck:** L'Asceta pays for destroying cards (L'Eremita, Il Cerusico).
  - **Growing deck:** Il Tipografo adds cards. Copies also make Five of a Kind and
    I Gemelli possible.
- **Face cards:** Il Ritrattista makes every card a face card. That powers La Bauta,
  La Commedia and Il Carnevale, but breaks Meneghino ("no face cards"). Choose one side.
- **Lone wolf:** La Prima Donna (×4 alone) is a different way to play: one Jester, lots
  of Signs and Tarocchi.
- **Money:** Il Mendicante rewards being broke (pairs with L'Usuraio's debt).
  Il Gonfaloniere rewards beating Patrons.

## Engine notes (for me, not decisions)

- **"Counts as a face card":** this becomes a run rule, so Il Ritrattista affects every
  "face card" check, including the existing Jesters.
- **New per-show rules:** Il Buttafuori's per-show mute and L'Avvocato's free single
  discard.

## Next batches

| Batch | Contents |
|---|---|
| 9 | 18 Omens (incl. the one that summons a legendary), 32 Warrants, booster packs |
| 10 | 28 Patrons + 24 Favors |
| 11 | 15 decks + 8 stakes + 20 challenges + unlock rules |
