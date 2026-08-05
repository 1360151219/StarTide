# 关卡与内容接入指南

当前战役使用显式资源清单，不扫描目录，也不在脚本中维护关卡数组。新增数值型内容和关卡不需要修改运行时代码；只有引入新的行为机制时才需要扩展系统。

## 1. 数据边界

| 目标 | 唯一数据源 |
| --- | --- |
| 战役顺序、章节、难度曲线、新手装备 | `levels/campaign_main.tres` |
| 单关地图、阶段、内容池、掉落、精英、胜负、奖励 | 对应 `levels/level_*.tres` |
| 大厅预览图与展示怪物 | `levels/level_presentations.tres` |
| 英雄、怪物、怪物技能、道具、技能、遗物、装备定义 | `content/*.tres` |
| 运行逻辑 | `scripts/systems/`、`scripts/skills/`、`scripts/run/` |

目录脚本只提供查询和校验。不要把新内容重新写回 `*_catalog.gd` 字典，也不要在 UI 或状态机里判断关卡编号。

## 2. 新增关卡

1. 复制一份现有关卡 `.tres`，设置新的稳定 `level_id`、全局连续 `order`、`chapter_id` 和 `content_tier`。
2. 配置地图、时长、场上总上限、远程怪物全局上限、怪物技能预算、精英和胜负条件。
3. 为每个阶段配置 `EnemySpawnEntryConfig[]`：
   - `enemy_id`：必须存在于 `content/enemies.tres`。
   - `weight`：同阶段总和必须为 1。
   - `max_active`：该怪物在此阶段的独立场上上限；0 表示只受关卡总上限约束。
   - `ability_variant_id`：可为空；非空时必须属于该怪物。
4. 配置 `LevelContentPoolConfig`：
   - `introduced_*_ids` 只记录本关第一次出现的内容，不能重复声明。
   - `skill_entries` / `relic_entries` 保存本关新增或重设权重的候选。
   - `guaranteed` 内容优先进入本局池，保底数不能超过池上限。
   - `discovered_*_slots` 决定玩家已发现内容最多可回流多少项。
5. 配置 `EquipmentDropTableConfig`：掉落数必须保持 1～4，装备不能高于关卡 `content_tier`，品质权重总和只需大于 0。
6. 在 `RewardConfig` 中设置后续解锁关卡和 `first_clear_equipment_reward`。固定奖励 ID 与实例 ID 一经发布不得复用或改义。
7. 把关卡加入 `campaign_main.tres` 的 `levels`，同时加入对应章节的 `level_ids`。
8. 在 `level_presentations.tres` 增加同 ID 的展示项。预览怪物必须实际存在于该关怪物编成。

`LevelCatalog` 会从 `CampaignManifest` 自动读取新关卡；无需修改脚本数组。大厅轮播始终只复用 3 个页面节点，因此关卡数量不会增加常驻卡片节点。

## 3. 章节难度曲线

每个章节引用一条 `DifficultyProfileConfig`：

- `pressure_curve` 是相对本曲线第 0 阶的目标压力倍率。
- `recommended_power_curve` 是对应阶数的推荐战力。
- `pressure_tolerance` 是实际压力允许偏离目标的比例。

关卡通过 `difficulty_profile_id` 与 `difficulty_step` 选择曲线位置。实际压力由怪物基础属性、阶段权重、刷新速度、额外生成、关卡倍率、技能威胁和喘息时间共同计算。校验比较真实遭遇压力，不用“关卡编号乘常数”代替平衡。

扩展曲线时先追加曲线点，再增加对应关卡；不要为了让校验通过而放宽到失去约束意义的容差。

## 4. 新增内容

### 怪物

在 `content/enemies.tres` 增加 `ContentEntryConfig`，填写基础属性、角色类型、正面/侧面纹理与图鉴字段。怪物技能参数放在 `content/enemy_abilities.tres`，复用 `runtime_kind` 可以直接配置同类技能变体；新的移动、攻击或受击机制需要实现运行时策略，并增加对应测试。

### 技能

调整已有技能的数值、图标和分支只需修改 `content/skills.tres`。新增技能时还要提供稳定 ID、英雄归属、三级数值、图标、恰好两条分支，并在 `scripts/skills/` 注册对应 `runtime_key` 的行为；配置可以决定技能何时出现，但不能凭空描述任意战斗机制。随后由目标关卡声明首次出现和候选权重。

### 遗物与道具

遗物放入 `content/relics.tres`，道具放入 `content/pickups.tres`。复用已有修正字段或道具效果只需资源条目；新增修正维度或效果类型时才扩展运行系统。

### 永久装备

在 `content/equipment.tres` 增加稳定 ID、槽位、`content_tier`、基础属性和每级成长。内容阶级决定最早可进入哪个关卡掉落池，品质仍由掉落表独立抽取。随后将装备加入目标关卡的掉落表；若是首通固定奖励，再配置稳定奖励与实例 ID。

## 5. 验收

提交前运行：

```bash
./tools/run_tests.sh
```

重点校验包括：

- 战役清单 ID、顺序、章节归属与解锁目标。
- 难度曲线阶数、推荐战力和实际压力偏差。
- 怪物编成权重、独立上限、远程上限与技能归属。
- 内容首次出现、继承、保底、权重和池上限。
- 装备内容阶级、1～4 件数量、品质曲线和掉落等级。
- 固定奖励与实例 ID 的跨关唯一性。
- 大厅展示怪物与真实关卡内容一致。
- 旧存档奖励幂等、随机装备持久化和完整运行时烟测。

若只增加资源条目而测试要求修改某个脚本中的关卡数量，说明那里仍残留硬编码，应先移除硬编码，不要给测试追加新的关卡特判。
