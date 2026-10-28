# Batch 14: more inside the gameplay

Status: **proposed 2026-10-22, waiting for Luca's review.** Nothing is coded. The open
questions are at the end; each has a proposed answer.

Luca asked "what can I add inside the gameplay" and picked ten features: four inside a show,
four between shows and on the road, and two from group 3 of the 16 ideas (SPEC.md §10). He
left the Critic's review for later.

| | Feature | Where |
|---|---|---|
| A | Crowd requests | in a show |
| B | Crescendo | in a show |
| C | Bets before a show | before a show |
| D | The Patron's second act | Patron shows |
| E | Road events | on the Map of Italy |
| F | Masks for Jesters | the Market, the troupe |
| G | Rival troupe shows | some Evening shows |
| H | Haggling | the Market |
| I | Jester voices | everywhere a Jester acts |
| J | Hecklers | in a show, when the crowd turns |

**Fair play:** all ten are rules of the game, not perks, so they're on in every mode (normal,
campaign, daily, seeded, challenges). Every random part (requests, events, the rival's hands,
hecklers, haggling) is drawn from the run's seed, so a daily or seeded run plays the same for
everyone.

**Balance:** Crescendo, bets, requests and masks add power. The fuzz bot will play thousands
of runs with them to check that targets still bite; if win rates jump, the numbers here move
before the targets do.

---

## A. Crowd requests (*le richieste del pubblico*)

The audience shouts what it wants to see. Answer it and they love you.

- **When:** in a Matinee or Evening show, after your first hand, there's a **3 in 5** chance a
  request comes up. At most one per show. Never in a Patron show (the Patron has the stage),
  never on the last hand.
