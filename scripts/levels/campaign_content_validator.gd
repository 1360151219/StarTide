extends RefCounted

const EnemyCatalog = preload("res://scripts/enemy_catalog.gd")
const EnemyAbilityCatalog = preload("res://scripts/enemy_ability_catalog.gd")
const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const PickupCatalog = preload("res://scripts/pickup_catalog.gd")
const SkillCatalog = preload("res://scripts/skill_catalog.gd")
const RelicCatalog = preload("res://scripts/relic_catalog.gd")
const HERO_MANIFEST: ContentManifestConfig = preload("res://content/heroes.tres")


static func validation_errors(manifest: CampaignManifest, levels: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	_validate_catalogs(errors)
	_validate_enemy_entries(manifest, errors)
	_validate_content_pools(manifest, levels, errors)
	_validate_drop_tables(manifest, errors)
	_validate_rewards(manifest, levels, errors)
	return errors


static func _validate_catalogs(errors: PackedStringArray) -> void:
	_append(errors, "英雄目录", HERO_MANIFEST.validation_errors(PackedStringArray([
		"name", "title", "description", "passive_name", "passive_description", "max_health", "speed",
	])))
	_append(errors, "怪物目录", EnemyCatalog.validation_errors())
	_append(errors, "怪物技能目录", EnemyAbilityCatalog.validation_errors(EnemyCatalog.ids()))
	_append(errors, "道具目录", PickupCatalog.validation_errors())
	_append(errors, "技能目录", SkillCatalog.validation_errors())
	_append(errors, "遗物目录", RelicCatalog.validation_errors())
	_append(errors, "装备目录", EquipmentCatalog.validation_errors())
	var hero_ids := PackedStringArray(HERO_MANIFEST.as_dictionary().keys())
	for skill_id in SkillCatalog.ids():
		var owner_id := str(SkillCatalog.skill(skill_id).get("owner_hero_id", ""))
		if not hero_ids.has(owner_id):
			errors.append("技能 %s 引用了未知英雄 %s" % [skill_id, owner_id])
	for hero_id in hero_ids:
		if SkillCatalog.signature_for_hero(hero_id).is_empty():
			errors.append("英雄 %s 缺少签名技能" % hero_id)


static func _validate_enemy_entries(manifest: CampaignManifest, errors: PackedStringArray) -> void:
	for level in manifest.levels:
		if level == null:
			continue
		for stage in level.stages:
			for entry in stage.enemy_entries:
				if entry == null or entry.ability_variant_id.is_empty() or not EnemyAbilityCatalog.ids().has(entry.ability_variant_id):
					continue
				var ability := EnemyAbilityCatalog.ability(entry.ability_variant_id)
				if str(ability.get("enemy_id", "")) != entry.enemy_id:
					errors.append("%s/%s 的技能变体不属于怪物 %s" % [level.level_id, stage.stage_id, entry.enemy_id])


static func _validate_content_pools(manifest: CampaignManifest, levels: Dictionary, errors: PackedStringArray) -> void:
	var introduced_skills: Dictionary = {}
	var introduced_relics: Dictionary = {}
	for level in manifest.levels:
		if level == null or level.content_pool == null:
			continue
		_validate_introductions(level.content_pool.introduced_skill_ids, SkillCatalog.ids(), introduced_skills, level.level_id, "技能", errors)
		_validate_introductions(level.content_pool.introduced_relic_ids, RelicCatalog.ids(), introduced_relics, level.level_id, "遗物", errors)
		_validate_debut_entries(level.content_pool.introduced_skill_ids, level.content_pool.skill_entries, level.level_id, "技能", errors)
		_validate_debut_entries(level.content_pool.introduced_relic_ids, level.content_pool.relic_entries, level.level_id, "遗物", errors)
	if not manifest.levels.is_empty() and manifest.levels[0] != null:
		for hero_id in HERO_MANIFEST.as_dictionary():
			var signature := SkillCatalog.signature_for_hero(hero_id)
			if not signature.is_empty() and introduced_skills.get(signature, "") != manifest.levels[0].level_id:
				errors.append("英雄 %s 的签名技能必须在首关出现" % hero_id)
	for level in manifest.levels:
		if level == null or level.content_pool == null:
			continue
		var pool := level.content_pool
		var parent_id := pool.inherit_from_level_id
		if not parent_id.is_empty() and (not levels.has(parent_id) or levels[parent_id].order >= level.order):
			errors.append("%s 只能继承已存在的更早关卡内容池" % level.level_id)
		_validate_pool_entries(pool.skill_entries, SkillCatalog.ids(), introduced_skills, levels, level, "技能", errors)
		_validate_pool_entries(pool.relic_entries, RelicCatalog.ids(), introduced_relics, levels, level, "遗物", errors)
		_validate_guaranteed_limit(level, levels, true, errors)
		_validate_guaranteed_limit(level, levels, false, errors)


static func _validate_introductions(ids: PackedStringArray, valid_ids: PackedStringArray, introduced: Dictionary, level_id: String, label: String, errors: PackedStringArray) -> void:
	for content_id in ids:
		if introduced.has(content_id):
			errors.append("%s重复声明首次出现：%s" % [label, content_id])
		if not valid_ids.has(content_id):
			errors.append("内容池引用了未知%s：%s" % [label, content_id])
		introduced[content_id] = level_id


static func _validate_debut_entries(ids: PackedStringArray, entries: Array[WeightedContentEntryConfig], level_id: String, label: String, errors: PackedStringArray) -> void:
	var entry_ids := PackedStringArray()
	for entry in entries:
		if entry != null:
			entry_ids.append(entry.content_id)
	for content_id in ids:
		if not entry_ids.has(content_id):
			errors.append("%s 声明%s首次出现但未加入本关候选：%s" % [level_id, label, content_id])


static func _validate_pool_entries(entries: Array[WeightedContentEntryConfig], valid_ids: PackedStringArray, introduced: Dictionary, levels: Dictionary, level: LevelConfig, label: String, errors: PackedStringArray) -> void:
	for entry in entries:
		if entry == null:
			continue
		_append(errors, "%s %s候选" % [level.level_id, label], entry.validation_errors(valid_ids, label))
		if not introduced.has(entry.content_id):
			errors.append("%s 的%s候选尚未声明首次出现：%s" % [level.level_id, label, entry.content_id])
		elif levels[introduced[entry.content_id]].order > level.order:
			errors.append("%s 提前使用了未来%s：%s" % [level.level_id, label, entry.content_id])


static func _validate_guaranteed_limit(level: LevelConfig, levels: Dictionary, skills: bool, errors: PackedStringArray) -> void:
	var merged: Dictionary = {}
	var lineage: Array[LevelConfig] = []
	var current: LevelConfig = level
	while current != null and current.content_pool != null and not lineage.has(current):
		lineage.push_front(current)
		var parent_id := current.content_pool.inherit_from_level_id
		current = levels.get(parent_id) if not parent_id.is_empty() else null
	for ancestor in lineage:
		var entries := ancestor.content_pool.skill_entries if skills else ancestor.content_pool.relic_entries
		for entry in entries:
			if entry != null:
				merged[entry.content_id] = entry.guaranteed
	var limit := level.content_pool.skill_pool_limit if skills else level.content_pool.relic_pool_limit
	var guaranteed_count := 0
	if skills:
		var counts_by_hero: Dictionary = {}
		for content_id in merged:
			if not bool(merged[content_id]):
				continue
			var hero_id := str(SkillCatalog.skill(content_id).get("owner_hero_id", ""))
			counts_by_hero[hero_id] = int(counts_by_hero.get(hero_id, 0)) + 1
		for count in counts_by_hero.values():
			guaranteed_count = maxi(guaranteed_count, int(count))
	else:
		for guaranteed in merged.values():
			guaranteed_count += int(guaranteed)
	if guaranteed_count > limit:
		errors.append("%s 继承后的%s保底数超过候选池上限" % [level.level_id, "技能" if skills else "遗物"])


static func _validate_drop_tables(manifest: CampaignManifest, errors: PackedStringArray) -> void:
	var tiers: Dictionary = {}
	for equipment_id in EquipmentCatalog.ids():
		tiers[equipment_id] = EquipmentCatalog.content_tier(equipment_id)
	var previous_max_level := 0
	var previous_quality_shares: Dictionary = {}
	for level in manifest.levels:
		if level == null or level.equipment_drop_table == null:
			continue
		var table := level.equipment_drop_table
		_append(errors, "%s 装备掉落" % level.level_id, table.validation_errors(
			EquipmentCatalog.ids(), PackedStringArray(EquipmentCatalog.RARITIES), tiers, level.content_tier
		))
		if table.max_level < previous_max_level:
			errors.append("%s 的装备掉落等级上限低于前一关" % level.level_id)
		previous_max_level = table.max_level
		var total_weight := 0.0
		for rarity_id in EquipmentCatalog.RARITIES:
			total_weight += maxf(0.0, float(table.rarity_weights.get(rarity_id, 0.0)))
		for rarity_id in EquipmentCatalog.RARITIES:
			if float(table.rarity_weights.get(rarity_id, 0.0)) > 0.0 and table.min_level > EquipmentCatalog.max_level(rarity_id):
				errors.append("%s 的最低掉落等级超过 %s 品质上限" % [level.level_id, rarity_id])
			if EquipmentCatalog.rarity_order(rarity_id) <= 0 or total_weight <= 0.0:
				continue
			var share := maxf(0.0, float(table.rarity_weights.get(rarity_id, 0.0))) / total_weight
			if share + 0.000001 < float(previous_quality_shares.get(rarity_id, 0.0)):
				errors.append("%s 的 %s 品质掉落占比低于前一关" % [level.level_id, rarity_id])
			previous_quality_shares[rarity_id] = share


static func _validate_rewards(manifest: CampaignManifest, levels: Dictionary, errors: PackedStringArray) -> void:
	var reward_ids: Dictionary = {}
	var instance_ids: Dictionary = {}
	_validate_equipment_reward(manifest.starter_equipment_reward, "初始装备", reward_ids, instance_ids, errors)
	for level in manifest.levels:
		if level == null or level.reward == null:
			continue
		if reward_ids.has(level.reward.reward_id):
			errors.append("奖励 ID 重复：%s" % level.reward.reward_id)
		reward_ids[level.reward.reward_id] = true
		var unlock_id := level.reward.unlock_level_id
		if not unlock_id.is_empty() and not levels.has(unlock_id):
			errors.append("%s 解锁了不存在的关卡：%s" % [level.level_id, unlock_id])
		elif not unlock_id.is_empty() and levels[unlock_id].order <= level.order:
			errors.append("%s 的解锁目标不是后续关卡：%s" % [level.level_id, unlock_id])
		_validate_equipment_reward(level.reward.first_clear_equipment_reward, level.level_id, reward_ids, instance_ids, errors)


static func _validate_equipment_reward(reward: EquipmentRewardConfig, label: String, reward_ids: Dictionary, instance_ids: Dictionary, errors: PackedStringArray) -> void:
	if reward == null:
		errors.append("%s 缺少固定装备奖励" % label)
		return
	if reward_ids.has(reward.reward_id):
		errors.append("固定装备奖励 ID 重复：%s" % reward.reward_id)
	reward_ids[reward.reward_id] = true
	var max_levels: Dictionary = {}
	for rarity_id in EquipmentCatalog.RARITIES:
		max_levels[rarity_id] = EquipmentCatalog.max_level(rarity_id)
	_append(errors, label, reward.validation_errors(EquipmentCatalog.ids(), PackedStringArray(EquipmentCatalog.RARITIES), max_levels))
	for entry in reward.entries:
		if entry != null and instance_ids.has(entry.instance_id):
			errors.append("固定装备实例 ID 跨奖励重复：%s" % entry.instance_id)
		if entry != null:
			instance_ids[entry.instance_id] = true


static func _append(target: PackedStringArray, prefix: String, source: PackedStringArray) -> void:
	for message in source:
		target.append("%s：%s" % [prefix, message])
