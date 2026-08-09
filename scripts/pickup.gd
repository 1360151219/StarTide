extends Node2D

const PickupCatalog = preload("res://scripts/pickup_catalog.gd")

var kind := "xp"
var value := 5
var age := 0.0
var radius := 8.0


func _process(delta: float) -> void:
	age += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(age * 4.0) * 2.0
	var data := PickupCatalog.pickup(kind)
	var size: Vector2 = data.get("size", Vector2(34.0, 38.0))
	var glow: Color = data.get("accent", Color.WHITE)
	glow.a = 0.2
	draw_circle(Vector2(0, bob), maxf(size.x, size.y) * 0.47, glow)
	draw_arc(Vector2(0, bob), maxf(size.x, size.y) * 0.42, 0.0, TAU, 28, Color(0.03, 0.22, 0.28, 0.72), 2.2)
	var texture := PickupCatalog.texture(kind)
	if texture != null:
		draw_texture_rect(texture, Rect2(-size.x * 0.5, -size.y * 0.5 + bob, size.x, size.y), false)
	if kind == "heart":
		draw_line(Vector2(-5, bob), Vector2(5, bob), Color(1.0, 0.98, 0.86, 0.92), 2.4, true)
		draw_line(Vector2(0, bob - 5), Vector2(0, bob + 5), Color(1.0, 0.98, 0.86, 0.92), 2.4, true)
