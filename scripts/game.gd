extends Node2D

const PlayerEntity = preload("res://scripts/player.gd")
const EnemyEntity = preload("res://scripts/enemy.gd")
const ProjectileEntity = preload("res://scripts/projectile.gd")
const PickupEntity = preload("res://scripts/pickup.gd")
const VirtualJoystickScript = preload("res://scripts/virtual_joystick.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")
const CombatEffectsScript = preload("res://scripts/combat_effects.gd")
const CompendiumCatalog = preload("res://scripts/compendium_catalog.gd")
const FLOOR_TEXTURE := preload("res://assets/art/environment/celestial_floor.png")
const SKILL_ICONS := {
	"star_lance": preload("res://assets/art/skills/star_lance.png"),
	"sun_orbit": preload("res://assets/art/skills/sun_orbit.png"),
	"frost_tide": preload("res://assets/art/skills/frost_tide.png"),
	"ember_volley": preload("res://assets/art/skills/ember_volley.png"),
	"meteor_rain": preload("res://assets/art/skills/meteor_rain.png"),
	"phoenix_heart": preload("res://assets/art/skills/phoenix_heart.png"),
}
const HERO_TEXTURES := {
	"star_warden": preload("res://assets/art/characters/star_tide_warden.png"),
	"ember_ranger": preload("res://assets/art/characters/emberwing_ranger.png"),
}
const PICKUP_ICONS := {
	"heart": preload("res://assets/art/pickups/healing_heart.png"),
	"magnet": preload("res://assets/art/pickups/magnet_charm.png"),
}

const VIEW_SIZE := Vector2(540.0, 960.0)
const WORLD_BOUNDS := Rect2(-1600.0, -1600.0, 3200.0, 3200.0)
const SKILL_MAX_LEVEL := 3

var player: Node2D
var camera: Camera2D
var audio_manager: Node
var combat_effects: Node2D
var selected_hero_id := "star_warden"
var active_skill_ids: Array = []
var enemies: Array = []
var projectiles: Array = []
var pickups: Array = []
var burst_effects: Array = []
var rng := RandomNumberGenerator.new()

var elapsed := 0.0
var kills := 0
var level := 1
var experience := 0
var experience_needed := 28
var pending_upgrades := 0
var gameplay_paused := false
var game_over := false
var game_started := false

var spawn_timer := 0.3
var bolt_timer := 0.25
var pulse_timer := 1.0
var meteor_timer := 1.0
var phoenix_timer := 1.0
var orbit_hit_timer := 0.0
var orbit_phase := 0.0
var pulse_visual_time := 0.0
var magnet_until := 0.0
var tutorial_time := 8.0

var skill_levels: Dictionary = {}

var hud_canvas: CanvasLayer
var start_canvas: CanvasLayer
var joystick: Control
var health_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var stats_label: Label
var skill_slot_icons: Array[TextureRect] = []
var skill_slot_labels: Array[Label] = []
var skill_icon_nodes: Dictionary = {}
var skill_level_labels: Dictionary = {}
var item_label: Label
var tutorial_label: Label
var upgrade_overlay: ColorRect
var upgrade_title: Label
var upgrade_buttons: Array[Button] = []
var game_over_overlay: ColorRect
var game_over_title: Label
var pause_overlay: ColorRect
var pause_button: Button
var hero_card_panels: Dictionary = {}
var start_button: Button
var music_buttons: Array[Button] = []
var sfx_buttons: Array[Button] = []
var music_sliders: Array[HSlider] = []
var sfx_sliders: Array[HSlider] = []
var compendium_overlay: ColorRect
var compendium_list: VBoxContainer
var compendium_tab_buttons: Dictionary = {}


func _ready() -> void:
	rng.randomize()
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
	combat_effects = CombatEffectsScript.new()
	combat_effects.z_index = 3950
	add_child(combat_effects)
	burst_effects = combat_effects.effects
	_build_ui()
	_build_start_screen()
	hud_canvas.visible = false
	queue_redraw()


func _start_run() -> void:
	audio_manager.play_sfx("ui_confirm", 2.0)
	game_started = true
	gameplay_paused = false
	start_canvas.visible = false
	hud_canvas.visible = true
	var hero_data := HeroCatalog.hero(selected_hero_id)
	active_skill_ids = hero_data["skills"].duplicate()
	skill_levels.clear()
	for skill_id in active_skill_ids:
		skill_levels[skill_id] = 0
	skill_levels[active_skill_ids[0]] = 1
	_create_player(hero_data)
	_configure_skill_dock()
	for index in range(5):
		_spawn_enemy(index * TAU / 5.0)
	_update_hud()
	queue_redraw()


func _create_player(hero_data: Dictionary) -> void:
	player = PlayerEntity.new()
	add_child(player)
	player.position = Vector2.ZERO
	player.z_index = 1700
	player.configure(selected_hero_id, hero_data)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.enabled = true
	player.add_child(camera)


func _process(delta: float) -> void:
	if not game_started or game_over or gameplay_paused:
		return

	elapsed += delta
	tutorial_time = maxf(0.0, tutorial_time - delta)
	pulse_visual_time = maxf(0.0, pulse_visual_time - delta)
	combat_effects.advance(delta)
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector2 = keyboard + joystick.value
	player.move(direction.limit_length(1.0), delta, WORLD_BOUNDS)

	_update_spawning(delta)
	_update_enemies(delta)
	_update_star_lance(delta)
	_update_sun_orbit(delta)
	_update_frost_tide(delta)
	_update_ember_volley(delta)
	_update_meteor_rain(delta)
	_update_phoenix_heart(delta)
	_update_projectiles(delta)
	_update_pickups(delta)
	_update_hud()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or not game_started or game_over:
		return
	if pause_overlay.visible:
		_resume_game()
	else:
		_pause_game()
	get_viewport().set_input_as_handled()


