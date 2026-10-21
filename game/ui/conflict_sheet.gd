class_name ConflictSheet
extends Sheet
## Both this device and the cloud changed the save since they last agreed: show what each
## holds and let the player choose which to keep (the other is replaced).

var cloud: Dictionary = {}


func _init(cloud_save: Dictionary) -> void:
	cloud = cloud_save
	title_text = "Which progress do you keep?"
	panel_size = Vector2(460, 300)
	closable = false


func _build() -> void:
	body.add_child(words("Your progress changed on this device and in the cloud. Choose one to keep; the other is replaced.", 10, UiTheme.MUTED))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	body.add_child(columns)
	var here := Game.cloud_data()
	columns.add_child(_side("This device", "", here))
	var data: Dictionary = cloud.get("data", {}) if cloud.get("data") is Dictionary else {}
	columns.add_child(_side("The cloud", "Saved %s%s" % [Sheet.ago(float(cloud.get("updated_at", 0))), " on " + str(cloud["device"]) if str(cloud.get("device", "")) != "" else ""], data))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	var keep_here := UiTheme.button("Keep this device", func() -> void: _choose("device"), 12, UiTheme.POINTS)
	keep_here.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(keep_here)
	var keep_cloud := UiTheme.button("Keep the cloud", func() -> void: _choose("cloud"), 12, UiTheme.MULT)
	keep_cloud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(keep_cloud)
	body.add_child(buttons)


func _side(heading_text: String, note: String, save: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL_DARK, UiTheme.PANEL_LIGHT, 4))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	panel.add_child(col)
	col.add_child(UiTheme.title(heading_text, 12, UiTheme.GOLD))
	if note != "":
		col.add_child(UiTheme.label(note, 8, UiTheme.MUTED))
	var profile: Dictionary = save.get("profile", {}) if save.get("profile") is Dictionary else {}
	col.add_child(pair("Runs won", str(int(profile.get("total_wins", 0)))))
	col.add_child(pair("Runs lost", str(int(profile.get("runs_lost", 0)))))
	col.add_child(pair("Cards discovered", str((profile.get("discovered", []) as Array).size())))
	var run: Variant = save.get("run")
	col.add_child(pair("Run in progress", "Town %d" % int(run.get("town", 1)) if run is Dictionary else "none"))
	return panel


func _choose(keep: String) -> void:
	Feel.play("buy")
	Online.resolve_conflict(keep, cloud)
	queue_free()
