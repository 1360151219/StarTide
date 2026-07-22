extends RefCounted

var player: Node2D
var move_time := 0.0
var stop_time := 0.0
var active := false
var active_time := 0.0


func configure(player_node: Node2D, _effects: Node2D, _audio: Node) -> void:
	player = player_node
	move_time = 0.0
	stop_time = 0.0
	active = false
	active_time = 0.0


func advance(movement: Vector2, delta: float, _elapsed: float) -> float:
	if movement.length_squared() > 0.02:
		move_time += delta
		stop_time = 0.0
		if move_time >= 0.9:
			active = true
	else:
		stop_time += delta
		if stop_time >= 0.55:
			active = false
			move_time = 0.0
	if active:
		active_time += delta
	player.passive_active = active
	return delta * (1.18 if active else 1.0)


func try_absorb(_enemy: Node, _elapsed: float) -> bool:
	return false


func try_absorb_hit(_hit: PlayerHit, _elapsed: float) -> bool:
	return false


func status_text(_elapsed: float) -> String:
	if active:
		return "燎原 +18%"
	if move_time > 0.0:
		return "燎原 %d%%" % clampi(roundi(move_time / 0.9 * 100.0), 0, 99)
	return "燎原 充能"


func result_text() -> String:
	return "燎原激活 %.1f 秒" % active_time
