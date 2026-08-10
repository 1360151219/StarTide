extends Button

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")
const UpgradeChoiceCardStyle = preload("res://scripts/ui/upgrade_choice_card_style.gd")

const INK := UiFactory.INK
const MUTED_INK := UiFactory.MUTED_INK
const TEAL := UiFactory.PRIMARY_DARK

var views: Dictionary = {}
var visible_metric_count := 0
var shape_id := "skill"
var rarity_level := 1
var quality_seams: Array[Panel] = []


func _ready() -> void:
	size = Vector2(480, 176)
	clip_contents = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus_mode = Control.FOCUS_ALL
	add_theme_constant_override("outline_size", 0)
	_build_quality_seams()
	_build_content()
	UpgradeChoiceCardStyle.apply_button(self, shape_id, rarity_level, false)


func configure(index: int) -> void:
	position = Vector2(30, 174 + index * 192)
	set_meta("rest_position", position)


func present(choice: Dictionary, view_model: Dictionary) -> void:
	set_meta("choice_id", str(choice.get("choice_key", "")))
	accessibility_name = str(choice.get("title", "未知强化"))
	accessibility_description = str(choice.get("description", ""))
	tooltip_text = str(choice.get("description", ""))
	shape_id = str(view_model.get("shape", "skill"))
	rarity_level = clampi(int(view_model.get("rarity_level", 1)), 1, 3)
	views["icon"].texture = view_model["icon"]
	views["type"].text = str(view_model["type"])
	views["name"].text = str(view_model["name"])
	var metrics: Array = view_model["metrics"]
	visible_metric_count = metrics.size()
	for index in range(views["metric_panels"].size()):
		var shown := index < metrics.size()
		views["metric_panels"][index].visible = shown
		if not shown:
			continue
		var metric: Dictionary = metrics[index]
		views["metric_symbols"][index].set("glyph_id", str(metric["symbol"]))
		views["metric_symbols"][index].queue_redraw()
		views["metric_labels"][index].text = str(metric["label"])
		views["metric_values"][index].text = str(metric["value"])
	_layout_metric_panels(visible_metric_count)
	var special := str(view_model["special"])
	views["special_panel"].visible = not special.is_empty()
	views["special"].text = special
	var highlighted := bool(view_model["highlighted"])
	UpgradeChoiceCardStyle.apply_content(views, quality_seams, shape_id, rarity_level, highlighted)
	UpgradeChoiceCardStyle.apply_button(self, shape_id, rarity_level, highlighted)


func metric_count() -> int:
	return visible_metric_count


func _build_quality_seams() -> void:
	for index in range(2):
		var seam := Panel.new()
		var inset := 8.0 + index * 4.0
		seam.position = Vector2(inset, inset)
		seam.size = size - Vector2(inset * 2.0, inset * 2.0)
		seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.border_color = Color(UiFactory.RARE, 0.42 - index * 0.08)
		style.set_border_width_all(1)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 3
		seam.add_theme_stylebox_override("panel", style)
		seam.visible = false
		add_child(seam)
		quality_seams.append(seam)


func _build_content() -> void:
	var icon_back := Panel.new()
	icon_back.position = Vector2(18, 34)
	icon_back.size = Vector2(108, 108)
	icon_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_back)
	var icon := TextureRect.new()
	icon.position = Vector2(12, 10)
	icon.size = Vector2(84, 84)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_back.add_child(icon)
	var type_panel := Panel.new()
	type_panel.position = Vector2(144, 16)
	type_panel.size = Vector2(126, 28)
	type_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(type_panel)
	var type_label := _surface_label("", 14, TEAL)
	type_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	type_label.offset_left = 12.0
	type_label.offset_right = -12.0
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.clip_text = true
	type_panel.add_child(type_label)
	var name_label := _surface_label("", 23, INK)
	name_label.position = Vector2(144, 48)
	name_label.size = Vector2(310, 38)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	add_child(name_label)
	var title_rule := ColorRect.new()
	title_rule.position = Vector2(144, 87)
	title_rule.size = Vector2(300, 2)
	title_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_rule)
	var metric_band := Panel.new()
	metric_band.position = Vector2(144, 96)
	metric_band.size = Vector2(300, 60)
	metric_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(metric_band)
	var metric_views := _build_metric_panels(metric_band)
	var special_panel := _build_special_panel()
	views = {
		"icon": icon,
		"icon_back": icon_back,
		"type": type_label,
		"type_panel": type_panel,
		"name": name_label,
		"title_rule": title_rule,
		"metric_panels": metric_views["panels"],
		"metric_symbols": metric_views["symbols"],
		"metric_labels": metric_views["labels"],
		"metric_values": metric_views["values"],
		"metric_band": metric_band,
		"special_panel": special_panel,
		"special": special_panel.get_child(0),
	}


func _build_metric_panels(parent: Control) -> Dictionary:
	var panels: Array[Panel] = []
	var symbols: Array[Control] = []
	var labels: Array[Label] = []
	var values: Array[Label] = []
	for index in range(3):
		var panel := Panel.new()
		panel.position = Vector2(4 + index * 98, 3)
		panel.size = Vector2(94, 54)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		parent.add_child(panel)
		panels.append(panel)
		var symbol := SunlitGlyph.new()
		symbol.glyph_id = "confirm"
		symbol.position = Vector2(5, 16)
		symbol.size = Vector2(24, 24)
		panel.add_child(symbol)
		symbols.append(symbol)
		var caption := _surface_label("", 14, MUTED_INK)
		caption.anchor_right = 1.0
		caption.offset_left = 32.0
		caption.offset_top = 3.0
		caption.offset_right = -4.0
		caption.offset_bottom = 25.0
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.clip_text = true
		panel.add_child(caption)
		labels.append(caption)
		var value := _surface_label("", 17, INK)
		value.anchor_right = 1.0
		value.offset_left = 32.0
		value.offset_top = 24.0
		value.offset_right = -4.0
		value.offset_bottom = 52.0
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value.clip_text = true
		panel.add_child(value)
		values.append(value)
	return {"panels": panels, "symbols": symbols, "labels": labels, "values": values}


func _layout_metric_panels(count: int) -> void:
	if count <= 0:
		return
	var gap := 4.0
	var available_width := 292.0
	var panel_width := 164.0 if count == 1 else (available_width - gap * (count - 1)) / count
	var start_x := 4.0 + (available_width - panel_width) * 0.5 if count == 1 else 4.0
	for index in range(count):
		views["metric_panels"][index].position.x = start_x + index * (panel_width + gap)
		views["metric_panels"][index].size.x = panel_width


func _build_special_panel() -> Panel:
	var panel := Panel.new()
	panel.position = Vector2(344, 13)
	panel.size = Vector2(112, 30)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var label := _surface_label("", 14, Color(0.54, 0.28, 0.05, 1.0))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _surface_label(text: String, font_size: int, color: Color) -> Label:
	var node := UiFactory.label(text, font_size, color)
	node.add_theme_constant_override("outline_size", 0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
