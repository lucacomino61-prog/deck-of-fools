# Card batch 4: 20 more uncommon Jesters

The game is now **Deck of Fools** and the joker cards are **Jesters**. Batches 1–3 say
"zanni"; it's the same cards.

Status: **approved 2026-10-21 as written, coded and tested.** Code:
game/content/zanni_batch_04.gd; tests: game/tests/test_batch_04.gd.

## Rules for this batch

- **Rarity:** all 20 are **uncommon** and available from the first run.
- **Theme:** the stage and its audience (the claque, the gallery, opening night, the
  script), plus more commedia masks.
- **"Gains":** grows during the run and is kept on that copy of the card.

### The stage and the audience

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 41 | **La Claque** | Paid applauders in the stalls | +1 Mult for every **3 ducats** you hold (max +15) | 6 |
| 42 | **Il Loggione** | The gallery, the loudest seats | ×1.5 Mult if this is your **most played** hand (counting this one) | 6 |
| 43 | **La Prima** | Opening night | On the **first hand** of each show, every scored card scores one extra time | 7 |
| 44 | **Il Copione** | The script | +10 Mult if you play **the same poker hand** as your previous hand | 5 |
| 45 | **Il Canovaccio** | The improvised scenario | +3 Mult for each **different suit** among scored cards | 5 |
| 46 | **Il Teatrino** | The puppet stage | **+1 card slot** in the shop | 6 |
| 47 | **L'Impresario** | The theatre manager | At cash-out: +1 ducat for each **Jester you own** | 5 |

### Suits and ranks

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 48 | **Scaramuccia** | The quick swordsman | Each scored **Jack**: ×1.2 Mult | 6 |
| 49 | **Beltrame** | The Milanese trickster | Each **Spade held** in hand: +3 Mult | 5 |
| 50 | **Lucinda** | A lover, all heart | Each scored **Heart**: +20 Points, +3 Mult | 5 |
| 51 | **Il Mercante** | The travelling merchant | Each scored **Diamond**: 1 in 3 chance of +3 ducats | 5 |
| 52 | **La Moretta** | The silent Venetian mask | ×3 Mult if **exactly 1 card** is played | 6 |
| 53 | **Il Pappagallo** | The parrot that repeats | If the hand is exactly a **Pair**, both paired cards score one extra time | 6 |

### Shaping the deck

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 54 | **Il Cerusico** | The barber-surgeon | Discarded **face cards are destroyed**; +2 ducats each | 5 |
| 55 | **Lelio** | The vain lover, always at the mirror | Each scored **Mirror** card: an extra ×1.5 Mult | 6 |
| 56 | **Ottavio** | The patient lover | +2 Mult for each **enhanced card in your full deck** | 6 |
| 57 | **Il Volto** | The plain white mask | Each scored card with **no enhancement, edition or seal**: +3 Mult | 5 |

### Growth

| # | Jester | Who | Effect | Cost |
|---|---|---|---|---|
| 58 | **Giangurgolo** | The greedy Calabrian captain | Gains **+2 Mult** permanently every time you **sell** a card | 5 |
| 59 | **Pasquariello** | The dancing acrobat | Gains **+4 Mult** permanently every time you **skip** a show | 5 |
| 60 | **La Chiromante** | The palm reader | When you use a **Tarocchi**: 1 in 3 chance to create a random **Sign** (if there's room) | 5 |

## Balance notes

- **Builds that open up:**
  - **Single card:** La Moretta (×3) with Il Trombettiere's Aces and Lucinda's Hearts.
  - **Plain deck:** Il Volto rewards keeping cards bare, the opposite of Smeraldina and
    Ottavio, which reward enhancing.
  - **Thin, face-free deck:** Il Cerusico + Meneghino (batch 1) + Il Mangiafuoco
    (batch 3). Cerusico's destroyed cards also feed Mangiafuoco.
  - **One-hand specialist:** Il Loggione + Il Copione + La Papessa reward playing the
    same hand all run.
- **Money:**
  - La Claque turns savings into Mult, which competes with spending.
  - L'Impresario pays more as the troupe fills up.
  - Il Mercante's chance is doubled by Il Ciarlatano.
- **Opening hand:** La Prima is the strongest early card here (every card scores twice
  on the first hand). That's why it's the batch's most expensive, at 7. It pairs with
  Il Capitano (+12 Mult on the first hand).
- **Shop:** Il Teatrino adds a third card slot in every shop, which helps find
  specific Jesters.

## Suits left for later

This batch covers Spades and Hearts. Clubs and Diamonds get matching cards in batch 6,
so no suit is favoured at launch.

## Next batches

| Batch | Contents |
|---|---|
| 5 | Rare Jesters (~20) + 5 legendary |
| 6–7 | Remaining commons and uncommons up to ~150 |
| 8 | 18 Omens, 32 Warrants, booster packs |
| 9 | 28 Patrons + 24 Favors |
| 10 | 15 decks + 8 stakes + 20 challenges + unlock rules |
