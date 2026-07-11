extends Node2D

const PICKUP_TEXTURES := {
	"xp": preload("res://assets/art/pickups/experience_shard.png"),
	"heart": preload("res://assets/art/pickups/healing_heart.png"),
	"magnet": preload("res://assets/art/pickups/magnet_charm.png"),
}

var kind := "xp"
var value := 5
var age := 0.0
var radius := 8.0


func _process(delta: float) -> void:
	age += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(age * 4.0) * 2.0
	var size := Vector2(30.0, 32.0)
	var glow := Color(0.35, 0.92, 1.0, 0.18)
	if kind == "heart":
		size = Vector2(35.4, 42.0)
		glow = Color(1.0, 0.35, 0.48, 0.18)
	elif kind == "magnet":
		size = Vector2(37.9, 50.0)
		glow = Color(1.0, 0.78, 0.25, 0.2)
	draw_circle(Vector2(0, bob), maxf(size.x, size.y) * 0.47, glow)
	draw_texture_rect(PICKUP_TEXTURES[kind], Rect2(-size.x * 0.5, -size.y * 0.5 + bob, size.x, size.y), false)
