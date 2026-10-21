# Card batch 10: 28 Patrons + 24 Favors

Status: **approved 2026-10-21 as written, coded and tested.** Code: game/content/patron_cards.gd,
favor_cards.gd; tests: game/tests/test_batch_10.gd.

## A. Patrons (28): the nobles who pay for the third show of every town

- **Each town** has one Patron: a noble with a **whim** that bends the rules for that
  show.
- **Town 8** always has one of the 5 **finale** Patrons.
- **Show pays:** 5 ducats; finale Patrons pay 8.
- **Unless the table says otherwise,** the target is ×2 the town's base.
- **"Debuffed"** cards score nothing and trigger nothing.
- **"Face down"** cards play normally; you just can't see them until they're played.
- **From town:** harsher Patrons appear only from a later town onwards.

### Regular Patrons (23)

| # | Patron | Who | Whim | From town |
|---|---|---|---|---|
| P1 | **Il Censore** | The censor: no royalty on stage | All **face cards** are debuffed | 1 |
| P2 | **La Badessa** | The abbess | All **Hearts** are debuffed | 1 |
| P3 | **Il Banchiere** | The banker | All **Diamonds** are debuffed | 1 |
| P4 | **Il Capitano di Giustizia** | The chief of the guard | All **Spades** are debuffed | 1 |
| P5 | **Il Guardacaccia** | The gamekeeper | All **Clubs** are debuffed | 1 |
| P6 | **Il Critico** | The theatre critic | You **can't play the same poker hand twice** this show | 1 |
| P7 | **Il Purista** | The purist | Only **one kind** of poker hand allowed: whichever you play first | 2 |
| P8 | **Il Gabelliere** | The tax collector | **−1 ducat** for each card you play | 2 |
| P9 | **L'Avaro** | The miserly count | Playing your **most played hand** sets your ducats to **0** | 6 |
| P10 | **La Fortezza** | The lady of the fortress | Target is **×4** instead of ×2 | 2 |
| P11 | **Lo Spione** | The spy | 1 card in 7 is dealt **face down** | 2 |
| P12 | **La Maschera Grigia** | The grey mask | Your **first hand** is dealt **face down** | 2 |
| P13 | **Il Gioco al Buio** | Playing in the dark | After each hand, the cards you draw are **face down** | 2 |
| P14 | **Il Ciambellano** | The chamberlain, a stickler | You must play **exactly 5 cards** | 1 |
| P15 | **Il Priore** | The austere prior | You start with **0 discards** | 2 |
| P16 | **Il Maggiordomo** | The butler who tidies too much | **−1 card** in hand | 1 |
| P17 | **Il Borsaiolo** | The pickpocket | Each time you play, **2 random cards** in your hand are discarded | 1 |
| P18 | **Il Vescovo** | The bishop | Playing a hand **lowers its level** by 1 | 2 |
| P19 | **Il Duca** | The bored duke | Base Points and Mult of every hand are **halved** | 2 |
| P20 | **Il Siniscalco** | The steward who remembers everything | Cards **already played this town** are debuffed | 1 |
| P21 | **L'Impaziente** | The impatient one | After every play or discard you draw exactly **3 cards**, no more | 3 |
| P22 | **Il Marchese** | The marquis | **Face cards** are dealt **face down** | 2 |
| P23 | **La Contessa** | The countess, easily bored | You get **only 1 hand**, but the target is **×1** | 2 |

### Finale Patrons (5): town 8 only

| # | Patron | Who | Whim |
|---|---|---|---|
| P24 | **Il Granduca** | The grand duke | Target is **×6** |
| P25 | **La Granduchessa** | The grand duchess | Each hand, **one random Jester stops working** |
| P26 | **L'Inquisitore** | The inquisitor | **Every card is debuffed** until you sell a Jester |
| P27 | **Il Cardinale** | The cardinal | When the show starts, your Jesters are turned **face down and shuffled** |
| P28 | **La Regina** | The queen | One card in your hand is **always selected**: you must play or discard it |

## B. Favors (24): what you get for skipping a show

- **When you get one:** when you skip a matinee or an evening show, you take that
  show's **Favor**. Both are shown before you choose.
