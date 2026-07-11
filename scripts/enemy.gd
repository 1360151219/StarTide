extends Node2D

const ENEMY_TEXTURES := {
	"slime": {
		"front": preload("res://assets/art/enemies/starblight_slime.png"),
		"side": preload("res://assets/art/enemies/starblight_slime_side.png"),
	},
	"bat": {
		"front": preload("res://assets/art/enemies/duskwing_bat.png"),
		"side": preload("res://assets/art/enemies/duskwing_bat_side.png"),
	},
	"brute": {
		"front": preload("res://assets/art/enemies/meteor_brute.png"),
		"side": preload("res://assets/art/enemies/meteor_brute_side.png"),
	},
}

var kind := "slime"
var max_health := 35.0
var health := 35.0
var speed := 78.0
var damage := 8.0
var radius := 18.0
var experience := 7
var color := Color("ef718d")
var next_contact_time := 0.0
var slow_until := 0.0
var slow_factor := 1.0
var hit_flash := 0.0
var animation_time := 0.0
var slowed := false
var side_blend := 0.0
var horizontal_facing := -1
var turn_progress := 1.0


func configure(enemy_kind: String, difficulty: float) -> void:
	kind = enemy_kind
	match kind:
		"bat":
			max_health = 22.0 * difficulty
			speed = 125.0 + difficulty * 3.0
			damage = 7.0
			radius = 14.0
			experience = 6
			color = Color("b889ff")
		"brute":
			max_health = 105.0 * difficulty
			speed = 48.0 + difficulty * 2.0
			damage = 16.0
			radius = 28.0
			experience = 16
			color = Color("ff9f5a")
		_:
			max_health = 36.0 * difficulty
			speed = 76.0 + difficulty * 2.5
			damage = 9.0
			radius = 18.0
			experience = 8
			color = Color("ef718d")
	health = max_health
	queue_redraw()


func advance(target: Vector2, delta: float, now: float) -> void:
	animation_time += delta
	var direction := global_position.direction_to(target)
	var target_side_blend := 1.0 if absf(direction.x) > 0.2 else 0.0
	side_blend = move_toward(side_blend, target_side_blend, delta * 6.0)
	if absf(direction.x) > 0.2:
		var next_facing := -1 if direction.x < 0.0 else 1
		if next_facing != horizontal_facing:
			horizontal_facing = next_facing
			turn_progress = 0.0
	turn_progress = minf(1.0, turn_progress + delta * 7.0)
	slowed = now < slow_until
	var active_slow := slow_factor if slowed else 1.0
	position += direction * speed * active_slow * delta
	z_index = clampi(roundi(position.y + 1700.0), 1, 3800)
	hit_flash = maxf(0.0, hit_flash - delta)
	queue_redraw()


func take_damage(amount: float) -> bool:
	health -= amount
	hit_flash = 0.1
	return health <= 0.0


func apply_slow(factor: float, duration: float, now: float) -> void:
	slow_factor = minf(slow_factor, factor)
	slow_until = maxf(slow_until, now + duration)


func _draw() -> void:
	var shown_color := Color.WHITE if hit_flash <= 0.0 else Color("ffd2dc")
	var bob_speed := 8.5 if kind == "bat" else 4.8
	var bob_amount := 3.5 if kind == "bat" else 1.5
	var bob := sin(animation_time * bob_speed) * bob_amount
	var texture_size := Vector2(70.0, 58.8)
	var texture_y := -30.0
	var shadow_width := 25.0
	var bar_y := -42.0
	match kind:
		"bat":
			texture_size = Vector2(92.0, 58.4)
			texture_y = -33.0
			shadow_width = 25.0
			bar_y = -44.0
		"brute":
			texture_size = Vector2(118.0, 102.3)
			texture_y = -61.0
			shadow_width = 43.0
			bar_y = -70.0
	# 椭圆阴影让静态单帧素材具有稳定的落地感。
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2(3, 42), shadow_width, Color(0.01, 0.02, 0.06, 0.46))
	draw_set_transform(Vector2.ZERO)
	if slowed:
		draw_arc(Vector2.ZERO, radius + 7.0, 0.0, TAU, 28, Color(0.4, 0.9, 1.0, 0.46), 2.0)
	var textures: Dictionary = ENEMY_TEXTURES[kind]
	var front_texture: Texture2D = textures["front"]
	var side_texture: Texture2D = textures["side"]
	if side_blend < 1.0:
		var front_color := shown_color
		front_color.a *= 1.0 - side_blend
		draw_texture_rect(front_texture, Rect2(-texture_size.x * 0.5, texture_y + bob, texture_size.x, texture_size.y), false, front_color)
	if side_blend > 0.0:
		var side_height := texture_size.y
		var side_size := Vector2(side_height * side_texture.get_width() / side_texture.get_height(), side_height)
		var side_color := shown_color
		side_color.a *= side_blend
		var turn_width := lerpf(0.2, 1.0, sin(turn_progress * PI * 0.5))
		var flip := 1.0 if horizontal_facing < 0 else -1.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip * turn_width, 1.0))
		draw_texture_rect(side_texture, Rect2(-side_size.x * 0.5, texture_y + bob, side_size.x, side_size.y), false, side_color)
		draw_set_transform(Vector2.ZERO)
	if health < max_health:
		var bar_width := maxf(38.0, radius * 2.0)
		draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, 5.0), Color(0.03, 0.04, 0.1, 0.88), true)
		draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width * maxf(health, 0.0) / max_health, 5.0), Color("ffcf6a"), true)
