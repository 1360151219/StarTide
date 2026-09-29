extends Node2D

const UNLIMITED_PIERCE := -1
const Visual = preload("res://scripts/skills/projectile_visual.gd")

var velocity := Vector2.ZERO
var damage := 20.0
var radius := 7.0
var lifetime := 2.0
var pierce := 0
var blast_radius := 0.0
var visual_kind := "star_lance"
var source_id := "unknown"
var skill_level := 1
var branch_id := ""
var volley_index := 0
var volley_count := 1
var age := 0.0
var previous_position := Vector2.ZERO
var hit_ids: Dictionary = {}
var visual: Node2D
var visual_player: Node2D


func _ready() -> void:
	rotation = velocity.angle()
	visual = Visual.new()
	add_child(visual)
	visual.configure(self)


func advance(delta: float) -> bool:
	previous_position = position
	age += delta
	position += velocity * delta
	rotation = velocity.angle()
	lifetime -= delta
	if visual != null: visual.refresh()
	return lifetime <= 0.0


func collision_fraction(center: Vector2, combined_radius: float) -> float:
	var segment := position - previous_position
	var length_squared := segment.length_squared()
	var offset := previous_position - center
	var outside := offset.length_squared() - combined_radius * combined_radius
	if outside <= 0.0:
		return 0.0
	if length_squared <= 0.0001:
		return INF
	var projection := offset.dot(segment)
	var discriminant := projection * projection - length_squared * outside
	if discriminant < 0.0:
		return INF
	var fraction := (-projection - sqrt(discriminant)) / length_squared
	return fraction if fraction >= 0.0 and fraction <= 1.0 else INF


func can_hit(enemy: Node) -> bool:
	return not hit_ids.has(enemy.get_instance_id())


func register_hit(enemy: Node) -> bool:
	hit_ids[enemy.get_instance_id()] = true
	if pierce == UNLIMITED_PIERCE:
		return false
	if pierce > 0:
		pierce -= 1
		return false
	return true