func _update_spawning(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0 or enemies.size() >= 110:
		return
	var interval := maxf(0.28, 0.92 - elapsed / 180.0)
	spawn_timer = interval
	var count := 1 + int(elapsed > 70.0 and rng.randf() < 0.35)
	for index in range(count):
		_spawn_enemy(rng.randf_range(0.0, TAU))


func _spawn_enemy(angle: float) -> void:
	var enemy := EnemyEntity.new()
	var roll := rng.randf()
	var enemy_kind := "slime"
	if elapsed > 42.0 and roll < 0.18:
		enemy_kind = "brute"
	elif elapsed > 12.0 and roll < 0.46:
		enemy_kind = "bat"
	var difficulty := 1.0 + elapsed / 105.0
	enemy.configure(enemy_kind, difficulty)
	var spawn_distance := rng.randf_range(570.0, 690.0)
	enemy.position = player.position + Vector2.from_angle(angle) * spawn_distance
	enemy.position.x = clampf(enemy.position.x, WORLD_BOUNDS.position.x + 30.0, WORLD_BOUNDS.end.x - 30.0)
	enemy.position.y = clampf(enemy.position.y, WORLD_BOUNDS.position.y + 30.0, WORLD_BOUNDS.end.y - 30.0)
	enemy.z_index = clampi(roundi(enemy.position.y + 1700.0), 1, 3800)
	add_child(enemy)
	enemies.append(enemy)


func _update_enemies(delta: float) -> void:
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		enemy.advance(player.position, delta, elapsed)
		var contact_distance: float = enemy.radius + 21.0
		if enemy.position.distance_squared_to(player.position) <= contact_distance * contact_distance:
			if elapsed >= enemy.next_contact_time:
				enemy.next_contact_time = elapsed + 0.75
				audio_manager.play_sfx("hero_hurt", 0.0, rng.randf_range(0.94, 1.06))
				if player.take_damage(enemy.damage):
					_finish_game()
					return


func _update_star_lance(delta: float) -> void:
	var skill_level: int = skill_levels.get("star_lance", 0)
	if skill_level <= 0:
		return
	bolt_timer -= delta
	if bolt_timer > 0.0:
		return
	var cooldowns := [0.0, 0.92, 0.72, 0.48]
	var damages := [0.0, 22.0, 29.0, 36.0]
	var counts := [0, 1, 2, 5]
	bolt_timer = cooldowns[skill_level]
	var target := _nearest_enemy(player.position)
	if target == null:
		return
	var base_angle: float = player.position.direction_to(target.position).angle()
	for index in range(counts[skill_level]):
		var spread: float = (index - (counts[skill_level] - 1) * 0.5) * (0.13 if skill_level < 3 else 0.19)
		var projectile := ProjectileEntity.new()
		projectile.position = player.position
		projectile.velocity = Vector2.from_angle(base_angle + spread) * (520.0 if skill_level < 3 else 610.0)
		projectile.damage = damages[skill_level]
		projectile.radius = 7.0 if skill_level < 3 else 9.0
		projectile.pierce = 0 if skill_level < 3 else 2
		projectile.visual_kind = "star_lance"
		projectile.z_index = 3900
		add_child(projectile)
		projectiles.append(projectile)
	audio_manager.play_sfx("skill_star_lance", -1.0, rng.randf_range(0.96, 1.04))


func _update_sun_orbit(delta: float) -> void:
	var skill_level: int = skill_levels.get("sun_orbit", 0)
	if skill_level <= 0:
		return
	orbit_phase += delta * (2.2 if skill_level < 3 else 3.0)
	orbit_hit_timer -= delta
	if orbit_hit_timer > 0.0:
		return
	orbit_hit_timer = 0.38 if skill_level < 3 else 0.25
	var orb_count: int = [0, 1, 2, 4][skill_level]
	var orbit_radius: float = [0.0, 68.0, 78.0, 92.0][skill_level]
	var orb_radius := 13.0 if skill_level < 3 else 18.0
	var damage: float = [0.0, 13.0, 19.0, 28.0][skill_level]
	var hit_anything := false
	for index in range(orb_count):
		var angle: float = orbit_phase + index * TAU / orb_count
		var orb_position: Vector2 = player.position + Vector2.from_angle(angle) * orbit_radius
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and enemy.position.distance_to(orb_position) <= enemy.radius + orb_radius:
				hit_anything = true
				_add_burst(enemy.position, 34.0, Color("ffbf45"), 0.24, "sun_hit")
				if enemy.take_damage(damage):
					_defeat_enemy(enemy)
	if hit_anything:
		audio_manager.play_sfx("skill_sun_orbit", -5.0, rng.randf_range(0.96, 1.04))


func _update_frost_tide(delta: float) -> void:
	var skill_level: int = skill_levels.get("frost_tide", 0)
	if skill_level <= 0:
		return
	pulse_timer -= delta
	if pulse_timer > 0.0:
		return
	var cooldowns := [0.0, 2.45, 1.95, 1.35]
	var radii := [0.0, 125.0, 165.0, 245.0]
	var damages := [0.0, 20.0, 32.0, 50.0]
	pulse_timer = cooldowns[skill_level]
	pulse_visual_time = 0.3
	audio_manager.play_sfx("skill_frost_tide", 0.0, rng.randf_range(0.97, 1.03))
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and enemy.position.distance_to(player.position) <= radii[skill_level] + enemy.radius:
			enemy.apply_slow(0.58 if skill_level < 3 else 0.28, 1.6 if skill_level < 3 else 2.3, elapsed)
			if enemy.take_damage(damages[skill_level]):
				_defeat_enemy(enemy)


func _update_ember_volley(delta: float) -> void:
	var skill_level: int = skill_levels.get("ember_volley", 0)
	if skill_level <= 0:
		return
	bolt_timer -= delta
	if bolt_timer > 0.0:
		return
	var cooldowns := [0.0, 0.86, 0.66, 0.42]
	var damages := [0.0, 19.0, 26.0, 34.0]
	var counts := [0, 1, 2, 4]
	var blast_radii := [0.0, 44.0, 57.0, 74.0]
	bolt_timer = cooldowns[skill_level]
	var target := _nearest_enemy(player.position)
	if target == null:
		return
	var base_angle: float = player.position.direction_to(target.position).angle()
	for index in range(counts[skill_level]):
		var spread: float = (index - (counts[skill_level] - 1) * 0.5) * (0.16 if skill_level < 3 else 0.22)
		var projectile := ProjectileEntity.new()
		projectile.position = player.position
		projectile.velocity = Vector2.from_angle(base_angle + spread) * 590.0
		projectile.damage = damages[skill_level]
		projectile.radius = 7.0 if skill_level < 3 else 9.0
		projectile.pierce = 0 if skill_level < 3 else 1
		projectile.blast_radius = blast_radii[skill_level]
		projectile.visual_kind = "ember_arrow"
		projectile.trail_color = Color("ff743c")
		projectile.core_color = Color("fff0b0")
		projectile.outline_color = Color("f29a3c")
		projectile.z_index = 3900
		add_child(projectile)
		projectiles.append(projectile)
	audio_manager.play_sfx("skill_ember_volley", -1.0, rng.randf_range(0.95, 1.05))


func _update_meteor_rain(delta: float) -> void:
	var skill_level: int = skill_levels.get("meteor_rain", 0)
	if skill_level <= 0:
		return
	meteor_timer -= delta
	if meteor_timer > 0.0:
		return
	var cooldowns := [0.0, 2.55, 1.9, 1.2]
	var counts := [0, 1, 2, 4]
	var damages := [0.0, 32.0, 43.0, 62.0]
	var radii := [0.0, 62.0, 74.0, 96.0]
	meteor_timer = cooldowns[skill_level]
	audio_manager.play_sfx("skill_meteor_rain", 1.0, rng.randf_range(0.96, 1.03))
	var candidates: Array = []
	for enemy in enemies:
		if is_instance_valid(enemy):
			candidates.append(enemy.position)
	candidates.shuffle()
	for index in range(mini(counts[skill_level], candidates.size())):
		var impact_position: Vector2 = candidates[index]
		_damage_area(impact_position, radii[skill_level], damages[skill_level])
		_add_burst(impact_position, radii[skill_level], Color("ff7a35"), 0.72, "meteor")


func _update_phoenix_heart(delta: float) -> void:
	var skill_level: int = skill_levels.get("phoenix_heart", 0)
	if skill_level <= 0:
		return
	phoenix_timer -= delta
	if phoenix_timer > 0.0:
		return
	var cooldowns := [0.0, 3.1, 2.35, 1.55]
	var damages := [0.0, 17.0, 28.0, 45.0]
	var radii := [0.0, 105.0, 145.0, 205.0]
	var healing := [0.0, 2.0, 4.0, 7.0]
	phoenix_timer = cooldowns[skill_level]
	audio_manager.play_sfx("skill_phoenix_heart", 0.0, rng.randf_range(0.97, 1.03))
	player.heal(healing[skill_level])
	_damage_area(player.position, radii[skill_level], damages[skill_level])
	_add_burst(player.position, radii[skill_level], Color("ff9b3d"), 0.55, "phoenix")


func _update_projectiles(delta: float) -> void:
	for projectile in projectiles.duplicate():
		if not is_instance_valid(projectile):
			continue
		if projectile.advance(delta):
			_remove_projectile(projectile)
			continue
		var removed := false
		for enemy in enemies.duplicate():
			if not is_instance_valid(enemy) or not projectile.can_hit(enemy):
				continue
			var hit_distance: float = enemy.radius + projectile.radius
			if projectile.position.distance_squared_to(enemy.position) <= hit_distance * hit_distance:
				audio_manager.play_sfx("impact", -3.0, rng.randf_range(0.92, 1.08))
				if enemy.take_damage(projectile.damage):
					_defeat_enemy(enemy)
				if projectile.blast_radius > 0.0:
					_damage_area(projectile.position, projectile.blast_radius, projectile.damage * 0.55, enemy)
					_add_burst(projectile.position, projectile.blast_radius, Color("ff7a35"), 0.32, "ember")
				elif projectile.visual_kind == "star_lance":
					_add_burst(projectile.position, 38.0, Color("75eaff"), 0.26, "star_hit")
				if projectile.register_hit(enemy):
					_remove_projectile(projectile)
					removed = true
					break
		if removed:
			continue


func _damage_area(center: Vector2, radius: float, damage: float, excluded: Node = null) -> void:
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or enemy == excluded:
			continue
		if enemy.position.distance_to(center) <= radius + enemy.radius:
			if enemy.take_damage(damage):
				_defeat_enemy(enemy)


func _add_burst(center: Vector2, radius: float, color: Color, duration: float, kind: String) -> void:
	combat_effects.add_effect(center, radius, color, duration, kind)


func _update_burst_effects(delta: float) -> void:
	combat_effects.advance(delta)


func _remove_projectile(projectile: Node) -> void:
	projectiles.erase(projectile)
	if is_instance_valid(projectile):
		projectile.queue_free()


func _nearest_enemy(from_position: Vector2) -> Node:
	var nearest: Node = null
	var nearest_distance := INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance: float = from_position.distance_squared_to(enemy.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest


func _defeat_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy) or not enemies.has(enemy):
		return
	kills += 1
	audio_manager.play_sfx("enemy_defeat", -2.0, rng.randf_range(0.9, 1.1))
	_add_burst(enemy.position, enemy.radius + 24.0, enemy.color, 0.42, "defeat")
	_spawn_pickup("xp", enemy.position, enemy.experience)
	var item_roll := rng.randf()
	if item_roll < 0.055:
		_spawn_pickup("heart", enemy.position + Vector2(12, 0), 22)
	elif item_roll < 0.09:
		_spawn_pickup("magnet", enemy.position + Vector2(-12, 0), 1)
	enemies.erase(enemy)
	enemy.queue_free()


func _spawn_pickup(kind: String, spawn_position: Vector2, value: int) -> void:
	var pickup := PickupEntity.new()
	pickup.kind = kind
	pickup.value = value
	pickup.position = spawn_position
	pickup.radius = 13.0 if kind != "xp" else 8.0
	pickup.z_index = clampi(roundi(pickup.position.y + 1700.0), 1, 3800)
	add_child(pickup)
	pickups.append(pickup)


func _update_pickups(delta: float) -> void:
	var pickup_radius := 520.0 if elapsed < magnet_until else 92.0
	for pickup in pickups.duplicate():
		if not is_instance_valid(pickup):
			continue
		var distance: float = pickup.position.distance_to(player.position)
		if distance < pickup_radius:
			var pull_speed: float = 760.0 if elapsed < magnet_until else lerpf(140.0, 520.0, 1.0 - distance / pickup_radius)
			pickup.position = pickup.position.move_toward(player.position, pull_speed * delta)
		pickup.z_index = clampi(roundi(pickup.position.y + 1700.0), 1, 3800)
		if pickup.position.distance_to(player.position) <= 28.0:
			_collect_pickup(pickup)


func _collect_pickup(pickup: Node) -> void:
	audio_manager.play_sfx("pickup", -2.0, rng.randf_range(0.95, 1.08))
	match pickup.kind:
		"heart":
			player.heal(float(pickup.value))
		"magnet":
			magnet_until = maxf(magnet_until, elapsed + 5.0)
		_:
			_add_experience(pickup.value)
	pickups.erase(pickup)
	pickup.queue_free()


func _add_experience(amount: int) -> void:
	experience += amount
	while experience >= experience_needed:
		experience -= experience_needed
		level += 1
		experience_needed = 28 + (level - 1) * 20
		pending_upgrades += 1
	if pending_upgrades > 0 and not gameplay_paused:
		_show_upgrade_choices()


func _show_upgrade_choices() -> void:
	gameplay_paused = true
	joystick.cancel_input()
	var pool: Array = []
	for skill_id in skill_levels.keys():
		if skill_levels[skill_id] < SKILL_MAX_LEVEL:
			pool.append({"id": skill_id})
	pool.append_array([
		{"id": "vitality"},
		{"id": "swiftness"},
		{"id": "recovery"},
	])
	pool.shuffle()
	var choices := pool.slice(0, 3)
	upgrade_title.text = "等级 %d · 星辉赐福" % level
	for index in range(3):
		var choice: Dictionary = choices[index]
		var choice_id: String = choice["id"]
		var button := upgrade_buttons[index]
		button.text = _choice_text(choice_id)
		button.icon = _choice_icon(choice_id)
		button.set_meta("choice_id", choice_id)
		var is_ultimate: bool = skill_levels.has(choice_id) and skill_levels[choice_id] + 1 == SKILL_MAX_LEVEL
		var border := Color("f2ca72") if is_ultimate else Color("578ac6")
		button.add_theme_stylebox_override("normal", _button_style(Color(0.055, 0.085, 0.18, 0.98), border))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.08, 0.14, 0.27, 1.0), Color("70e8ff")))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.04, 0.07, 0.15, 1.0), Color("fff0a8")))
	upgrade_overlay.visible = true
	audio_manager.play_sfx("upgrade", -1.0)


