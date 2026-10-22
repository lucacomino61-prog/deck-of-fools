# Batch 13: what makes Deck of Fools its own game, group 2 (progression)

Status: **reviewed 2026-10-22, then coded and tested the same day** (Luca: "Build group 2 from
batch 13 as recorded, with the campaign difficulty climbing by stake 1 to 4"). He answered the
seven questions (listed at the end) and kept every list as written. The numbers below include
his answers: Maestro at 120 fame, Maestri 1.25×, the coin is scudi, each chapter is a full
8-town run, one Jester carries on, and the rematch is 1 in 5. Tests: 329 rules tests (25 in
game/tests/test_batch_13.gd), the fuzz bot playing runs with random Maestri, props, nemeses and
chapters, the UI smoke (Wagon, Campaign, a Maestro, a Patron speaking, a cleared chapter), the
online smoke and the server's 18 tests.

Code: content/fame.gd, wagon_cards.gd (props, cosmetics, scudi), campaign_cards.gd (chapters,
Messer Grifone); RunState `extras` (maestri, props, nemesis, chapter, carry, rivalry), fame,
beaten, rematch, patron_waiting(), action swap_scenario; Profile (fame, scudi, wagon, campaign,
nemesis, last_gains, extras_for, brings_extras); ui/wagon_sheet.gd, campaign_sheet.gd,
speech_bubble.gd, wagon_art.gd; the run screen (Maestro frames and stars, rival Patrons on the
show and the map, the wagon rolling, Patron lines, the end screen's gains and the chapter's end
with the Jester to carry); How to play page 3 "Between runs"; server migration 0002 (assisted
runs stay off the best-hand and town boards).

**Changes made while coding** (small, to fit the game's own rules):
- **Seeded runs earn no fame or scudi**, like their feats and wins (a known seed could be
  farmed). Daily runs, ranked or practice, do earn them.
- **A duo's fame goes to both its Jesters** (its events carry the duo's name, not each part's).
- **Leaderboards:** a run with Maestri in use, a prop, a campaign chapter or a carried Jester is
  sent as *assisted*: it counts in the player's own stats but not on the best-hand or town
  boards. A nemesis or a rematch doesn't make a run assisted (they only make it harder).
- **The wagon and its trims are drawn in code**, not painted, so a bought paint recolours the
  whole wagon and trims sit on it. The table cloth tints the show backdrop's swirl.
- **Paintings still to come:** Messer Grifone and the 7 card backs are code-drawn until the
  free generator paints them (briefs in tools/art/prompts.mjs PROGRESSION_ART; added to the
  scheduled run of 2026-10-23 with the tour art). No griffin figure: the story lines show on the
  Campaign sheet and the chapter's end screen.
- **La Lanterna** draws every city's Patron together with the map, so the map can show it.
- **Marks:** on the map a rematch is a red ribbon, the nemesis a black seal and a chapter's
  story Patron a gold crown over the city; on the show screen they're a gold line under the
  Patron ("Your nemesis! Beat it: +10 ducats") rather than a glove or seal drawn on its card.
- **Chapter rules that are a city's twist** apply that city's twist all tour, and the twist
  isn't added twice when the troupe reaches that city. La Bottega (Firenze) adds one enhanced
  playing card to every pack.
- **Chapter 1** loops out from Bergamo and back; **chapter 10** sets out from Napoli.
- **"The Wagon screen opens"** after chapter 1 means it opens once by itself, as an
  introduction; the Wagon is on the main menu from the start.
- **Profile extras** (Maestri, props, nemesis) come along to a run only when it starts: a
  Maestro reached mid-run plays as one from the next run.

Group 2 of the 16 ideas Luca picked (SPEC.md §10). His choices:

- **A. Jester fame:** permanent across runs. A Jester that reaches 3 stars becomes its
  **Maestro** version for good.
- **B. The troupe wagon:** spend between runs on all four: cosmetics, small starting perks,
  earlier unlocks, and the wagon rolling on the map.
- **C. The campaign:** a long tour of 15+ chapters, one per city.
- **D. Patron rivalry:** both kinds. A beaten Patron can come back later in the run, the one
  that beat you comes back next run as your **nemesis**, and every Patron gets lines.

**Fair play** (Luca's rule, 2026-10-22): Maestros, wagon perks and the nemesis are **on** in
normal runs and the campaign. They're **off** in daily, weekly, duel, ranked and seeded runs,
so a seed plays the same for everyone and leaderboards stay equal. Fame and scudi are still
*earned* in those runs (earning changes nothing in them).

Numbers are first guesses; the fuzz bot and Luca's play will tune them.

## A. Jester fame and the Maestri (Luca chose "Permanent across runs")

Commedia actors played one mask all their lives; the great ones were remembered by the mask's
name (Tristano Martinelli *was* Arlecchino). Here a Jester that keeps performing well earns
fame, and after enough of it, becomes a Maestro of its mask for good.

**Earning fame** (per Jester, kept in the profile):

| What happened | Fame |
|---|---|
| A show won while it's in your troupe **and it fired** at least once that show | +1 |
| It fired in a winning Encore hand | +1 more |
| It's in your troupe when you win the run (Venezia) | +3 |
| You beat your nemesis (D) with it in the troupe | +2 |

- A Jester inside a Lazzi duo earns fame for both of its members.
- A Jester bought in town 2 and kept to Venezia earns about 15–20 fame in a winning run.

**Stars:**

| Stars | Fame | Roughly (Luca chose 120 for a Maestro) |
|---|---|---|
| ★ | 25 | one or two good runs with it |
| ★★ | 60 | three or four |
| ★★★ = **Maestro** | 120 | seven or eight |

- Stars show in a corner of the card, in the long-press view (with a fame bar to the next
  star) and in the Collection. The Collection counts "Maestri: 7 of 150".
- The stake badges (the coloured seals for the highest stake won with a Jester) stay as
  they are; stars sit in the other corner.

**The Maestro version:**

- **Look:** a gold laurel frame, the name gains "Maestro" / "Maestra" (*Maestra Colombina*),
  and a small gold glow when it fires. Il Maestro di Cappella becomes *Il Gran Maestro di
  Cappella*.
- **Effect: about 1.25× stronger**, by the same rule as the duos (which are 1.5×):
  - Points, Mult and ducats ×1.25, rounded to round numbers (+4 Mult → +5, +30 Points → +40).
  - ×Mult grows by a quarter of its bonus (×1.5 → ×1.625, ×2 → ×2.25).
  - Chances improve a quarter (1 in 4 → about 1 in 3).
  - Counts stay the same (retriggers, levels, slots, copies). A Jester with nothing to scale
    (Il Burattinaio copies, slot-only Jesters) gets **+2 ducats at each cash-out** instead.
- **For good:** every copy of that Jester you meet in a normal run or the campaign is the
  Maestro. Same shop price, same sell value.
- **In a duo:** a duo is 1.5×; if **both** its Jesters are Maestri the duo is **1.75×**.

## B. The troupe wagon (Luca chose all four)

The troupe lives in a painted wagon, *il carrozzone* (not to be confused with the Jester *Il
Carro di Tespi*, which stays as it is). A **Wagon** button on the main menu opens it.

**Scudi**, a new coin earned at the end of every run, won or lost (ducats stay in-run only):

| What happened in the run | Scudi |
|---|---|
| Each show won | +1 |
| Each Scenario performed in full (all 3 beats) | +1 |
| Each Encore hit | +2 |
| Winning the run (Venezia) | +5, plus 1 per stake above 1 |
| A campaign chapter cleared the first time | its reward (C) |

A won run at stake 1 pays about 35–40 scudi; a run lost in town 4 about 10–12.

**1. Props: small starting perks.** One prop is carried at a time (a second slot costs 200).
Off in daily, weekly, duel, ranked and seeded runs.

| # | Prop | Effect | Scudi |
|---|---|---|---|
| P1 | **Il Salvadanaio** (the piggy bank) | Start each run with +2 ducats | 40 |
| P2 | **La Lanterna** | The map shows the Patron waiting in every city | 40 |
| P3 | **Il Copione Vecchio** (the old script) | +1 hand in the run's first show | 50 |
| P4 | **Il Baule dei Costumi** (costume trunk) | The first shop of the run offers +1 Jester | 50 |
| P5 | **La Claque** (paid applause) | Every show starts at mood 6 instead of 5 | 60 |
| P6 | **Il Suggeritore** (the prompter) | Once per town, swap the Scenario for another of the same tier | 60 |
| P7 | **La Cassetta degli Attrezzi** (toolbox) | Start with a random Tarocchi | 60 |
| P8 | **Il Mulo Testardo** (the stubborn mule) | The first reroll in each shop costs 1 ducat less | 70 |
| P9 | **La Bandiera** (the troupe flag) | +1 scudo for each Patron beaten | 80 |
| P10 | **Il Ritratto del Fondatore** (the founder's portrait) | Start with a random common Jester | 120 |

**2. Earlier unlocks.** Anything still locked can be bought instead of waiting for its rule:

| What | Scudi |
|---|---|
| A deck | 80 |
| A rare Jester (instead of its feat) | 50 |
| A challenge | 20 |

Stakes still unlock only by winning the stake below, as now.

**3. Cosmetics.**

| What | How many | Scudi each | Art |
|---|---|---|---|
| Wagon paints (Rosso Arlecchino, Verde Brighella, Bianco Pierrot, Nero Dottore, Azzurro Laguna, Oro Doge) | 6 | 20 (Oro Doge: campaign only) | tinted from one wagon painting |
| Wagon trims (lanterns, flags, an awning, bells) | 4 | 30 | small painted overlays |
| Table cloths for the show screen (felt colours) | 6 | 25 | code-drawn |
| Card backs | 6 | 40 | 6 new paintings |
| Flaps between screens (were curtains in the theatre boxes) | 4 | 25 | tinted |

**4. The wagon on the map.** Your wagon (its paint and trims) stands at your city on the Map
of Italy. When you travel it rolls along the chosen road (about 1.2 s, bumping over the
road; instant with Reduce motion). The Wagon screen shows the same wagon large, with a shelf
for props, a wardrobe for cosmetics and a notice board for unlocks.

**Art for B:** one wagon painting (side view, for the screen), one small wagon for the map,
4 trims, 6 card backs: about 12 pictures, one morning of the free generator.

## C. The campaign: Il Lungo Giro (Luca chose "Long tour, 15+ chapters")

A **Campaign** button on the main menu. 16 chapters, one per city, played in order around
Italy and ending in Venezia.

**The story.** A ragged troupe from Bergamo, **I Folli** ("the Fools"), finds half of a torn
playbill: the Doge invites the finest company in Italy to the Carnevale. The other half is
signed by **Messer Grifone**, an impresario who has bought every stage and paid every Patron
between Bergamo and Venezia to keep upstart troupes out. The troupe takes the long way round,
city by city.

**How a chapter plays** (Luca chose a full 8-town run for each):

- **A full tour of 8 towns** (24 shows, about 45–60 minutes; the campaign is about 12–16
  hours). The map starts in the city where the last chapter ended and its last row is the
  chapter's city, where its story Patron waits as the town 8 Patron. Chapter 1 loops out
  from Bergamo and back; chapter 16 ends in Venezia with Messer Grifone.
- **Its own rule** for the whole chapter (often the city's twist), on top of the cities'
  own twists, with the normal Scenarios, mood and Encores. No endless after a chapter.
- **Difficulty climbs by stake** (confirmed by Luca, 2026-10-22):
  chapters 1–4 at Stake 1, 5–8 at Stake 2, 9–12 at Stake 3 and 13–16 at Stake 4. The
  campaign's stakes don't need unlocking first.
- **Deck:** the chapter suggests one, and any deck you've unlocked can be used.
- **One Jester carries on:** when you clear a chapter you choose one Jester from your troupe
  to start the next chapter with. The troupe grows a little along the road.
- **Story:** two short lines before the chapter and one after, over the city's painting.
  Tap to skip; the Campaign screen keeps them to reread.
- Losing just means trying the chapter again (your nemesis, D, may be waiting).
- Maestri and the wagon prop count here.

| # | City | Chapter | Rule for the whole chapter | Story Patron | First clear |
|---|---|---|---|---|---|
| 1 | Bergamo | **Il Biglietto** (the playbill) | Scenarios always tier 1; first-run tips on | Il Censore | The Wagon screen opens; 20 scudi |
| 2 | Milano | **Alla Scala** | Targets ×1.25, every show +3 ducats | Il Banchiere | 20 scudi |
| 3 | Torino | **La Corte dei Savoia** | Patrons pay double | Il Ciambellano | 20 scudi, card back *La Corte* |
| 4 | Genova | **Il Porto** | Start with 0 ducats; cards sell for double | Il Gabelliere | Genova deck (if locked), 20 scudi |
| 5 | Lucca | **Le Mura** | −1 discard, +1 hand | La Fortezza | 25 scudi |
| 6 | Firenze | **La Bottega** | Every pack holds one enhanced card | Il Critico | Firenze deck, 25 scudi |
| 7 | Siena | **Il Palio** | The first hand of each show to reach half its target pays +5 ducats | Il Purista | Siena deck, 25 scudi |
| 8 | Roma | **Il Colosseo** | Patron targets ×1.5, Patrons pay triple | Il Vescovo | Roma deck, 25 scudi |
| 9 | Napoli | **Il Vesuvio** | After your 2nd hand each show, 2 cards in your draw pile turn to Marble | Il Borsaiolo | Napoli deck, 30 scudi |
| 10 | Bari | **Il Mare** | +1 card in hand, −1 hand | Il Maggiordomo | 30 scudi, wagon trim *the sail* |
| 11 | Palermo | **L'Opera dei Pupi** | Jesters fire right to left | Il Marchese | Palermo deck, 30 scudi |
| 12 | Urbino | **La Città Ideale** | Hands of exactly 5 cards ×1.5 Mult | L'Impaziente | 30 scudi |
| 13 | Bologna | **La Dotta** | Each discard grows your hand by 1 for the show (up to +2) | L'Avaro | Bologna deck, 35 scudi |
| 14 | Mantova | **Palazzo Te** | The first hand of each show ×2, the last ×0.5 | La Contessa | Mantova deck, 35 scudi |
| 15 | Verona | **L'Arena** | Each scored Heart +3 Mult (and the Patron bans Hearts) | La Badessa | Verona deck, 35 scudi |
| 16 | Venezia | **Il Carnevale** | Finale targets; the last Patron is Messer Grifone | **Messer Grifone** | Carnevale deck, the *Oro Doge* wagon paint, the title **Compagnia Reale**, 100 scudi |

**Messer Grifone, l'Impresario** (new, campaign only): *target ×5. After each hand, he "buys
out" your rightmost working Jester: it stops working for the rest of the show.* (Put your
best Jesters on the left.) His lines are with the others in D.

**The chapters' lines:**

| # | Before | After |
|---|---|---|
| 1 | A torn playbill blows into the wagon: the Doge invites the finest company in Italy to the Carnevale. The rest of the page is missing. | Arlecchino finds the other half under the Censore's chair: "Apply in person. — Messer Grifone, Impresario." |
| 2 | La Scala is booked solid all season, by Grifone's companies. | The banker settles up and lets a name slip: Grifone owns every stage from here to Venezia. |
| 3 | The Savoy court wants a private show. The Chamberlain wants the request in triplicate. | The court pays in gold and gossip: Grifone is buying the Patrons, city by city. |
| 4 | The port impounds the wagon until the troupe pays its tolls. | Brighella sells the costumes twice and buys them back once. The wagon rolls on. |
| 5 | The gates of Lucca are shut for the night. The guard will open them for a laugh. | The gates swing open. Someone in a griffin cloak watches from the ramparts. |
| 6 | The painters of Florence want a show worth painting. | The Critic's review is fair. Suspiciously fair. Grifone paid him to be cruel. |
| 7 | Palio day: the troupe must win the crowd before the horses do. | The contrade cheer. Grifone's companies are still three towns ahead. |
| 8 | In the Colosseum every show is a duel. | The Bishop blesses the troupe and slips them a letter: Grifone never paid his tithe. |
| 9 | Vesuvio rumbles. Pulcinella says it's only hungry. | The pickpocket returns everything he stole, and Grifone's purse too. |
| 10 | A ship south: the troupe performs on deck to pay the fare. | Land. The butler bows and calls them "Signori". A first. |
| 11 | The puppeteers of Palermo challenge the troupe: masks against marionettes. | The puppets bow. Their strings, the Marquis admits, lead to Grifone. |
| 12 | The ideal city wants an ideal show. Nothing less. | Perfect proportions, perfect applause. Venezia sends a second invitation. |
| 13 | The doctors of Bologna argue for an hour over whether comedy is medicine. | The Miser pays up. The doctors agree: comedy is medicine. Expensive medicine. |
| 14 | The Gonzaga court applauds the first act and yawns through the last. | The Countess offers a carriage to Venezia. The troupe keeps the wagon. |
| 15 | In the city of lovers, the Abbess has banned love. | The Abbess laughs despite herself. Verona's hearts are free again. |
| 16 | Carnevale. Every mask in Italy is here, and the griffin waits on the last stage. | Grifone takes off his mask: just a man who never learned to laugh. The Doge crowns I Folli the Compagnia Reale. |

**Art for C:** the 16 chapters reuse the city paintings (deck paintings plus the 10 city
views painted on 2026-10-23). New: Messer Grifone's Patron card and a griffin-cloak figure
for the story screen: 2 pictures.

## D. Patron rivalry (Luca chose "Both", with lines)

**1. The rematch (*la rivincita*), inside a run.**

- From town 5 to town 7, the town's Patron has a **1 in 5** chance (Luca's choice) to be one
  you already beat this run, back for revenge. At most once per run, so about half of runs
  see one; never in town 8.
- It keeps its rule, its target is **×1.25** of what it was, and it **pays double**.
- The map marks the city with a red ribbon, and the Patron card wears a torn glove.
- It says its *revenge* line at the start of the show.

**2. The nemesis (*la nemesi*), across runs.**

- When a Patron ends your run (you lose its show), it becomes your **nemesis**.
- In your next normal run or campaign chapter, it takes the Patron's place in the **same
  town where it beat you** (or the nearest town it's allowed in). A black seal marked
  *Nemesi* sits on its card and on the map.
- **Beat it:** +10 ducats at cash-out, +2 fame for every Jester in the troupe, the feat
  *Vendetta*, and it stops being your nemesis.
- **Lose to it again:** it stays your nemesis, and it gloats.
- Losing to a different Patron makes that one the new nemesis. A run lost on a Matinee or
  Evening show leaves the nemesis as it was.
- Off in daily, weekly, duel, ranked, seeded runs and challenges (they must play the same
  for everyone).

**3. Lines.** Each Patron speaks in a speech bubble from its card: an **entrance** line when
its show starts, a **defeat** line when you beat it, a **victory** line when it beats you, and
a **revenge** line for a rematch or as your nemesis. About 2.5 s each, tap to skip; all
lines can be reread in the Collection. Group 3 adds their babble voices.

| Patron | Entrance | Defeat | Victory | Revenge |
|---|---|---|---|---|
| **Il Censore** (face cards debuffed) | Kings, Queens, Jacks... indecent. Cover them up. | I shall be writing a strongly worded letter. | Another show saved from bad taste. | I've drafted new rules. Longer ones. |
| **La Badessa** (Hearts debuffed) | No Hearts in my convent. Not one. | Heaven forgive me, I laughed. | Pray harder next time, child. | I said a hundred prayers for your failure. |
| **Il Banchiere** (Diamonds debuffed) | Diamonds? Mine. Read the contract. | Put it on my account. | Your troupe is now a write-off. | Interest has been accruing, Jester. |
| **Il Capitano di Giustizia** (Spades debuffed) | Spades are evidence. Confiscated. | Release them. On a technicality. | Case closed. Take them away. | I never close a case for good. |
| **Il Guardacaccia** (Clubs debuffed) | Clubs are poaching tools. Hand them over. | Slippery as hares, the lot of you. | Bagged a whole troupe today. | I followed your wagon tracks for three towns. |
| **Il Critico** (no hand twice) | Do the same trick twice and I'm leaving. | ...Fine. Three stars. Grudgingly. | Derivative. Predictable. Closing night. | I came back to see if you'd improved. Doubtful. |
| **Il Purista** (one kind of hand) | Choose one style. Commit to it. | Consistent. I'll allow it. | You strayed from the form. | Purity demands a second hearing. |
| **Il Gabelliere** (−1 ducat per card) | Every card that crosses this stage pays a toll. | Keep the change. I insist. Ugh. | Tolls, tariffs, fees. You're bankrupt. | New season, new taxes! |
| **L'Avaro** (favourite hand empties your purse) | Play your favourite again and your purse is mine. | My money! My beautiful money! | Mine, mine, all of it mine. | I counted my coins. Some were yours. |
| **La Fortezza** (target ×4) | These walls have never fallen. | A breach! Ring the bells! | Still standing. As always. | We rebuilt. Thicker. |
| **Lo Spione** (1 card in 7 face down) | I see everything. You'll see a little less. | Didn't see that coming. Embarrassing, for a spy. | I knew your hand before you did. | I've been watching you since the last town. |
| **La Maschera Grigia** (first hand face down) | Play blind, as I do. | Under this mask, I'm smiling. A little. | Grey wins. Grey always wins. | Did you think I'd forget your face? |
| **Il Gioco al Buio** (draws face down) | Lights out after the first act. | Who lit a candle?! | In the dark, everyone's a fool. | The dark is back. So am I. |
| **Il Marchese** (face cards face down) | Nobility prefers not to be seen with commoners. | How vulgar. How... entertaining. | Know your place, Jester. | My family never forgets a slight. |
| **Il Ciambellano** (exactly 5 cards) | Protocol: five cards. No more, no less. | Protocol permits applause. Just this once. | Improper form. Dismissed. | I've amended the protocol. Against you. |
| **Il Priore** (no discards) | No take-backs in this house. | A small sin, enjoying that. | Live with your choices. | Penance is due. Yours. |
| **Il Maggiordomo** (−1 card in hand) | I've taken the liberty of removing a card, sir. | Very good, sir. Very good indeed. | Shall I fetch your coat? | I've taken the liberty of returning, sir. |
| **Il Borsaiolo** (2 cards stolen per play) | Nice cards. Shame if they wandered off. | Fine, fine. Have your pockets back. | Thanks for the show. And the wallet. | Didn't I rob you already? Once more, then. |
| **Il Vescovo** (each hand loses a level) | Pride goes before a fall. Each hand, a little lower. | Bless you. Begrudgingly. | Humility, at last. | I've come to hear your confession. |
| **Il Duca** (base halved) | Half for you, half for the Duchy. | Even half of you was too much. | The Duchy thanks you for your contribution. | The Duchy's appetite has grown. |
| **Il Siniscalco** (cards played this town debuffed) | Already used? Then you're done. | Fresh tricks. I didn't expect that. | I've seen all your cards. Boring. | I remember every card you've ever played. |
| **L'Impaziente** (draw exactly 3) | Hurry. Hurry! Three cards, go! | Finally over! ...Wait, I lost? | Too slow! Next! | Back already? No, I'm back. Hurry! |
| **La Contessa** (one hand, target ×1) | One hand, darling. Make it count. | Exquisite. You may kiss the ring. | One chance, and you missed it. | I'll grant you one more hand. Only one. |
| **Il Granduca** (finale, target ×6) | The whole Carnevale is watching. Impress me. | Magnificent. Venezia is yours tonight. | Tuscany has seen better jugglers. | Grand dukes do not lose twice. |
| **La Granduchessa** (finale, a Jester stops each hand) | Let's see who's really in your troupe. | Every one of them earned their place. | A troupe is only as good as its weakest mask. | I've picked my favourite. To silence. |
| **L'Inquisitore** (finale, all debuffed until a sale) | Confess. Give me one of your Jesters. | Absolved. This time. | Heresy. All of it. | The tribunal has reopened your case. |
| **Il Cardinale** (finale, Jesters shuffled face down) | Let's shuffle the order of things. | A miracle. Or a very good trick. | Chaos favours the Church. | Shall we shuffle again? |
| **La Regina** (finale, one card forced) | That one. Play that one. I insist. | You may keep your head. | Disobedience. Exile them. | The Queen requests a command performance. |
| **Messer Grifone** (campaign finale) | Every stage in Italy is mine. This one too. | ...Bravo. I never learned how you do it. | Sold. The whole troupe, for a song. | I bought your last stage. I'll buy this one too. |

## What gets built

- **Profile:** fame per Jester, scudi, owned props and cosmetics, the carried prop, campaign
  progress, the nemesis. All in the cloud save (no server change: the save is one JSON).
- **Rules:** the Maestro scale on the duo machinery; scudi at run end; props as run sources
  (like the deck's rule), off in the fair-play modes; the rematch and the nemesis in the
  Patron draw; Messer Grifone; the campaign as a run mode whose 8-row map runs from the last chapter's city to this one's,
  with a chapter rule, a chapter stake and one carried Jester.
- **Screens:** Wagon (props, cosmetics, unlocks), Campaign (chapters, story), star and Maestro
  frames on cards, speech bubbles for Patrons, the wagon token on the map.
- **Tests:** rules tests for each part, the fuzz bot playing campaign chapters and runs with
  props, Maestri and a nemesis, UI smoke for the new screens.
- **Art:** about 14 pictures (wagon, map wagon, 4 trims, 6 card backs, Grifone, the griffin
  figure), free generator.

## Luca's answers (2026-10-22)

| # | Question | Proposed | Luca chose |
|---|---|---|---|
| 1 | Fame for a Maestro | 50 (stars 10/25/50) | **120** (stars 25/60/120) |
| 2 | Maestro strength | 1.25× | **1.25×** |
| 3 | The wagon's coin | scudi | **scudi** |
| 4 | Campaign chapter length | 3 towns | **a full 8-town run** |
| 5 | Carry a Jester between chapters | one | **one** |
| 6 | Rematch chance | 1 in 3, once per run | **1 in 5**, once per run |
| 7 | The lists | keep | **keep all as written** |

Follow-on from answer 4, confirmed by Luca when he said build it: the campaign's difficulty
climbs by stake (1 to 4) instead of by town.
