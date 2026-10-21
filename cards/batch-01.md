# Card batch 1: poker hands, the 12 Signs, 20 common zanni

Status: **approved 2026-10-21, coded and tested.** Code: game/content/sign_cards.gd and
zanni_batch_01.gd; tests: game/tests/test_batch_01.gd; card text: game/i18n/cards.csv.
The zodiac cards were called Stars here; batch 2 renamed them **Signs** so they aren't
confused with the Tarocchi La Stella.

## A. Poker hands and their Signs

The score is **Points × Mult**. Each hand starts at level 1. Using its Sign raises it one
level and adds the "per level" values. The base values are the genre's standard ones,
so the balance feels familiar.

| # | Hand | Base Points × Mult | Per Sign level | Sign (zodiac) | Why that sign |
|---|---|---|---|---|---|
| 1 | High Card | 5 × 1 | +10 / +1 | **Aries** | The first sign: one lone card |
| 2 | Pair | 10 × 2 | +15 / +1 | **Gemini** | The twins |
| 3 | Two Pair | 20 × 2 | +20 / +1 | **Pisces** | Two fish |
| 4 | Three of a Kind | 30 × 3 | +20 / +2 | **Taurus** | Solid, stubborn, heavy |
| 5 | Straight | 30 × 4 | +30 / +3 | **Sagittarius** | The arrow flies straight |
| 6 | Flush | 35 × 4 | +15 / +2 | **Aquarius** | Water flows all one way |
| 7 | Full House | 40 × 4 | +25 / +2 | **Cancer** | The crab carries its house |
| 8 | Four of a Kind | 60 × 7 | +30 / +3 | **Leo** | A pride of lions |
| 9 | Straight Flush | 100 × 8 | +40 / +4 | **Scorpio** | Rare and deadly |
| 10 | Five of a Kind ★ | 120 × 12 | +35 / +3 | **Virgo** | Five identical, untouched |
| 11 | Flush House ★ | 140 × 14 | +40 / +4 | **Capricorn** | Climbs the highest |
| 12 | Flush Five ★ | 160 × 16 | +50 / +3 | **Libra** | Perfect balance |

★ Secret hands: hidden in the hand list, and their Sign never appears, until you've
played that hand once.

All Signs cost **3 ducats** in the shop. Each has the same text: "Level up [hand]: +X Points,
+Y Mult."

## B. Zanni: 20 commons

All 20 are **common** and unlocked from the first run. Prices are in ducats; you sell for
half, rounded down, minimum 1.

### Plain and positional

| # | Zanni | Who | Effect | Cost |
|---|---|---|---|---|
| 1 | **Zanni** | The plain servant mask; the troupe's first face | +4 Mult | 2 |
| 2 | **Arlecchino** | Harlequin, the patchwork acrobat | +2 Mult for each zanni to his **left** | 4 |
| 3 | **Il Capitano** | The braggart soldier; loud at the start | +12 Mult on the **first hand** of each show | 4 |
| 4 | **Pedrolino** | The sad moon-faced clown | +3 Mult for each hand **already played** this show (+0, +3, +6, +9) | 4 |
| 5 | **Scapino** | The servant who always runs away | +4 Mult for each **discard used** this show | 4 |

### Hand shapes

| # | Zanni | Who | Effect | Cost |
|---|---|---|---|---|
| 6 | **Isabella** | The young lover | If the hand contains a **Pair**: +15 Points, +5 Mult | 3 |
| 7 | **Flavio** | Her lover, never apart | If the hand contains **Two Pair**: +20 Points, +6 Mult | 4 |
| 8 | **Gianduja** | Turin's cheerful wine-lover | If the hand contains **Three of a Kind**: +40 Points, +6 Mult | 4 |
| 9 | **Coviello** | The Neapolitan acrobat | If the hand contains a **Straight**: +60 Points, +4 Mult | 4 |
| 10 | **Stenterello** | The skinny Florentine | If the hand contains a **Flush**: +40 Points, +5 Mult | 4 |
| 11 | **Il Dottore** | The pedant doctor; wants everything complete | +45 Points if **exactly 5 cards** are played | 4 |

### Cards that score

| # | Zanni | Who | Effect | Cost |
|---|---|---|---|---|
| 12 | **Tartaglia** | The stutterer; repeats the small things | Each scored **2, 3 or 4**: +3 Mult | 4 |
| 13 | **Colombina** | The clever maid who runs the house | Each scored **Queen**: +15 Points, +3 Mult | 5 |
| 14 | **Pulcinella** | Naples' hook-nosed trickster | Each scored card **of the same suit as the first scored card**: +2 Mult | 5 |
| 15 | **Sandrone** | The patient peasant | Each scored **8, 9 or 10**: +12 Points | 3 |
| 16 | **Meneghino** | Milan's honest servant; no airs | +35 Points if **no face cards** scored | 3 |

### Money and growth

| # | Zanni | Who | Effect | Cost |
|---|---|---|---|---|
| 17 | **Brighella** | The scheming innkeeper | At cash-out: +1 ducat for each **discard you didn't use** | 5 |
| 18 | **Pantalone** | The miserly merchant | Gains **+1 Mult permanently** every time you buy something in the shop | 5 |
| 19 | **Truffaldino** | Servant of two masters | +4 ducats whenever you **skip** a show | 4 |
| 20 | **Mezzetino** | The troupe's musician | Each scored **7**: +1 ducat | 4 |

## Balance notes

- **Mix of roles:** flat Mult (1–5), hand-shape bonuses (6–11), card triggers (12–16) and
  money/scaling (17–20), so early shops already offer different builds.
- **No ×Mult in this batch:** ×Mult is what makes late towns beatable, and it belongs to
  uncommon and rare zanni (batches 3–6).
- **Order puzzles:** Arlecchino rewards going last. Pedrolino and Scapino reward a slower
  show (play late, or discard first). Il Capitano rewards one big opening hand. These pull
  against each other on purpose.
- **Strongest here:** Pulcinella with Flush builds (+10 Mult on a 5-card flush) and
  Pantalone in long runs. Both are priced 5.

## Next batches (proposed order)

| Batch | Contents |
|---|---|
| 2 | 22 Tarocchi + enhancements (8), editions (4), seals (4) |
| 3–4 | Uncommon zanni (~40 across two batches) |
| 5 | Rare zanni (~20) + 5 legendary |
| 6–7 | Remaining commons and uncommons up to ~150 |
| 8 | 18 Omens + 32 Warrants |
| 9 | 28 Patrons + 24 Favors |
| 10 | 15 decks + 8 stakes + 20 challenges |