func _choice_icon(choice_id: String) -> Texture2D:
	if SKILL_ICONS.has(choice_id):
		return SKILL_ICONS[choice_id]
	if choice_id == "swiftness":
		return PICKUP_ICONS["magnet"]
	return PICKUP_ICONS["heart"]


func _choice_text(choice_id: String) -> String:
	if skill_levels.has(choice_id):
		var next_level: int = skill_levels[choice_id] + 1
		var skill_data := HeroCatalog.skill(choice_id)
		var skill_name: String = skill_data["ultimate_name"] if next_level == SKILL_MAX_LEVEL else skill_data["name"]
		var prefix := "终极 · " if next_level == SKILL_MAX_LEVEL else ""
		return "%s%s  %s\n%s" % [prefix, skill_name, _roman(next_level), skill_data["descriptions"][next_level]]
	match choice_id:
		"vitality":
			return "星核扩容\n最大生命 +25，并立刻恢复 25"
		"swiftness":
			return "流光步\n移动速度永久 +12%"
		_:
			return "应急修复\n立刻恢复 45 点生命"


func _on_upgrade_selected(button: Button) -> void:
	audio_manager.play_sfx("ui_confirm", 0.0)
	var choice_id: String = button.get_meta("choice_id")
	if skill_levels.has(choice_id):
		skill_levels[choice_id] += 1
		if choice_id == "frost_tide":
			pulse_timer = minf(pulse_timer, 0.3)
		elif choice_id == "meteor_rain":
			meteor_timer = minf(meteor_timer, 0.3)
		elif choice_id == "phoenix_heart":
			phoenix_timer = minf(phoenix_timer, 0.3)
	elif choice_id == "vitality":
		player.max_health += 25.0
		player.heal(25.0)
	elif choice_id == "swiftness":
		player.speed *= 1.12
	else:
		player.heal(45.0)
	pending_upgrades -= 1
	upgrade_overlay.visible = false
	_update_hud()
	if pending_upgrades > 0:
		_show_upgrade_choices()
	else:
		gameplay_paused = false


