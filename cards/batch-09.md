# Card batch 9: 18 Omens, 32 Warrants, booster packs

Status: **approved 2026-10-21 as written, coded and tested.** Code: game/content/omen_cards.gd,
warrant_cards.gd, pack_defs.gd and game/core/pack_maker.gd; tests: game/tests/test_batch_09.gd.
One fix while coding: La Janara, Il Fantasma and Il Folletto never pick Marble, which would
erase the rank they promise.

## A. Omens (18): Italian superstitions, powerful and risky

- **Where they come from:** Omen packs, a couple of Jesters and Favors, and the
  **Il Baule dei Presagi** Warrant. They never sit in the shop's card slots.
- **Price:** 4 ducats (sell for 2).
- **Rarest:** the two marked ★ appear only about 1 time in 300 per pack card.

| # | Omen | What it is | Effect |
|---|---|---|---|
| O1 ★ | **La Maschera Divina** | The divine mask | Create a **legendary Jester** (needs a free slot) |
| O2 ★ | **L'Eclissi** | The eclipse | **Every poker hand** gains a level |
| O3 | **La Janara** | The witch of Benevento | Destroy 1 random card in your hand; add 3 random **enhanced face cards** to your hand |
| O4 | **Il Fantasma** | The theatre ghost | Destroy 1 random card in your hand; add 2 random **enhanced Aces** |
| O5 | **Il Folletto** | The mischievous sprite | Destroy 1 random card in your hand; add 4 random **enhanced number cards** |
| O6 | **Il Corno** | The Neapolitan horn charm | Add a **Ducal seal** to 1 selected card |
| O7 | **Il Ritorno** | The return | Add an **Encore seal** to 1 selected card |
| O8 | **La Civetta** | The owl, bird of night | Add an **Astral seal** to 1 selected card |
| O9 | **La Sibilla** | The sibyl | Add an **Oracle seal** to 1 selected card |
| O10 | **Il Fuoco Fatuo** | The will-o'-the-wisp | Give 1 selected card a random **Silvered, Opaline or Prismatic** edition |
| O11 | **Il Patto** | The pact | Create a random **rare Jester** (needs a free slot); your ducats are **halved** |
| O12 | **L'Acqua Alta** | Venice's high water | Every card in your hand becomes **one random suit** |
| O13 | **La Seduta** | The séance | Every card in your hand becomes **one random rank**; **−1 discard** each show for the rest of the run |
| O14 | **L'Ombra** | The shadow | A random Jester becomes **Shadow** (+1 slot); **−1 card in hand** for the rest of the run |
| O15 | **Il Vesuvio** | The eruption | Destroy **4** random cards in your hand; gain **16 ducats** |
| O16 | **Il Sosia** | The double | Copy a random Jester; **destroy all your other Jesters** |
| O17 | **Il Malocchio** | The evil eye | A random Jester becomes **Prismatic**; **destroy all your other Jesters** |
| O18 | **Lo Specchio Magico** | The magic mirror | Create **2 copies** of 1 selected card in your hand |

Copies and transformations keep a card's enhancement, edition and seal. Jesters
destroyed by Il Sosia and Il Malocchio are gone for good; nothing protects them yet
(stake stickers come in batch 11).

## B. Warrants (32): royal permits, one in the shop per town

- **Price:** 10 ducats.
- **How they're offered:** one Warrant is on sale per town. It stays until you buy it or
  the town ends.
- **Upgrades:** each upgrade (right column) only appears after you own its base Warrant.
- **Duration:** they last the whole run and can't be sold.

