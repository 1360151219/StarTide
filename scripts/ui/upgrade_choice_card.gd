extends Button

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

const CARD_SURFACE := Color(1.0, 0.98, 0.9, 0.98)
const CARD_MINT := Color(0.89, 0.97, 0.92, 0.98)
const CARD_GOLD := Color(1.0, 0.94, 0.72, 0.99)
const INK := Color(0.07, 0.2, 0.24, 1.0)
const MUTED_INK := Color(0.25, 0.39, 0.42, 1.0)
const TEAL := Color(0.08, 0.55, 0.57, 1.0)
const AMBER := Color(1.0, 0.67, 0.2, 1.0)

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
		views["metric_symbols"][index].text = str(metric["symbol"])
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
	icon_back.position = Vector2(14, 16)
	icon_back.size = Vector2(104, 144)
	icon_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_back.add_theme_stylebox_override("panel", UiFactory.panel_style(CARD_MINT, 20.0, Color(0.31, 0.72, 0.65, 0.78)))
	add_child(icon_back)
	var icon := TextureRect.new()
	icon.position = Vector2(13, 10)
	icon.size = Vector2(78, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_back.add_child(icon)
	var type_label := _surface_label("", 12, TEAL)
	type_label.position = Vector2(8, 112)
	type_label.size = Vector2(88, 24)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.add_theme_stylebox_override("normal", UiFactory.flat_bar_style(Color(0.81, 0.94, 0.86, 0.96), 10.0))
	icon_back.add_child(type_label)
	var name_label := _surface_label("", 23, INK)
	name_label.position = Vector2(132, 30)
	name_label.size = Vector2(320, 38)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	add_child(name_label)
	var metric_views := _build_metric_panels()
	var special_panel := _build_special_panel()
	views = {
		"icon": icon,
		"type": type_label,
		"name": name_label,
		"metric_panels": metric_views["panels"],
		"metric_symbols": metric_views["symbols"],
		"metric_labels": metric_views["labels"],
		"metric_values": metric_views["values"],
		"special_panel": special_panel,
		"special": special_panel.get_child(0),
	}


func _build_metric_panels() -> Dictionary:
	var panels: Array[Panel] = []
	var symbols: Array[Label] = []
	var labels: Array[Label] = []
	var values: Array[Label] = []
	for index in range(3):
		var panel := Panel.new()
		panel.position = Vector2(132 + index * 108, 82)
		panel.size = Vector2(102, 70)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(panel)
		panels.append(panel)
		var symbol := _surface_label("✦", 21, TEAL)
		symbol.position = Vector2(6, 3)
		symbol.size = Vector2(28, 26)
		symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	var available_width := 320.0
	var panel_width := 156.0 if count == 1 else (available_width - gap * (count - 1)) / count
	var start_x := 132.0 + (available_width - panel_width) * 0.5 if count == 1 else 132.0
	for index in range(count):
		views["metric_panels"][index].position.x = start_x + index * (panel_width + gap)
		views["metric_panels"][index].size.x = panel_width


func _build_special_panel() -> Panel:
	var panel := Panel.new()
	panel.position = Vector2(344, 8)
	panel.size = Vector2(108, 24)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(CARD_GOLD, 12.0, AMBER))
	add_child(panel)
	var label := _surface_label("", 11, Color(0.54, 0.28, 0.05, 1.0))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _style_metric_panels(highlighted: bool) -> void:
	for panel in views["metric_panels"]:
		panel.add_theme_stylebox_override(
			"panel",
			UiFactory.panel_style(
				Color(1.0, 0.94, 0.72, 0.94) if highlighted else Color(0.86, 0.95, 0.88, 0.96),
				13.0,
				AMBER if highlighted else Color(0.3, 0.7, 0.59, 0.52)
			)
		)


func _apply_style(highlighted: bool, branch: bool) -> void:
	var background := CARD_GOLD if highlighted else CARD_SURFACE
	var border := AMBER if highlighted else (Color(0.39, 0.67, 0.83, 0.95) if branch else Color(0.22, 0.66, 0.61, 0.9))
	UiFactory.apply_button_styles(self, background, border, Color(0.78, 0.8, 0.72, 0.92), Color(0.54, 0.61, 0.56, 0.75))


func _surface_label(text: String, font_size: int, color: Color) -> Label:
	var node := UiFactory.label(text, font_size, color)
	node.add_theme_constant_override("outline_size", 0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