func _roman(value: int) -> String:
	return ["", "I", "II", "III"][value]


func _finish_game() -> void:
	game_over = true
	var hero_data := HeroCatalog.hero(selected_hero_id)
	game_over_title.text = "%s的远征结束\n\n坚持时间  %s\n击败怪物  %d\n到达等级  %d" % [hero_data["name"], _format_time(elapsed), kills, level]
	game_over_overlay.visible = true
	joystick.visible = false
	pause_button.visible = false


func _restart_game() -> void:
	get_tree().reload_current_scene()


func _update_hud() -> void:
	if not is_instance_valid(player):
		return
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	xp_bar.max_value = experience_needed
	xp_bar.value = experience
	level_label.text = "LV.%d" % level
	stats_label.text = "%s     击败 %d" % [_format_time(elapsed), kills]
	for skill_id in skill_levels:
		var skill_level: int = skill_levels[skill_id]
		skill_icon_nodes[skill_id].modulate = Color.WHITE if skill_level > 0 else Color(0.38, 0.44, 0.58, 0.4)
		skill_level_labels[skill_id].text = _skill_badge(skill_level)
	item_label.visible = elapsed < magnet_until
	item_label.text = "✦ 星引磁场  %ds" % ceili(magnet_until - elapsed)
	tutorial_label.modulate.a = clampf(tutorial_time / 2.0, 0.0, 1.0)


func _configure_skill_dock() -> void:
	skill_icon_nodes.clear()
	skill_level_labels.clear()
	for index in range(3):
		var skill_id: String = active_skill_ids[index]
		var icon := skill_slot_icons[index]
		var badge := skill_slot_labels[index]
		icon.texture = SKILL_ICONS[skill_id]
		skill_icon_nodes[skill_id] = icon
		skill_level_labels[skill_id] = badge


func _skill_badge(skill_level: int) -> String:
	if skill_level <= 0:
		return "—"
	if skill_level >= SKILL_MAX_LEVEL:
		return "MAX"
	return _roman(skill_level)


