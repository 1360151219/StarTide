extends Button

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const UpgradeChoiceCardStyle = preload("res://scripts/ui/upgrade_choice_card_style.gd")
const ICON_MEDALLION := preload("res://assets/art/ui/upgrade/upgrade_icon_medallion.png")
const TYPE_RIBBON := preload("res://assets/art/ui/upgrade/upgrade_type_ribbon.png")
const METRIC_ICONS := {
	"level": preload("res://assets/art/ui/upgrade/metrics/metric_level.png"),
	"confirm": preload("res://assets/art/ui/upgrade/metrics/metric_trait.png"),
	"expedition": preload("res://assets/art/ui/upgrade/metrics/metric_target.png"),
	"heal": preload("res://assets/art/ui/upgrade/metrics/metric_heal.png"),
	"haste": preload("res://assets/art/ui/upgrade/metrics/metric_speed.png"),
	"enemy": preload("res://assets/art/ui/upgrade/metrics/metric_damage.png"),
	"clock": preload("res://assets/art/ui/upgrade/metrics/metric_time.png"),
	"magnet": preload("res://assets/art/ui/upgrade/metrics/metric_range.png"),
	"bomb": preload("res://assets/art/ui/upgrade/metrics/metric_range.png"),
	"count": preload("res://assets/art/ui/upgrade/metrics/metric_count.png"),
}

var views: Dictionary = {}
var visible_metric_count := 0
var shape_id := "skill"
var rarity_level := 1


func _ready() -> void:
	size = Vector2(452, 168)
	clip_contents = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus_mode = Control.FOCUS_ALL
	add_theme_constant_override("outline_size", 0)
	_build_content()
	UpgradeChoiceCardStyle.apply_button(self, rarity_level, false)


func configure(index: int) -> void:
	position = Vector2(44, 252 + index * 174)
	set_meta("rest_position", position)


func present(choice: Dictionary, view_model: Dictionary) -> void:
	set_meta("choice_id", str(choice.get("choice_key", "")))
	accessibility_name = str(choice.get("title", "未知强化"))
	accessibility_description = str(choice.get("description", ""))
	tooltip_text = accessibility_description
	shape_id = str(view_model.get("shape", "skill"))
	rarity_level = clampi(int(view_model.get("rarity_level", 1)), 1, 3)
	views["icon"].texture = view_model["icon"]
	views["icon"].modulate = Color.WHITE
	var is_branch := bool(view_model.get("branch", false))
	var label_over_icon := is_branch or shape_id == "relic"
	views["type_ribbon"].position.x = 16.0 if label_over_icon else 132.0
	views["type"].position.x = 28.0 if label_over_icon else 144.0
	views["icon"].position.y = 43.0 if shape_id == "relic" else 47.0
	views["icon_ring"].position.y = 36.0 if shape_id == "relic" else 40.0
	views["type"].text = str(view_model["type"])
	views["type_ribbon"].modulate = UpgradeChoiceCardStyle.type_modulate(shape_id)
	views["name"].text = str(view_model["name"])
	views["description"].text = str(view_model["description"])
	var metrics: Array = view_model["metrics"]
	visible_metric_count = mini(metrics.size(), 3)
	for index in range(views["metric_panels"].size()):
		var shown := index < visible_metric_count
		views["metric_panels"][index].visible = shown
		if not shown:
			continue
		var metric: Dictionary = metrics[index]
		views["metric_symbols"][index].texture = METRIC_ICONS.get(str(metric["symbol"]), METRIC_ICONS["confirm"])
		views["metric_labels"][index].text = str(metric["label"])
		views["metric_values"][index].text = str(metric["value"])
	_layout_metric_panels(visible_metric_count)
	var special := str(view_model["special"])
	views["special_panel"].visible = not special.is_empty()
	views["special"].text = special
	var highlighted := bool(view_model["highlighted"])
	UpgradeChoiceCardStyle.apply_content(views, rarity_level, highlighted)
	views["special_panel"].visible = not special.is_empty()
	UpgradeChoiceCardStyle.apply_button(self, rarity_level, highlighted)


func metric_count() -> int:
	return visible_metric_count


