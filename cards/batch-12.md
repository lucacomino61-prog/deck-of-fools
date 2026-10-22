# Batch 12: what makes Deck of Fools its own game, group 1 (gameplay)

Status: **approved 2026-10-22 as written, then coded and tested the same day** (304 rules
tests, the fuzz bot, UI smoke). His answers to the questions at the end: Scenarios are
chosen each show (Perform or Improvise); every run ends in Venezia; Maestro fame and wagon
perks are off in daily, weekly, duel and ranked runs.

Code: game/content/scenario_cards.gd, city_cards.gd, lazzi_cards.gd, game/core/route_map.gd,
RunState (the tour; phases MAP and ENCORE; actions travel, encore, bow, merge), ui/map_view.gd,
ui/theatre_box.gd and the run screen. Tests: game/tests/test_batch_12.gd. The tour is on for
every run with a city deck (all 15 real decks), so normal play always has it.

**Changes made while coding** (small, to fit the game's own names and rules):
- Cities: Napoli turns cards to **Marble** and Amalfi doubles **Gilt** cards (the game's
  names for Stone and Gold). Bologna became "each discard grows your hand by 1 card for the
  show (up to +2)", because "draws 1 extra card" did nothing once the hand refilled.
- Duos follow one rule (about 1.5×, rounded), so a few numbers differ from the table:
  I Vecchi gains +1.5 Mult per purchase; Primo e Secondo Zanni pays +1.5 per unused discard;
  Le Lacrime di Pierrot is +4.5 Mult per hand and per card; La Locandiera's Diamond chance
  pays +5. Tristano Martinelli now gives one ×1.5 per Jester to his left (the same total on
  his own), so a duo grows each one.
- The map's route loops: out from home towards the far side of Italy, then back up to
  Venezia (a straight line from a northern home crowded the north).
- Found by the fuzz bot: the Warrant La Clessidra sends the town number back, so the map
  keeps its own row; and selling Il Carro di Tespi while every one-use slot was full left a
  card without a slot, so that sale now waits until a one-use card is used or sold.

On 2026-10-22 Luca picked all 16 ideas for making the game more its own (SPEC.md §10) and
chose to build them in four groups, gameplay first, playing each group before the next. This
batch is group 1:

- **A. Scenarios:** risky three-beat scripts on every show.
- **B. The Map of Italy:** a branching route through real cities.
- **C. Lazzi:** classic duos that merge into one card.
- **D. The theatre boxes:** a live audience, crowd mood, and the Encore ("Bis!").

Numbers are first guesses; the fuzz bot and Luca's play will tune them.

## A. Scenarios: risky scripts on every show (Luca chose "Risky scripts")

Commedia troupes played without a written text. Backstage hung the *scenario*, the outline
of what had to happen, and the actors improvised around it. Here each show has one.

**Name.** The Jester **Il Canovaccio** already exists, so the scripts are called
**Scenarios** (Italian *scenario*, the word Flaminio Scala used for his 50 plots).

- **What you see:** every show (Matinee, Evening and Patron) shows its Scenario on the
  choose-show screen: a name and three beats, e.g. *a Pair → a Flush → a Full House*.
- **Taking it on:** you choose **Perform** or **Improvise** before the show starts.
  Improvising plays the show as today, with no reward and no risk.
- **Performing:** your next three hands must hit the beats in order, one beat per hand.
  Discards don't count. A beat is met when the played hand *contains* it, so a Full House
  meets "a Pair".
- **Rewards:**
  - **Beat 1:** +3 ducats at cash-out.
  - **Beat 2:** that hand gets **×2 Mult**.
  - **Beat 3 (the finale):** that hand gets **×3 Mult** and +5 ducats.
- **Fiasco:** a hand that misses its beat ends the Scenario. That hand scores **half**,
  the crowd loses 3 mood (D), and the rest of the show is played normally.
- **Difficulty:** Scenarios come in three tiers by town.

| # | Scenario | Beat 1 | Beat 2 | Beat 3 | Tier |
|---|---|---|---|---|---|
| S1 | **Il Servitore di Due Padroni** | a Pair | a Pair | Two Pair | 1 (towns 1–3) |
| S2 | **Le Burle di Arlecchino** | a single card | a Pair | Three of a Kind | 1 |
| S3 | **La Serenata** | a Heart | a Queen | Two Pair | 1 |
| S4 | **Il Dottore Pedante** | exactly 5 cards | a Pair | a Straight | 1 |
| S5 | **La Cena di Pantalone** | no face cards | a Pair | Two Pair | 1 |
| S6 | **Il Capitano Spaccone** | a face card | a face card | Three of a Kind | 1 |
| S7 | **La Fiera di Bergamo** | exactly 2 cards | exactly 3 cards | exactly 4 cards | 1 |
| S8 | **Il Ritorno di Flavio** | High Card | a Pair | Three of a Kind | 1 |
| S9 | **La Pazzia d'Isabella** | Three of a Kind | a single card | a Straight | 2 (towns 4–6) |
| S10 | **Il Finto Principe** | a King | Two Pair | a Flush | 2 |
| S11 | **La Locandiera** | a Pair | a Flush | a Pair | 2 |
| S12 | **Il Marito Geloso** | Two Pair | a Straight | Two Pair | 2 |
| S13 | **Pulcinella Mago** | a Spade | a Flush | a Straight | 2 |
| S14 | **Il Ladro Gentiluomo** | only Diamonds | only Diamonds | a Flush | 2 |
| S15 | **Gli Amori di Lelio** | only Hearts | a Pair | a Flush | 2 |
| S16 | **Il Naufragio** | a Straight | Three of a Kind | a Straight | 2 |
| S17 | **L'Amore delle Tre Melarance** | Three of a Kind | Three of a Kind | a Full House | 3 (towns 7–8, endless) |
| S18 | **Il Re Cervo** | a Flush | a Full House | a Flush | 3 |
| S19 | **Turandot** | a Straight | a Flush | a Full House | 3 |
| S20 | **L'Amore delle Maschere** | a Full House | Two Pair | Four of a Kind | 3 |
| S21 | **La Gran Commedia** | 5 cards, ⅓ of the target | 5 cards, ⅓ of the target | 5 cards, ⅓ of the target | 3 |
| S22 | **Il Mondo alla Rovescia** | High Card | High Card | a hand worth ¼ of the target | 3 |
| S23 | **Il Carnevale di Venezia** | a Flush | a Straight | a Full House | 3 |
| S24 | **La Commedia Finale** | Two Pair | a Full House | Four of a Kind | 3 |

## B. The Map of Italy: a branching route (Luca chose "Branching route")

- **The map:** each run draws a route of **8 rows**.
  - Row 1 is your deck's home city (the Bergamo deck starts in Bergamo).
  - Rows 2–7 hold 3 cities each, drawn from the 24 below and placed roughly where they
    are in Italy. Each city has roads to 1–2 cities in the next row.
  - Row 8 is always **Venezia**, the Carnevale finale, where the five finale Patrons wait.
    The Venezia deck starts and ends at home.
- **Choosing:** the map opens at the start and after each Patron; tap the next city. You
  see each city's twist before you choose.
- **Twists:** a city's twist applies to all three shows there. Its shop leans towards
  certain cards.
- **Seeds:** seeded, daily and weekly runs draw the same map for everyone.
- **Endless:** after Venezia the road goes on with new rows drawn from all 24 cities.
- **The wagon:** your wagon (group 2) rolls along the roads.

| # | City | Twist (all three shows) | Shop leans to |
|---|---|---|---|
| C1 | **Bergamo** | Home crowd: +1 hand each show | Jesters |
| C2 | **Milano** (La Scala) | Targets ×1.25, every show pays +3 ducats | Packs −1 ducat |
| C3 | **Torino** (the royal court) | The Patron here pays double | Tarocchi |
| C4 | **Genova** (the port) | Cards sell for double | Packs −1 ducat |
| C5 | **Venezia** (finale) | Carnevale: every Jester starts each show masked (face down) until it first fires | Editions ×2 |
| C6 | **Padova** (the university) | Signs level a hand twice | Signs |
| C7 | **Verona** (the lovers) | Each scored Heart: +3 Mult | Heart cards in packs |
| C8 | **Mantova** (the Gonzaga court) | The first hand of each show ×2, the last hand ×0.5 | Rare Jesters |
| C9 | **Ferrara** (the chequered floor) | Hands that alternate red and black cards: ×1.5 Mult | Playing-card packs |
| C10 | **Bologna** (the doctors) | Each discard draws 1 extra card | Tarocchi |
| C11 | **Firenze** (the painters) | Face cards: +10 Points | Enhanced cards |
| C12 | **Siena** (the Palio) | The first hand to reach half the target pays +5 ducats | Rerolls −1 ducat |
| C13 | **Pisa** (the leaning tower) | Straights may skip one rank | Jesters |
| C14 | **Lucca** (the walls) | −1 discard, +1 hand | Warrants −2 ducats |
| C15 | **Roma** (the Colosseum) | The Patron's target ×1.5, but it pays triple | Rare Jesters ×2 |
| C16 | **Napoli** (Vesuvius) | After your 2nd hand each show, 2 random cards in your draw pile turn to Stone | Omen packs |
| C17 | **Palermo** (the puppet theatre) | Jesters fire right to left | Jester packs |
| C18 | **Benevento** (the witches) | Omens can appear in the shop | Omens |
| C19 | **Bari** (the sea) | +1 card in hand | Signs |
| C20 | **Amalfi** (the lemon groves) | Gold cards pay double | Enhanced cards |
| C21 | **Parma** (Teatro Regio) | Each scored number card: +5 Points | Playing-card packs |
| C22 | **Urbino** (the ideal city) | Hands of exactly 5 cards: ×1.5 Mult | Warrants −2 ducats |
| C23 | **Trieste** (the bora wind) | After each discard, 1 random card in hand blows away too | Rerolls −1 ducat |
| C24 | **Messina** (Scylla and Charybdis) | On arrival you choose: −1 hand each show, or targets ×1.25 | Omens |

## C. Lazzi: classic duos that merge (Luca chose "Duos merge")

A *lazzo* was a rehearsed comic routine two masks could drop into any scenario.

- **Merging:** when you own both Jesters of a duo, a **Merge** button appears on either of
  them in the shop. Merging is free.
- **The duo card:** it takes **one slot** (the merge frees a slot), keeps **both effects,
  about 1.5× stronger**, and can't be split again.
  - Points, Mult and ducats ×1.5, rounded to round numbers.
  - ×Mult grows by half its bonus (×1.5 → ×1.75, ×2.5 → ×3.25).
  - Counts stay the same (retriggers, levels, slots); chances improve one step.
- **Selling:** a duo sells for the two prices together.
- **Art:** each duo gets its own painting of the pair (15 paintings: one day of the free
  generator).
- **Collection:** a new **Lazzi** tab.
- **Sharing:** a Jester can belong to two duos (Arlecchino has two), but merging uses it up.

| # | Duo | Jesters | Duo effect |
|---|---|---|---|
| L1 | **Arlecchino e Colombina** | Arlecchino + Colombina | +3 Mult for each Jester to its left; each scored Queen +25 Points, +5 Mult |
| L2 | **I Vecchi** | Pantalone + Il Dottore | Gains +2 Mult for good each time you buy in the shop; +70 Points if exactly 5 cards are played |
| L3 | **Isabella e Flavio** | Isabella + Flavio | Hand contains a Pair: +25 Points, +8 Mult; Two Pair: a further +30 Points, +9 Mult |
| L4 | **I Bravacci** | Il Capitano + Scaramuccia | +18 Mult on the first hand of each show; each scored Jack ×1.3 Mult |
| L5 | **Primo e Secondo Zanni** | Brighella + Truffaldino | At cash-out +2 ducats per unused discard; +6 ducats whenever you skip a show |
| L6 | **Napoli Nobilissima** | Pulcinella + Coviello | Each scored card of the first card's suit +3 Mult; hand contains a Straight: +90 Points, +6 Mult |
| L7 | **Le Lacrime di Pierrot** | Pedrolino + Il Pagliaccio | +5 Mult per hand already played this show; +5 Mult per card played |
| L8 | **La Sorpresa dell'Amore** | Lelio + Silvia | Each scored Mirror card ×1.75 Mult; each Heart held in hand +3 Mult |
| L9 | **La Vedova Scaltra** | Rosaura + Florindo | Full House: +75 Points, +12 Mult; Four of a Kind: +90 Points, +15 Mult |
| L10 | **Il Principe Tartaglia** | Tartaglia + Il Principe | Each scored 2, 3 or 4 +5 Mult; each scored King +25 Points, +3 Mult |
| L11 | **La Locandiera** | Mirandolina + Il Mercante | At cash-out +5 ducats; each scored Diamond: 1 in 2 chance of +3 ducats |
| L12 | **I Gelosi** (the real troupe) | Isabella Andreini + Flaminio Scala | Each scored Queen ×3.25 Mult; winning a show levels your most played hand |
| L13 | **La Rivalità** (Goldoni against Gozzi) | Carlo Goldoni + Carlo Gozzi | Every scored card scores one extra time; gains ×0.75 Mult per Sign used |
| L14 | **Il Teatro dei Burattini** | Il Burattinaio + Burattino | Copies the Jester to its right; +15 Points per Jester owned |
| L15 | **Il Primo Arlecchino** | Tristano Martinelli + Arlecchino | Each Jester to its left ×1.75 Mult and +3 Mult |

## D. The theatre boxes: audience, mood and the Encore

Luca chose **theatre boxes**, **bonus and penalty**, and an Encore **when the crowd
demands**.

- **The boxes:** two painted theatre boxes (*palchi*) at the edge of the show screen, each
  holding a few spectators. They react on their own:
  - Opera glasses go up for a big hand.
  - Fans wave on a good beat.
  - Roses fly on a standing ovation; tomatoes fly when the crowd turns.
  - Exact placement is settled with screenshots when it's built.
- **Art:** about 6 paintings (each box calm, cheering and booing).
- **Mood:** a meter from 0 to 10 beside the boxes. It starts each show at 5.

| What happened | Mood |
|---|---|
| A hand worth half the show's target or more | +3 |
| A hand worth a quarter or more | +2 |
| A hand worth a tenth or more | +1 |
| A weaker hand | −2 |
| A Scenario beat hit | +1 |
| A Fiasco (missed beat) | −3 |

- **At 10, standing ovation:** the next hand gets **×1.5 Mult**, then the meter drops to 7.
- **At 0, the crowd walks out:** −3 ducats at this show's cash-out, and a **heckler**
  appears (built with group 3: his tomato splats a card in hand, which scores half until
  played).
- **The Encore ("Bis!"):** win a show with mood **8 or more** and the crowd chants *Bis!*
  - **Perform:** play one more hand from your current hand (refilled), against **half the
    show's target**. Hit it and the show's **whole cash-out doubles**; miss it and you lose
    the show's base reward (3, 4 or 5 ducats).
  - **Bow out:** no risk, normal cash-out.

## Questions for Luca

1. **Scenarios: take one on, or always on?** Proposed: you choose Perform or Improvise
   each show. Alternative: always on, so every show is risky.
2. **Finale:** Venezia as the last town of every run (Carnevale), or any city?
3. **Fair play:** Maestro fame and wagon perks (group 2) are permanent power. Proposed:
   they're off in daily, weekly, duel and ranked runs, so leaderboards stay equal, and on
   everywhere else.
4. **The lists:** keep, change or cut any Scenario, city or duo above.
