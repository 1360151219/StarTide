extends Control

signal slot_selected(slot_id: String)

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")
const StageBackdrop = preload("res://scripts/ui/character_stage_backdrop.gd")
const SlotCard = preload("res://scripts/ui/equipment_slot_card.gd")
const HERO_RIG_PATH := "res://scenes/presentation/hero_rig_2d.tscn"
const HERO_TEXTURES := {
	"star_warden": preload("res://assets/art/characters/star_tide_warden.png"),
	"ember_ranger": preload("res://assets/art/characters/emberwing_ranger.png"),
}

var slot_buttons: Dictionary = {}
var hero_name_label: Label
var hero_title_label: Label
var power_label: Label
var power_plate: Panel
var power_delta_feedback: Control
var power_delta_glyph: Control
var power_delta_label: Label
var level_label: Label
var portrait: TextureRect
var hero_rig: Node
var hero_hit_area: Button
var current_hero_id := ""
var content_active := false
var shown_power_by_hero: Dictionary = {}
var latest_power_by_hero: Dictionary = {}
var power_tween: Tween


func _ready() -> void:
	size = Vector2(504, 286)
	var backdrop := StageBackdrop.new()
	backdrop.size = size
	add_child(backdrop)
	hero_name_label = CharacterStyle.add_label(self, "", 26, UiFactory.INK, Vector2(116, 8), Vector2(272, 34), HORIZONTAL_ALIGNMENT_CENTER)
	hero_title_label = CharacterStyle.add_label(self, "", 14, UiFactory.PRIMARY_DARK, Vector2(116, 38), Vector2(272, 24), HORIZONTAL_ALIGNMENT_CENTER)
	hero_name_label.visible = false
	hero_title_label.visible = false
	portrait = TextureRect.new()
	portrait.position = Vector2(150, 46)
	portrait.size = Vector2(204, 194)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(portrait)
	_build_rig()
	hero_hit_area = Button.new()
	hero_hit_area.position = Vector2(154, 52)
	hero_hit_area.size = Vector2(196, 184)
	hero_hit_area.flat = true
	hero_hit_area.focus_mode = Control.FOCUS_ALL
	hero_hit_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hero_hit_area.tooltip_text = "点击角色查看动作"
	hero_hit_area.accessibility_name = "当前英雄，点击查看动作"
	hero_hit_area.pressed.connect(react)
	add_child(hero_hit_area)
	level_label = CharacterStyle.add_label(self, "", 14, UiFactory.INK, Vector2(14, 174), Vector2(94, 54), HORIZONTAL_ALIGNMENT_CENTER)
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var positions := {"weapon": Vector2(14, 72), "armor": Vector2(400, 72), "charm": Vector2(400, 170)}
	for slot_id in EquipmentCatalog.SLOTS:
		var card := SlotCard.new()
		card.position = positions[slot_id]
		card.size = Vector2(90, 88)
		card.pressed.connect(slot_selected.emit.bind(slot_id))
		add_child(card)
		slot_buttons[slot_id] = card
	power_plate = Panel.new()
	power_plate.name = "PowerPlate"
	power_plate.position = Vector2(142, 232)
	power_plate.size = Vector2(220, 50)
	power_plate.pivot_offset = power_plate.size * 0.5
	power_plate.tooltip_text = "当前英雄的综合战力"
	CharacterStyle.apply_continuous_panel(power_plate, Color(UiFactory.SURFACE, 0.9), Color(CharacterStyle.POWER, 0.74), 8.0)
	add_child(power_plate)
	var power_caption := CharacterStyle.add_label(
		power_plate, "战力", 14, UiFactory.PRIMARY_DARK,
		Vector2(14, 8), Vector2(54, 34), HORIZONTAL_ALIGNMENT_CENTER
	)
	power_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	power_label = CharacterStyle.add_label(
		power_plate, "1000", 30, CharacterStyle.POWER,
		Vector2(62, 1), Vector2(142, 46), HORIZONTAL_ALIGNMENT_CENTER
	)
	CharacterStyle.apply_power_label(power_label)
	power_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	power_delta_feedback = Control.new()
	power_delta_feedback.position = Vector2(4, 232)
	power_delta_feedback.size = Vector2(136, 28)
	power_delta_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	power_delta_feedback.z_index = 8
	add_child(power_delta_feedback)
	power_delta_glyph = SunlitGlyph.new()
	power_delta_glyph.position = Vector2.ZERO
	power_delta_glyph.size = Vector2(28, 28)
	power_delta_feedback.add_child(power_delta_glyph)
	power_delta_label = CharacterStyle.add_label(
		power_delta_feedback, "", 16, CharacterStyle.POWER_GAIN,
		Vector2(24, 0), Vector2(112, 28), HORIZONTAL_ALIGNMENT_CENTER
	)
	power_delta_label.name = "PowerDelta"
	power_delta_label.add_theme_color_override("font_outline_color", Color(0.02, 0.12, 0.15, 0.94))
	power_delta_label.add_theme_constant_override("outline_size", 3)
	power_delta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	power_delta_feedback.visible = false
	power_delta_label.visible = false


