# Card batch 5: 20 rare Jesters + 5 legendary

Status: **approved 2026-10-21 as written, coded and tested.** Code:
game/content/zanni_batch_05.gd; tests: game/tests/test_batch_05.gd.

## Rules for this batch

- **Rare:**
  - Turns up in about 1 shop Jester in 20.
  - Each one can define a whole run.
  - Prices 6–10 ducats.
- **Legendary:**
  - **Never in the shop.** They come only from a rare Omen (batch 8).
  - They're the great historical figures of the commedia dell'arte: real 16th–18th
    century actors and playwrights.
  - Price 20 ducats (sell for 10).
- **"Gains":** grows during the run and is kept on that copy of the card.

## A. Rare Jesters (20)

### Copying and the troupe

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 61 | **Il Burattinaio** | The puppeteer | Copies the effect of the Jester to his **right** | 10 |
| 62 | **Il Mattacino** | Venice's egg-throwing jester | Copies the effect of your **leftmost** Jester | 10 |
| 63 | **Il Re dei Folli** | The King of Fools, crowned at the medieval Feast of Fools | Every **other Jester** you own gives ×1.2 Mult | 9 |
| 64 | **La Compagnia** | The whole company | **+2 Jester slots** (one more than it uses) | 9 |

### Big Mult

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 65 | **Il Capriccio** | The whim | Each show names a random poker hand; playing it gives **×3 Mult** | 8 |
| 66 | **La Maschera d'Oro** | The golden mask | ×1 Mult, plus ×0.1 for every **5 ducats** you hold | 8 |
| 67 | **L'Orologio** | St Mark's clock tower | Gains **×0.25 Mult** each time you beat a **Patron** | 8 |
| 68 | **Il Notturno** | The night performance | **×2 Mult** during Patron shows | 7 |
| 69 | **I Gemelli** | The twins, the oldest comedy plot | **×3 Mult** if the played cards include two of the **same rank and suit** | 8 |
| 70 | **Il Gioco delle Parti** | The role swap | When it triggers, **Points and Mult swap** places | 8 |

### Rules that bend

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 71 | **Il Pittore** | The scene painter | **Flushes and Straights** need only **4 cards** | 8 |
| 72 | **Il Gran Ballo** | The grand ball | In a hand containing a **Straight or Flush**, every scored card scores one extra time | 9 |
| 73 | **Il Teatro Olimpico** | Europe's oldest indoor theatre (Vicenza) | **+1 hand and +1 discard** each show | 8 |
| 74 | **La Nebbia** | The lagoon fog | Patrons **lose their whim**, but their target is ×2.5 instead of ×2 | 7 |
| 75 | **La Fenice** | Venice's opera house that rose from its ashes | If you'd lose a show after scoring **at least a quarter** of the target, you pass it instead (no show reward). La Fenice then burns | 6 |

### Growth, Signs and money

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 76 | **Il Banditore** | The town crier | **Signs level their hand twice** | 8 |
| 77 | **Il Maestro di Cappella** | The bandmaster | +3 Mult for each **level** of the played hand | 7 |
| 78 | **Il Carnevale** | Carnival itself | Each scored **face card** without an enhancement becomes **Masked** after scoring | 7 |
| 79 | **Il Prestigiatore** | The conjurer | When a show starts, a random card in your deck without an edition gains **Silvered, Opaline or Prismatic** | 9 |
| 80 | **Il Doge** | The ruler of Venice | **Interest pays double** (up to 10 a show, 20 with Il Notaio) | 8 |

## B. Legendary Jesters (5): the legends of the commedia

| # | Jester | Who | Effect |
|---|---|---|---|
| L1 | **Tristano Martinelli** | The first great Arlecchino (1557–1630) | Each Jester **to his left** gives ×1.5 Mult |
| L2 | **Isabella Andreini** | The most celebrated actress and poet of her age (1562–1604) | Each scored **Queen**: ×2.5 Mult |
| L3 | **Carlo Goldoni** | The playwright who reformed the commedia (1707–1793) | **Every scored card** scores one extra time |
| L4 | **Carlo Gozzi** | Goldoni's rival, author of fairy-tale plays (1720–1806) | Gains **×0.5 Mult** every time you use a **Sign** |
| L5 | **Flaminio Scala** | Published the first book of commedia scenarios (1611) | When you win a show, your **most played hand gains a level** |

## Balance notes

- **Copiers:**
  - Il Burattinaio and Il Mattacino copy a Jester's scoring effect and its cash-out
    money.
  - They don't copy growth: a copied Pantalone doesn't grow twice.
- **Most powerful here:**
  - **Il Re dei Folli:** with 4 other Jesters it's ×2.07.
  - **Il Gran Ballo:** doubles a whole Flush.
  - Both are priced 9–10.
- **Trade-offs:**
  - **La Nebbia:** easier patrons, higher targets.
  - **Il Gioco delle Parti:** only pays in high-Points builds (Lacquered, Marble,
    Silvered). It's useless in Mult builds.
  - **La Fenice:** a one-time safety net that destroys itself.
- **Signs build:** Il Banditore + Il Maestro di Cappella + Carlo Gozzi + Flaminio Scala
  turns levelling one hand into a whole strategy.
- **Legendaries:** each one is roughly a run-winner on its own, which is why only an
  Omen can give one.

## Next batches

| Batch | Contents |
|---|---|
| 6 | 20 commons + Clubs and Diamonds cards (to balance the suits) |
| 7 | Last ~45 Jesters to reach ~150 (commons and uncommons) |
| 8 | 18 Omens (incl. the one that summons a legendary), 32 Warrants, booster packs |
| 9 | 28 Patrons + 24 Favors |
| 10 | 15 decks + 8 stakes + 20 challenges + unlock rules |