func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _build_ui() -> void:
	hud_canvas = CanvasLayer.new()
	add_child(hud_canvas)
	var canvas := hud_canvas

	var top_panel := Panel.new()
	top_panel.position = Vector2(18, 18)
	top_panel.size = Vector2(504, 112)
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.115, 0.92), 18.0, Color(0.75, 0.58, 0.27, 0.65)))
	canvas.add_child(top_panel)

	level_label = _make_label("LV.1", 24, Color("f6d782"))
	level_label.position = Vector2(18, 12)
	top_panel.add_child(level_label)
	stats_label = _make_label("00:00     击败 0", 19, Color("d9e8f4"))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_label.position = Vector2(190, 15)
	stats_label.size = Vector2(292, 28)
	top_panel.add_child(stats_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(18, 49)
	health_bar.size = Vector2(466, 17)
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", _panel_style(Color("18203c"), 8.0))
	health_bar.add_theme_stylebox_override("fill", _panel_style(Color("f0647d"), 8.0, Color(1.0, 0.63, 0.7, 0.6)))
	top_panel.add_child(health_bar)
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(18, 76)
	xp_bar.size = Vector2(466, 9)
	xp_bar.show_percentage = false
	xp_bar.add_theme_stylebox_override("background", _panel_style(Color("18203c"), 5.0))
	xp_bar.add_theme_stylebox_override("fill", _panel_style(Color("55d9e8"), 5.0, Color(0.7, 1.0, 1.0, 0.55)))
	top_panel.add_child(xp_bar)

	var skill_dock := Panel.new()
	skill_dock.position = Vector2(132, 140)
	skill_dock.size = Vector2(276, 64)
	skill_dock.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.115, 0.86), 16.0, Color(0.38, 0.64, 0.78, 0.5)))
	canvas.add_child(skill_dock)
	for index in range(3):
		var icon := TextureRect.new()
		icon.position = Vector2(13 + index * 88, 8)
		icon.size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		skill_dock.add_child(icon)
		skill_slot_icons.append(icon)
		var badge := _make_label("—", 14, Color("fff0a8"))
		badge.position = Vector2(53 + index * 88, 35)
		badge.size = Vector2(32, 22)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skill_dock.add_child(badge)
		skill_slot_labels.append(badge)

	pause_button = Button.new()
	pause_button.position = Vector2(438, 140)
	pause_button.size = Vector2(84, 64)
	pause_button.text = "Ⅱ"
	pause_button.add_theme_font_size_override("font_size", 25)
	pause_button.add_theme_color_override("font_color", Color("f6d782"))
	pause_button.add_theme_stylebox_override("normal", _button_style(Color(0.025, 0.045, 0.115, 0.9), Color(0.75, 0.58, 0.27, 0.65)))
	pause_button.add_theme_stylebox_override("hover", _button_style(Color("173c63"), Color("70e8ff")))
	pause_button.add_theme_stylebox_override("pressed", _button_style(Color("102c50"), Color("fff0a8")))
	pause_button.pressed.connect(_pause_game)
	canvas.add_child(pause_button)

	item_label = _make_label("", 18, Color("70e8ff"))
	item_label.position = Vector2(334, 214)
	item_label.size = Vector2(180, 34)
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	canvas.add_child(item_label)

	joystick = VirtualJoystickScript.new()
	joystick.position = Vector2(18, 740)
	joystick.size = Vector2(180, 180)
	canvas.add_child(joystick)

	tutorial_label = _make_label("拖动左下摇杆移动 · 技能会自动释放", 18, Color("dff7ff"))
	tutorial_label.position = Vector2(110, 892)
	tutorial_label.size = Vector2(410, 36)
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(tutorial_label)

	_build_upgrade_overlay(canvas)
	_build_pause_overlay(canvas)
	_build_game_over_overlay(canvas)


func _build_start_screen() -> void:
	start_canvas = CanvasLayer.new()
	start_canvas.layer = 20
	add_child(start_canvas)

	var background := ColorRect.new()
	background.position = Vector2.ZERO
	background.size = VIEW_SIZE
	background.color = Color("071126")
	start_canvas.add_child(background)
	var floor_art := TextureRect.new()
	floor_art.position = Vector2.ZERO
	floor_art.size = VIEW_SIZE
	floor_art.texture = FLOOR_TEXTURE
	floor_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	floor_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	floor_art.modulate = Color(0.62, 0.72, 1.0, 0.48)
	floor_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(floor_art)
	var shade := ColorRect.new()
	shade.position = Vector2.ZERO
	shade.size = VIEW_SIZE
	shade.color = Color(0.01, 0.025, 0.08, 0.58)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(shade)

	var title := _make_label("星潮守望者", 46, Color("f6d782"))
	title.position = Vector2(20, 48)
	title.size = Vector2(500, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	background.add_child(title)
	var subtitle := _make_label("选择英雄，踏入无尽星潮", 20, Color("d3e5f3"))
	subtitle.position = Vector2(20, 112)
	subtitle.size = Vector2(500, 38)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	background.add_child(subtitle)

	var start_music_button := _make_audio_toggle("music")
	start_music_button.position = Vector2(18, 18)
	background.add_child(start_music_button)
	var start_music_slider := _make_volume_slider("music")
	start_music_slider.position = Vector2(18, 68)
	background.add_child(start_music_slider)
	var start_sfx_button := _make_audio_toggle("sfx")
	start_sfx_button.position = Vector2(400, 18)
	background.add_child(start_sfx_button)
	var start_sfx_slider := _make_volume_slider("sfx")
	start_sfx_slider.position = Vector2(400, 68)
	background.add_child(start_sfx_slider)

	var hero_ids := ["star_warden", "ember_ranger"]
	for index in range(hero_ids.size()):
		var hero_id: String = hero_ids[index]
		var hero_data := HeroCatalog.hero(hero_id)
		var card := Panel.new()
		card.position = Vector2(18 + index * 254, 182)
		card.size = Vector2(232, 510)
		background.add_child(card)
		hero_card_panels[hero_id] = card

		var name_label := _make_label(hero_data["name"], 25, Color("fff0b0"))
		name_label.position = Vector2(10, 16)
		name_label.size = Vector2(212, 34)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(name_label)
		var portrait := TextureRect.new()
		portrait.position = Vector2(18, 54)
		portrait.size = Vector2(196, 242)
		portrait.texture = HERO_TEXTURES[hero_id]
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		var role_label := _make_label(hero_data["title"], 18, Color("70e8ff") if hero_id == "star_warden" else Color("ff9a62"))
		role_label.position = Vector2(10, 300)
		role_label.size = Vector2(212, 28)
		role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(role_label)
		var description := _make_label(hero_data["description"], 16, Color("d3ddea"))
		description.position = Vector2(18, 338)
		description.size = Vector2(196, 78)
		description.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(description)
		var select_button := Button.new()
		select_button.position = Vector2(22, 434)
		select_button.size = Vector2(188, 58)
		select_button.text = "选择"
		select_button.add_theme_font_size_override("font_size", 20)
		select_button.add_theme_stylebox_override("normal", _button_style(Color("17304e"), Color("527fa8")))
		select_button.add_theme_stylebox_override("hover", _button_style(Color("20476c"), Color("70e8ff")))
		select_button.add_theme_stylebox_override("pressed", _button_style(Color("10243e"), Color("fff0a8")))
		select_button.pressed.connect(_select_hero.bind(hero_id))
		card.add_child(select_button)

	start_button = Button.new()
	start_button.position = Vector2(72, 720)
	start_button.size = Vector2(396, 74)
	start_button.add_theme_font_size_override("font_size", 26)
	start_button.add_theme_stylebox_override("normal", _button_style(Color("173c63"), Color("f2ca72")))
	start_button.add_theme_stylebox_override("hover", _button_style(Color("20527c"), Color.WHITE))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color("102c50"), Color("fff0a8")))
	start_button.pressed.connect(_start_run)
	background.add_child(start_button)
	var compendium_button := Button.new()
	compendium_button.position = Vector2(126, 812)
	compendium_button.size = Vector2(288, 62)
	compendium_button.text = "✦  星潮图鉴"
	compendium_button.add_theme_font_size_override("font_size", 22)
	compendium_button.add_theme_stylebox_override("normal", _button_style(Color(0.045, 0.07, 0.14, 0.96), Color("6285ad")))
	compendium_button.add_theme_stylebox_override("hover", _button_style(Color("173c63"), Color("70e8ff")))
	compendium_button.add_theme_stylebox_override("pressed", _button_style(Color("102c50"), Color("fff0a8")))
	compendium_button.pressed.connect(_open_compendium.bind("heroes"))
	background.add_child(compendium_button)
	var movement_hint := _make_label("左下摇杆移动 · 技能自动释放", 17, Color("aebfd2"))
	movement_hint.position = Vector2(30, 898)
	movement_hint.size = Vector2(480, 36)
	movement_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	background.add_child(movement_hint)
	_build_compendium_overlay(background)
	_select_hero(selected_hero_id)


