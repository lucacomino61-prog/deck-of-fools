// The daily run: the same seed, deck and stake for everyone on a UTC day. The game makes the
// same choice offline for practice (game/ui/online.gd, daily_setup), so keep the two in step:
// both are checked against the same examples in their tests.

// The game's decks, in the order the game registers them.
export const DECKS = [
  'd_bergamo', 'd_venezia', 'd_genova', 'd_siena', 'd_napoli', 'd_palermo', 'd_padova', 'd_benevento',
  'd_verona', 'd_ferrara', 'd_bologna', 'd_firenze', 'd_roma', 'd_mantova', 'd_carnevale',
];

export function today(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

export function dailySetup(dateText) {
  const [y, m, d] = dateText.split('-').map(Number);
  const day = Math.floor(Date.UTC(y, m - 1, d) / 86_400_000);
  return { date: dateText, seed: `DAY${dateText.replace(/-/g, '')}`, deck: DECKS[day % DECKS.length], stake: 1 };
}

/** A ranked attempt may be handed in on its day or the day after (a run can cross midnight). */
export function acceptableDates(date = new Date()) {
  const yesterday = new Date(date.getTime() - 86_400_000);
  return [today(date), today(yesterday)];
}
