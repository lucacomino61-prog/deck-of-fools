extends SceneTree
## Turns the downloaded paintings (PNG ~880×1168, or the free generator's 1024² JPEG, cut to
## shape around the middle) into the game's card art: 480×640 lossy
## WebP in game/art/<kind>/<id>.webp, small enough for a phone download and sharp at any
## card size the game draws (the biggest, a held card on a 3× phone, is ~360×500).
##   godot --headless --path game -s res://../tools/art/convert.gd -- --from=<raw dir>
## Skips paintings already converted unless --force.

const SIZE := Vector2i(480, 640)
const QUALITY := 0.82


func _initialize() -> void:
	var from := ""
	var force := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--from="):
			from = arg.get_slice("=", 1)
		elif arg == "--force":
			force = true
	var out_root := ProjectSettings.globalize_path("res://art")
	var made := 0
	for kind in DirAccess.get_directories_at(from):
		DirAccess.make_dir_recursive_absolute(out_root.path_join(kind))
		for file in DirAccess.get_files_at(from.path_join(kind)):
			if not (file.ends_with(".png") or file.ends_with(".jpg")):
				continue
			var out := out_root.path_join(kind).path_join(file.get_basename() + ".webp")
			if FileAccess.file_exists(out) and not force:
				continue
			var image := Image.load_from_file(from.path_join(kind).path_join(file))
			if image == null or image.is_empty():
				push_error("can't read " + file)
				continue
			image.convert(Image.FORMAT_RGB8)
			# Cut to the card's shape around the middle first (the free generator paints squares).
			var w := mini(image.get_width(), roundi(image.get_height() * float(SIZE.x) / SIZE.y))
			var h := mini(image.get_height(), roundi(w * float(SIZE.y) / SIZE.x))
			image = image.get_region(Rect2i((image.get_width() - w) / 2, (image.get_height() - h) / 2, w, h))
			image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
			image.save_webp(out, true, QUALITY)
			made += 1
	print("converted %d paintings into %s" % [made, out_root])
	quit()
