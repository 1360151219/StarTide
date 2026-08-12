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
var record_label: Label


func _ready() -> void:
	size = Vector2(504, 506)
	CharacterStyle.apply_panel(self, false, 22.0)
	_build_hero_summary()
	_build_metrics()
	record_label = CharacterStyle.add_label(self, "", 14, CharacterStyle.MUTED, Vector2(20, 418), Vector2(464, 56), HORIZONTAL_ALIGNMENT_CENTER)
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
	CharacterStyle.apply_continuous_panel(plate, UiFactory.SURFACE_ALT, Color(UiFactory.PRIMARY, 0.62), 8.0)
	add_child(plate)
	portrait = TextureRect.new()
	portrait.position = Vector2(18, 8)
	portrait.size = Vector2(130, 150)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plate.add_child(portrait)
	name_label = CharacterStyle.add_label(plate, "", 23, UiFactory.INK, Vector2(166, 16), Vector2(286, 32))
	UiFactory.apply_key_heading(name_label, 23)
	power_label = CharacterStyle.add_label(plate, "", 25, UiFactory.ACCENT_DARK, Vector2(166, 50), Vector2(286, 36))
	level_label = CharacterStyle.add_label(plate, "", 14, UiFactory.PRIMARY_DARK, Vector2(166, 90), Vector2(286, 24))
	progress_bar = CompactProgressBar.new()
	progress_bar.position = Vector2(166, 120)
	progress_bar.size = Vector2(270, 10)
	progress_bar.configure_colors(UiFactory.ACCENT, Color(UiFactory.PRIMARY, 0.2), 5.0)
	plate.add_child(progress_bar)
	progress_label = CharacterStyle.add_label(plate, "", 14, UiFactory.MUTED_INK, Vector2(166, 132), Vector2(270, 22), HORIZONTAL_ALIGNMENT_RIGHT)


func _build_metrics() -> void:
	var sheet := Panel.new()
	sheet.position = Vector2(14, 194)
	sheet.size = Vector2(476, 204)
	CharacterStyle.apply_continuous_panel(sheet, UiFactory.SURFACE_ALT, Color(UiFactory.PRIMARY, 0.48), 6.0)
	add_child(sheet)
	var heading := CharacterStyle.add_label(sheet, "核心属性", 18, CharacterStyle.INK, Vector2(16, 10), Vector2(180, 28))
	UiFactory.apply_key_heading(heading, 18)
	var metrics := [
		["health", "最大生命"], ["damage", "技能伤害"],
		["speed", "移动速度"], ["points", "可用技能点"],
	]
	for index in range(metrics.size()):
		var y := 44.0 + float(index) * 38.0
		if index > 0:
			_add_divider(sheet, Vector2(16, y), Vector2(444, 1))
		CharacterStyle.add_label(sheet, str(metrics[index][1]), 14, CharacterStyle.MUTED, Vector2(18, y + 2), Vector2(230, 34))
		metric_values[metrics[index][0]] = CharacterStyle.add_label(
			sheet, "0", 20, CharacterStyle.INK,
			Vector2(254, y), Vector2(202, 36), HORIZONTAL_ALIGNMENT_RIGHT
		)


func _add_divider(parent: Control, at: Vector2, divider_size: Vector2) -> void:
	var divider := ColorRect.new()
	divider.position = at
	divider.size = divider_size
	divider.color = Color(UiFactory.PRIMARY, 0.26)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(divider)


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
	level_label.text = "LV.%d" % level
	progress_bar.max_value = maxf(1.0, maximum)
	progress_bar.value = current
	progress_label.text = "经验  %d / %d" % [current, maximum]
	var health := float(resolved.get("max_health", hero["max_health"]))
	var speed := float(resolved.get("speed", hero["speed"]))
	var damage := maxf(0.0, float(resolved.get("damage_multiplier", progression.get("damage_multiplier", 1.0))) - 1.0)
	metric_values["health"].text = "%.0f" % health
	metric_values["speed"].text = "%.0f" % speed
	metric_values["damage"].text = "+%.0f%%" % (damage * 100.0)
	metric_values["points"].text = "%d" % int(progression.get("available_skill_points", 0))
	record_label.text = records.summary(hero_id) if is_instance_valid(records) and records.has_method("summary") else "等待首次远征"