func _select_hero(hero_id: String) -> void:
	if is_instance_valid(audio_manager):
		audio_manager.play_sfx("ui_select", -2.0)
	selected_hero_id = hero_id
	for card_hero_id in hero_card_panels:
		var selected: bool = card_hero_id == hero_id
		var border := Color("f2ca72") if selected else Color(0.34, 0.5, 0.68, 0.6)
		var background := Color(0.045, 0.075, 0.15, 0.97) if selected else Color(0.025, 0.045, 0.1, 0.9)
		hero_card_panels[card_hero_id].add_theme_stylebox_override("panel", _panel_style(background, 20.0, border))
	var hero_data := HeroCatalog.hero(hero_id)
	start_button.text = "以%s开始远征" % hero_data["name"]


func _build_compendium_overlay(parent: Control) -> void:
	compendium_overlay = ColorRect.new()
	compendium_overlay.position = Vector2.ZERO
	compendium_overlay.size = VIEW_SIZE
	compendium_overlay.color = Color(0.008, 0.018, 0.055, 0.985)
	compendium_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	compendium_overlay.visible = false
	parent.add_child(compendium_overlay)

	var title := _make_label("星潮图鉴", 38, Color("f6d782"))
	title.add_theme_constant_override("outline_size", 0)
	title.position = Vector2(28, 34)
	title.size = Vector2(360, 54)
	compendium_overlay.add_child(title)
	var close_button := Button.new()
	close_button.position = Vector2(440, 28)
	close_button.size = Vector2(72, 60)
	close_button.text = "×"
	close_button.add_theme_font_size_override("font_size", 30)
	close_button.add_theme_stylebox_override("normal", _button_style(Color("172944"), Color("6683a3")))
	close_button.add_theme_stylebox_override("hover", _button_style(Color("263c5c"), Color.WHITE))
	close_button.pressed.connect(_close_compendium)
	compendium_overlay.add_child(close_button)

	var categories := [
		{"id": "heroes", "name": "英雄"},
		{"id": "enemies", "name": "怪物"},
		{"id": "pickups", "name": "道具"},
		{"id": "skills", "name": "技能"},
	]
	for index in range(categories.size()):
		var category: Dictionary = categories[index]
		var tab := Button.new()
		tab.position = Vector2(20 + index * 126, 112)
		tab.size = Vector2(116, 54)
		tab.text = category["name"]
		tab.add_theme_font_size_override("font_size", 19)
		tab.pressed.connect(_show_compendium_category.bind(category["id"]))
		compendium_overlay.add_child(tab)
		compendium_tab_buttons[category["id"]] = tab

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 184)
	scroll.size = Vector2(500, 744)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	compendium_overlay.add_child(scroll)
	compendium_list = VBoxContainer.new()
	compendium_list.custom_minimum_size = Vector2(478, 0)
	compendium_list.add_theme_constant_override("separation", 14)
	scroll.add_child(compendium_list)


func _open_compendium(category: String) -> void:
	audio_manager.play_sfx("ui_confirm", -1.0)
	compendium_overlay.visible = true
	_show_compendium_category(category)


func _close_compendium() -> void:
	audio_manager.play_sfx("ui_select", -1.0)
	compendium_overlay.visible = false


func _show_compendium_category(category: String) -> void:
	audio_manager.play_sfx("ui_select", -2.0)
	for category_id in compendium_tab_buttons:
		var selected: bool = category_id == category
		var button: Button = compendium_tab_buttons[category_id]
		button.add_theme_stylebox_override("normal", _button_style(Color("173c63") if selected else Color("101d36"), Color("f2ca72") if selected else Color("526d8c")))
		button.add_theme_stylebox_override("hover", _button_style(Color("20527c"), Color("70e8ff")))
	for child in compendium_list.get_children():
		child.queue_free()
	for entry in CompendiumCatalog.entries(category):
		compendium_list.add_child(_make_compendium_card(entry))


func _make_compendium_card(entry: Dictionary) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(478, 178)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.06, 0.125, 0.98), 18.0, entry["accent"]))
	var icon := TextureRect.new()
	icon.position = Vector2(16, 18)
	icon.size = Vector2(132, 140)
	icon.texture = entry["texture"]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)
	var name_label := _make_label(entry["name"], 24, Color("fff0b0"))
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.position = Vector2(164, 17)
	name_label.size = Vector2(292, 34)
	card.add_child(name_label)
	var subtitle := _make_label(entry["subtitle"], 15, entry["accent"])
	subtitle.add_theme_constant_override("outline_size", 1)
	subtitle.position = Vector2(164, 52)
	subtitle.size = Vector2(292, 28)
	card.add_child(subtitle)
	var description := _make_label(entry["description"], 15, Color("d5e0ee"))
	description.add_theme_constant_override("outline_size", 1)
	description.position = Vector2(164, 84)
	description.size = Vector2(292, 76)
	description.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	description.clip_text = true
	card.add_child(description)
	return card


