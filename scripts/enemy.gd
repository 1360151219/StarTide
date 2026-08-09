extends Node2D

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemyVisualDetails = preload("res://scripts/presentation/enemy_visual_details.gd")

var kind := "slime"
var max_health := 35.0
var health := 35.0
var speed := 78.0
var damage := 8.0
var radius := 18.0
var experience := 7
var color := Color("ef718d")
var next_contact_time := 0.0
var slow_factor := 1.0
var slow_effects: Array[Dictionary] = []
var hit_flash := 0.0
var animation_time := 0.0
var slowed := false
var side_blend := 0.0
var horizontal_facing := -1
var turn_progress := 1.0
var is_elite := false
var display_name := ""
var visual_scale := 1.0
var ability_damage_multiplier := 1.0
var ability_id := ""
var contact_enabled := true
var spawn_serial := 0
var ability_visual_id := ""
var ability_visual_phase := ""
var ability_visual_progress := 0.0
var ability_visual_direction := Vector2.ZERO


func configure(enemy_kind: String, scaling: Dictionary, elite_config: EliteConfig = null, configured_ability_id := "") -> void:
	kind = enemy_kind
	ability_id = configured_ability_id
	var data := EnemyCatalog.enemy(kind)
	max_health = float(data["health"]) * float(scaling["health"])
	speed = float(data["speed"]) * float(scaling["speed"])
	damage = float(data["damage"]) * float(scaling["damage"])
	ability_damage_multiplier = float(scaling["damage"])
	radius = float(data["radius"])
	experience = int(data["experience"])
	color = data["color"]
	is_elite = elite_config != null
	display_name = elite_config.display_name if elite_config != null else ""
	visual_scale = elite_config.visual_scale if elite_config != null else 1.0
	if is_elite:
		max_health *= elite_config.health_multiplier
		speed *= elite_config.speed_multiplier
		damage *= elite_config.damage_multiplier
		ability_damage_multiplier *= elite_config.damage_multiplier
		radius *= elite_config.radius_multiplier
		experience = elite_config.experience
		color = Color("f6c968")
	health = max_health
	queue_redraw()


func advance(target: Vector2, delta: float, now: float) -> void:
	var direction := global_position.direction_to(target)
	advance_motion(direction, speed, delta, now)


func advance_motion(direction: Vector2, move_speed: float, delta: float, now: float) -> Vector2:
	animation_time += delta
	var target_side_blend := 1.0 if absf(direction.x) > 0.2 else 0.0
	side_blend = move_toward(side_blend, target_side_blend, delta * 6.0)
	if absf(direction.x) > 0.2:
		var next_facing := -1 if direction.x < 0.0 else 1
		if next_facing != horizontal_facing:
			horizontal_facing = next_facing
			turn_progress = 0.0
	turn_progress = minf(1.0, turn_progress + delta * 7.0)
	_refresh_slow(now)
	var movement := direction.normalized() * move_speed * (slow_factor if slowed else 1.0) * delta
	position += movement
	hit_flash = maxf(0.0, hit_flash - delta)
	queue_redraw()
	return movement


func take_damage(amount: float) -> bool:
	health -= amount
	hit_flash = 0.1
	return health <= 0.0


func apply_slow(factor: float, duration: float, now: float) -> void:
	if duration <= 0.0 or factor >= 1.0:
		return
	var normalized_factor := clampf(factor, 0.0, 1.0)
	for effect in slow_effects:
		if is_equal_approx(float(effect["factor"]), normalized_factor):
			effect["until"] = maxf(float(effect["until"]), now + duration)
			_refresh_slow(now)
			return
	slow_effects.append({"factor": normalized_factor, "until": now + duration})
	_refresh_slow(now)


func set_ability_visual(ability: String, phase: String, progress: float, direction: Vector2) -> void:
	ability_visual_id = ability
	ability_visual_phase = phase
	ability_visual_progress = clampf(progress, 0.0, 1.0)
	ability_visual_direction = direction
	queue_redraw()


func clear_ability_visual() -> void:
	ability_visual_id = ""
	ability_visual_phase = ""
	ability_visual_progress = 0.0
	ability_visual_direction = Vector2.ZERO
	queue_redraw()


func _refresh_slow(now: float) -> void:
	var active_effects: Array[Dictionary] = []
	slow_factor = 1.0
	for effect in slow_effects:
		if now >= float(effect["until"]):
			continue
		active_effects.append(effect)
		slow_factor = minf(slow_factor, float(effect["factor"]))
	slow_effects = active_effects
	slowed = slow_factor < 1.0


