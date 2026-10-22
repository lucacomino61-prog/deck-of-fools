// Builds the painting brief for every card that gets painted art, from the game's own data:
// each Jester's hand-made design in game/ui/jester_designs.gd (hat, mask, face, costume and
// colours, prop, backdrop) and every card's name and text in game/i18n/cards.csv. All briefs
// share one style, so the paintings read as one set.
//   node tools/art/prompts.mjs [--ids z_zanni,z_arlecchino] > prompts.json
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const game = path.join(here, '..', '..', 'game');

export const STYLE = 'Premium digital painting for a luxury fantasy card game, in the spirit of Venetian carnival and commedia dell\'arte theatre. '
  + 'Rich painterly brushwork, smooth high-detail rendering, warm theatrical stage lighting with a soft golden rim light, vibrant saturated jewel colours, '
  + 'gentle depth of field. Portrait composition for a tall playing card, subject centred, generous space at the bottom. '
  + 'No text, no letters, no numbers, no border, no frame, no watermark, no logo.';

const HATS = {
  cap2: 'a two-pointed jester\'s cap with little gold bells', cap3: 'a three-pointed jester\'s cap with little gold bells',
  cap4: 'a four-pointed jester\'s cap with little gold bells', bicorne: 'a black bicorne hat', tricorne: 'a tricorne hat',
  sugarloaf: 'a tall white sugarloaf hat', crown: 'a golden crown', tiara: 'a jewelled tiara', beret: 'a soft beret',
  flatcap: 'a flat cloth cap', feather: 'a wide hat with a long sweeping feather', laurel: 'a laurel wreath', turban: 'a silk turban',
  hood: 'a dark hood', flowers: 'a crown of fresh flowers in the hair', tophat: 'a top hat', chef: 'a tall chef\'s hat',
  helmet: 'a polished steel helmet with a plume', skullcap: 'a close skullcap', nightcap: 'a floppy nightcap', bonnet: 'a lace bonnet',
  doge: 'the horned corno cap of a Venetian doge', wig: 'a powdered curled wig', hair: 'tousled hair', longhair: 'long flowing hair',
  bald: 'a bald head',
};
const MASKS = {
  none: '', half: 'a black leather half-mask over the eyes', nose: 'a carnival mask with a long comic nose',
  domino: 'a small domino eye mask', bauta: 'a white bauta mask covering the face', volto: 'a white full-face volto mask',
  gold: 'a gleaming golden mask', moretta: 'a black oval moretta mask', white: 'white face paint', wood: 'a carved wooden mask',
};
const FACES = {
  smile: 'smiling warmly', grin: 'with a mischievous grin', frown: 'frowning sternly', o: 'with a surprised open mouth',
  smirk: 'smirking slyly', sleepy: 'with sleepy half-closed eyes', wink: 'winking playfully', shout: 'shouting boldly',
  tear: 'with a single painted tear on the cheek',
};
/** "a" or "an" before a word. */
const an = (word) => (/^[aeiou]/i.test(word) ? `an ${word}` : `a ${word}`);
const COSTUMES = {
  diamonds: (a, b) => `a harlequin costume of ${a} and ${b} diamonds`, stripes: (a, b) => `${an(a)} and ${b} striped tunic`,
  plain: (a, b) => `${an(a)} tunic with ${b} trim`, buttons: (a, b) => `a loose ${a} blouse with big ${b} buttons`,
  checks: (a, b) => `${an(a)} and ${b} checked costume`, sash: (a, b) => `${an(a)} coat with ${an(b)} sash`,
  robe: (a, b) => `a long ${a} robe trimmed with ${b}`, patches: (a, b) => `${an(a)} costume sewn with colourful ${b} patches`,
  apron: (a, b) => `${an(a)} work smock with ${an(b)} apron`, dots: (a, b) => `${an(a)} costume with ${b} polka dots`,
  cape: (a, b) => `${an(a)} cape lined with ${b}`, armour: (a, b) => `${a} breastplate armour with ${b} accents`,
  gown: (a, b) => `an elegant ${a} gown embroidered with ${b}`,
};
const PROPS = {
  balls: 'juggling three bright balls', marotte: 'holding a marotte jester\'s stick with a little carved head', lute: 'playing a lute',
  cards: 'fanning a hand of playing cards', slapstick: 'holding a wooden slapstick', coins: 'holding a pile of gold coins',
  bag: 'clutching a heavy coin purse', dice: 'rolling a pair of dice', sword: 'brandishing a rapier', book: 'reading an old book',
  quill: 'writing with a feather quill', goblet: 'raising a golden goblet', mirror: 'holding a hand mirror', rose: 'holding a red rose',
  lantern: 'holding a glowing lantern', maskstick: 'holding a mask on a stick', bell: 'ringing a brass bell',
  hourglass: 'holding an hourglass', scroll: 'unrolling a scroll', star: 'holding a glowing star', heart: 'holding a red heart',
  key: 'holding an ornate key', fan: 'holding a lace fan', bottle: 'holding a potion bottle', bread: 'holding a loaf of bread',
  drum: 'beating a small drum', trumpet: 'blowing a trumpet', torch: 'holding a blazing torch', flag: 'waving a flag',
  broom: 'leaning on a broom', scissors: 'holding large scissors', hammer: 'holding a hammer', brush: 'holding a paintbrush',
  telescope: 'looking through a brass telescope', crystal: 'gazing into a crystal ball', letter: 'holding a sealed letter',
  fish: 'holding a silver fish', pan: 'holding a frying pan', shovel: 'holding a shovel', gem: 'holding a sparkling gem',
  clock: 'holding a pocket clock', candle: 'holding a lit candle', puppet: 'working a little marionette',
  ticket: 'holding a theatre ticket', flowers: 'holding a bouquet', wheel: 'beside a cart wheel', horn: 'blowing a curved horn',
  bird: 'with a small bird perched on the hand', masks: 'holding carnival masks', pole: 'balancing a long pole',
  pie: 'about to throw a cream pie', ribbon: 'twirling a silk ribbon', bubbles: 'blowing soap bubbles',
  chest: 'opening a small treasure chest', chisel: 'holding a chisel', wand: 'waving a magic wand',
  question: 'with a curious question-mark charm', none: '',
};
const EXTRAS = {
  moustache: 'a curled moustache', beard: 'a full beard', goatee: 'a pointed goatee', stubble: 'stubble', glasses: 'round spectacles',
  monocle: 'a monocle', freckles: 'freckles', blush: 'rosy cheeks', earring: 'a gold earring', rednose: 'a red clown nose', mole: 'a beauty mark',
};
const BACKDROPS = {
  night: 'deep midnight blue', plum: 'deep plum purple', sea: 'deep sea blue', wine: 'deep wine red', forest: 'deep forest green',
  amber: 'dark warm amber', rust: 'dark rust orange', slate: 'slate blue-grey', teal: 'deep teal', rose: 'deep rose',
  ink: 'inky violet-black', moss: 'dark moss green', gold: 'dark burnished gold', sky: 'twilight blue',
};
const PATTERNS = {
  rays: 'soft radiating light rays', lattice: 'a faint diamond lattice', rings: 'glowing concentric rings', stripes: 'subtle stripes',
  stars: 'twinkling stars', dots: 'floating glowing motes', checks: 'a faint checkerboard', waves: 'gentle waves of light',
  curtain: 'red velvet theatre curtains', plain: 'soft bokeh',
};
const COLOURS = { cream: 'cream', tan: 'tan', silver: 'silver', crimson: 'crimson', navy: 'navy blue', sky: 'sky blue', grey: 'grey' };
const RARITY = ['', 'finely detailed', 'ornate, with gilded details', 'legendary, glowing with a golden aura, opulent'];

