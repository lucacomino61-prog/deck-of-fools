# Card batch 7: 22 Jesters (14 common, 8 uncommon)

Status: **approved 2026-10-21 as written, coded and tested.** Code:
game/content/zanni_batch_07.gd; tests: game/tests/test_batch_07.gd. 128 Jesters in total.

## Rules for this batch

- **Rarity:** cards 107–120 are **common**, 121–128 are **uncommon**. All are available
  from the first run.
- **Theme:** the town around the theatre (its shopkeepers, street sellers and
  tradespeople) plus a few more stage figures.

## A. Commons (14)

### Hand size and shape

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 107 | **Gli Innamorati** | The lovers, always a pair | +10 Mult if **exactly 2 cards** are played | 4 |
| 110 | **Il Principe** | The young prince | Each scored **King**: +15 Points, +2 Mult | 4 |
| 111 | **Il Garzone** | The shop boy | Each scored **number card** (2–10): +2 Mult | 4 |
| 115 | **Il Calzolaio** | The cobbler, stamps every pair he makes | Each scored card **with a seal**: +5 Mult | 4 |
| 118 | **Lo Sbandieratore** | The flag-thrower | +20 Points for each Jester **to his right** (Arlecchino's mirror image) | 3 |

### Hands and discards left

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 112 | **La Lavandaia** | The washerwoman | +4 Mult for each **discard you have left** | 4 |
| 113 | **Il Postino** | The messenger | +15 Points for each **hand you have left** (counting this one) | 3 |
| 117 | **Il Venditore di Almanacchi** | The almanac seller | +1 Mult for each **different poker hand** you've played this run | 4 |

### Money, shop and growth

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 108 | **Il Rigattiere** | The junk dealer | The **first reroll** in each shop is free | 4 |
| 109 | **Lo Spazzino** | The street sweeper | Discarding **5 cards at once**: +3 ducats | 3 |
| 114 | **Il Cuoco** | The troupe's cook | +3 Mult for each **Tarocchi or Sign you hold** | 3 |
| 116 | **La Fioraia** | The flower girl | Win a show **with your first hand**: +4 ducats at cash-out | 4 |
| 119 | **La Sarta** | The costume seamstress | When a show starts, a random card in your deck **without an enhancement** becomes **Lacquered** | 4 |
| 120 | **Lo Specchiaio** | The mirror maker | +4 ducats whenever a **Mirror** card is destroyed | 3 |

## B. Uncommons (8)

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 121 | **Il Gigante** | The giant of the fairground | **+2 cards** in hand, but **1 fewer hand** each show | 5 |
| 122 | **Il Mecenate** | The patron of the arts | Cards and packs in the shop cost **1 ducat less** (minimum 1) | 6 |
| 123 | **Lo Straniero** | The foreigner, new to everything | **×2 Mult** the first time you play each poker hand this run | 6 |
| 124 | **L'Eco** | The theatre's echo | Cards **held in hand** trigger their held effects one extra time (Iron, La Bauta, Beltrame…) | 6 |
| 125 | **Il Sagrestano** | The bell-ringer | Each scored card **with a seal** scores one extra time | 6 |
| 126 | **L'Usuraio** | The moneylender | You can spend up to **20 ducats you don't have** | 4 |
| 127 | **Il Fattucchiere** | The village sorcerer | When you **skip** a show, also create a random **Tarocchi** (if there's room) | 5 |
| 128 | **Il Becchino** | The gravedigger | Gains **×0.2 Mult** permanently each time you **sell a Jester** | 6 |

## Balance notes

- **Seals become a build:** Il Calzolaio (+5 Mult per sealed card) and Il Sagrestano
  (sealed cards score twice), with batch 2's Encore and Ducal seals. A Ducal + Encore
  card with Il Sagrestano pays 9 ducats each time it scores.
- **Held-in-hand build:** L'Eco doubles Iron cards and every "held" Jester (La Bauta,
  Beltrame, Silvia, Corallina). It pairs with Il Gigante's bigger hand.
- **Position:** Lo Sbandieratore wants to sit far left, Arlecchino far right. Both in one
  troupe pull the row in opposite directions.
- **Variety vs. focus:**
  - **Rewards variety:** Lo Straniero and Il Venditore di Almanacchi (play many
    different hands).
  - **Rewards focus:** Il Loggione and Il Copione (batch 4).
- **Money:**
  - **Spending:** Il Mecenate and Il Rigattiere make shopping cheaper.
  - **Debt:** L'Usuraio lets you overspend; it fights interest (no interest while
    you're in debt).
  - **Selling:** Il Becchino rewards selling Jesters, Giangurgolo (batch 4) any card.

## Engine notes (for me, not decisions)

- **Free rerolls, a shop discount and debt:** small new stats.
- **Lo Specchiaio:** reads "destroyed", not "shattered", so it also pays when
  L'Eremita destroys a Mirror card. That's simpler, and fair.

## Next batches

| Batch | Contents |
|---|---|
| 8 | 22 Jesters (commons, uncommons, a few rares), reaching 150 |
| 9 | 18 Omens (incl. the one that summons a legendary), 32 Warrants, booster packs |
| 10 | 28 Patrons + 24 Favors |
| 11 | 15 decks + 8 stakes + 20 challenges + unlock rules |
