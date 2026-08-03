extends Panel

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const CompactProgressBar = preload("res://scripts/ui/compact_progress_bar.gd")
const HERO_TEXTURES := {
	"star_warden": preload("res://assets/art/characters/star_tide_warden.png"),
	"ember_ranger": preload("res://assets/art/characters/emberwing_ranger.png"),
}

var records: RefCounted
var hero_id := ""
var portrait: TextureRect
var name_label: Label
var power_label: Label
var level_label: Label
var progress_label: Label
var progress_bar: Control
var metric_values: Dictionary = {}
var breakdown_values: Dictionary = {}
var record_label: Label


func _ready() -> void:
	size = Vector2(504, 574)
	add_theme_stylebox_override("panel", CharacterStyle.paper_card(false, 22.0))
	_build_hero_summary()
	CharacterStyle.add_label(self, "核心属性", 18, CharacterStyle.INK, Vector2(18, 194), Vector2(220, 30))
	var metrics := [
		["health", "最大生命", Vector2(16, 228)], ["speed", "移动速度", Vector2(258, 228)],
		["damage", "技能伤害", Vector2(16, 310)], ["points", "可用技能点", Vector2(258, 310)],
	]
	for row in metrics:
		metric_values[row[0]] = _metric_card(str(row[1]), row[2])
	CharacterStyle.add_label(self, "战力构成", 18, CharacterStyle.INK, Vector2(18, 400), Vector2(220, 30))
	var breakdowns := [
		["base", "基础"], ["level", "等级"], ["training", "技能"], ["equipment", "装备"],
	]
	for index in range(breakdowns.size()):
		breakdown_values[breakdowns[index][0]] = _breakdown_card(
			str(breakdowns[index][1]), Vector2(16 + index * 118, 436)
		)
	record_label = CharacterStyle.add_label(self, "", 14, CharacterStyle.MUTED, Vector2(20, 520), Vector2(464, 44), HORIZONTAL_ALIGNMENT_CENTER)
	record_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func configure(run_records: RefCounted) -> void:
	records = run_records


func show_for(selected_hero_id: String, snapshot: Dictionary) -> void:
	hero_id = selected_hero_id
	_refresh(snapshot)


func _build_hero_summary() -> void:
	var plate := Panel.new()
	plate.position = Vector2(12, 12)
	plate.size = Vector2(480, 166)
	plate.add_theme_stylebox_override("panel", CharacterStyle.surface(UiFactory.GLASS, 18.0, UiFactory.GOLD))
	add_child(plate)
	portrait = TextureRect.new()
	portrait.position = Vector2(18, 8)
	portrait.size = Vector2(130, 150)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plate.add_child(portrait)
	name_label = CharacterStyle.add_label(plate, "", 23, UiFactory.PALE, Vector2(166, 16), Vector2(286, 32))
	power_label = CharacterStyle.add_label(plate, "", 25, UiFactory.GOLD, Vector2(166, 50), Vector2(286, 36))
	level_label = CharacterStyle.add_label(plate, "", 14, UiFactory.CYAN, Vector2(166, 90), Vector2(286, 24))
	progress_bar = CompactProgressBar.new()
	progress_bar.position = Vector2(166, 120)
	progress_bar.size = Vector2(270, 10)
	progress_bar.configure_colors(UiFactory.GOLD, Color(0.3, 0.56, 0.56, 0.28), 5.0)
	plate.add_child(progress_bar)
	progress_label = CharacterStyle.add_label(plate, "", 12, UiFactory.PALE_MUTED, Vector2(166, 134), Vector2(270, 20), HORIZONTAL_ALIGNMENT_RIGHT)


func _refresh(snapshot: Dictionary) -> void:
	var hero := HeroCatalog.hero(hero_id)
	var progression: Dictionary = snapshot.get("progression", snapshot)
	var power: Dictionary = snapshot.get("power", {})
	var resolved: Dictionary = snapshot.get("resolved_stats", {})
	var level := int(progression.get("level", snapshot.get("level", 1)))
	var current := int(progression.get("level_progress", snapshot.get("level_progress", 0)))
	var maximum := int(progression.get("level_progress_max", snapshot.get("level_progress_max", 100)))
	portrait.texture = HERO_TEXTURES.get(hero_id)
	name_label.text = str(hero["name"])
	power_label.text = "战力  %d" % int(power.get("total", snapshot.get("combat_power", 0)))
	level_label.text = "英雄等级  Lv.%d" % level
	progress_bar.max_value = maxf(1.0, maximum)
	progress_bar.value = current
	progress_label.text = "成长经验  %d/%d" % [current, maximum]
	var health := float(resolved.get("max_health", hero["max_health"]))
	var speed := float(resolved.get("speed", hero["speed"]))
	var damage := maxf(0.0, float(resolved.get("damage_multiplier", progression.get("damage_multiplier", 1.0))) - 1.0)
	metric_values["health"].text = "%.0f" % health
	metric_values["speed"].text = "%.0f" % speed
	metric_values["damage"].text = "+%.1f%%" % (damage * 100.0)
	metric_values["points"].text = "%d" % int(progression.get("available_skill_points", 0))
	for key in breakdown_values:
		breakdown_values[key].text = "%d" % int(power.get(key, 0))
	record_label.text = records.summary(hero_id) if is_instance_valid(records) and records.has_method("summary") else "等待首次远征"


func _metric_card(caption: String, at: Vector2) -> Label:
	var card := Panel.new()
	card.position = at
	card.size = Vector2(230, 72)
	card.add_theme_stylebox_override("panel", CharacterStyle.paper_card(true, 16.0, Color(UiFactory.PAPER_STROKE, 0.78), false))
	add_child(card)
	CharacterStyle.add_label(card, caption, 13, CharacterStyle.MUTED, Vector2(14, 9), Vector2(202, 20))
	return CharacterStyle.add_label(card, "0", 23, CharacterStyle.INK, Vector2(14, 30), Vector2(202, 34))


func _breakdown_card(caption: String, at: Vector2) -> Label:
	var card := Panel.new()
	card.position = at
	card.size = Vector2(110, 68)
	card.add_theme_stylebox_override("panel", CharacterStyle.paper_card(false, 14.0, Color(UiFactory.PAPER_STROKE, 0.82), false))
	add_child(card)
	CharacterStyle.add_label(card, caption, 12, CharacterStyle.MUTED, Vector2(8, 6), Vector2(94, 20), HORIZONTAL_ALIGNMENT_CENTER)
	return CharacterStyle.add_label(card, "0", 19, CharacterStyle.INK, Vector2(8, 28), Vector2(94, 30), HORIZONTAL_ALIGNMENT_CENTER)
