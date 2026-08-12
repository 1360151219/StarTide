extends Panel

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const CompactProgressBar = preload("res://scripts/ui/compact_progress_bar.gd")
const SunlitGlyph = preload("res://scripts/ui/sunlit_glyph.gd")
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
var metric_labels: Dictionary = {}
var record_label: Label


func _ready() -> void:
	size = Vector2(504, 506)
	CharacterStyle.apply_panel(self, false, 22.0)
	_build_hero_summary()
	_build_metrics()
	_add_divider(self, Vector2(24, 400), Vector2(456, 1))
	CharacterStyle.add_label(self, "远征记录", 14, CharacterStyle.MUTED, Vector2(26, 414), Vector2(88, 32))
	record_label = CharacterStyle.add_label(self, "", 14, CharacterStyle.INK, Vector2(118, 406), Vector2(360, 48), HORIZONTAL_ALIGNMENT_RIGHT)
	record_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func configure(run_records: RefCounted) -> void:
	records = run_records


func show_for(selected_hero_id: String, snapshot: Dictionary) -> void:
	hero_id = selected_hero_id
	_refresh(snapshot)


func _build_hero_summary() -> void:
	portrait = TextureRect.new()
	portrait.position = Vector2(22, 14)
	portrait.size = Vector2(134, 154)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(portrait)
	_add_divider(self, Vector2(170, 20), Vector2(1, 144))
	name_label = CharacterStyle.add_label(self, "", 23, UiFactory.INK, Vector2(188, 20), Vector2(282, 32))
	UiFactory.apply_key_heading(name_label, 23)
	power_label = CharacterStyle.add_label(self, "", 25, UiFactory.ACCENT_DARK, Vector2(188, 54), Vector2(282, 36))
	level_label = CharacterStyle.add_label(self, "", 14, UiFactory.PRIMARY_DARK, Vector2(188, 96), Vector2(282, 24))
	progress_bar = CompactProgressBar.new()
	progress_bar.position = Vector2(188, 126)
	progress_bar.size = Vector2(270, 10)
	progress_bar.configure_colors(UiFactory.ACCENT, Color(UiFactory.PRIMARY, 0.2), 5.0)
	add_child(progress_bar)
	progress_label = CharacterStyle.add_label(self, "", 14, UiFactory.MUTED_INK, Vector2(188, 140), Vector2(270, 22), HORIZONTAL_ALIGNMENT_RIGHT)
	_add_divider(self, Vector2(24, 182), Vector2(456, 1))