func _draw() -> void:
	var hit_color := Color("fff4d8") if kind == "green_grub" else Color("ffd2dc")
	var shown_color := Color.WHITE if hit_flash <= 0.0 else hit_color
	var metrics := _visual_metrics()
	_draw_ground(metrics)
	if slowed:
		EnemyVisualDetails.draw_slow_fragments(self)
	if is_elite:
		_draw_elite_aura()
	_draw_body(metrics, shown_color)
	EnemyVisualDetails.draw_ability_overlay(self, metrics)
	if health < max_health:
		_draw_health_bar(metrics)


func _visual_metrics() -> Dictionary:
	var texture_size := Vector2(82.0, 69.0)
	var texture_y := -35.0
	var shadow_width := 29.0
	var bar_y := -48.0
	if kind == "green_grub":
		texture_size = Vector2(88.0, 65.0)
		texture_y = -34.0
		shadow_width = 28.0
		bar_y = -47.0
	elif kind == "bat":
		texture_size = Vector2(105.0, 67.0)
		texture_y = -38.0
		bar_y = -50.0
	elif kind == "brute":
		texture_size = Vector2(126.0, 109.0)
		texture_y = -65.0
		shadow_width = 46.0
		bar_y = -75.0
	return {"size": texture_size * visual_scale, "y": texture_y * visual_scale, "shadow": shadow_width * visual_scale, "bar_y": bar_y * visual_scale}


func _draw_ground(metrics: Dictionary) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2(3, 42), metrics["shadow"], Color(0.01, 0.02, 0.06, 0.46))
	draw_set_transform(Vector2.ZERO)


func _draw_elite_aura() -> void:
	draw_circle(Vector2.ZERO, radius + 18.0, Color(1.0, 0.72, 0.2, 0.07))
	draw_arc(Vector2.ZERO, radius + 13.0, animation_time * 0.8, animation_time * 0.8 + PI * 1.45, 42, Color(1.0, 0.8, 0.32, 0.78), 3.0)
	for index in range(6):
		var angle := animation_time * 0.65 + index * TAU / 6.0
		draw_circle(Vector2.from_angle(angle) * (radius + 18.0), 3.0, Color("fff1a8"))


func _draw_body(metrics: Dictionary, shown_color: Color) -> void:
	var bob := sin(animation_time * (8.5 if kind == "bat" else 4.8)) * (3.5 if kind == "bat" else 1.5)
	var data := EnemyCatalog.enemy(kind)
	var size: Vector2 = metrics["size"]
	var hit_scale := Vector2(1.14, 0.74) if kind == "green_grub" and hit_flash > 0.0 else Vector2.ONE
	hit_scale *= EnemyVisualDetails.body_scale(self)
	if side_blend < 1.0:
		var front_color := shown_color
		front_color.a *= 1.0 - side_blend
		draw_set_transform(Vector2.ZERO, 0.0, hit_scale)
		var front_rect := Rect2(-size.x * 0.5, metrics["y"] + bob, size.x, size.y)
		EnemyVisualDetails.draw_texture_outline(self, data["front"], front_rect, front_color.a)
		draw_texture_rect(data["front"], front_rect, false, front_color)
		draw_set_transform(Vector2.ZERO)
	if side_blend > 0.0:
		_draw_side(data["side"], metrics, shown_color, bob, hit_scale)


func _draw_side(texture: Texture2D, metrics: Dictionary, shown_color: Color, bob: float, hit_scale: Vector2) -> void:
	var size: Vector2 = metrics["size"]
	var side_size := Vector2(size.y * texture.get_width() / texture.get_height(), size.y)
	var side_color := shown_color
	side_color.a *= side_blend
	var turn_width := lerpf(0.2, 1.0, sin(turn_progress * PI * 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2((1.0 if horizontal_facing < 0 else -1.0) * turn_width * hit_scale.x, hit_scale.y))
	var side_rect := Rect2(-side_size.x * 0.5, metrics["y"] + bob, side_size.x, side_size.y)
	EnemyVisualDetails.draw_texture_outline(self, texture, side_rect, side_color.a)
	draw_texture_rect(texture, side_rect, false, side_color)
	draw_set_transform(Vector2.ZERO)


func _draw_health_bar(metrics: Dictionary) -> void:
	var bar_width := maxf(38.0, radius * 2.0)
	draw_rect(Rect2(-bar_width * 0.5, metrics["bar_y"], bar_width, 5.0), Color(0.03, 0.04, 0.1, 0.88), true)
	draw_rect(Rect2(-bar_width * 0.5, metrics["bar_y"], bar_width * maxf(health, 0.0) / max_health, 5.0), Color("ffcf6a"), true)
