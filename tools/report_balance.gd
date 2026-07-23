extends SceneTree

const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")
const LevelBalance = preload("res://scripts/levels/level_balance.gd")


func _initialize() -> void:
	var previous := 0.0
	for level in LevelCatalog.all():
		var pressure := LevelBalance.level_pressure(level)
		var ratio := pressure / previous if previous > 0.0 else 1.0
		print("%s pressure=%.2f ratio=%.3f xp=%.2f" % [
			level.level_id, pressure, ratio, level.loot.experience_multiplier,
		])
		for index in range(level.stages.size()):
			print("  %s pressure=%.2f" % [
				level.stages[index].stage_id, LevelBalance.stage_pressure(level, index),
			])
		previous = pressure
	quit()