func _build_content() -> void:
	var icon := _texture_layer(null, Vector2(23, 47), Vector2(90, 90), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	var icon_ring := _texture_layer(ICON_MEDALLION, Vector2(16, 40), Vector2(104, 104))
	var type_ribbon := _texture_layer(TYPE_RIBBON, Vector2(132, 10), Vector2(128, 30), TextureRect.STRETCH_SCALE)
	var type_label := _surface_label("", 14, UiFactory.HUD_TEXT)
	type_label.position = Vector2(144, 11)
	type_label.size = Vector2(94, 27)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.clip_text = true
	add_child(type_label)
	var special_panel := Panel.new()
	special_panel.position = Vector2(338, 8)
	special_panel.size = Vector2(100, 28)
	special_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	special_panel.add_theme_stylebox_override("panel", _special_style())
	add_child(special_panel)
	var special := _surface_label("", 14, UiFactory.PRIMARY_DARK)
	special.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	special.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	special.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	special_panel.add_child(special)
	var name_label := _surface_label("", 23, UiFactory.INK)
	UiFactory.apply_key_heading(name_label, 23, UiFactory.INK)
	name_label.position = Vector2(136, 39)
	name_label.size = Vector2(302, 31)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	add_child(name_label)
	var description := _surface_label("", 14, UiFactory.MUTED_INK)
	description.position = Vector2(136, 70)
	description.size = Vector2(302, 35)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(description)
	var title_rule := ColorRect.new()
	title_rule.position = Vector2(136, 106)
	title_rule.size = Vector2(302, 1)
	title_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_rule)
	var metric_band := Control.new()
	metric_band.position = Vector2(136, 109)
	metric_band.size = Vector2(302, 52)
	metric_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(metric_band)
	var metric_views := _build_metric_panels(metric_band)
	views = {
		"icon": icon, "icon_ring": icon_ring, "type": type_label, "type_ribbon": type_ribbon,
		"name": name_label, "description": description, "title_rule": title_rule,
		"metric_panels": metric_views["panels"], "metric_symbols": metric_views["symbols"],
		"metric_labels": metric_views["labels"], "metric_values": metric_views["values"],
		"special_panel": special_panel, "special": special,
	}


func _build_metric_panels(parent: Control) -> Dictionary:
	var panels: Array[Control] = []
	var symbols: Array[TextureRect] = []
	var labels: Array[Label] = []
	var values: Array[Label] = []
	for index in range(3):
		var panel := Control.new()
		panel.position = Vector2(index * 102, 0)
		panel.size = Vector2(98, 52)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(panel)
		panels.append(panel)
		var label_row := HBoxContainer.new()
		label_row.position = Vector2.ZERO
		label_row.size = Vector2(98, 24)
		label_row.alignment = BoxContainer.ALIGNMENT_CENTER
		label_row.add_theme_constant_override("separation", 4)
		label_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label_row)
		var symbol := UiFactory.texture_rect(METRIC_ICONS["confirm"], TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		symbol.custom_minimum_size = Vector2(22, 22)
		symbol.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		label_row.add_child(symbol)
		symbols.append(symbol)
		var caption := _surface_label("", 13, UiFactory.MUTED_INK)
		caption.custom_minimum_size = Vector2(56, 24)
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.clip_text = true
		label_row.add_child(caption)
		labels.append(caption)
		var value := _surface_label("", 16, UiFactory.INK)
		value.position = Vector2(0, 24)
		value.size = Vector2(98, 27)
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
	var width := (302.0 - gap * (count - 1)) / count
	for index in range(count):
		var panel: Control = views["metric_panels"][index]
		panel.position.x = index * (width + gap)
		panel.size.x = width
		panel.get_child(0).size.x = width
		views["metric_values"][index].size.x = width


func _texture_layer(texture: Texture2D, at: Vector2, extent: Vector2, stretch_mode := TextureRect.STRETCH_KEEP_ASPECT_CENTERED) -> TextureRect:
	var layer := UiFactory.texture_rect(texture, stretch_mode)
	layer.position = at
	layer.size = extent
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(layer)
	return layer


func _special_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UiFactory.ACCENT_LIGHT, 0.76)
	style.border_color = Color(UiFactory.ACCENT_DARK, 0.58)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 3
	return style


func _surface_label(text: String, font_size: int, color: Color) -> Label:
	var node := UiFactory.surface_label(text, font_size, color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