func show_for(hero_id: String, snapshot: Dictionary) -> void:
	var hero := HeroCatalog.hero(hero_id)
	var power: Dictionary = snapshot.get("power", {})
	var total_power := int(power.get("total", snapshot.get("combat_power", 0)))
	if hero_id != current_hero_id:
		_cancel_power_animation()
	current_hero_id = hero_id
	latest_power_by_hero[hero_id] = total_power
	if not shown_power_by_hero.has(hero_id):
		shown_power_by_hero[hero_id] = total_power
		_set_power_value(total_power)
	elif content_active:
		_present_power_change(hero_id, total_power)
	else:
		_set_power_value(total_power)
	hero_name_label.text = str(hero["name"])
	hero_title_label.text = "%s · %s" % [hero["title"], hero["passive_name"]]
	level_label.text = "英雄等级\nLV.%d" % int(snapshot.get("level", 1))
	portrait.texture = HERO_TEXTURES.get(hero_id)
	portrait.visible = not is_instance_valid(hero_rig)
	if is_instance_valid(hero_rig):
		hero_rig.configure(hero_id, 210.0)
		hero_rig.play_state("menu_idle", true)


func _present_power_change(hero_id: String, target_power: int) -> void:
	var previous := int(shown_power_by_hero.get(hero_id, target_power))
	shown_power_by_hero[hero_id] = target_power
	if hero_id != current_hero_id or target_power == previous:
		_set_power_value(target_power)
		return
	_animate_power_change(previous, target_power)


func _animate_power_change(previous: int, target_power: int) -> void:
	if power_tween != null and power_tween.is_valid():
		power_tween.kill()
	var delta := target_power - previous
	power_plate.scale = Vector2.ONE
	power_label.modulate = Color.WHITE
	power_label.add_theme_color_override("font_color", CharacterStyle.POWER_FLASH)
	power_delta_feedback.position = Vector2(4, 232)
	power_delta_feedback.modulate = Color.WHITE
	if delta > 0:
		power_delta_glyph.glyph_id = "up"
		power_delta_label.text = "战力 +%d" % delta
		power_delta_label.add_theme_color_override("font_color", CharacterStyle.POWER_GAIN)
		power_delta_label.accessibility_name = "战力提升 %d" % delta
	else:
		power_delta_glyph.glyph_id = "down"
		power_delta_label.text = "战力 -%d" % absi(delta)
		power_delta_label.add_theme_color_override("font_color", CharacterStyle.POWER_LOSS)
		power_delta_label.accessibility_name = "战力下降 %d" % absi(delta)
	power_delta_glyph.queue_redraw()
	power_delta_feedback.visible = true
	power_delta_glyph.visible = true
	power_delta_label.visible = true
	_set_power_value(previous)
	power_tween = create_tween().set_parallel(true)
	power_tween.tween_method(_set_power_value, float(previous), float(target_power), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	power_tween.tween_property(power_plate, "scale", Vector2(1.09, 1.09), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	power_tween.tween_property(power_plate, "scale", Vector2.ONE, 0.22).set_delay(0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	power_tween.tween_property(power_delta_feedback, "position:y", 204.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	power_tween.tween_property(power_delta_feedback, "modulate:a", 0.0, 0.52).set_delay(0.18)
	power_tween.tween_callback(_finish_power_animation).set_delay(0.72)


func _set_power_value(value: Variant) -> void:
	var rounded := roundi(float(value))
	power_label.text = "%d" % rounded
	power_label.accessibility_name = "当前战力 %d" % rounded


func _cancel_power_animation() -> void:
	if power_tween != null and power_tween.is_valid():
		power_tween.kill()
	power_tween = null
	power_plate.scale = Vector2.ONE
	power_label.modulate = Color.WHITE
	power_label.add_theme_color_override("font_color", CharacterStyle.POWER)
	power_delta_feedback.visible = false
	power_delta_glyph.visible = false
	power_delta_label.visible = false


func _finish_power_animation() -> void:
	power_plate.scale = Vector2.ONE
	power_label.add_theme_color_override("font_color", CharacterStyle.POWER)
	power_delta_feedback.visible = false
	power_delta_glyph.visible = false
	power_delta_label.visible = false
	if latest_power_by_hero.has(current_hero_id):
		_set_power_value(int(latest_power_by_hero[current_hero_id]))


func show_slot(slot_id: String, item: Dictionary) -> void:
	slot_buttons[slot_id].present(slot_id, item)


func set_active(active: bool) -> void:
	content_active = active
	if is_instance_valid(hero_rig):
		if hero_rig.has_method("set_active"):
			hero_rig.set_active(active)
		else:
			hero_rig.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if active and latest_power_by_hero.has(current_hero_id):
		_present_power_change(current_hero_id, int(latest_power_by_hero[current_hero_id]))


func react() -> void:
	if is_instance_valid(hero_rig) and hero_rig.has_method("trigger_menu_react"):
		hero_rig.trigger_menu_react()


func _build_rig() -> void:
	if not ResourceLoader.exists(HERO_RIG_PATH):
		return
	var rig_scene: PackedScene = load(HERO_RIG_PATH)
	hero_rig = rig_scene.instantiate()
	hero_rig.position = Vector2(252, 230)
	add_child(hero_rig)
