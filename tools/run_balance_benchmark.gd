extends SceneTree

const AudioStub = preload("res://tools/support/audio_stub.gd")
const BalanceContract = preload("res://scripts/run/balance_sample_contract.gd")
const BalanceSampleStore = preload("res://scripts/run/balance_sample_store.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const RunSession = preload("res://scripts/run/run_session.gd")
const BalanceProfileFactory = preload("res://tools/support/balance_profile_factory.gd")

const DEFAULT_SAMPLES_PER_CELL := 1
const DEFAULT_SEED := 20260812
const CHOICE_PRIORITY := {
	"skill_branch": 0,
	"skill_upgrade": 1,
	"skill_unlock": 2,
	"relic_upgrade": 3,
	"utility_recovery": 4,
}

var failed := false


func _initialize() -> void:
	var options := _options()
	var hero_ids := _selected_ids(str(options["hero"]), HeroCatalog.ids())
	var level_ids := _selected_ids(str(options["level"]), LevelCatalog.ids())
	var profile_ids := _selected_ids(str(options["profile"]), BalanceProfileFactory.ids())
	if hero_ids.is_empty() or level_ids.is_empty() or profile_ids.is_empty():
		push_error("BALANCE_BENCHMARK_FAILED: hero、level 或 profile 参数没有匹配稳定 ID")
		quit(1)
		return
	var host := Node2D.new()
	root.add_child(host)
	var audio := AudioStub.new()
	host.add_child(audio)
	var effects := CombatEffects.new()
	host.add_child(effects)
	var store := BalanceSampleStore.new(str(options["output"]))
	var samples_per_cell := maxi(1, int(options["samples"]))
	var base_seed := int(options["seed"])
	var step_seconds := maxf(0.001, float(options["step"]))
	var batch_id := "%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	var completed := 0
	for level_index in range(level_ids.size()):
		var level_id: String = level_ids[level_index]
		for sample_index in range(samples_per_cell):
			var seed_value := base_seed + level_index * 1000003 + sample_index * 1009
			var pair_id := "%s-%d" % [level_id, seed_value]
			for hero_id in hero_ids:
				for profile_id in profile_ids:
					if not _run_cell(host, effects, audio, store, hero_id, level_id, profile_id, seed_value, sample_index, pair_id, batch_id, step_seconds):
						failed = true
					completed += 1
	host.free()
	if not failed:
		print("BALANCE_BENCHMARK_OK samples=%d profiles=%d policy_version=%d step=%.6f output=%s" % [completed, profile_ids.size(), BalanceContract.POLICY_VERSION, step_seconds, str(options["output"])])
	quit(1 if failed else 0)


func _run_cell(host: Node2D, effects: Node2D, audio: Node, store: RefCounted, hero_id: String, level_id: String, profile_id: String, seed_value: int, sample_index: int, pair_id: String, batch_id: String, step_seconds: float) -> bool:
	var level := LevelCatalog.by_id(level_id)
	if level == null:
		push_error("BALANCE_BENCHMARK_FAILED: 未知关卡 %s" % level_id)
		return false
	var session := RunSession.new()
	host.add_child(session)
	var records := BalanceProfileFactory.create(hero_id, profile_id)
	var opening_score := int(records.get_permanent_snapshot(hero_id)["power"]["total"])
	var result_holder: Dictionary = {}
	session.finished.connect(func(presentation: Dictionary) -> void: result_holder["presentation"] = presentation)
	session.configure(
		hero_id, level, records, audio, effects, _random_streams(seed_value), store,
		{
			"mode": "fixed_policy", "policy_version": BalanceContract.POLICY_VERSION,
			"profile_id": profile_id, "pair_id": pair_id, "batch_id": batch_id,
			"seed": seed_value, "sample_index": sample_index, "step_seconds": step_seconds,
			"sample_id": "%s-%s-%s-%s-%d" % [batch_id, hero_id, level_id, profile_id, seed_value],
		}
	)
	var max_steps := ceili((level.duration + 100.0) / step_seconds)
	for _step in range(max_steps):
		if session.state.finished:
			break
		if session.state.paused:
			if not _resolve_pending_upgrades(session):
				break
			continue
		var angle := session.state.elapsed * 0.55 + float(seed_value % 360) * PI / 180.0
		var direction := Vector2.from_angle(angle)
		session.advance(step_seconds, direction)
	var result: Dictionary = result_holder.get("presentation", {})
	var success := session.state.finished and not result.is_empty()
	if success:
		print("BALANCE_BENCHMARK_SAMPLE hero=%s level=%s profile=%s score=%d pair=%s won=%s duration=%.2f" % [
			hero_id, level_id, profile_id, opening_score, pair_id, str(result["won"]), session.state.elapsed,
		])
	else:
		push_error("BALANCE_BENCHMARK_FAILED: %s/%s seed=%d 未在步数预算内结束" % [hero_id, level_id, seed_value])
	session.free()
	return success


func _resolve_pending_upgrades(session: Node) -> bool:
	var choices: Array = session.build_state.pending_choices.values()
	if choices.is_empty():
		push_error("BALANCE_BENCHMARK_FAILED: 升级暂停但没有候选")
		return false
	choices.sort_custom(_choice_less)
	return session.select_upgrade(str(choices[0]["choice_key"]))


func _choice_less(left: Dictionary, right: Dictionary) -> bool:
	var left_priority := int(CHOICE_PRIORITY.get(str(left.get("kind", "")), 99))
	var right_priority := int(CHOICE_PRIORITY.get(str(right.get("kind", "")), 99))
	if left_priority != right_priority:
		return left_priority < right_priority
	return str(left.get("choice_key", "")) < str(right.get("choice_key", ""))


func _random_streams(seed_value: int) -> Dictionary:
	var streams := {}
	for stream_id in ["spawn", "loot", "skill", "upgrade", "enemy_ability"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + streams.size() * 97
		streams[stream_id] = rng
	return streams


func _selected_ids(requested: String, available: PackedStringArray) -> PackedStringArray:
	if requested == "all":
		return available
	return PackedStringArray([requested]) if available.has(requested) else PackedStringArray()


func _options() -> Dictionary:
	var result := {
		"hero": "all",
		"level": "all",
		"profile": "all",
		"samples": DEFAULT_SAMPLES_PER_CELL,
		"seed": DEFAULT_SEED,
		"step": BalanceContract.DEFAULT_SIMULATION_STEP_SECONDS,
		"output": BalanceContract.DEFAULT_BENCHMARK_PATH,
	}
	for argument in OS.get_cmdline_user_args():
		var parts := str(argument).split("=", true, 1)
		if parts.size() != 2:
			continue
		var key := parts[0].trim_prefix("--")
		if not result.has(key):
			continue
		if key in ["samples", "seed"]:
			result[key] = int(parts[1])
		elif key == "step":
			result[key] = float(parts[1])
		else:
			result[key] = parts[1]
	return result