func _build_pause_overlay(canvas: CanvasLayer) -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.position = Vector2.ZERO
	pause_overlay.size = VIEW_SIZE
	pause_overlay.color = Color(0.012, 0.02, 0.07, 0.95)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	canvas.add_child(pause_overlay)

	var title := _make_label("游戏暂停", 38, Color("f6d782"))
	title.position = Vector2(30, 220)
	title.size = Vector2(480, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_overlay.add_child(title)
	var hint := _make_label("星潮会在你回来时继续流动", 20, Color("c6d7ea"))
	hint.position = Vector2(30, 292)
	hint.size = Vector2(480, 40)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_overlay.add_child(hint)
	var pause_music_button := _make_audio_toggle("music")
	pause_music_button.position = Vector2(136, 344)
	pause_overlay.add_child(pause_music_button)
	var pause_music_slider := _make_volume_slider("music")
	pause_music_slider.position = Vector2(136, 397)
	pause_overlay.add_child(pause_music_slider)
	var pause_sfx_button := _make_audio_toggle("sfx")
	pause_sfx_button.position = Vector2(282, 344)
	pause_overlay.add_child(pause_sfx_button)
	var pause_sfx_slider := _make_volume_slider("sfx")
	pause_sfx_slider.position = Vector2(282, 397)
	pause_overlay.add_child(pause_sfx_slider)

	var resume_button := Button.new()
	resume_button.position = Vector2(92, 458)
	resume_button.size = Vector2(356, 76)
	resume_button.text = "继续游戏"
	resume_button.add_theme_font_size_override("font_size", 25)
	resume_button.add_theme_stylebox_override("normal", _button_style(Color("173c63"), Color("70e8ff")))
	resume_button.add_theme_stylebox_override("hover", _button_style(Color("20527c"), Color.WHITE))
	resume_button.add_theme_stylebox_override("pressed", _button_style(Color("102c50"), Color("fff0a8")))
	resume_button.pressed.connect(_resume_game)
	pause_overlay.add_child(resume_button)

	var home_button := Button.new()
	home_button.position = Vector2(92, 568)
	home_button.size = Vector2(356, 72)
	home_button.text = "返回英雄选择"
	home_button.add_theme_font_size_override("font_size", 22)
	home_button.add_theme_stylebox_override("normal", _button_style(Color(0.06, 0.08, 0.16, 0.96), Color("8da5bd")))
	home_button.add_theme_stylebox_override("hover", _button_style(Color("202a49"), Color.WHITE))
	home_button.pressed.connect(_restart_game)
	pause_overlay.add_child(home_button)


func _pause_game() -> void:
	if not game_started or game_over or upgrade_overlay.visible:
		return
	gameplay_paused = true
	joystick.cancel_input()
	pause_overlay.visible = true
	audio_manager.play_sfx("ui_select", -1.0)


func _resume_game() -> void:
	audio_manager.play_sfx("ui_confirm", -1.0)
	pause_overlay.visible = false
	gameplay_paused = false


func _make_audio_toggle(kind: String) -> Button:
	var button := Button.new()
	button.size = Vector2(122, 48)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.035, 0.06, 0.12, 0.94), Color("55708f")))
	button.add_theme_stylebox_override("hover", _button_style(Color("173c63"), Color("70e8ff")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("102c50"), Color("fff0a8")))
	if kind == "music":
		button.pressed.connect(_toggle_music)
		music_buttons.append(button)
	else:
		button.pressed.connect(_toggle_sfx)
		sfx_buttons.append(button)
	_update_audio_button_labels()
	return button


func _make_volume_slider(kind: String) -> HSlider:
	var slider := HSlider.new()
	slider.size = Vector2(122, 24)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.scrollable = false
	if kind == "music":
		slider.value = audio_manager.music_volume * 100.0
		slider.value_changed.connect(_set_music_volume_percent)
		music_sliders.append(slider)
	else:
		slider.value = audio_manager.sfx_volume * 100.0
		slider.value_changed.connect(_set_sfx_volume_percent)
		sfx_sliders.append(slider)
	return slider


func _toggle_music() -> void:
	audio_manager.toggle_music()
	audio_manager.play_sfx("ui_select", -2.0)
	_update_audio_button_labels()


func _toggle_sfx() -> void:
	var was_enabled: bool = audio_manager.sfx_enabled
	audio_manager.toggle_sfx()
	if not was_enabled:
		audio_manager.play_sfx("ui_select", -2.0)
	_update_audio_button_labels()


func _set_music_volume_percent(value: float) -> void:
	audio_manager.set_music_volume(value / 100.0)
	_sync_volume_controls()


func _set_sfx_volume_percent(value: float) -> void:
	audio_manager.set_sfx_volume(value / 100.0)
	_sync_volume_controls()
	if audio_manager.sfx_enabled:
		audio_manager.play_sfx("ui_select", -2.0)


func _sync_volume_controls() -> void:
	for slider in music_sliders:
		slider.set_value_no_signal(audio_manager.music_volume * 100.0)
	for slider in sfx_sliders:
		slider.set_value_no_signal(audio_manager.sfx_volume * 100.0)
	_update_audio_button_labels()


func _update_audio_button_labels() -> void:
	if not is_instance_valid(audio_manager):
		return
	for button in music_buttons:
		button.text = "♫ 音乐 %s" % ("%d%%" % roundi(audio_manager.music_volume * 100.0) if audio_manager.music_enabled else "关")
	for button in sfx_buttons:
		button.text = "✦ 音效 %s" % ("%d%%" % roundi(audio_manager.sfx_volume * 100.0) if audio_manager.sfx_enabled else "关")


func _build_upgrade_overlay(canvas: CanvasLayer) -> void:
	upgrade_overlay = ColorRect.new()
	upgrade_overlay.position = Vector2.ZERO
	upgrade_overlay.size = VIEW_SIZE
	upgrade_overlay.color = Color(0.012, 0.02, 0.07, 0.96)
	upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	upgrade_overlay.visible = false
	canvas.add_child(upgrade_overlay)
	var backdrop := TextureRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = VIEW_SIZE
	backdrop.texture = FLOOR_TEXTURE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.38, 0.5, 0.72, 0.14)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_overlay.add_child(backdrop)

	upgrade_title = _make_label("星辉赐福", 34, Color("f6d782"))
	upgrade_title.position = Vector2(30, 80)
	upgrade_title.size = Vector2(480, 50)
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_overlay.add_child(upgrade_title)
	var hint := _make_label("选择 1 项强化，构筑只属于你的流派", 19, Color("b9c7e5"))
	hint.position = Vector2(30, 132)
	hint.size = Vector2(480, 34)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_overlay.add_child(hint)

	for index in range(3):
		var button := Button.new()
		button.position = Vector2(36, 205 + index * 198)
		button.size = Vector2(468, 166)
		button.text = "升级选项"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.add_theme_font_size_override("font_size", 21)
		button.add_theme_color_override("font_color", Color("eef7ff"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_constant_override("outline_size", 4)
		button.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.12, 0.8))
		button.add_theme_constant_override("icon_max_width", 112)
		button.add_theme_constant_override("h_separation", 22)
		button.add_theme_stylebox_override("normal", _button_style(Color(0.055, 0.085, 0.18, 0.98), Color("578ac6")))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.08, 0.14, 0.27, 1.0), Color("70e8ff")))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.04, 0.07, 0.15, 1.0), Color("fff0a8")))
		button.pressed.connect(_on_upgrade_selected.bind(button))
		upgrade_overlay.add_child(button)
		upgrade_buttons.append(button)