- **When they apply:**
  - "Next shop" Favors wait for the next shop.
  - "Next Patron" ones wait for the next Patron you beat.
  - The rest act at once.

| # | Favor | Who gives it | Effect |
|---|---|---|---|
| F1 | **La Raccomandazione** | A letter of recommendation | The next shop has a **free uncommon Jester** |
| F2 | **La Lettera del Principe** | The prince's letter | The next shop has a **free rare Jester** |
| F3 | **Il Velo Nero** | The black veil | The next plain Jester in the shop becomes **Shadow** (free) |
| F4 | **Il Filo d'Argento** | The silver thread | The next plain Jester in the shop becomes **Silvered** (free) |
| F5 | **La Perla** | The pearl | The next plain Jester in the shop becomes **Opaline** (free) |
| F6 | **Il Caleidoscopio** | The kaleidoscope | The next plain Jester in the shop becomes **Prismatic** (free) |
| F7 | **La Dote** | The dowry | **+25 ducats** after you beat the next Patron |
| F8 | **Il Sigillo Reale** | The royal seal | The next shop offers an **extra Warrant** |
| F9 | **Il Lasciapassare** | The pass | **Swap this town's Patron** for free |
| F10 | **Il Biglietto Omaggio** | The free ticket | A free **Grand Card Pack** |
| F11 | **Il Mazzo Incantato** | The enchanted deck | A free **Grand Tarocchi Pack** |
| F12 | **La Stella Cadente** | The shooting star | A free **Grand Sign Pack** |
| F13 | **L'Invito** | The invitation | A free **Grand Jester Pack** |
| F14 | **La Visione** | The vision | A free **Omen Pack** |
| F15 | **La Mancia** | The tip | **+1 ducat** for each hand you've played this run |
| F16 | **Lo Straccio** | The rag | **+1 ducat** for each discard you **didn't use** this run |
| F17 | **Il Buono** | The coupon | In the next shop, the **first cards and packs are free** |
| F18 | **Il Gemello** | The twin | **Copies** the next Favor you get |
| F19 | **Il Bagaglio** | The luggage | **+3 cards** in hand for the next show |
| F20 | **Il Rimpasto** | The reshuffle | Rerolls start at **0** in the next shop |
| F21 | **Il Rinforzo** | The reinforcements | Create up to **2 common Jesters** (if there's room) |
| F22 | **La Fretta** | Haste | **+5 ducats** for each show you've skipped this run |
| F23 | **L'Oroscopo** | The horoscope | A poker hand (named when offered) gains **3 levels** |
| F24 | **Il Raddoppio** | The doubling | **Double your ducats** (max +40) |

## Balance notes

- **Patron difficulty:**
  - **Town 1:** the suit and face-card Patrons are fair (you can play around them).
  - **Town 2 on:** rule-benders like Il Critico and Il Purista.
  - **Town 6 on:** L'Avaro (ducats to 0) is the cruellest.
- **Finales:** each tests a different build.
  - **Il Granduca:** raw power.
  - **La Granduchessa:** depth beyond one key Jester.
  - **L'Inquisitore:** willingness to sell.
  - **Il Cardinale:** order-dependent combos (Arlecchino, Il Burattinaio).
  - **La Regina:** hand flexibility.
- **Your answers to a Patron:** batch 5's La Nebbia mutes all Patrons. Il Buttafuori
  (batch 8) mutes one by being sold. Il Ricatto (batch 9) swaps them.
- **Favors make skipping worth it:**
  - **Strongest:** La Lettera del Principe (a free rare), the Grand pack Favors, and
    L'Oroscopo (+3 levels).
  - **Weakest:** La Mancia and Lo Straccio early, though they grow late.

## Engine notes (for me, not decisions)

New engine pieces this batch needs:
- **Face-down cards:** a flag the screen uses to hide a card.
- **Play rules:** exact card counts, repeat-hand and one-type limits.
- **Patron state across a town:** e.g. cards already played this town.
- **Pending Favors:** they wait for "next shop" or "next Patron".
- **Free shop items.**

## Next batch

| Batch | Contents |
|---|---|
| 11 | 15 decks + 8 stakes + 20 challenges + unlock rules |

Batch 11 is the last content batch. After it, M2 (the playable screen) can start.
