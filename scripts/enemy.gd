extends Node2D
const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemyVisualDetails = preload("res://scripts/presentation/enemy_visual_details.gd")
const EnemyHitVisuals = preload("res://scripts/presentation/enemy_hit_visuals.gd")
const EnemyVisualProfile = preload("res://scripts/presentation/enemy_visual_profile.gd")
const HIT_FLASH_DURATION := 0.065
const HIT_OFFSET_DURATION := 0.1
const HIT_FRAGMENT_DURATION := 0.16
const HIT_OFFSET_DISTANCE := 4.0
const HEALTH_BAR_DURATION := 0.7

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
var hit_fragment_time := 0.0
var health_bar_time := 0.0
var hit_offset := Vector2.ZERO
var hit_impulse_direction := Vector2.ZERO
var animation_time := 0.0
var slowed := false
var side_blend := 0.0
var horizontal_facing := -1
var turn_progress := 1.0
var is_elite := false
var is_boss := false
var defeated := false
var recognizing := false
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
	is_boss = false
	defeated = false
	recognizing = false
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


func configure_boss(config: BossConfig) -> void:
	configure(config.boss_id, {"health": 1.0, "speed": 1.0, "damage": 1.0})
	max_health = config.health
	health = max_health
	speed = config.speed
	damage = config.contact_damage
	radius = config.collision_radius
	visual_scale = config.visual_scale
	display_name = config.display_name
	is_boss = true
	experience = 0
	color = Color("f1d48a")
	queue_redraw()


func advance(target: Vector2, delta: float, now: float) -> void:
	var direction := global_position.direction_to(target)
	advance_motion(direction, speed, delta, now)


func advance_motion(direction: Vector2, move_speed: float, delta: float, now: float) -> Vector2:
	animation_time += delta
	if recognizing:
		queue_redraw()
		return Vector2.ZERO
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
	hit_fragment_time = maxf(0.0, hit_fragment_time - delta)
	health_bar_time = maxf(0.0, health_bar_time - delta)
	hit_offset = hit_offset.move_toward(Vector2.ZERO, delta * HIT_OFFSET_DISTANCE / HIT_OFFSET_DURATION)
	queue_redraw()
	return movement


func take_damage(amount: float, source_position := Vector2.INF) -> bool:
	if defeated:
		return false
	health -= amount
	hit_flash = HIT_FLASH_DURATION
	hit_fragment_time = HIT_FRAGMENT_DURATION
	health_bar_time = HEALTH_BAR_DURATION
	hit_impulse_direction = Vector2.ZERO
	hit_offset = Vector2.ZERO
	if source_position.is_finite() and source_position.distance_squared_to(position) > 0.0001:
		hit_impulse_direction = source_position.direction_to(position)
		hit_offset = hit_impulse_direction * HIT_OFFSET_DISTANCE
	if health <= 0.0:
		health = 0.0
		defeated = true
		return true
	return false


func trigger_recognition() -> void:
	recognizing = true
	contact_enabled = false
	clear_ability_visual()
	queue_redraw()


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
	var metrics := EnemyVisualProfile.metrics(self)
	EnemyVisualProfile.draw_ground(self, metrics)
	if slowed:
		EnemyVisualDetails.draw_slow_fragments(self)
	if is_elite or is_boss:
		_draw_elite_aura()
	_draw_body(metrics, shown_color)
	if hit_fragment_time > 0.0:
		EnemyHitVisuals.draw_fragments(self, metrics, 1.0 - hit_fragment_time / HIT_FRAGMENT_DURATION, hit_impulse_direction, hit_offset)
	EnemyVisualDetails.draw_ability_overlay(self, metrics)
	if health_bar_time > 0.0 and health < max_health and not is_boss:
		EnemyVisualProfile.draw_health_bar(self, metrics)


func _draw_elite_aura() -> void:
	var aura_color := Color("78bfc2") if is_boss else Color("f6c968")
	draw_circle(Vector2.ZERO, radius + 18.0, Color(aura_color, 0.07))
	draw_arc(Vector2.ZERO, radius + 13.0, animation_time * 0.8, animation_time * 0.8 + PI * 1.45, 42, Color(aura_color, 0.78), 3.0)
	for index in range(6):
		var angle := animation_time * 0.65 + index * TAU / 6.0
		draw_circle(Vector2.from_angle(angle) * (radius + 18.0), 3.0, Color("e8fff2") if is_boss else Color("fff1a8"))


func _draw_body(metrics: Dictionary, shown_color: Color) -> void:
	var bob := sin(animation_time * (8.5 if kind in ["bat", "bellfeather_kite"] else 4.8)) * (3.5 if kind in ["bat", "bellfeather_kite"] else 1.5)
	if recognizing:
		bob += 7.0
	var data := EnemyCatalog.enemy(kind)
	var size: Vector2 = metrics["size"]
	var hit_scale := Vector2(1.14, 0.74) if kind == "green_grub" and hit_flash > 0.0 else Vector2.ONE
	hit_scale *= EnemyVisualDetails.body_scale(self)
	if side_blend < 1.0:
		var front_color := shown_color
		front_color.a *= 1.0 - side_blend
		draw_set_transform(Vector2.ZERO, 0.0, hit_scale)
		var front_rect := Rect2(-size.x * 0.5 + hit_offset.x, metrics["y"] + bob + hit_offset.y, size.x, size.y)
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
	var side_rect := Rect2(-side_size.x * 0.5 + hit_offset.x, metrics["y"] + bob + hit_offset.y, side_size.x, side_size.y)
	draw_texture_rect(texture, side_rect, false, side_color)
	draw_set_transform(Vector2.ZERO)
