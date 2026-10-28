class_name Settings
extends RefCounted
## Player settings, saved on the device.
## - Sound: music and effects volume (0–1) and mutes.
## - Display: graphics quality (Low/Medium/High), frame-rate cap, CRT effect (Off/Light/Full),
##   Reduce motion (no shake, tilt, CRT curve or moving backdrop; starts on when the browser or
##   system asks for reduced motion), high-contrast suits (four suit colours).
## - Play: game speed (scoring 0.5x to 4x), screen shake, text and card size, vibration
##   strength, which side Play and Discard sit on, card back.
## - Progress flags: How to play seen, account offered, the first-run tips.

const PATH := "user://settings.json"
## Saved with the settings; older files get the new defaults where noted in load_saved().
const VERSION := 2
const QUALITY_NAMES := ["Low", "Medium", "High"]
const FPS_CHOICES := [30, 60, 120]
const CRT_NAMES := ["Off", "Light", "Full"]
const SPEEDS := [0.5, 1.0, 2.0, 4.0]
const SHAKE_NAMES := ["Off", "Low", "Normal", "Strong"]
## How hard the screen shakes at each Screen shake setting.
const SHAKE_SCALE := [0.0, 0.5, 1.0, 1.6]
const SIZE_NAMES := ["Small", "Normal", "Large"]
const VIBRATION_NAMES := ["Off", "Light", "Strong"]
const CARD_BACKS := ["Harlequin", "Sun and moon", "Venetian mask", "Curtain", "Night sky", "Gold filigree"]

static var reduce_motion := false
static var sound := true
static var music := true
static var sfx_volume := 0.8
static var music_volume := 0.7
static var quality := 2
static var fps := 60
static var crt := 2
static var speed := 1.0
static var shake := 2
static var size := 1
static var vibration_level := 1
static var card_back := 0
## Four suit colours (Spades black, Hearts red, Clubs blue, Diamonds orange) instead of two.
static var high_contrast := false
## Discard on the left of Play, for playing with the left thumb.
static var left_handed := false
## A new player's normal runs bring one new part of the game each (Learning); off plays
## everything from the start.
static var step_by_step := true
## Whether the practice town was played or skipped (a new player's first Play opens it).
static var practice_done := false
## Whether How to play has been closed once; the first run opens it until then.
static var seen_help := false
## Whether "Save your progress" has been offered after the first run (it's offered once).
static var asked_account := false
## How far the first-run tips have got (-1 once they're finished or skipped).
static var tutorial_step := 0


static func load_saved() -> void:
	reduce_motion = _system_prefers_less_motion()
	# Phones and browsers start on Medium graphics, computers on High. The CRT effect starts off
	# (the game's look is painted and sharp now; it can be turned on in Settings).
	var phone := OS.has_feature("mobile") or OS.has_feature("web")
	quality = 1 if phone else 2
	crt = 0
	if FileAccess.file_exists(PATH):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if data is Dictionary:
			reduce_motion = bool(data.get("reduce_motion", reduce_motion))
			sound = bool(data.get("sound", sound))
			music = bool(data.get("music", music))
			sfx_volume = clampf(float(data.get("sfx_volume", sfx_volume)), 0.0, 1.0)
			music_volume = clampf(float(data.get("music_volume", music_volume)), 0.0, 1.0)
			quality = clampi(int(data.get("quality", quality)), 0, 2)
			fps = int(data.get("fps", fps)) if FPS_CHOICES.has(int(data.get("fps", fps))) else 60
			# Settings saved before the painted look (no "v") had the CRT on by default: off once.
			crt = clampi(int(data.get("crt", crt)), 0, 2) if int(data.get("v", 1)) >= VERSION else 0
			speed = float(data.get("speed", speed)) if SPEEDS.has(float(data.get("speed", speed))) else 1.0
			shake = clampi(int(data.get("shake", shake)), 0, SHAKE_NAMES.size() - 1)
			high_contrast = bool(data.get("high_contrast", high_contrast))
			left_handed = bool(data.get("left_handed", left_handed))
			step_by_step = bool(data.get("step_by_step", step_by_step))
			practice_done = bool(data.get("practice_done", practice_done))
			size = clampi(int(data.get("size", size)), 0, 2)
			var old_vibration: Variant = data.get("vibration")
			vibration_level = clampi(int(data.get("vibration_level", 1 if old_vibration == null or bool(old_vibration) else 0)), 0, 2)
			card_back = clampi(int(data.get("card_back", card_back)), 0, CARD_BACKS.size() - 1)
			seen_help = bool(data.get("seen_help", seen_help))
			asked_account = bool(data.get("asked_account", asked_account))
			tutorial_step = int(data.get("tutorial_step", tutorial_step))


static func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"v": VERSION, "reduce_motion": reduce_motion, "sound": sound, "music": music,
			"sfx_volume": sfx_volume, "music_volume": music_volume, "quality": quality, "fps": fps,
			"crt": crt, "speed": speed, "shake": shake, "size": size, "vibration_level": vibration_level,
			"card_back": card_back, "high_contrast": high_contrast, "left_handed": left_handed, "step_by_step": step_by_step, "practice_done": practice_done,
			"seen_help": seen_help, "asked_account": asked_account, "tutorial_step": tutorial_step,
		}))


## A speed as the settings show it: "0.5x", "1x", "4x".
static func speed_name(value: float) -> String:
	return ("%sx" % ("%.1f" % value).trim_suffix(".0"))


## Text is drawn this much bigger or smaller (Text & card size).
static func text_scale() -> float:
	return [0.9, 1.0, 1.12][size]


## Cards in a run are this much bigger or smaller (Text & card size).
static func card_scale() -> float:
	return [0.92, 1.0, 1.1][size]


static func _system_prefers_less_motion() -> bool:
	if not OS.has_feature("web"):
		return false
	var answer: Variant = JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 1 : 0", true)
	# A number from the page (it arrives as a float): comparing what came back with true gave
	# null in the release web build, which left Reduce motion unset and broke the title.
	return (typeof(answer) == TYPE_INT or typeof(answer) == TYPE_FLOAT) and float(answer) == 1.0