func _build_game_over_overlay(canvas: CanvasLayer) -> void:
	game_over_overlay = ColorRect.new()
	game_over_overlay.position = Vector2.ZERO
	game_over_overlay.size = VIEW_SIZE
	game_over_overlay.color = Color(0.012, 0.02, 0.07, 0.97)
	game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_overlay.visible = false
	canvas.add_child(game_over_overlay)

	var heading := _make_label("本轮远征结束", 38, Color("f28aa0"))
	heading.position = Vector2(30, 170)
	heading.size = Vector2(480, 54)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_overlay.add_child(heading)
	game_over_title = _make_label("", 24, Color("e5ecff"))
	game_over_title.position = Vector2(30, 260)
	game_over_title.size = Vector2(480, 210)
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_overlay.add_child(game_over_title)
	var restart_button := Button.new()
	restart_button.position = Vector2(92, 550)
	restart_button.size = Vector2(356, 74)
	restart_button.text = "再次出发"
	restart_button.add_theme_font_size_override("font_size", 25)
	restart_button.add_theme_stylebox_override("normal", _button_style(Color("173c63"), Color("f2ca72")))
	restart_button.add_theme_stylebox_override("hover", _button_style(Color("20527c"), Color.WHITE))
	restart_button.add_theme_stylebox_override("pressed", _button_style(Color("102c50"), Color("fff0a8")))
	restart_button.pressed.connect(_restart_game)
	game_over_overlay.add_child(restart_button)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.09, 0.85))
	return label


func _panel_style(background: Color, radius: float, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0.0, 0.0, 0.05, 0.36)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(background, 18.0, border)
	style.content_margin_left = 24.0
	style.content_margin_right = 18.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	return style


func _draw() -> void:
	draw_rect(WORLD_BOUNDS, Color("09132c"))
	draw_texture_rect(FLOOR_TEXTURE, WORLD_BOUNDS, true, Color(0.82, 0.87, 1.0, 0.92))
	# 大尺度的冷色光晕打散贴图重复感，同时为战斗提供方向参照。
	for index in range(14):
		var glow_position := Vector2(
			WORLD_BOUNDS.position.x + fposmod(float(index * 617 + 180), WORLD_BOUNDS.size.x),
			WORLD_BOUNDS.position.y + fposmod(float(index * 953 + 320), WORLD_BOUNDS.size.y)
		)
		draw_circle(glow_position, 105.0 + index % 4 * 24.0, Color(0.18, 0.72, 0.82, 0.025))
	draw_rect(WORLD_BOUNDS, Color(0.76, 0.62, 0.3, 0.6), false, 8.0)

	var orbit_level: int = skill_levels.get("sun_orbit", 0)
	if orbit_level > 0 and is_instance_valid(player):
		var count: int = [0, 1, 2, 4][orbit_level]
		var distance: float = [0.0, 68.0, 78.0, 92.0][orbit_level]
		var orb_size := 13.0 if orbit_level < 3 else 18.0
		for index in range(count):
			var orb_position: Vector2 = player.position + Vector2.from_angle(orbit_phase + index * TAU / count) * distance
			draw_circle(orb_position, orb_size + 16.0, Color(1.0, 0.58, 0.16, 0.12))
			for ray_index in range(10):
				var ray_direction := Vector2.from_angle(orbit_phase * 1.7 + ray_index * TAU / 10.0)
				draw_line(orb_position + ray_direction * (orb_size + 3.0), orb_position + ray_direction * (orb_size + 9.0 + ray_index % 2 * 4.0), Color(1.0, 0.76, 0.28, 0.64), 2.0, true)
			draw_arc(orb_position, orb_size + 5.0, orbit_phase, orbit_phase + PI * 1.55, 18, Color(1.0, 0.72, 0.25, 0.75), 3.0)
			draw_circle(orb_position, orb_size, Color("f7a83c"))
			draw_circle(orb_position - Vector2(3, 4), orb_size * 0.5, Color("fff3b0"))
			draw_circle(orb_position + Vector2(5, 4), orb_size * 0.28, Color("d96a26"))
		draw_arc(player.position, distance, orbit_phase - 1.2, orbit_phase + 1.9, 40, Color(1.0, 0.76, 0.28, 0.46), 2.2)
		draw_arc(player.position, distance + 6.0, orbit_phase + PI, orbit_phase + PI * 1.7, 24, Color(1.0, 0.94, 0.55, 0.24), 1.4)

	if pulse_visual_time > 0.0 and is_instance_valid(player):
		var pulse_level: int = skill_levels.get("frost_tide", 0)
		var pulse_radius: float = [0.0, 125.0, 165.0, 245.0][pulse_level]
		var progress := 1.0 - pulse_visual_time / 0.3
		var alpha := 1.0 - progress
		draw_arc(player.position, pulse_radius * progress, 0.0, TAU, 72, Color(0.55, 0.95, 1.0, alpha), 8.0)
		draw_arc(player.position, pulse_radius * progress * 0.86, 0.0, TAU, 64, Color(0.78, 0.98, 1.0, alpha * 0.55), 2.0)
		for index in range(12):
			var shard_angle := index * TAU / 12.0 + progress * 0.3
			var shard_position := player.position + Vector2.from_angle(shard_angle) * pulse_radius * progress
			var shard_direction := Vector2.from_angle(shard_angle)
			draw_line(shard_position - shard_direction * (8.0 + pulse_level * 2.0), shard_position + shard_direction * (8.0 + pulse_level * 2.0), Color(0.8, 0.98, 1.0, alpha), 2.6, true)
			draw_line(shard_position - shard_direction.rotated(PI * 0.5) * 5.0, shard_position + shard_direction.rotated(PI * 0.5) * 5.0, Color(0.68, 0.92, 1.0, alpha), 2.0, true)
		for rune_index in range(6):
			var rune_direction := Vector2.from_angle(rune_index * TAU / 6.0)
			draw_line(player.position, player.position + rune_direction * pulse_radius * progress * 0.52, Color(0.62, 0.93, 1.0, alpha * 0.45), 1.6, true)
