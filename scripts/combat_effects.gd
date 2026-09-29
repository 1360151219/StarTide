extends "res://scripts/presentation/combat_effect_draw_combat.gd"

const ImpactVisual = preload("res://scripts/skills/skill_impact_visual.gd")
const MeteorVisual = preload("res://scripts/skills/meteor_rain_visual.gd")
const MAX_EFFECTS := 64
const MAX_DAMAGE_NUMBERS := 18
const DAMAGE_MERGE_WINDOW := 0.12

var effects: Array[Dictionary] = []
var player: Node2D
var next_serial := 0


func add_effect(center: Vector2, radius: float, color: Color, duration: float, kind: String, data := {}) -> void:
	var effect := {
		"position": center,
		"radius": radius,
		"color": color,
		"duration": maxf(duration, 0.01),
		"time": maxf(duration, 0.01),
		"kind": kind,
		"priority": _priority_for(kind),
		"serial": next_serial,
		"data": data,
	}
	next_serial += 1
	_append_with_budget(effect)


func add_follow_effect(target: Node2D, radius: float, color: Color, duration: float, kind: String, data := {}) -> void:
	var payload: Dictionary = data.duplicate()
	payload["follow"] = target
	add_effect(target.position, radius, color, duration, kind, payload)


func add_damage_number(center: Vector2, amount: float, color: Color, is_player := false, target_id := 0) -> void:
	if _merge_damage_number(center, amount, color, is_player, target_id):
		queue_redraw()
		return
	_trim_damage_numbers()
	var duration := 0.62 if is_player else 0.46
	var effect := {
		"position": center,
		"radius": 0.0,
		"color": color,
		"duration": duration,
		"time": duration,
		"kind": "damage_text",
		"amount": amount,
		"text": "-%d" % roundi(amount) if is_player else "%d" % roundi(amount),
		"is_player": is_player,
		"target_id": target_id,
		"priority": 84 if is_player else 46,
		"serial": next_serial,
		"data": {},
	}
	next_serial += 1
	_append_with_budget(effect)


func add_heal_number(center: Vector2, amount: float) -> void:
	_trim_damage_numbers()
	var duration := 0.72
	_append_with_budget({
		"position": center,
		"radius": 0.0,
		"color": Color("7ee69b"),
		"duration": duration,
		"time": duration,
		"kind": "heal_text",
		"text": "+%d" % roundi(amount),
		"is_player": true,
		"priority": 82,
		"serial": next_serial,
		"data": {},
	})
	next_serial += 1


func advance(delta: float) -> void:
	for index in range(effects.size() - 1, -1, -1):
		effects[index]["time"] = float(effects[index]["time"]) - delta
		if float(effects[index]["time"]) <= 0.0:
			_remove_effect(index)
		elif effects[index].has("visual"):
			effects[index]["visual"].refresh(effects[index])
	queue_redraw()


func clear_all() -> void:
	for effect in effects:
		if effect.has("visual"): effect["visual"].free()
	effects.clear()
	queue_redraw()


func _remove_effect(index: int) -> void:
	if effects[index].has("visual"): effects[index]["visual"].free()
	effects.remove_at(index)


func _append_with_budget(effect: Dictionary) -> void:
	if effects.size() >= MAX_EFFECTS:
		var removable_index := -1
		var removable_priority := INF
		var removable_serial := INF
		for index in range(effects.size()):
			var candidate := effects[index]
			var priority := int(candidate["priority"])
			var serial := int(candidate["serial"])
			if priority < removable_priority or priority == removable_priority and serial < removable_serial:
				removable_index = index
				removable_priority = priority
				removable_serial = serial
		if removable_index < 0 or int(effect["priority"]) <= removable_priority:
			return
		_remove_effect(removable_index)
	effects.append(effect)
	if effect["kind"] in ["meteor_warning", "meteor", "meteor_impact"]:
		var visual := MeteorVisual.new()
		add_child(visual)
		visual.configure(effect)
		effect["visual"] = visual
	elif effect["kind"] in ImpactVisual.KINDS:
		var visual := ImpactVisual.new()
		add_child(visual)
		visual.configure(effect, player)
		effect["visual"] = visual
	queue_redraw()


