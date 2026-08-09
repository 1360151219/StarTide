extends Control

signal confirmed
signal adjust_character_requested
signal closed

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const HERO_TEXTURES := {
	"star_warden": preload("res://assets/art/characters/star_tide_warden.png"),
	"ember_ranger": preload("res://assets/art/characters/emberwing_ranger.png"),
}

var records: RefCounted
var title_label: Label
var level_label: Label
var objective_label: Label
var hero_label: Label
var role_label: Label
var power_label: Label
var power_hint_label: Label
var hero_portrait: TextureRect
var adjust_button: Button
var confirm_button: Button
var back_button: Button


func _ready() -> void:
	ScreenLayout.fill(self)
	z_index = 40
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.006, 0.04, 0.07, 0.78)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(veil)
	ScreenLayout.fill(veil)
	var card := Panel.new()
	card.position = Vector2(42, 220)
	card.size = Vector2(456, 442)
	SunlitCardStyle.apply_panel(card, UiFactory.SURFACE, UiFactory.PRIMARY, 12.0, true, false, "map_tag")
	add_child(card)
	title_label = _label(card, "远征确认", 30, UiFactory.INK, Vector2(62, 22), Vector2(326, 46))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label = _label(card, "", 25, UiFactory.ACCENT_DARK, Vector2(24, 80), Vector2(408, 36))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label = _label(card, "", 16, UiFactory.MUTED_INK, Vector2(34, 120), Vector2(388, 50))
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var divider := ColorRect.new()
	divider.color = Color(UiFactory.PRIMARY, 0.28)
	divider.position = Vector2(34, 178)
	divider.size = Vector2(388, 2)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(divider)
	hero_portrait = TextureRect.new()
	hero_portrait.position = Vector2(34, 190)
	hero_portrait.size = Vector2(110, 142)
	hero_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(hero_portrait)
	hero_label = _label(card, "", 25, UiFactory.INK, Vector2(160, 194), Vector2(264, 34))
	role_label = _label(card, "", 16, UiFactory.PRIMARY_DARK, Vector2(160, 230), Vector2(264, 28))
	power_label = _label(card, "", 23, UiFactory.ACCENT_DARK, Vector2(160, 270), Vector2(264, 36))
	power_hint_label = _label(card, "", 13, UiFactory.MUTED_INK, Vector2(160, 310), Vector2(264, 38))
	power_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	adjust_button = _button(card, "调整角色", Vector2(24, 360), Vector2(188, 58), false)
	adjust_button.pressed.connect(adjust_character_requested.emit)
	confirm_button = _button(card, "开始远征", Vector2(220, 360), Vector2(212, 58), true)
	confirm_button.pressed.connect(confirmed.emit)
	back_button = Button.new()
	back_button.position = Vector2(386, 16)
	back_button.size = Vector2(48, 48)
	back_button.text = "×"
	back_button.add_theme_font_size_override("font_size", 25)
	back_button.accessibility_name = "返回关卡大厅"
	UiFactory.apply_secondary_button(back_button)
	back_button.pressed.connect(closed.emit)
	card.add_child(back_button)
	visible = false


func configure(run_records: RefCounted) -> void:
	records = run_records


func show_for(hero_id: String, level: LevelConfig) -> void:
	var hero := HeroCatalog.hero(hero_id)
	hero_portrait.texture = HERO_TEXTURES.get(hero_id)
	var snapshot: Dictionary = records.get_permanent_snapshot(hero_id)
	var power: Dictionary = snapshot.get("power", {})
	var current_power := int(power.get("total", snapshot.get("combat_power", 0)))
	level_label.text = "%s  ·  %s" % [level.display_name, level.subtitle]
	objective_label.text = level.description
	hero_label.text = hero["name"]
	role_label.text = "%s  ·  %s" % [hero["title"], hero["passive_name"]]
	power_label.text = "战力 %d  /  推荐 %d" % [current_power, level.recommended_power]
	var ready := current_power >= level.recommended_power
	power_label.add_theme_color_override("font_color", UiFactory.ACCENT_DARK if ready else UiFactory.DANGER_DARK)
	power_hint_label.text = "状态良好，可以出发" if ready else "战力偏低，仍可挑战；也可先调整角色"
	visible = true


func _label(parent: Control, text: String, font_size: int, color: Color, at: Vector2, label_size: Vector2) -> Label:
	var label := UiFactory.label(text, font_size, color)
	label.position = at
	label.size = label_size
	label.clip_text = true
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, at: Vector2, button_size: Vector2, primary: bool) -> Button:
	var button := Button.new()
	button.position = at
	button.size = button_size
	button.text = text
	button.add_theme_font_size_override("font_size", 19)
	if primary:
		UiFactory.apply_primary_button(button)
	else:
		UiFactory.apply_secondary_button(button)
	parent.add_child(button)
	return button