func _build_metrics() -> void:
	var heading := CharacterStyle.add_label(self, "核心属性", 18, CharacterStyle.INK, Vector2(26, 190), Vector2(180, 28))
	UiFactory.apply_key_heading(heading, 18)
	CharacterStyle.add_label(self, "当前结算值", 14, CharacterStyle.MUTED, Vector2(330, 194), Vector2(148, 24), HORIZONTAL_ALIGNMENT_RIGHT)
	var metrics := [
		["attack", "攻击力", "equipment"], ["health", "最大生命", "heal"],
		["speed", "移动速度", "haste"], ["frequency", "施法频率", "clock"],
	]
	for index in range(metrics.size()):
		var y := 226.0 + float(index) * 40.0
		if index > 0:
			_add_divider(self, Vector2(26, y), Vector2(452, 1))
		var glyph := SunlitGlyph.new()
		glyph.position = Vector2(28, y + 6)
		glyph.size = Vector2(24, 24)
		glyph.glyph_id = str(metrics[index][2])
		add_child(glyph)
		metric_labels[metrics[index][0]] = CharacterStyle.add_label(self, str(metrics[index][1]), 14, CharacterStyle.MUTED, Vector2(64, y + 2), Vector2(228, 34))
		metric_values[metrics[index][0]] = CharacterStyle.add_label(
			self, "0", 20, CharacterStyle.INK,
			Vector2(310, y), Vector2(168, 36), HORIZONTAL_ALIGNMENT_RIGHT
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
	var breakdown: Dictionary = snapshot.get("stat_breakdown", {})
	var level := int(progression.get("level", snapshot.get("level", 1)))
	var current := int(progression.get("level_progress", snapshot.get("level_progress", 0)))
	var maximum := int(progression.get("level_progress_max", snapshot.get("level_progress_max", 100)))
	var points := int(progression.get("available_skill_points", 0))
	portrait.texture = HERO_TEXTURES.get(hero_id)
	name_label.text = str(hero["name"])
	power_label.text = "养成评分  %d" % int(power.get("total", snapshot.get("combat_power", 0)))
	level_label.text = "LV.%d  ·  技能点 %d" % [level, points]
	progress_bar.max_value = maxf(1.0, maximum)
	progress_bar.value = current
	progress_label.text = "经验  %d / %d" % [current, maximum]
	var damage_multiplier := float(resolved.get("damage_multiplier", progression.get("damage_multiplier", 1.0)))
	var attack := float(resolved.get("attack_power", 100.0 * damage_multiplier))
	var health := float(resolved.get("max_health", hero["max_health"]))
	var speed := float(resolved.get("speed", hero["speed"]))
	var cooldown_multiplier := float(resolved.get("cooldown_multiplier", 1.0))
	var frequency := float(resolved.get("skill_frequency", 1.0 / maxf(0.001, cooldown_multiplier)))
	_set_metric("attack", _format_stat(attack), _attack_detail(breakdown.get("attack_power", {}), attack))
	_set_metric("health", _format_stat(health), _health_detail(breakdown.get("max_health", {}), health))
	_set_metric("speed", _format_stat(speed), _speed_detail(breakdown.get("speed", {}), speed))
	_set_metric("frequency", "%.2f×" % frequency, _frequency_detail(breakdown.get("skill_frequency", {}), frequency))
	record_label.text = records.summary(hero_id) if is_instance_valid(records) and records.has_method("summary") else "等待首次远征"


func _set_metric(metric_id: String, value_text: String, detail: String) -> void:
	metric_values[metric_id].text = value_text
	metric_values[metric_id].tooltip_text = detail
	metric_labels[metric_id].tooltip_text = detail
	metric_values[metric_id].accessibility_name = "%s %s" % [metric_labels[metric_id].text, value_text]


func _format_stat(value: float) -> String:
	return "%.0f" % value if is_equal_approx(value, roundf(value)) else "%.1f" % value


func _attack_detail(raw: Variant, final_value: float) -> String:
	var detail: Dictionary = raw if raw is Dictionary else {}
	if detail.is_empty():
		return "攻击力是以 100 为基准的通用伤害指数，不代表英雄实际 DPS；单技能培养倍率另行结算。"
	return "攻击力是以 100 为基准的永久通用伤害指数，不代表英雄实际 DPS。\n攻击力 = 基准 %.0f × 等级 %.3f × 装备 %.3f = %.1f\n局内等级、遗物、技能分支及技能培养倍率在进入远征后另行结算" % [
		float(detail.get("base", 100.0)), float(detail.get("level_multiplier", 1.0)),
		float(detail.get("equipment_multiplier", 1.0)), final_value,
	]


func _health_detail(raw: Variant, final_value: float) -> String:
	var detail: Dictionary = raw if raw is Dictionary else {}
	if detail.is_empty():
		return "进入远征时的实际最大生命；单局升级另行叠加。"
	return "最大生命 = 基础 %.1f × 等级 %.3f × 装备 %.3f + 固定 %.1f = %.1f" % [
		float(detail.get("base", 0.0)), float(detail.get("level_multiplier", 1.0)),
		float(detail.get("equipment_multiplier", 1.0)), float(detail.get("equipment_flat", 0.0)), final_value,
	]


func _speed_detail(raw: Variant, final_value: float) -> String:
	var detail: Dictionary = raw if raw is Dictionary else {}
	if detail.is_empty():
		return "进入远征时每秒可移动的实际距离；临时加速另行叠加。"
	return "移动速度 = 基础 %.1f × 装备 %.3f = %.1f；单局与临时加速另行叠加" % [
		float(detail.get("base", 0.0)), float(detail.get("equipment_multiplier", 1.0)), final_value,
	]


func _frequency_detail(raw: Variant, final_value: float) -> String:
	var detail: Dictionary = raw if raw is Dictionary else {}
	if detail.is_empty():
		return "施法频率 = 1 ÷ 通用冷却间隔倍率；各技能自身冷却与培养另行结算。"
	return "施法频率 = 1 ÷ 冷却间隔倍率 %.3f = %.3f×；各技能自身冷却与培养另行结算" % [
		float(detail.get("interval_multiplier", 1.0)), final_value,
	]
