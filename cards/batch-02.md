# Card batch 2: Tarocchi, enhancements, editions, seals

Status: **approved 2026-10-21 as written.** The zodiac cards are renamed **Signs**.
Code: game/content/deck_mods.gd and tarocchi_cards.gd; tests: game/tests/test_batch_02.gd.

Batch 2 is the cards that **change your deck**. The 8 enhancements, 4 editions and
4 seals come first because the Tarocchi apply them. Their values are the genre's
standard ones, so build strength feels familiar. Names and the Tarocchi assignments
are ours.

## A. Enhancements (8): what a playing card can become

A card has at most one enhancement; a new one replaces the old.

| # | Enhancement | Effect |
|---|---|---|
| E1 | **Lacquered** | +30 Points when scored |
| E2 | **Masked** | +4 Mult when scored |
| E3 | **Motley** | Counts as every suit (harlequin patchwork) |
| E4 | **Mirror** | ×2 Mult when scored; 1 in 4 chance to shatter afterwards (the card is destroyed) |
| E5 | **Iron** | ×1.5 Mult while **held in hand** (not played) |
| E6 | **Marble** | +50 Points; no rank or suit; always scores |
| E7 | **Gilt** | +3 ducats if **held in hand** when you win the show |
| E8 | **Charmed** | When scored: 1 in 5 chance of +20 Mult, and separately a 1 in 15 chance of +20 ducats |

## B. Editions (4): a shine on a card or a zanni

| # | Edition | Effect | On | Shop chance on a zanni | Extra price |
|---|---|---|---|---|---|
| D1 | **Silvered** | +50 Points | cards, zanni | 2% | +2 |
| D2 | **Opaline** | +10 Mult | cards, zanni | 1.4% | +3 |
| D3 | **Prismatic** | ×1.5 Mult | cards, zanni | 0.3% | +5 |
| D4 | **Shadow** | +1 slot (zanni or consumable) | zanni, Tarocchi, Signs | 0.3% | +5 |

- **On a playing card:** the edition applies when the card scores.
- **On a zanni:** Silvered and Opaline apply just before the zanni's own effect,
  Prismatic just after it.

## C. Seals (4): wax stamps on playing cards

| # | Seal | Effect |
|---|---|---|
| S1 | **Ducal seal** | +3 ducats when this card scores |
| S2 | **Encore seal** | This card scores one extra time ("Encore!") |
| S3 | **Astral seal** | If held in hand when you win the show: create the Sign of the last hand you played (if there's room) |
| S4 | **Oracle seal** | When discarded: create a random Tarocchi (if there's room) |

## D. Tarocchi (22): the Italian Major Arcana

- **Price:** all cost **3 ducats**.
- **"Selected"** means cards you pick in your hand before using the Tarocchi. Most can
  be used during a show or while opening a pack.
- **"Create"** needs a free consumable slot.

| # | Tarocchi | Effect |
|---|---|---|
| 0 | **Il Matto** (The Fool) | Turn up to 2 selected cards into random cards: random rank, suit and enhancement |
| 1 | **Il Bagatto** (The Magician) | Make 1 selected card **Motley** |
| 2 | **La Papessa** (The High Priestess) | Create the Sign of your **most played** hand |
| 3 | **L'Imperatrice** (The Empress) | Make up to 2 selected cards **Lacquered** |
| 4 | **L'Imperatore** (The Emperor) | Make 1 selected card **Gilt** |
| 5 | **Il Papa** (The Pope) | Create up to 2 random Tarocchi (never Il Papa) |
| 6 | **Gli Amanti** (The Lovers) | Make up to 2 selected cards **Masked** |
| 7 | **Il Carro** (The Chariot) | Raise the rank of up to 2 selected cards by 1 (King → Ace, Ace → 2) |
| 8 | **La Giustizia** (Justice) | Select 2 cards: the **left** one becomes an exact copy of the **right** one |
| 9 | **L'Eremita** (The Hermit) | **Destroy** up to 2 selected cards (thins your deck) |
| 10 | **La Ruota** (Wheel of Fortune) | Make up to 2 selected cards **Charmed** |
| 11 | **La Forza** (Strength) | Make 1 selected card **Iron** |
| 12 | **L'Appeso** (The Hanged Man) | 1 in 4 chance: a random zanni with no edition becomes Silvered, Opaline or Prismatic |
| 13 | **La Morte** (Death) | Gain ducats equal to the total sell value of your zanni (max 50), like an inheritance |
| 14 | **La Temperanza** (Temperance) | Make 1 selected card **Mirror** |
| 15 | **Il Diavolo** (The Devil) | Double your ducats (max +20) |
| 16 | **La Torre** (The Tower) | Make 1 selected card **Marble** |
| 17 | **La Stella** (The Star) | Turn up to 3 selected cards into **Hearts** |
| 18 | **La Luna** (The Moon) | Turn up to 3 selected cards into **Spades** |
| 19 | **Il Sole** (The Sun) | Turn up to 3 selected cards into **Diamonds** |
| 20 | **Il Giudizio** (Judgement) | Create a random zanni (if there's a free zanni slot) |
| 21 | **Il Mondo** (The World) | Turn up to 3 selected cards into **Clubs** |

The Tarocchi use the original Italian names in every language, like the zanni. Each
gets an English gloss under the name.

## Balance notes

- **Enhancements:**
  - 4 of 22 Tarocchi enhance up to 2 cards (Lacquered, Masked, Charmed, plus Il Matto's
    random one).
  - The strong enhancements, Mirror and Iron, are 1 card per use.
  - Motley, Gilt and Marble are also 1 card per use.
- **Deck shaping:**
  - Suit changes (17, 18, 19, 21) push toward Flush builds and pair with Pulcinella
    and Stenterello from batch 1.
  - L'Eremita (destroy) and La Giustizia (copy) shrink and focus the deck, which is
    how Five of a Kind and Flush Five become reachable.
- **Money:** Il Diavolo (+20 max) and La Morte (+50 max) are the cash cards. La Morte
  is strongest late, with expensive zanni.
- **Two original cards** replace genre staples:
  - **Il Matto** (randomise 2 cards) replaces "copy the last card used".
  - **La Papessa** (Sign of your most played hand) replaces "2 random planets". It's
    more reliable, but only 1 Sign.

## Decided

The zodiac cards from batch 1 are now **Signs** (Gemini is a Sign), so they can't be
confused with the Tarocchi **La Stella**.

## Next batches

| Batch | Contents |
|---|---|
| 3–4 | Uncommon zanni (~40 across two batches), the first ×Mult cards |
| 5 | Rare zanni (~20) + 5 legendary |
| 6–7 | Remaining commons and uncommons up to ~150 |
| 8 | 18 Omens, 32 Warrants, booster packs |
| 9 | 28 Patrons + 24 Favors |
| 10 | 15 decks + 8 stakes + 20 challenges |