- **How long:** you have your **next 2 hands** to answer it.
- **Answered:** **+2 mood** and **+3 ducats** (+5 for a hard request).
- **Missed:** **−1 mood**.
- **On screen:** a head in the audience pops up with a speech bubble ("Un Full! A Full
  House!"), and a chip under the goal bar shows the request and the hands left. When the
  selected cards would answer it, the chip lights up.
- Picked to fit the town: easy ones in towns 1 to 3, hard ones from town 4.

| Easy (+3 ducats) | Hard (+5 ducats) |
|---|---|
| A Pair of face cards | A Flush |
| Two Pair | A Straight |
| Three of a Kind | A Full House |
| Only red cards | Four of a Kind |
| Only black cards | Only face cards (3 or more) |
| A hand with an Ace | Exactly one card, worth a quarter of the target |
| Exactly 5 cards | A hand worth half the target |
| No discard before it | Every card in the hand scores |

## B. Crescendo

Like music, a show should build.

- Each hand of a **higher kind** than the hand before (in the poker hands order) adds a step
  of **Crescendo**: **+0.25× Mult** per step, up to 4 steps (**×2**).
- A hand of the **same** kind keeps the Crescendo where it is. A **lower** kind breaks it
  back to nothing.
- It starts at nothing in every show.
- **Example:** Pair, then Two Pair (×1.25), then a Straight (×1.5), then a Full House (×1.75).
- **On screen:** a hairpin *cresc.* mark grows beside the goal bar with the current ×; it
  shatters when broken. The music's drum layer swells with it.
- It's a new question on every hand: play the strong hand now, or save it for the climb?

## C. Bets before a show (*le scommesse*)

- In the show choice (before Play), a **Bet** button. Pick a stake and a promise:

| Promise | Pays |
|---|---|
| Win this show in **3 hands** or fewer | stake ×2 |
| Win it in **2 hands** or fewer | stake ×3 |
| Win it in **1 hand** | stake ×5 |

- **Stakes:** 3, 6 or 10 ducats (only what you have).
- Won: the payout joins the cash-out. Missed (more hands, or the show lost): the stake is gone.
- One bet per show. Patron shows too: the bravest bets are on the Patron.
- **On screen:** the bet sits as a ticket on the goal bar ("6 on 2 hands"); its hands count
  down beside it.

## D. The Patron's second act (*il secondo atto*)

Halfway to its target, a Patron answers back.

- When your show score passes **half the Patron's target**, the Patron stands up, says its
  second-act line, and **a second rule** comes in for the rest of the show: the rule of
  another Patron, called in for help (below).
- Beat a Patron after its second act: **+2 ducats**.
- La Contessa gives you a single hand, so she has no second act.
- **On screen:** the screen dims for a beat, the Patron's card flips to show both rules, the
  second Patron's crest joins it.

| Patron (its rule) | Calls in (second rule) | Second-act line |
|---|---|---|
| Il Censore (face cards debuffed) | Lo Spione (1 card in 7 face down) | I've hired someone to watch you. Closely. |
| La Badessa (Hearts debuffed) | Il Priore (no discards) | Confession is final. No taking anything back. |
| Il Banchiere (Diamonds debuffed) | Il Gabelliere (−1 ducat per card played) | Transaction fees now apply. |
| Il Capitano di Giustizia (Spades debuffed) | Il Guardacaccia (Clubs debuffed) | The Clubs were accomplices. Arrest them too. |
| Il Guardacaccia (Clubs debuffed) | Il Maggiordomo (−1 card in hand) | One less pocket to hide your loot in. |
| Il Critico (no hand twice) | Il Vescovo (each hand loses a level) | Every act worse than the last. As I predicted. |
| Il Purista (one kind of hand) | Il Ciambellano (exactly 5 cards) | And now: perfect form. Five cards. |
| Il Gabelliere (−1 ducat per card) | L'Avaro (favourite hand empties the purse) | The toll has a toll now. |
| L'Avaro (favourite hand empties the purse) | Il Banchiere (Diamonds debuffed) | Diamonds go in my vault. Where they belong. |
| La Fortezza (target ×4) | Il Duca (base halved) | Half of everything for the garrison. |
| Lo Spione (1 card in 7 face down) | Il Gioco al Buio (draws face down) | Let's see how you do in the dark. |
| La Maschera Grigia (first hand face down) | Il Marchese (face cards face down) | More masks. Everyone wears one now. |
| Il Gioco al Buio (draws face down) | Il Borsaiolo (2 cards stolen per play) | In the dark, pockets get lighter. |
| Il Marchese (face cards face down) | Il Censore (face cards debuffed) | Commoners only on this stage. |
| Il Ciambellano (exactly 5 cards) | Il Priore (no discards) | Protocol forbids second thoughts. |
| Il Priore (no discards) | La Badessa (Hearts debuffed) | The Abbess and I agree. No Hearts. |
| Il Maggiordomo (−1 card in hand) | L'Impaziente (draw exactly 3) | I've asked the staff to hurry you along, sir. |
| Il Borsaiolo (2 cards stolen per play) | Il Gabelliere (−1 ducat per card) | And a small fee for the inconvenience. |
| Il Vescovo (each hand loses a level) | Il Critico (no hand twice) | Do not repeat your sins. |
| Il Duca (base halved) | Il Banchiere (Diamonds debuffed) | The Duchy's treasury needs your Diamonds. |
| Il Siniscalco (cards played this town debuffed) | Il Vescovo (each hand loses a level) | Old tricks wear thin. So will you. |
| L'Impaziente (draw exactly 3) | Il Priore (no discards) | No time for discards! None! |
| La Contessa (one hand) | (none: she gave you one hand) | |
| Il Granduca (finale, target ×6) | La Regina (one card forced) | Her Majesty has a request. |
| La Granduchessa (finale, a Jester stops each hand) | Il Cardinale (Jesters shuffled face down) | Let's mix up your little troupe. |
| L'Inquisitore (finale, all debuffed until a sale) | Il Censore (face cards debuffed) | The tribunal bans the court cards. |
| Il Cardinale (finale, Jesters shuffled face down) | La Granduchessa (a Jester stops each hand) | One of them stays silent. You won't know which. |
| La Regina (finale, one card forced) | Il Marchese (face cards face down) | My court prefers to stay hidden. |
| Messer Grifone (campaign finale) | Il Banchiere (Diamonds debuffed) | I've bought your Diamonds. All of them. |

## E. Road events (*incontri per strada*)

The roads between cities get stories.

- When the route of the tour is drawn, **about 1 road in 3** gets an event (from the run's
  seed). The map marks those roads with a wax-seal "?" so you can choose to go for them or
  avoid them.
- Travelling a marked road opens the event before the next city: a painted card, two or three
  choices, an instant result. No event in town 8's road to Venezia.

| Event | Choices |
|---|---|
| **La Chiromante** (the palm reader) | Pay 4 ducats: a random Tarocchi. / Walk on. |
| **I Briganti** (bandits) | Pay 5 ducats. / Perform for them: if your troupe has 3+ Jesters they laugh and give you 4 ducats; if not, they take a random one-use card. |
| **La Sagra** (a village fair) | Buy one of 3 enhanced playing cards for 3 ducats each (it joins your deck). / Walk on. |
| **Un Giullare randagio** (a stray Jester) | A free common Jester joins (if you have a slot). / Leave him by the road. |
| **L'Osteria** (the tavern) | Drink: +1 hand, −1 discard in the next show. / Sleep: +1 discard in the next show. |
| **La Ruota Rotta** (a broken wheel) | Pay the smith 3 ducats. / Fix it yourselves: −1 hand in the next show. |
| **I Pellegrini** (pilgrims) | Give 2 ducats: the next show starts at mood 8. / Walk on. |
| **L'Ammiratore** (a rich admirer) | Take 6 ducats; the next show's target is +15%. / Decline politely. |
| **L'Edicola** (a roadside shrine) | Leave one playing card of your choice as an offering (it leaves the deck). / Walk on. |
| **Il Prestigiatore** (a street magician) | Pay 3 ducats: copy one playing card of your choice. / Walk on. |
| **Il Vecchio Attore** (the old actor) | Pay 5 ducats: +1 level to a poker hand of your choice. / Walk on. |
| **Le Nozze** (a wedding) | Play at the wedding: +3 ducats, the next show starts at mood 7. (only choice) |
| **La Lettera** (a Patron's letter) | Read it: see the Patrons waiting in the next two towns. (only choice) |
| **Il Traghetto** (the river ferry) | Pay 2 ducats. / Take the long way: −1 discard in the next show. |

## F. Masks for Jesters (*le maschere*)

A new kind of card: a mask you put on one of your Jesters.

- **Where:** the Market sometimes offers a mask in a one-use card's place (about 1 offer in
  6), and a new **Mask pack** (2 masks, pick 1) joins the packs.
- **Wearing:** tap a mask, then a Jester (or drag the mask onto it). One mask per Jester; a
  new one replaces the old. The mask is drawn on the Jester's card and goes wherever the
  Jester goes (into a duo too; sold with it).
- Masks don't take a slot; they're worn straight away.

| Mask | Price | What it does to the Jester wearing it |
|---|---|---|
| **Volto** (the plain white face) | 5 | Its effect ×2, for 3 shows; then the mask cracks and falls off. |
| **Moretta** (the silent black oval) | 6 | Its effect ×1.5, but it can't be sold or moved. |
| **Bauta** (the cloaked white mask) | 10 | It no longer takes a Jester slot. |
| **Gatto** (the cat) | 5 | +1 ducat each time it fires (up to 3 a hand). |
| **Medico della Peste** (the plague doctor) | 7 | Patron rules can't touch it (not silenced, not face down), and +3 Mult. |
| **Mezza Maschera** (Arlecchino's half mask) | 6 | It fires twice on the last hand of each show. |
| **Colombina** (the jewelled eye mask) | 5 | +1 crowd mood each hand it fires. |
| **Pantalone** (the hooked nose) | 4 | It sells for 3× its value. |
| **Zanni** (the long nose) | 5 | +25 Points each time it fires. |
| **Larva** (the paper ghost) | 10 | It copies the Jester to its left (its own effect is replaced). |

## G. Rival troupe shows (*la sfida*)

The great companies of the real commedia dell'arte were rivals. They're on tour too.

- From town 2, the **Evening show** of about **1 town in 4** is a *sfida* against a rival
  company instead of a fixed target: **I Gelosi, I Confidenti, I Desiosi, Gli Accesi, I
  Fedeli, Gli Uniti** (all real companies of the 1500s and 1600s).
- **How it plays:** after each of your hands, the rival plays one of its own and its total
  climbs on a second bar under yours. Its hands add up to about the show's normal target
  (from 90% to 110%, from the seed), dealt unevenly, some hands big, some small. You must be
  **ahead after your last hand**.
- **Run away with it:** be ahead by half again (150% of their total) at any hand and they
  leave the stage: you win at once.
- **Win:** the Evening reward +4 ducats, and **their star**: pick one of 2 Jesters they offer
  (common or uncommon), free if you have a slot.
- **Lose:** like any show (question 7).
- **On screen:** their company crest and name, their bar racing yours, their head of company
  speaking a line at the start and the end (6 companies × 3 lines).

## H. Haggling (*contrattare*)

- Once per Market visit, a **Haggle** button on a selected offer (a Jester, pack, Warrant or
  mask).

| Result | Chance | |
|---|---|---|
| A deal | 1 in 2 | Its price −2 ducats (never under 1). |
| No | 1 in 3 | Nothing changes. |
| Offended | 1 in 6 | Every price in this Market +1, rerolls too, until you leave. |

- Luck (the Lucky cards and Jesters) moves the odds toward a deal.
- The shopkeeper answers in a bubble ("Per voi? Va bene." / "Ma siete matti?").

## I. Jester voices (group 3)

- Every Jester gets its own **babbling voice**: synthesized Italian-sounding syllables (no
  real words spoken), pitch, speed and timbre from its design (Il Capitano booms, Colombina
  chirps, Pantalone wheezes).
- **When it speaks** (about half a second, with a speech bubble of one Italian word or two):
  when it fires big (a ×Mult, or a third of the hand's score or more), when you buy it
  ("Eccomi!"), when you sell it ("Addio!"), when it becomes a Maestro ("Maestro!").
- At most one voice at a time, and not more often than every 2 seconds, so a big hand isn't a
  choir.
- **Settings:** a Voices volume next to Music and Effects.
- Bubble words: *Bravo! Mamma mia! Che spettacolo! Andiamo! Ecco! Magnifico! Ahi! Avanti! Sì,
  sì! Evviva! Bellissimo! Forza! Ma dai! Perfetto! Ole! Attenzione! Che fortuna! Uffa! Ancora!
  Va bene!* and more, about 40.
- Made like the music: synthesized offline (tools/audio), about 30 syllables, no downloads.

## J. Hecklers (*i disturbatori*, group 3)

- When the crowd's mood falls to **2 or lower**, a heckler stands up in the audience (taller,
  lit red, shaking a fist).
- After your next hand, while the mood is still 2 or lower, they throw a **tomato**: it splats
  a random card in your hand, which is **debuffed for your next hand** (it scores nothing),
  then washes off.
- One heckler at a time. Bring the mood back to 4 and they sit down grumbling.
- With Reduce motion the tomato doesn't fly; the card just shows the splat.

---

## What gets built

- **Rules:** requests, Crescendo, bets, second acts, road events, masks, rival shows and
  haggling in RunState (new actions bet, haggle, wear_mask, event_choice), all seeded; the
  hecklers' tomato as a one-hand debuff.
- **Screens:** the request chip and audience bubble, the Crescendo hairpin, the bet ticket,
  the second-act moment, road event cards on the map, masks on Jester cards, the rival's bar,
  the Haggle button and the shopkeeper's bubble, the heckler and the tomato splat.
- **Sound:** about 30 synthesized voice syllables and a tomato splat.
- **Tests:** rules tests for each, the fuzz bot playing all of them, UI smoke for each screen.
- **Art (free generator, FLUX):** 14 road event pictures and 10 masks, about 24 pictures:
  one day's free allowance after tomorrow's scheduled run. Rival companies use crests drawn
  in code.

## Questions for Luca

| # | Question | Proposed |
|---|---|---|
| 1 | Crowd requests: how often? | 3 in 5 shows (not Patron shows) |
| 2 | Crescendo: how strong per step? | +0.25× per step, up to ×2 |
| 3 | Bets: stakes and payouts | 3/6/10 ducats; ×2 for 3 hands, ×3 for 2, ×5 for 1 |
| 4 | Patron second act: what happens at half the target? | a second Patron's rule joins (table D) |
| 5 | Road events: how many roads, and marked or a surprise? | 1 road in 3, marked "?" on the map |
| 6 | Masks: where do you get them? | the Market (1 offer in 6) and Mask packs |
| 7 | Rival troupe: what does losing do? | ends the run, like losing any show |
| 8 | Haggling odds | 1 in 2 deal (−2), 1 in 3 no, 1 in 6 offended (+1 on everything) |
| 9 | Hecklers: what does the tomato do? | debuffs one card for the next hand |
| 10 | The lists (requests, second acts, events, masks, companies, voice words) | keep as written |
