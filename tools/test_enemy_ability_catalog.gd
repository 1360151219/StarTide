extends SceneTree

const AudioCueCatalog = preload("res://scripts/audio_cue_catalog.gd")
const EnemyAbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const LevelCatalog = preload("res://scripts/levels/level_catalog.gd")

var failed := false


func _initialize() -> void:
	_require(EnemyAbilityCatalog.validation_errors().is_empty(), "怪物技能目录配置无效")
	for ability_id in EnemyAbilityCatalog.ids():
		var ability := EnemyAbilityCatalog.ability(ability_id)
		for cue_field in ["warning_cue", "charge_cue", "execute_cue", "hit_cue", "miss_cue"]:
			var cue_id := str(ability.get(cue_field, ""))
			_require(cue_id.is_empty() or not AudioCueCatalog.cue(cue_id).is_empty(), "%s 引用了不存在的音频 Cue：%s" % [ability_id, cue_id])
	_require(EnemyAbilityCatalog.ability_for_enemy("green_grub") == "green_grub_roll", "青叶团团缺少技能映射")
	_require(EnemyAbilityCatalog.ability_for_enemy("bat") == "bat_bolt", "暮翼蝠缺少技能映射")
	_require(EnemyAbilityCatalog.ability_for_enemy("cloud_hart") == "cloud_hart_sector", "云角鹿缺少技能映射")
	_require(EnemyAbilityCatalog.ability_for_enemy("bellfeather_kite") == "bellfeather_circle", "铃羽鸢缺少技能映射")
	_require(EnemyAbilityCatalog.ability_for_enemy("slime").is_empty(), "星蚀史莱姆不应拥有技能")
	_require(EnemyAbilityCatalog.ability_for_enemy("brute").is_empty(), "陨岩巨怪不应拥有技能")
	var previous_telegraphs := 0
	var previous_projectiles := 0
	for level in LevelCatalog.all().slice(0, 3):
		_require(level.enemy_ability_budget.max_telegraphs >= previous_telegraphs, "%s 预警预算随关卡倒退" % level.display_name)
		_require(level.enemy_ability_budget.max_projectiles >= previous_projectiles, "%s 敌弹预算随关卡倒退" % level.display_name)
		previous_telegraphs = level.enemy_ability_budget.max_telegraphs
		previous_projectiles = level.enemy_ability_budget.max_projectiles
		_validate_stage_abilities(level)
	var fourth := LevelCatalog.by_id("level_04")
	var fifth := LevelCatalog.by_id("level_05")
	_require(fourth.enemy_ability_budget.max_player_danger_areas == 2, "第四关组合预警预算错误")
	_require(fifth.enemy_ability_budget.max_telegraphs == 1 and fifth.enemy_ability_budget.max_player_danger_areas == 1 and fifth.boss != null, "第五关随从预警或 Boss 配置错误")
	_validate_stage_abilities(fourth)
	_validate_stage_abilities(fifth)
	if not failed:
		print("ENEMY_ABILITY_CATALOG_OK abilities=%d cues=data_driven geometry=4 budgets=level_specific" % EnemyAbilityCatalog.ids().size())
	quit(1 if failed else 0)


func _validate_stage_abilities(level: LevelConfig) -> void:
	for stage in level.stages:
		for entry in stage.enemy_entries:
			if not entry.ability_variant_id.is_empty():
				_require(EnemyAbilityCatalog.ids().has(entry.ability_variant_id), "阶段引用了无效技能：%s" % entry.ability_variant_id)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("ENEMY_ABILITY_CATALOG_FAILED: " + message)
