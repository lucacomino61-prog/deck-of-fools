# Card batch 11: 15 decks, 8 stakes, 20 challenges, unlock rules

Status: **approved 2026-10-21 as written, coded and tested** (269 tests pass). Code:
game/content/deck_cards.gd, stake_cards.gd, challenge_cards.gd, unlocks.gd and
game/core/profile.gd; tests: game/tests/test_batch_11.gd. Every card in the spec now exists.

## A. Decks (15): one for each city of the commedia

- **What a deck sets:** your starting cards and one rule for the whole run.
- **Unlocking:** you start with only **Bergamo**, Arlecchino's home town. The rest
  unlock as shown.

| # | Deck | Rule | Unlock |
|---|---|---|---|
| D1 | **Bergamo** | +1 discard each show | From the start |
| D2 | **Venezia** | +1 hand each show | Discover 20 cards in the collection |
| D3 | **Genova** (the bankers' city) | Start with +10 ducats | Discover 40 cards |
| D4 | **Siena** | No interest; at cash-out +2 per unused hand and +1 per unused discard | Discover 60 cards |
| D5 | **Napoli** (Pulcinella's black mask) | +1 Jester slot, −1 hand each show | Discover 80 cards |
| D6 | **Palermo** (the puppet theatre) | Start with the **Il Baule** Warrant and 2 **Il Matto** Tarocchi | Win with Bergamo |
| D7 | **Padova** (Galileo's telescope) | Start with the **Il Cannocchiale** Warrant; −1 consumable slot | Win with Venezia |
| D8 | **Benevento** (city of witches) | Omens can appear in the shop; start with **Il Malocchio** | Win with Genova |
| D9 | **Verona** (the lovers' city) | **No face cards**: a 40-card deck | Win with Siena |
| D10 | **Ferrara** (the chequered castle floor) | 26 **Spades** and 26 **Hearts** only | Win with Napoli |
| D11 | **Bologna** (the learned doctors) | Start with **Il Mazzo dei Tarocchi**, **La Mappa Celeste** and **Licenza di Bottega** | Win with Palermo |
| D12 | **Firenze** (the painters) | **+2 cards** in hand, −1 Jester slot | Win with Padova |
| D13 | **Roma** (the eternal city) | After each Patron you beat, gain **Il Gemello** | Win with Benevento |
| D14 | **Mantova** (the Gonzaga court) | Before each total, **Points and Mult are evened out** (both become their average); targets ×2 | Win with Verona |
| D15 | **Carnevale** | Every card starts with a **random rank and suit** | Win with Ferrara |

## B. Stakes (8): from the cheap seats to the royal box

- **Unlocking:** a stake is unlocked **per deck** by winning that deck on the stake below.
- **Stacking:** each stake keeps every rule of the ones before it.
- **Reward:** winning gives every Jester you finished with a **badge** in that stake's
  colour, shown in the collection.

| # | Stake | Adds |
|---|---|---|
| S1 | **Platea** (the stalls) | The normal game |
| S2 | **Galleria** (the gallery) | The **matinee pays nothing** |
| S3 | **Palco** (a box) | Targets grow **faster** (the second target row) |
| S4 | **Palco d'Onore** (box of honour) | Shop Jesters may be **Eternal**: can't be sold or destroyed |
| S5 | **Palco Reale** (royal box) | **−1 discard** each show |
| S6 | **Proscenio** (the forestage) | Targets grow **faster still** (the third row) |
| S7 | **Ribalta** (the footlights) | Shop Jesters may be **Perishable**: they stop working after 5 shows |
| S8 | **Sipario d'Oro** (the golden curtain) | Shop Jesters may be **Rented**: 1 ducat to buy, −3 ducats at every cash-out |

**Sticker odds:** from stake 4, each shop Jester has a 30% chance of a sticker; from
stake 7, Eternal and Perishable split it; from stake 8, Rented adds its own 30%. A Jester
can't be both Eternal and Perishable.

## C. Challenges (20): fixed runs with a twist

- **Set-up:** each challenge fixes the deck, the starting cards and one or two rules.
- **Unlocking:** **5 challenges unlock with each of your first four wins** (C1–5, then
  C6–10, C11–15, C16–20).

| # | Challenge | Rules |
|---|---|---|
| C1 | **Il Monologo** | Only **1 Jester slot**; start with an Eternal **La Prima Donna** |
| C2 | **Tutti Fuori** | **No Jesters** at all; +1 hand and +1 discard each show |
| C3 | **La Compagnia Povera** | Start with **0 ducats**; **no interest**; +1 hand |
| C4 | **Il Carnevale Eterno** | Every card in your deck is **Motley** |
| C5 | **Il Vetro Fragile** | Every card is **Mirror**, and Mirror cards shatter **1 in 2** |
| C6 | **Il Teatro di Marmo** | **26 random cards** start as **Marble** |
| C7 | **Cinque Carte** | **5 cards** in hand, and every hand must be **exactly 5 cards** |
| C8 | **La Tassa sul Lusso** | **−1 card in hand** for every 5 ducats you hold |
| C9 | **L'Inflazione** | Every purchase raises shop prices by **1** for the rest of the run |
| C10 | **L'Ultima Replica** | **1 hand and 6 discards** each show |
| C11 | **Solo Patroni** | **Every show** is a Patron show |
| C12 | **Il Divieto** | **Flushes and Straights** score nothing |
| C13 | **La Fame** | Every Jester is **Perishable** |
| C14 | **Il Contratto Eterno** | Every Jester is **Eternal** |
| C15 | **Il Noleggio** | Every Jester is **Rented** |
| C16 | **Il Grande Salto** | Every hand starts at **level 3**; −1 hand; **Signs never appear** |
| C17 | **La Bancarotta** | Start **20 ducats in debt** (you may owe up to 20) |
| C18 | **La Notte Bianca** | Every card is dealt **face down** |
| C19 | **Il Mazzo Doppio** | Your deck is **26 random cards, twice each** |
| C20 | **Il Gran Finale** | Start at **town 5** with **3 random rare Jesters** and 50 ducats |

## D. Unlocking Jesters

- **Unlocked from the first run:** all **61 commons** and **62 uncommons**, so the early
  game is full.
- **Rares:** the **22 rares** each unlock with a feat that matches what they do.
- **Legendaries:** the **5 legendaries** are never locked, only rare. They appear in the
  collection once La Maschera Divina has given you each one.

| Rare | Unlock feat |
|---|---|
| Il Burattinaio | Own 5 Jesters at once |
| Il Mattacino | Win a show with Il Burattinaio |
| Il Re dei Folli | Win a run |
| La Compagnia | Own 6 Jesters at once |
| Il Capriccio | Play every non-secret poker hand in one run |
| La Maschera d'Oro | Hold 50 ducats at once |
| L'Orologio | Beat 8 Patrons in one run |
| Il Notturno | Beat a Patron with your first hand |
| I Gemelli | Play a hand with two identical cards |
| Il Gioco delle Parti | Score a hand with over 1,000 Points before Mult |
| Il Pittore | Play a Flush |
| Il Gran Ballo | Play a Straight Flush |
| Il Teatro Olimpico | Win a show with your last hand |
| La Nebbia | Lose a run to a Patron |
| La Fenice | Lose 5 runs |
| Il Banditore | Use 20 Signs in one run |
| Il Maestro di Cappella | Get a poker hand to level 5 |
| Il Carnevale | Have 10 enhanced cards in your deck |
| Il Prestigiatore | Own 3 cards with editions at once |
| Il Doge | Earn 10 interest in one cash-out |
| La Cometa | Use 50 Signs in total |
| La Prima Donna | Win a show with only 1 Jester |

## Balance notes

- **Starting choices:** the first five decks are simple stat changes that teach the
  game. Later decks change how you play: Verona (no faces), Ferrara (two suits, Flushes
  everywhere), Mantova (balance both sides of the score), Carnevale (chaos).
- **Stakes:** they tighten money (Galleria, Sipario d'Oro), time (Palco Reale) and the
  target curve (Palco, Proscenio). The sticker stakes make every shop Jester a decision.
- **Challenges:** each one forces a build the shop rarely hands you: lone star, no
  Jesters, all-Motley, all-Mirror. They make good daily runs later.
- **Locked rares:** every feat happens through normal play, and most within the first
  few runs.

## Engine notes (for me, not decisions)

- **New engine pieces:**
  - Stake rules (reward, targets, discards).
  - Jester stickers: Eternal, Perishable and Rented.
  - Challenge set-up.
  - Deck building (no faces, two suits, random cards).
  - Mantova's balancing.
- **Profile work (M6):** unlocks, discovery counts and stake badges live in the player's
  profile, which cloud saves sync. The rules core only reports the events (wins,
  hands played…); a small profile layer turns them into unlocks.

## After this batch

Every card in the spec will exist. Next comes **M2: the playable screen**, with real
content from the start.
