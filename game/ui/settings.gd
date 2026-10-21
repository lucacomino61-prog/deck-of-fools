class_name Settings
extends RefCounted
## Player settings, saved on the device.
## - Sound: music and effects volume (0–1) and mutes.
## - Display: graphics quality (Low/Medium/High), frame-rate cap, CRT effect (Off/Light/Full),
##   Reduce motion (no shake, tilt, CRT curve or moving backdrop; starts on when the browser or
##   system asks for reduced motion).
## - Play: game speed (scoring 1x/2x/4x), text and card size, vibration strength, card back.
## - Progress flags: How to play seen, account offered, the first-run tips.

const PATH := "user://settings.json"
const QUALITY_NAMES := ["Low", "Medium", "High"]
const FPS_CHOICES := [30, 60, 120]
const CRT_NAMES := ["Off", "Light", "Full"]
const SPEEDS := [1, 2, 4]
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
static var speed := 1
static var size := 1
static var vibration_level := 1
static var card_back := 0
## Whether How to play has been closed once; the first run opens it until then.
static var seen_help := false
## Whether "Save your progress" has been offered after the first run (it's offered once).
static var asked_account := false
## How far the first-run tips have got (-1 once they're finished or skipped).
static var tutorial_step := 0


static func load_saved() -> void:
	reduce_motion = _system_prefers_less_motion()
	# Phones and browsers start on Medium; computers on High.
	quality = 1 if OS.has_feature("mobile") or OS.has_feature("web") else 2
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
			crt = clampi(int(data.get("crt", crt)), 0, 2)
			speed = int(data.get("speed", speed)) if SPEEDS.has(int(data.get("speed", speed))) else 1
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
			"reduce_motion": reduce_motion, "sound": sound, "music": music,
			"sfx_volume": sfx_volume, "music_volume": music_volume, "quality": quality, "fps": fps,
			"crt": crt, "speed": speed, "size": size, "vibration_level": vibration_level,
			"card_back": card_back, "seen_help": seen_help, "asked_account": asked_account,
			"tutorial_step": tutorial_step,
		}))


## Text is drawn this much bigger or smaller (Text & card size).
static func text_scale() -> float:
	return [0.9, 1.0, 1.12][size]


## Cards in a run are this much bigger or smaller (Text & card size).
static func card_scale() -> float:
	return [0.92, 1.0, 1.1][size]


static func _system_prefers_less_motion() -> bool:
	if OS.has_feature("web"):
		var answer: Variant = JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches", true)
		return answer == true
	return false
