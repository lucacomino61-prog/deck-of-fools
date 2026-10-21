# Card batch 3: 20 uncommon zanni, the first ×Mult

Status: **approved 2026-10-21 as written, coded and tested.** Code:
game/content/zanni_batch_03.gd; tests: game/tests/test_batch_03.gd.

## Rules for this batch

- **Rarity:** all 20 are **uncommon**. The shop rolls uncommon about 1 time in 4.
- **Unlocking:** all are available from the first run. Which zanni need unlocking is
  decided with decks and stakes in batch 10.
- **"Gains":** the bonus grows during the run and is kept on that copy of the card.
  Selling it loses the growth.

### ×Mult: what makes the late towns beatable

| # | Zanni | Who | Effect | Cost |
|---|---|---|---|---|
| 21 | **Il Capocomico** | The troupe's leader | ×1.5 Mult if **every zanni slot is full** | 6 |
| 22 | **La Maschera Nera** | The black mask | ×2.5 Mult, but you have **1 fewer hand** each show | 7 |
| 23 | **Il Funambolo** | The tightrope walker | ×2 Mult on the **last hand** of a show | 6 |
| 24 | **Il Lazzo** | The comic routine itself | ×2 Mult if **exactly 3 cards** are played | 6 |
| 25 | **Fracasso** | The loud one, never quiet | ×1.5 Mult if you **haven't discarded** this show | 5 |
| 26 | **Rugantino** | Rome's braggart | Gains ×0.15 Mult for each hand **in a row** containing a **Pair**; resets to ×1 on a hand without one | 6 |
| 27 | **Il Mangiafuoco** | The fire-eater | Gains ×0.25 Mult each time a playing card is **destroyed** (starts at ×1) | 6 |

### Encores

| # | Zanni | Who | Effect | Cost |
|---|---|---|---|---|
| 28 | **Il Suggeritore** | The prompter, whispering the last line | The **last** scored card scores one extra time | 6 |
| 29 | **Il Trombettiere** | The trumpeter | Each scored **Ace** scores one extra time | 6 |

### Slots and stats

| # | Zanni | Who | Effect | Cost |
|---|---|---|---|---|
| 30 | **Il Saltimbanco** | The street acrobat | **+1 card** in hand | 5 |
| 31 | **Il Carro di Tespi** | The troupe's travelling wagon | **+1 consumable slot** | 5 |
| 32 | **Il Notaio** | The notary | Interest cap **+5** (earn up to 10 interest per show) | 6 |

### Money and luck

| # | Zanni | Who | Effect | Cost |
|---|---|---|---|---|
| 33 | **Il Sipario** | The curtain | Each **unused hand** pays 1 extra ducat at cash-out | 5 |
| 34 | **Il Gobbo** | The lucky hunchback | Each scored **Charmed** card: +2 ducats | 5 |
| 35 | **Il Ciarlatano** | The charlatan selling miracles | **Doubles** every "N in M" chance (Mirror, Charmed, L'Appeso…) | 6 |

### Built on batch 2

| # | Zanni | Who | Effect | Cost |
|---|---|---|---|---|
| 36 | **Smeraldina** | The clever maid | Each scored **enhanced** card: +6 Mult | 6 |
| 37 | **Corallina** | Her rival maid | Each **Iron** card held in hand: an extra ×1.25 Mult | 6 |
| 38 | **Il Vetraio** | The Venetian glassblower | **Mirror** cards never shatter | 5 |
| 39 | **Il Cantastorie** | The storyteller | +1 Mult for each **Tarocchi or Sign used** this run | 5 |
| 40 | **La Bauta** | The Venetian carnival mask | Each **face card held** in hand: +4 Mult | 5 |

## Balance notes

- **First ×Mult cards:**
  - **Strongest:** La Maschera Nera (×2.5) pays for it with a hand.
  - **Mid-range:** Il Funambolo and Il Lazzo (×2) only fire under a condition.
  - **Easiest to trigger:** Capocomico and Fracasso (×1.5).
- **Pairs that pull together:**
  - **Rugantino + Isabella** (batch 1): Pair builds.
  - **Il Lazzo + Gianduja**: three-card Three of a Kind.
  - **Corallina + La Forza**: Iron cards.
  - **Il Gobbo + Il Ciarlatano + La Ruota**: a Charmed-card money engine.
  - **Smeraldina** rewards any Tarocchi that enhances cards.
- **Pairs that pull apart (on purpose):**
  - **Il Mangiafuoco** wants Mirror cards to shatter. **Il Vetraio** stops it.
  - **La Maschera Nera** removes a hand, which hurts Pedrolino and Il Funambolo.
- **Money:** Il Notaio raises the interest ceiling, which only pays if you can sit on
  50 ducats. Il Sipario rewards winning shows in fewer hands.

## Engine notes (for me, not decisions)

Everything here runs on hooks that already exist, except two small additions:

- **"In a row" counter** for Rugantino: kept on the card.
- **"Last hand" check** for Il Funambolo: hands left = 1 when scoring.

## Next batches

| Batch | Contents |
|---|---|
| 4 | 20 more uncommon zanni |
| 5 | Rare zanni (~20) + 5 legendary |
| 6–7 | Remaining commons and uncommons up to ~150 |
| 8 | 18 Omens, 32 Warrants, booster packs |
| 9 | 28 Patrons + 24 Favors |
| 10 | 15 decks + 8 stakes + 20 challenges + unlock rules |