| # | Warrant | Effect | Upgrade | Upgrade effect |
|---|---|---|---|---|
| W1 | **Licenza di Bottega** | +1 card slot in the shop | **Bottega Grande** | +1 more |
| W2 | **Sconto del Mercante** | Shop cards and packs **25% cheaper** | **Svendita** | **50%** cheaper |
| W3 | **Lustrini** (sequins) | Editions appear **2×** as often | **Paillettes** | **4×** |
| W4 | **Il Rimescolo** | Rerolls cost **2 less** | **Rimescolo Perpetuo** | 2 less again |
| W5 | **Il Baule** (the trunk) | **+1 consumable slot** | **Baule dei Presagi** | Omens can appear in Tarocchi packs |
| W6 | **Il Cannocchiale** (spyglass) | Sign packs always include your **most played hand's** Sign | **L'Osservatorio** | Each Sign you **hold** gives **×1.5 Mult** when you play its hand |
| W7 | **Il Copione Lungo** | **+1 hand** each show | **Il Secondo Atto** | +1 more |
| W8 | **Il Cestino** (wastebasket) | **+1 discard** each show | **Il Riciclo** | +1 more |
| W9 | **Il Mazzo dei Tarocchi** | Tarocchi appear **2×** as often in the shop | **Bottega dell'Arcano** | **4×** |
| W10 | **La Mappa Celeste** | Signs appear **2×** as often in the shop | **L'Atlante Celeste** | **4×** |
| W11 | **Il Salvadanaio** (piggy bank) | Interest cap **10** | **Banca di San Giorgio** | Interest cap **20** |
| W12 | **Il Foglio Bianco** | **Does nothing.** A blank page, a fool's purchase… | **L'Inchiostro Nero** | **+1 Jester slot** |
| W13 | **Il Mazzo del Prestigiatore** | **Playing cards** can appear in the shop | **Il Gran Trucco** | Those cards come enhanced, sealed or shining |
| W14 | **La Clessidra** (hourglass) | Go **back 1 town**; **−1 hand** each show | **La Meridiana** (sundial) | Back **1 more** town; **−1 discard** each show |
| W15 | **Il Ricatto** (blackmail) | Once per town, pay **10 ducats** to swap the Patron | **La Corruzione** | Swap as often as you like (10 each) |
| W16 | **Il Pennello** (paintbrush) | **+1 card** in hand | **La Tavolozza** (palette) | +1 more |

Interest caps don't stack: Il Salvadanaio's 10 replaces the base 5, and Il Notaio
(batch 3) adds +5 on top of whichever is active.

## C. Booster packs

- **Shop:** 2 packs on offer in every shop.
- **Opening:** pick from the cards shown; you can always skip.
- **Targets:** in Tarocchi and Omen packs you're dealt **8 cards from your deck** to use
  them on.

| Pack | Contents | Small | Big | Grand | Shop weight |
|---|---|---|---|---|---|
| **Tarocchi Pack** | Tarocchi | 3, pick 1 | 5, pick 1 | 5, pick 2 | 4 |
| **Sign Pack** | Signs | 3, pick 1 | 5, pick 1 | 5, pick 2 | 4 |
| **Card Pack** | Playing cards, some enhanced, sealed or shining; added to your deck | 3, pick 1 | 5, pick 1 | 5, pick 2 | 4 |
| **Jester Pack** | Jesters (shop odds) | 2, pick 1 | 4, pick 1 | 4, pick 2 | 1.2 |
| **Omen Pack** | Omens | 2, pick 1 | 4, pick 1 | 4, pick 2 | 0.6 |

- **Prices:** Small **4**, Big **6**, Grand **8** ducats.
- **Size odds:** Small 4, Big 2, Grand 0.5. Big packs are common, Grand ones rare.
- **The two rarest Omens:**
  - **La Maschera Divina** can appear in Tarocchi and Omen packs (0.3% per card).
  - **L'Eclissi** can appear in Sign and Omen packs (0.3% per card).

## Balance notes

- **Omens are the run-changers:** big gains with a price attached (lost cards, halved
  ducats, a smaller hand, a destroyed troupe). Il Sosia and Il Malocchio are the classic
  late-game gamble: bet everything on one Jester.
- **Warrant ladders:**
  - Il Foglio Bianco is the joke card: a Warrant that does nothing, bought only to
    unlock L'Inchiostro Nero (+1 Jester slot). It fits a game called *Deck of Fools*.
  - La Clessidra trades power for time: an easier town for a weaker show.
- **Packs:** most of the game's deck-building happens here. Card Packs are the main way
  to get enhanced cards without Tarocchi.

## Engine notes (for me, not decisions)

New engine pieces this batch needs:
- **Pack opening:** a new action phase where packs open and deal the 8 target cards.
- **Warrant slot:** in the shop, with its upgrade gating.
- **Shop rules:** percentage discounts, edition and kind multipliers, playing cards in
  the shop.
- **Il Ricatto's Patron swap:** a new action.
- **La Clessidra:** moves the town back without breaking the run's history.

## Next batches

| Batch | Contents |
|---|---|
| 10 | 28 Patrons + 24 Favors |
| 11 | 15 decks + 8 stakes + 20 challenges + unlock rules |

After batch 11 every card in the spec exists. Then M2 (the playable screen) can start
with real content.
