extends Button

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")

const CARD_SURFACE := Color(1.0, 0.98, 0.9, 0.98)
const CARD_MINT := UiFactory.SURFACE_ALT
const CARD_GOLD := Color(1.0, 0.94, 0.72, 0.99)
const INK := UiFactory.INK
const MUTED_INK := UiFactory.MUTED_INK
const TEAL := UiFactory.PRIMARY_DARK
const AMBER := UiFactory.ACCENT_DARK

var views: Dictionary = {}
var visible_metric_count := 0


func _ready() -> void:
	size = Vector2(480, 176)
	clip_contents = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus_mode = Control.FOCUS_ALL
	add_theme_constant_override("outline_size", 0)
	_build_content()
	_apply_style(false, false)


func configure(index: int) -> void:
	position = Vector2(30, 174 + index * 192)


func present(choice: Dictionary, view_model: Dictionary) -> void:
	set_meta("choice_id", str(choice.get("choice_key", "")))
	accessibility_name = str(choice.get("title", "未知强化"))
	accessibility_description = str(choice.get("description", ""))
	tooltip_text = str(choice.get("description", ""))
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
	_style_metric_panels(highlighted)
	_apply_style(highlighted, bool(view_model["branch"]))


func metric_count() -> int:
	return visible_metric_count


func _build_content() -> void:
	var icon_back := Panel.new()
	icon_back.position = Vector2(16, 26)
	icon_back.size = Vector2(116, 116)
	icon_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var medallion_style := SunlitCardStyle.panel_style(CARD_MINT, Color(UiFactory.PRIMARY, 0.78), 58.0, false)
	medallion_style.set_corner_radius_all(58)
	medallion_style.set_border_width_all(3)
	icon_back.add_theme_stylebox_override("panel", medallion_style)
	add_child(icon_back)
	var icon := TextureRect.new()
	icon.position = Vector2(12, 10)
	icon.size = Vector2(92, 92)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_back.add_child(icon)
	var type_label := _surface_label("", 12, TEAL)
	type_label.position = Vector2(24, 140)
	type_label.size = Vector2(100, 24)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.add_theme_stylebox_override("normal", UiFactory.flat_bar_style(Color(UiFactory.SURFACE, 0.96), 5.0))
	add_child(type_label)
	var name_plate := Panel.new()
	name_plate.position = Vector2(144, 18)
	name_plate.size = Vector2(270, 50)
	name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SunlitCardStyle.apply_panel(name_plate, Color(UiFactory.SURFACE, 0.78), Color(UiFactory.ACCENT_DARK, 0.5), 6.0, false, true, "map_tag")
	add_child(name_plate)
	var name_label := _surface_label("", 23, INK)
	name_label.position = Vector2(12, 5)
	name_label.size = Vector2(246, 40)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_plate.add_child(name_label)
	var metric_band := Panel.new()
	metric_band.position = Vector2(144, 76)
	metric_band.size = Vector2(292, 80)
	metric_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(metric_band)
	var metric_views := _build_metric_panels(metric_band)
	var special_panel := _build_special_panel()
	views = {
		"icon": icon,
		"type": type_label,
		"name": name_label,
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
		panel.position = Vector2(6 + index * 108, 4)
		panel.size = Vector2(102, 70)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		parent.add_child(panel)
		panels.append(panel)
		var symbol := SunlitGlyph.new()
		symbol.glyph_id = "confirm"
		symbol.position = Vector2(7, 4)
		symbol.size = Vector2(26, 26)
		panel.add_child(symbol)
		symbols.append(symbol)
		var caption := _surface_label("", 11, MUTED_INK)
		caption.anchor_right = 1.0
		caption.offset_left = 34.0
		caption.offset_top = 5.0
		caption.offset_right = -6.0
		caption.offset_bottom = 27.0
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.clip_text = true
		panel.add_child(caption)
		labels.append(caption)
		var value := _surface_label("", 17, INK)
		value.anchor_right = 1.0
		value.offset_left = 6.0
		value.offset_top = 29.0
		value.offset_right = -6.0
		value.offset_bottom = 63.0
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value.clip_text = true
		panel.add_child(value)
		values.append(value)
	return {"panels": panels, "symbols": symbols, "labels": labels, "values": values}


func _layout_metric_panels(count: int) -> void:
	if count <= 0:
		return
	var gap := 6.0
	var available_width := 280.0
	var panel_width := 156.0 if count == 1 else (available_width - gap * (count - 1)) / count
	var start_x := 6.0 + (available_width - panel_width) * 0.5 if count == 1 else 6.0
	for index in range(count):
		views["metric_panels"][index].position.x = start_x + index * (panel_width + gap)
		views["metric_panels"][index].size.x = panel_width


func _build_special_panel() -> Panel:
	var panel := Panel.new()
	panel.position = Vector2(362, 7)
	panel.size = Vector2(96, 24)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SunlitCardStyle.apply_panel(panel, CARD_GOLD, UiFactory.ACCENT_DARK, 6.0, false, true, "enamel", 3)
	add_child(panel)
	var label := _surface_label("", 11, Color(0.54, 0.28, 0.05, 1.0))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _style_metric_panels(highlighted: bool) -> void:
	SunlitCardStyle.apply_panel(
		views["metric_band"],
		Color(UiFactory.ACCENT_LIGHT, 0.78) if highlighted else Color(UiFactory.SURFACE_ALT, 0.9),
		Color(UiFactory.ACCENT_DARK, 0.6) if highlighted else Color(UiFactory.PRIMARY, 0.48),
		6.0,
		false,
		true,
		"ribbon"
	)
	for symbol in views["metric_symbols"]:
		symbol.set_selected(highlighted)


func _apply_style(highlighted: bool, branch: bool) -> void:
	var background := CARD_GOLD if highlighted else CARD_SURFACE
	var border := UiFactory.ACCENT_DARK if highlighted else (UiFactory.RARE if branch else UiFactory.PRIMARY)
	var normal := SunlitCardStyle.panel_style(background, border, 18.0, highlighted)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = background.lightened(0.025)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = background.darkened(0.04)
	var disabled_style := SunlitCardStyle.panel_style(Color(UiFactory.SURFACE_ALT, 0.88), Color(UiFactory.DISABLED, 0.62), 18.0, false, false)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("disabled", disabled_style)
	add_theme_stylebox_override("focus", SunlitCardStyle.panel_style(Color.TRANSPARENT, UiFactory.ACCENT, 18.0, true, false))
	SunlitCardStyle.decorate(self, border, 18.0, false, highlighted, UiFactory.ACCENT, "reward_card", 3 if highlighted else 2 if branch else 1)


func _surface_label(text: String, font_size: int, color: Color) -> Label:
	var node := UiFactory.label(text, font_size, color)
	node.add_theme_constant_override("outline_size", 0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