func _merge_damage_number(center: Vector2, amount: float, color: Color, is_player: bool, target_id: int) -> bool:
	for effect in effects:
		if effect["kind"] != "damage_text" or bool(effect["is_player"]) != is_player:
			continue
		var same_target := target_id != 0 and int(effect.get("target_id", 0)) == target_id
		var same_position := Vector2(effect["position"]).distance_squared_to(center) <= 34.0 * 34.0
		var recent := float(effect["time"]) >= float(effect["duration"]) - DAMAGE_MERGE_WINDOW
		if not recent or not (same_target or target_id == 0 and same_position):
			continue
		effect["amount"] = float(effect.get("amount", 0.0)) + amount
		effect["text"] = "-%d" % roundi(effect["amount"]) if is_player else "%d" % roundi(effect["amount"])
		effect["position"] = center
		effect["color"] = color
		effect["time"] = effect["duration"]
		return true
	return false


func _trim_damage_numbers() -> void:
	var count := 0
	var oldest_index := -1
	var oldest_serial := INF
	for index in range(effects.size()):
		if effects[index]["kind"] not in ["damage_text", "heal_text"]:
			continue
		count += 1
		if int(effects[index]["serial"]) < oldest_serial:
			oldest_serial = int(effects[index]["serial"])
			oldest_index = index
	if count >= MAX_DAMAGE_NUMBERS and oldest_index >= 0:
		effects.remove_at(oldest_index)


func _priority_for(kind: String) -> int:
	match kind:
		"meteor_warning", "meteor_impact", "phoenix_impact", "pickup_bomb", "elite_appear", "elite_defeat", "boss_appear", "zouwu_dash_trail", "zouwu_tail_sweep", "zouwu_mark_impact":
			return 88
		"pickup_heal", "pickup_magnet", "pickup_haste", "bat_impact", "grub_recover", "cloud_hart_sweep", "bellfeather_impact":
			return 74
		"frost_hit", "frost_tide_hit", "bat_launch", "grub_roll_trail", "star_hit", "star_shield", "ember_volley_hit", "ember_volley_blast":
			return 58
		"defeat", "grub_defeat", "pickup_xp", "bat_dissolve":
			return 42
	return 36


func _draw() -> void:
	for effect in effects:
		var progress: float = 1.0 - float(effect["time"]) / float(effect["duration"])
		var alpha: float = 1.0 - progress
		var color: Color = effect["color"]
		var center := _effect_center(effect)
		var radius: float = effect["radius"]
		match effect["kind"]:
			"damage_text", "heal_text":
				_draw_floating_text(effect, center, progress, alpha)
			"pickup_xp":
				_draw_pickup_xp(center, radius, progress, alpha)
			"pickup_heal":
				_draw_pickup_heal(center, radius, progress, alpha)
			"pickup_magnet":
				_draw_pickup_magnet(center, radius, progress, alpha)
			"pickup_haste":
				_draw_pickup_haste(center, radius, progress, alpha)
			"pickup_bomb":
				_draw_pickup_bomb(center, radius, progress, alpha)
			"grub_roll_trail":
				_draw_grub_trail(center, radius, progress, alpha, effect["data"])
			"grub_recover":
				_draw_grub_recover(center, radius, progress, alpha)
			"bat_launch":
				_draw_bat_launch(center, radius, progress, alpha, effect["data"])
			"bat_impact", "bat_dissolve":
				_draw_bat_impact(center, radius, progress, alpha, effect["kind"] == "bat_dissolve")
			"elite_appear", "elite_defeat":
				_draw_elite_burst(center, radius, progress, alpha, effect["kind"] == "elite_defeat")
			"boss_appear":
				_draw_boss_appear(center, radius, progress, alpha)
			"cloud_hart_sweep":
				_draw_cloud_hart_sweep(center, radius, progress, alpha, effect["data"])
			"bellfeather_impact":
				_draw_bellfeather_impact(center, radius, progress, alpha)
			"zouwu_dash_trail":
				_draw_zouwu_dash_trail(center, radius, progress, alpha, effect["data"])
			"zouwu_tail_sweep":
				_draw_zouwu_tail_sweep(center, radius, progress, alpha, effect["data"])
			"zouwu_mark_impact":
				_draw_zouwu_mark_impact(center, radius, progress, alpha)
			"star_shield":
				_draw_star_shield(center, radius, progress, alpha)
			"defeat":
				_draw_defeat(center, radius, progress, alpha, color)
			"grub_defeat":
				_draw_grub_defeat(center, radius, progress, alpha)


func _effect_center(effect: Dictionary) -> Vector2:
	var data: Dictionary = effect.get("data", {})
	var follow: Node2D = data.get("follow")
	return follow.position if is_instance_valid(follow) else Vector2(effect["position"])
