class_name PlayerHit
extends RefCounted

const CONTACT := "contact"
const GRUB_ROLL := "grub_roll"
const BAT_BOLT := "bat_bolt"

var damage := 0.0
var source: Node
var hit_type := CONTACT
var origin := Vector2.ZERO
var knockback := 0.0


static func create(amount: float, source_node: Node, type: String, hit_origin: Vector2, knockback_distance := 0.0) -> PlayerHit:
	var hit := PlayerHit.new()
	hit.damage = amount
	hit.source = source_node
	hit.hit_type = type
	hit.origin = hit_origin
	hit.knockback = knockback_distance
	return hit


func is_contact() -> bool:
	return hit_type == CONTACT


func can_knockback_source() -> bool:
	return is_contact() and is_instance_valid(source)


func telemetry_source_id() -> String:
	if is_contact() and is_instance_valid(source):
		return "contact:%s" % str(source.kind)
	return "ability:%s" % hit_type