function readCsv() {
  const out = {};
  for (const line of fs.readFileSync(path.join(game, 'i18n', 'cards.csv'), 'utf8').split('\n')) {
    const m = line.match(/^([^,]+),(.*)$/);
    if (m) out[m[1]] = m[2].replace(/^"|"$/g, '').replace(/""/g, '"');
  }
  return out;
}

function readDesigns() {
  const src = fs.readFileSync(path.join(game, 'ui', 'jester_designs.gd'), 'utf8');
  const out = {};
  for (const m of src.matchAll(/"(z_\w+)":\s*\[([^\]]*)\]/g)) out[m[1]] = [...m[2].matchAll(/"([^"]*)"/g)].map((x) => x[1]);
  return out;
}

/** The rarity of each Jester, read from the content files (0 common … 3 legendary). */
function readRarities() {
  const dir = path.join(game, 'content');
  const out = {};
  for (const file of fs.readdirSync(dir).filter((f) => f.startsWith('zanni_batch'))) {
    const src = fs.readFileSync(path.join(dir, file), 'utf8');
    const fixed = (src.match(/^const (?:COMMON|UNCOMMON|RARE) := (\d)/m) || [])[1];
    for (const m of src.matchAll(/_add\("(z_\w+)",\s*[^,]+,\s*(?:(COMMON|UNCOMMON|RARE|LEGENDARY)\s*,)?/g)) {
      const level = { COMMON: 0, UNCOMMON: 1, RARE: 2, LEGENDARY: 3 }[m[2]];
      out[m[1]] = level ?? Number(fixed ?? 0);
    }
  }
  return out;
}

const colour = (c) => COLOURS[c] || c;

export function jesterBrief(id, design, names, rarity = 0) {
  const [backdrop, pattern, hat, mask, face, costume, a, b, prop, , extras] = design;
  const name = names[`${id}.name`] || id;
  const looks = [HATS[hat], MASKS[mask], ...(extras || '').split(' ').filter(Boolean).map((e) => EXTRAS[e])].filter(Boolean);
  const who = `${name}, a commedia dell'arte jester character, waist-up portrait, ${FACES[face]}, wearing ${COSTUMES[costume](colour(a), colour(b))}`
    + (looks.length ? `, with ${looks.join(', ')}` : '') + (PROPS[prop] ? `, ${PROPS[prop]}` : '');
  const scene = `Background: ${BACKDROPS[backdrop]} with ${PATTERNS[pattern]}.`;
  return `${who}. ${RARITY[rarity] ? `The portrait is ${RARITY[rarity]}. ` : ''}${scene} ${STYLE}`;
}

// --- the other painted cards ---

const TAROCCHI = {
  t_matto: 'a carefree wandering fool with a bundle on a stick and a little dog at his heels, stepping toward a cliff edge',
  t_bagatto: 'a young magician at a table laid with cups, coins, a wand and a knife, one hand raised to the sky',
  t_papessa: 'a veiled high priestess enthroned between two pillars, holding a closed book, the moon at her feet',
  t_imperatrice: 'a crowned empress on a throne among wheat and flowers, holding a sceptre with an eagle shield',
  t_imperatore: 'a bearded emperor in armour on a stone throne carved with rams, holding a golden orb and sceptre',
  t_papa: 'a solemn pope in a triple crown raising a hand in blessing, two monks kneeling before him',
  t_amanti: 'two young lovers in Renaissance dress beneath a winged cupid drawing his bow',
  t_carro: 'a victorious prince standing in a chariot drawn by two horses, one white and one black',
  t_giustizia: 'Justice, a crowned woman holding a sword upright and golden scales',
  t_eremita: 'an old hermit in a grey cloak holding up a lantern with a shining star inside, on a snowy path',
  t_ruota: 'the great wheel of fortune turning in the clouds, little figures rising and falling with it',
  t_forza: 'a gentle woman calmly holding open the jaws of a lion, flowers in her hair',
  t_appeso: 'a man hanging upside down by one foot from a wooden beam, serene, a halo around his head',
  t_morte: 'a skeleton knight in black armour on a pale horse carrying a banner with a white rose',
  t_temperanza: 'a winged angel pouring water between two golden cups, one foot on land and one in a stream',
  t_diavolo: 'a horned devil with bat wings on a dark pedestal, two small chained imps below',
  t_torre: 'a tall stone tower struck by lightning, its crown blasted off, flames and falling figures',
  t_stella: 'a woman kneeling by a pool under a great eight-pointed star, pouring water from two jugs',
  t_luna: 'a full moon with a face above two towers, a dog and a wolf howling, a crayfish rising from a pool',
  t_sole: 'a radiant smiling sun above two children playing by a garden wall',
  t_giudizio: 'an angel blowing a trumpet from the clouds as figures rise from their tombs with arms raised',
  t_mondo: 'a dancing figure in a laurel wreath, surrounded by an angel, an eagle, a bull and a lion',
};
const SIGNS = {
  s_aries: 'a golden ram', s_taurus: 'a mighty bull', s_gemini: 'twin youths hand in hand', s_cancer: 'a crab',
  s_leo: 'a regal lion', s_virgo: 'a maiden holding wheat', s_libra: 'golden balance scales', s_scorpio: 'a scorpion',
  s_sagittarius: 'a centaur archer drawing his bow', s_capricorn: 'a sea-goat', s_aquarius: 'a water bearer pouring an urn',
  s_pisces: 'two fish swimming in a circle',
};
const OMENS = {
  o_maschera_divina: 'a radiant golden carnival mask floating in a beam of heavenly light',
  o_eclissi: 'a total solar eclipse over the lagoon of Venice, a ring of fire in a dark sky',
  o_janara: 'a Janara, a southern Italian witch, riding a broom past a walnut tree under the moon',
  o_fantasma: 'a pale translucent ghost in an old Venetian palazzo corridor lit by candles',
  o_folletto: 'a tiny mischievous sprite with a red cap grinning among glowing mushrooms',
  o_corno: 'a red Neapolitan good-luck horn charm (cornicello) on a gold chain, glowing',
  o_ritorno: 'a hooded traveller returning through a misty arched gate, a lantern in hand',
  o_civetta: 'a wise little owl perched on a carnival mask under the moon',
  o_sibilla: 'an ancient sibyl prophetess in a cave, smoke rising from a tripod, leaves with writing on them',
  o_fuoco_fatuo: 'eerie blue will-o\'-the-wisp flames drifting over a dark marsh',
  o_patto: 'two hands shaking over a parchment contract sealed with red wax, a flame between them',
  o_acqua_alta: 'Venice flooded at high tide, St Mark\'s square mirrored in the water at dusk',
  o_seduta: 'a candlelit séance, hands joined around a round table, ghostly light above',
  o_ombra: 'a long dark shadow of a jester cast on a theatre wall, with no one there',
  o_vesuvio: 'Mount Vesuvius erupting at night above the bay of Naples',
  o_sosia: 'a jester facing his exact double through an ornate mirror frame',
  o_malocchio: 'the evil eye, a staring blue glass eye amulet with a dark aura',
  o_specchio_magico: 'an ornate magic mirror showing a swirl of stars instead of a reflection',
};
const PATRONS = {
  pt_censore: 'a stern censor in black robes holding a quill and a list, glaring',
  pt_badessa: 'a severe abbess in a black and white habit clutching a rosary',
  pt_banchiere: 'a wealthy Florentine banker in fur-trimmed robes counting gold on an abacus',
  pt_capitano_giustizia: 'a captain of justice in a steel cuirass holding a halberd and shackles',
  pt_guardacaccia: 'a gamekeeper in a green hunting cloak with a crossbow and hounds',
  pt_critico: 'a sneering theatre critic in a powdered wig holding opera glasses',
  pt_purista: 'a prim purist scholar in grey robes with a single white lily',
  pt_gabelliere: 'a greedy toll collector with an iron coin box and a ledger',
  pt_avaro: 'a miser hugging a chest of gold, thin and suspicious',
  pt_fortezza: 'a stone fortress castle personified as a stern armoured lady with a tower crown',
  pt_spione: 'a sly spy peeking from behind a curtain, one eye glinting',
  pt_maschera_grigia: 'a mysterious figure in a plain grey mask and grey cloak',
  pt_gioco_buio: 'a gambler in the dark, only his hands and dice lit by a candle',
  pt_ciambellano: 'a pompous chamberlain with a staff of office and a chain of keys',
  pt_priore: 'a stern prior in brown robes holding a heavy bible',
  pt_maggiordomo: 'a haughty butler with a silver tray, nose in the air',
  pt_borsaiolo: 'a grinning pickpocket lifting a purse, quick fingers',
  pt_vescovo: 'a bishop in a mitre and crimson cope holding a crozier',
  pt_duca: 'a proud duke in an ermine mantle on a carved chair',
  pt_siniscalco: 'a seneschal in a velvet doublet holding a great iron key',
  pt_impaziente: 'an impatient nobleman tapping a pocket watch, scowling',
  pt_marchese: 'a scheming marquis in a black velvet mask and lace cuffs',
  pt_contessa: 'an elegant countess with a fan and a cold smile',
  pt_granduca: 'the grand duke of Tuscany, imposing, in gold-embroidered robes and a crown',
  pt_granduchessa: 'the grand duchess in a jewelled gown, a pet monkey on her shoulder',
  pt_inquisitore: 'a grim inquisitor in a red hood holding a burning candle',
  pt_cardinale: 'a cardinal in scarlet robes and a red hat shuffling playing cards',
  pt_regina: 'a queen with a high lace collar pointing an imperious finger',
};
const PACKS = {
  tarocchi: 'a sealed purple velvet bundle of tarot cards tied with a gold ribbon and a wax seal',
  sign: 'a sealed midnight-blue envelope sprinkled with golden stars and zodiac symbols',
  card: 'a wrapped deck of fine playing cards with a red ribbon and a gilded seal',
  zanni: 'a small wooden puppet-theatre box tied with a ribbon, a jester\'s cap peeking out',
  omen: 'a sealed black envelope with a glowing green eye on its wax seal, mist curling out',
};
const SUITS = {
  spades: ['Spades', 'midnight blue and silver'], hearts: ['Hearts', 'crimson and gold'],
  clubs: ['Clubs', 'emerald green and gold'], diamonds: ['Diamonds', 'amber orange and gold'],
};
const COURT = {
  j: 'a young Venetian page, the Jack, with a feathered cap',
  q: 'a graceful Renaissance queen, the Queen, holding a rose',
  k: 'a bearded Renaissance king, the King, holding a sceptre',
};
const BACKS = [
  'a harlequin pattern of red, green and gold diamonds with an ornate gold border',
  'a golden sun and a silver crescent moon in a starry deep blue sky, ornate gold border',
  'an elegant Venetian carnival mask with feathers on crimson brocade, ornate gold border',
  'red velvet theatre curtains drawn open on a glowing stage, gold tassels, ornate gold border',
  'a deep violet night sky full of stars and constellations with one bright star, silver border',
  'symmetrical gold filigree scrollwork and a rosette on dark green lacquer, ornate gold border',
];
export const OBJECT_STYLE = 'Premium digital painting for a luxury fantasy card game, Venetian Renaissance theatre mood. '
  + 'Rich painterly brushwork, high detail, warm theatrical lighting with a soft golden rim light, vibrant jewel colours, dark atmospheric background. '
  + 'Tall portrait composition, subject centred. No text, no letters, no numbers, no border, no frame, no watermark, no logo.';
export const BACK_STYLE = 'Back design of a luxury playing card, perfectly symmetrical and ornamental, painted in rich detail, '
  + 'filling the whole image edge to edge, vibrant jewel colours. No text, no letters, no numbers, no watermark, no logo.';

export function otherBriefs() {
  const names = readCsv();
  const out = {};
  for (const [id, scene] of Object.entries(TAROCCHI)) out[`tarocchi/${id}`] = `${names[`${id}.gloss`]} (${names[`${id}.name`]}), an Italian Renaissance tarot card painting: ${scene}. ${OBJECT_STYLE}`;
  for (const [id, figure] of Object.entries(SIGNS)) out[`sign/${id}`] = `The zodiac sign ${names[`${id}.name`]}: ${figure} drawn in glowing golden starlight and constellation lines across a deep night sky. ${OBJECT_STYLE}`;
  for (const [id, scene] of Object.entries(OMENS)) out[`omen/${id}`] = `${names[`${id}.name`]}, an omen from Italian folklore: ${scene}. Mysterious and eerie. ${OBJECT_STYLE}`;
  for (const [id, who] of Object.entries(PATRONS)) out[`patron/${id}`] = `${names[`${id}.name`]}, a powerful patron and villain of the theatre: ${who}, waist-up portrait, imposing, lit by stage lights from below. ${OBJECT_STYLE}`;
  for (const [kind, thing] of Object.entries(PACKS)) out[`pack/${kind}`] = `A booster pack for a card game: ${thing}, on a velvet table with sparkles. ${OBJECT_STYLE}`;
  for (const [suit, [suitName, colours]] of Object.entries(SUITS)) {
    for (const [rank, who] of Object.entries(COURT)) out[`face/${suit}_${rank}`] = `Court card portrait for the ${suitName} suit: ${who}, dressed in ${colours}, waist-up, regal, a small ${suitName.toLowerCase().slice(0, -1)} emblem on the clothing. ${OBJECT_STYLE}`;
  }
  BACKS.forEach((design, i) => { out[`back/${i}`] = `${design}. ${BACK_STYLE}`; });
  return out;
}

// --- painted by the free generator (tools/art/free.mjs: FLUX.1 schnell on Workers AI) ---
// FLUX tends to paint whatever a prompt names, "no text" included, so these briefs leave out
// anything with writing on it (letters, tickets, maps) instead of asking for no text.
const WARRANTS = {
  w_bottega: 'a Renaissance shop counter with an extra open shelf displaying fine playing cards',
  w_bottega_grande: 'a grand market stall overflowing with playing cards, masks and curiosities',
  w_sconto: 'a merchant\'s brass balance scale with a few gold coins and scissors cutting a red ribbon',
  w_svendita: 'a market stall with goods spilling out onto the cobbles, gold coins scattered, a lantern glowing',
  w_lustrini: 'a velvet box spilling a cascade of glittering golden sequins',
  w_paillettes: 'a shimmering carnival gown covered in iridescent rainbow sequins on a mannequin',
  w_rimescolo: 'two hands shuffling a deck of playing cards in a graceful arc',
  w_rimescolo_perpetuo: 'an ornate brass clockwork machine endlessly shuffling playing cards',
  w_baule: 'an old leather travelling trunk with brass corners, its lid half open',
  w_baule_presagi: 'a dark wooden trunk leaking green mist, an eye glinting inside',
  w_cannocchiale: 'a brass spyglass on a stone balcony pointing at the starry sky',
  w_osservatorio: 'a Renaissance observatory dome open to the stars, a great brass telescope inside',
  w_copione_lungo: 'a very long blank parchment scroll unrolling down the steps of a theatre stage',
  w_secondo_atto: 'a red theatre curtain rising on a brightly lit stage',
  w_cestino: 'a wicker basket full of crumpled playing cards',
  w_riciclo: 'crumpled playing cards turning back into fresh cards in a swirl of golden light',
  w_mazzo_tarocchi: 'a fanned deck of tarot cards on purple velvet beside a candle',
  w_bottega_arcano: 'an arcane little shop with tarot cards hanging on strings among candles and crystals',
  w_mappa_celeste: 'an antique brass armillary sphere of rings and stars on a table',
  w_atlante_celeste: 'a marble statue of Atlas holding a glowing starry celestial sphere',
  w_salvadanaio: 'a terracotta piggy bank surrounded by gold coins',
  w_banca_san_giorgio: 'a banker\'s table in a Genoese palazzo stacked high with gold coins',
  w_foglio_bianco: 'a single blank sheet of paper floating in a beam of light',
  w_inchiostro_nero: 'an inkwell of black ink with a quill, the spilled ink shaped like a jester',
  w_mazzo_prestigiatore: 'a magician\'s top hat with playing cards fluttering out of it',
  w_gran_trucco: 'a magician\'s gloved hands making playing cards float in sparkling light',
  w_clessidra: 'an ornate golden hourglass with the sand flowing upward',
  w_meridiana: 'a stone sundial in a Renaissance garden casting a long shadow at sunset',
  w_ricatto: 'a black wax-sealed envelope pinned to a wooden table by a dagger',
  w_corruzione: 'a gloved hand sliding a bag of gold coins under a door',
  w_pennello: 'a fine paintbrush dripping liquid gold paint',
  w_tavolozza: 'a painter\'s palette of rich jewel colours with brushes',
};
const FAVORS = {
  f_raccomandazione: 'a folded letter tied with a ribbon and a red wax seal on velvet',
  f_lettera_principe: 'a folded letter with a golden crown wax seal on a silver tray',
  f_velo_nero: 'a black lace veil floating in darkness',
  f_filo_argento: 'a spool of shining silver thread unwinding in the air',
  f_perla: 'a lustrous pink opaline pearl in an open oyster shell',
  f_caleidoscopio: 'a brass kaleidoscope casting rainbow prismatic light',
  f_dote: 'a small open chest of gold coins and jewels tied with a ribbon',
  f_sigillo_reale: 'a golden royal signet ring topped with a crown, on red velvet beside a pool of red sealing wax',
  f_lasciapassare: 'a heavy wooden city gate swinging open onto a sunlit Italian street, a red ribbon fluttering from its iron ring',
  f_biglietto_omaggio: 'a pair of golden theatre opera glasses resting on a red velvet seat under a spotlight',
  f_mazzo_incantato: 'an enchanted deck of tarot cards glowing with purple light',
  f_stella_cadente: 'a shooting star streaking across the night sky over Venice',
  f_invito: 'an ornate sealed invitation envelope with a carnival mask resting on it',
  f_visione: 'a crystal ball showing a swirling green vision',
  f_mancia: 'a gold coin dropping into an upturned velvet hat',
  f_straccio: 'a patched cloth rag wrapped around a few gold coins',
  f_buono: 'a gilded token coin stamped with a jester mask',
  f_gemello: 'two identical carnival masks side by side, mirror images',
  f_bagaglio: 'a traveller\'s leather satchel bursting with playing cards',
  f_rimpasto: 'playing cards swept up and rearranged by a gust of wind in a market square',
  f_rinforzo: 'two small jesters marching in step beating drums',
  f_fretta: 'a winged sandal with streaks of motion',
  f_oroscopo: 'an astrologer\'s golden wheel of the zodiac glowing',
  f_raddoppio: 'two stacks of gold coins mirroring each other, doubling',
};
const DECKS = {
  d_bergamo: 'the walled upper town of Bergamo with its towers at dusk',
  d_venezia: 'the Grand Canal of Venice with gondolas at sunset',
  d_genova: 'the port of Genoa with the Lanterna lighthouse and tall ships',
  d_siena: 'the Piazza del Campo in Siena and the Torre del Mangia',
  d_napoli: 'the bay of Naples with Mount Vesuvius at twilight',
  d_palermo: 'Palermo cathedral among palm trees in golden light',
  d_padova: 'the Prato della Valle in Padua, a ring of statues around a green island and canal',
  d_benevento: 'the Arch of Trajan in Benevento at night beside a great walnut tree',
  d_verona: 'the Roman arena of Verona under moonlight',
  d_ferrara: 'the Este castle of Ferrara with its moat and towers',
  d_bologna: 'the two leaning towers of Bologna above red porticoes',
  d_firenze: 'the dome of Florence cathedral over the rooftops at golden hour',
  d_roma: 'the Colosseum in Rome at dusk',
  d_mantova: 'the ducal palace of Mantua reflected in its lakes',
  d_carnevale: 'a carnival parade of masked dancers under fireworks in a piazza',
};
export const FREE_STYLE = 'Painterly digital illustration for a luxury fantasy card game, Venetian Renaissance theatre mood, '
  + 'rich brushwork, fine detail, warm golden theatrical lighting, vibrant jewel colours, dark atmospheric background, '
  + 'tall portrait composition with the subject in the centre.';
export const CITY_STYLE = 'Painterly digital illustration for a luxury fantasy card game, a romantic Italian Renaissance view, '
  + 'rich brushwork, fine detail, warm golden light, vibrant jewel colours, tall portrait composition with the landmark in the centre.';

// Batch 12's art (the tour): the 10 cities of the map that have no deck of their own (the
// others show their deck's painting) and two textures the map of Italy is painted with (the
// coastline itself is drawn from real coordinates). The audience along the table is one
// painting from GPT Image (game/art/crowd/strip.webp), not made here.
const CITIES = {
  c_milano: 'the Gothic cathedral of Milano with its forest of white marble spires under a golden sky',
  c_torino: 'the royal palace of Torino and the tall spire of the Mole Antonelliana with the snowy Alps behind',
  c_pisa: 'the leaning tower of Pisa beside the white marble cathedral on a green lawn',
  c_lucca: 'the tree-lined Renaissance walls of Lucca around medieval towers and red roofs',
  c_bari: 'the old town of Bari by the sea with the pale stone Romanesque basilica of San Nicola',
  c_amalfi: 'the town of Amalfi climbing steep cliffs above a turquoise sea, lemon groves and a striped cathedral',
  c_parma: 'the pink marble octagonal baptistery and the cathedral of Parma in warm evening light',
  c_urbino: 'the ducal palace of Urbino with its two slender towers on a green hilltop',
  c_trieste: 'the grand square of Trieste opening onto the sea, waves whipped up by a strong wind',
  c_messina: 'the strait of Messina with swirling whirlpools between the cliffs of Sicily and the mainland, an old lighthouse',
};
const MAP_TEXTURES = {
  land: 'seen from directly above, the surface of an old painted parchment, warm cream and ochre tones, faint painted hills, '
    + 'tiny forests and fields in soft brushwork, even and plain across the whole picture',
  sea: 'seen from directly above, a painted antique sea, deep blue and teal waves in fine curling brushstrokes, '
    + 'soft gold light, even across the whole picture',
};
// Batch 13's art (progression): Messer Grifone's Patron card and the Wagon's seven card backs.
// The wagon itself is drawn in code, so a bought paint can recolour it.
const CAMPAIGN_PATRONS = {
  pt_grifone: 'Messer Grifone, a rich and sly Renaissance impresario in a dark green velvet cloak lined with gold, '
    + 'a golden griffin brooch, rings on every finger, a heavy purse of gold coins in one hand, a thin smile, '
    + 'waist-up portrait, imposing, lit by stage lights from below',
};
const WAGON_BACKS = {
  back_maschere: 'a symmetrical pattern of small Venetian carnival masks on deep crimson',
  back_laguna: 'symmetrical stylised waves of the Venetian lagoon in teal and gold',
  back_scacchi: 'a flat black and ivory chequerboard pattern with a gold rosette in the centre',
  back_limoni: 'a symmetrical pattern of yellow lemons and green leaves on deep blue',
  back_stelle: 'a symmetrical field of small golden stars on deep midnight blue',
  back_rose: 'a symmetrical pattern of red roses and thorny stems on dusky pink',
  back_corte: 'a golden royal crown above two rampant golden lions on purple velvet',
};
const WAGON_BACK_STYLE = 'Back design of a luxury playing card, perfectly symmetrical and ornamental, an ornate gold border, '
  + 'painted in rich detail, filling the whole picture edge to edge, vibrant jewel colours.';
const TEXTURE_STYLE = 'Painterly texture for the map of a luxury fantasy card game, rich brushwork, subtle and calm.';

export function freeBriefs() {
  const out = {};
  for (const [id, scene] of Object.entries(WARRANTS)) out[`warrant/${id}`] = `${scene}. ${FREE_STYLE}`;
  for (const [id, scene] of Object.entries(FAVORS)) out[`favor/${id}`] = `${scene}. ${FREE_STYLE}`;
  for (const [id, view] of Object.entries(DECKS)) out[`deck/${id}`] = `${view}. ${CITY_STYLE}`;
  for (const [id, view] of Object.entries(CITIES)) out[`city/${id}`] = `${view}. ${CITY_STYLE}`;
  for (const [id, look] of Object.entries(MAP_TEXTURES)) out[`map/${id}`] = `${look}. ${TEXTURE_STYLE}`;
  for (const [id, who] of Object.entries(CAMPAIGN_PATRONS)) out[`patron/${id}`] = `${who}. ${FREE_STYLE}`;
  for (const [id, design] of Object.entries(WAGON_BACKS)) out[`back/${id}`] = `${design}. ${WAGON_BACK_STYLE}`;
  return out;
}

/** The keys of batch 12's art (cities, map), for free.mjs --tour. */
export const TOUR_ART = [
  ...Object.keys(CITIES).map((id) => `city/${id}`),
  ...Object.keys(MAP_TEXTURES).map((id) => `map/${id}`),
];

/** The keys of batch 13's art (Grifone, the Wagon's card backs), for free.mjs --progression. */
export const PROGRESSION_ART = [
  ...Object.keys(CAMPAIGN_PATRONS).map((id) => `patron/${id}`),
  ...Object.keys(WAGON_BACKS).map((id) => `back/${id}`),
];

export function allBriefs() {
  const names = readCsv();
  const designs = readDesigns();
  const rarities = readRarities();
  const out = {};
  for (const [id, design] of Object.entries(designs)) out[id] = jesterBrief(id, design, names, rarities[id] ?? 0);
  return out;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const i = process.argv.indexOf('--ids');
  const all = allBriefs();
  const ids = i > 0 ? process.argv[i + 1].split(',') : Object.keys(all);
  process.stdout.write(JSON.stringify(Object.fromEntries(ids.map((id) => [id, all[id]])), null, 2));
}
