extends Control

signal slot_selected(slot_id: String)

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
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
var level_label: Label
var portrait: TextureRect
var hero_rig: Node
var hero_hit_area: Button


func _ready() -> void:
	size = Vector2(504, 286)
	var backdrop := StageBackdrop.new()
	backdrop.size = size
	add_child(backdrop)
	hero_name_label = CharacterStyle.add_label(self, "", 26, UiFactory.PALE, Vector2(116, 8), Vector2(272, 34), HORIZONTAL_ALIGNMENT_CENTER)
	hero_title_label = CharacterStyle.add_label(self, "", 13, UiFactory.CYAN, Vector2(116, 38), Vector2(272, 24), HORIZONTAL_ALIGNMENT_CENTER)
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
	level_label = CharacterStyle.add_label(self, "", 14, UiFactory.PALE, Vector2(14, 174), Vector2(94, 54), HORIZONTAL_ALIGNMENT_CENTER)
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var positions := {"weapon": Vector2(14, 72), "armor": Vector2(400, 72), "charm": Vector2(400, 170)}
	for slot_id in EquipmentCatalog.SLOTS:
		var card := SlotCard.new()
		card.position = positions[slot_id]
		card.size = Vector2(90, 88)
		card.pressed.connect(slot_selected.emit.bind(slot_id))
		add_child(card)
		slot_buttons[slot_id] = card
	var power_plate := Panel.new()
	power_plate.position = Vector2(170, 240)
	power_plate.size = Vector2(164, 40)
	power_plate.add_theme_stylebox_override("panel", CharacterStyle.surface(Color(0.035, 0.22, 0.26, 0.98), 18.0, UiFactory.GOLD))
	add_child(power_plate)
	power_label = CharacterStyle.add_label(power_plate, "战力 1000", 19, UiFactory.PALE, Vector2.ZERO, power_plate.size, HORIZONTAL_ALIGNMENT_CENTER)
	power_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func show_for(hero_id: String, snapshot: Dictionary) -> void:
	var hero := HeroCatalog.hero(hero_id)
	var power: Dictionary = snapshot.get("power", {})
	hero_name_label.text = str(hero["name"])
	hero_title_label.text = "%s · %s" % [hero["title"], hero["passive_name"]]
	power_label.text = "战力  %d" % int(power.get("total", snapshot.get("combat_power", 0)))
	level_label.text = "英雄等级\nLv.%d" % int(snapshot.get("level", 1))
	portrait.texture = HERO_TEXTURES.get(hero_id)
	portrait.visible = not is_instance_valid(hero_rig)
	if is_instance_valid(hero_rig):
		hero_rig.configure(hero_id, 210.0)
		hero_rig.play_state("menu_idle", true)


func show_slot(slot_id: String, item: Dictionary) -> void:
	slot_buttons[slot_id].present(slot_id, item)


func set_active(active: bool) -> void:
	if not is_instance_valid(hero_rig):
		return
	if hero_rig.has_method("set_active"):
		hero_rig.set_active(active)
	else:
		hero_rig.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


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
