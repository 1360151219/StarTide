extends Node2D

const HERO_TEXTURES := {
	"star_warden": {
		"front": preload("res://assets/art/characters/star_tide_warden.png"),
		"side": preload("res://assets/art/characters/star_tide_warden_side.png"),
	},
	"ember_ranger": {
		"front": preload("res://assets/art/characters/emberwing_ranger.png"),
		"side": preload("res://assets/art/characters/emberwing_ranger_side.png"),
	},
}

var hero_id := "star_warden"
var max_health := 100.0
var health := 100.0
var speed := 230.0
var facing := Vector2.DOWN
var hurt_flash := 0.0
var animation_time := 0.0
var movement_amount := 0.0
var side_blend := 0.0
var horizontal_facing := -1
var turn_progress := 1.0
var passive_active := false
var map: MapConfig


func _process(delta: float) -> void:
	animation_time += delta
	hurt_flash = maxf(0.0, hurt_flash - delta)
	var target_side_blend := 1.0 if absf(facing.x) > 0.28 and movement_amount > 0.05 else 0.0
	side_blend = move_toward(side_blend, target_side_blend, delta * 7.0)
	turn_progress = minf(1.0, turn_progress + delta * 8.0)
	queue_redraw()


func configure(selected_hero_id: String, hero_data: Dictionary, map_config: MapConfig) -> void:
	hero_id = selected_hero_id
	map = map_config
	max_health = hero_data["max_health"]
	health = max_health
	speed = hero_data["speed"]
	queue_redraw()


func move(direction: Vector2, delta: float) -> Vector2:
	var bounds := map.world_bounds
	var previous_position := position
	movement_amount = direction.length()
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
		if absf(facing.x) > 0.28:
			var next_facing := -1 if facing.x < 0.0 else 1
			if next_facing != horizontal_facing:
				horizontal_facing = next_facing
				turn_progress = 0.0
		position += facing * speed * delta
	position.x = clampf(position.x, bounds.position.x + 24.0, bounds.end.x - 24.0)
	position.y = clampf(position.y, bounds.position.y + 24.0, bounds.end.y - 24.0)
	z_index = map.depth_index(position.y)
	return position - previous_position


func take_damage(amount: float) -> bool:
	health = maxf(0.0, health - amount)
	hurt_flash = 0.14
	return health <= 0.0


func heal(amount: float) -> void:
	health = minf(max_health, health + amount)


func _draw() -> void:
	var bob := sin(animation_time * 7.0) * 1.8 * movement_amount
	var texture_color := Color.WHITE if hurt_flash <= 0.0 else Color("ffd6dc")
	# 阴影独立于角色贴图，移动时仍然牢牢贴在地面上。
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2(3, 60), 32.0, Color(0.01, 0.02, 0.07, 0.48))
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2.ZERO, 31.0, Color(0.23, 0.87, 1.0, 0.08))
	draw_arc(Vector2.ZERO, 31.0, 0.0, TAU, 36, Color(0.55, 0.95, 1.0, 0.68), 2.2)
	if passive_active and hero_id == "star_warden":
		draw_circle(Vector2.ZERO, 43.0, Color(0.25, 0.9, 1.0, 0.08))
		draw_arc(Vector2.ZERO, 43.0, animation_time * 0.45, animation_time * 0.45 + PI * 1.55, 48, Color(0.48, 0.94, 1.0, 0.86), 3.2)
		for index in range(6):
			draw_circle(Vector2.from_angle(animation_time * 0.35 + index * TAU / 6.0) * 43.0, 2.8, Color("d9fbff"))
	elif passive_active and hero_id == "ember_ranger":
		for index in range(3):
			var wind_radius := 34.0 + index * 7.0
			draw_arc(Vector2.ZERO, wind_radius, animation_time * 2.5 + index, animation_time * 2.5 + index + PI * 0.9, 22, Color(1.0, 0.46 + index * 0.1, 0.18, 0.72 - index * 0.12), 2.8)
	var textures: Dictionary = HERO_TEXTURES[hero_id]
	var front_texture: Texture2D = textures["front"]
	var side_texture: Texture2D = textures["side"]
	var front_size := _texture_size_for_height(front_texture, 96.0)
	var side_size := _texture_size_for_height(side_texture, 96.0)
	if side_blend < 1.0:
		var front_color := texture_color
		front_color.a *= 1.0 - side_blend
		draw_texture_rect(front_texture, Rect2(-front_size.x * 0.5, -64.0 + bob, front_size.x, front_size.y), false, front_color)
	if side_blend > 0.0:
		var side_color := texture_color
		side_color.a *= side_blend
		var turn_width := lerpf(0.18, 1.0, sin(turn_progress * PI * 0.5))
		var flip := 1.0 if horizontal_facing < 0 else -1.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip * turn_width, 1.0))
		draw_texture_rect(side_texture, Rect2(-side_size.x * 0.5, -64.0 + bob, side_size.x, side_size.y), false, side_color)
		draw_set_transform(Vector2.ZERO)


func _texture_size_for_height(texture: Texture2D, height: float) -> Vector2:
	return Vector2(height * texture.get_width() / texture.get_height(), height)
