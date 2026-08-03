# 《星潮守望者》架构说明

> 适用版本：Godot 4.7 / 三关 MVP v2
> 更新日期：2026-07-26

## 1. 架构目标

1. 关卡、展示、英雄、怪物、技能、遗物和道具数值分别只有一个可信来源。
2. 英雄投射物只处理“英雄攻击怪物”，敌方弹体使用独立系统。
3. 接触、冲刺和敌弹统一生成 `PlayerHit`，由 `RunSession._apply_player_hit()` 结算。
4. 战斗只消费开局时取得的永久成长快照，不直接读写档案。
5. 每个第一方 GDScript 不超过 250 行；配置层不反向依赖 UI 或运行系统。
6. 新关卡通过资源、内容池和展示清单接入，不让大厅节点数、图鉴或升级逻辑随关卡数量线性膨胀。

## 2. 依赖关系

```text
main.tscn
  └─ game.gd（组合根）
      ├─ FrontendShell
      │   ├─ StartPage：LevelSelector（固定 3 个复用页）/ LevelPreview
      │   ├─ CharacterPage：状态 / 装备 / 技能
      │   ├─ BottomBar（开始 / 角色）
      │   └─ Compendium / AudioSettings
      ├─ HUD / Pause / Upgrade / Result
      ├─ AudioManager / CombatEffects / CombatFeedback
      └─ RunSession
          ├─ RunState / RunBuildState / RunContentResolver
          ├─ StageDirector / RunResultService
          └─ RunWorldBuilder
              ├─ Player
              ├─ EnemySystem ─ EnemySpawner
              ├─ EnemyAbilitySystem ─ EnemyTelegraphRenderer
              ├─ EnemyProjectileSystem
              ├─ ProjectileSystem（英雄弹体）
              ├─ PickupSystem → PickupCatalog
              ├─ UpgradeSystem → SkillCatalog / RelicCatalog
              ├─ SkillController / PassiveController
              └─ WorldRenderer ─ EnvironmentMotes

RunRecords
  ├─ ContentDiscoveryService
  ├─ EquipmentInventory / EquipmentRewardService
  ├─ HeroStatResolver → PowerRatingService
  └─ ProfileRepository
      └─ LocalProfileRepository（schema 6）

HeroRig2D
  ├─ HeroSpriteCatalog → 每英雄 6 张完整 Q 版姿势
  ├─ AnimatedSprite2D → 7 个稳定动作状态
  └─ VisualRoot → 统一脚底原点、呼吸和跑步起伏

LevelCatalog
  └─ levels/*.tres
      └─ LevelConfig
          ├─ MapConfig
          ├─ DifficultyConfig
          ├─ LootConfig → DropEntryConfig[]
          ├─ LevelContentPoolConfig
          ├─ EnemyAbilityBudgetConfig
          ├─ StageConfig[]
          ├─ EliteConfig
          ├─ VictoryConfig
          └─ RewardConfig

LevelPresentationCatalog
  └─ levels/level_presentations.tres
      └─ LevelPresentationConfig[]
```

## 3. 关键模块

| 模块 | 主要文件 | 职责 |
| --- | --- | --- |
| 组合根 | `scripts/game.gd` | 创建服务与 UI、启动会话、暂停/恢复、升级与结算路由 |
| 关卡配置 | `scripts/levels/`、`levels/*.tres` | 地图、阶段、怪物权重、掉落池、技能/遗物首次出现、预算、精英、胜负与奖励 |
| 关卡展示 | `level_presentation_catalog.gd`、`level_presentations.tres` | 预览图、主题色和预览怪物；与战斗配置按稳定关卡 ID 关联 |
| 单局编排 | `scripts/run/run_session.gd` | 单帧推进顺序、统一受击、升级暂停、胜负边界 |
| 内容解析 | `run_content_resolver.gd`、`run_build_state.gd` | 合并关卡首次开放内容和玩家已发现内容，维护技能槽、分支、遗物与重抽 |
| 世界装配 | `scripts/run/run_world_builder.gd` | 创建本局节点并注入配置、随机流、永久成长快照和局内构筑 |
| 怪物域 | `enemy_system.gd`、`enemy_spawner.gd`、`enemy.gd` | 生成、移动、接触、受伤、死亡和精英实例 |
| 怪物技能 | `enemy_ability_catalog.gd`、`enemy_ability_system.gd`、`enemy_ability_rules.gd` | 技能配置、状态机、站位、预算与几何规则 |
| 敌方弹体 | `enemy_projectile_system.gd`、`enemy_projectile.gd` | 敌弹数量限制、连续碰撞、命中和生命周期 |
| 英雄技能 | `scripts/skills/`、`projectile_system.gd` | 技能冷却、弹道、范围伤害和技能视觉 |
| 局内升级 | `skill_catalog.gd`、`relic_catalog.gd`、`upgrade_*` | 6 技能、12 分支、6 遗物、合法候选、严格应用和确定性重抽 |
| 道具目录 | `pickup_catalog.gd`、`pickup_system.gd` | 5 种道具效果、关卡掉落预算、单次判定与拾取运行时 |
| 永久成长与发现 | `scripts/profile/`、`run_records.gd` | schema 6、英雄经验、训练、装备品质/等级、战力、五类发现和旧档迁移 |
| 角色帧动画 | `hero_rig_2d.gd`、`hero_sprite_catalog.gd`、`hero_rig_2d.tscn` | 单一完整角色绘制节点、统一脚底基线、7 状态、左右镜像和暂停冻结 |
| 表现层 | `scripts/presentation/`、`scripts/ui/` | 三套生态、FrontendShell、BottomBar、角色中心、HUD、反馈和覆盖层 |
| 数据目录 | `hero_catalog.gd`、`enemy_catalog.gd`、`skill_catalog.gd`、`relic_catalog.gd`、`pickup_catalog.gd` | 静态数值、素材和稳定 ID |

## 4. 关卡配置

### 4.1 MapConfig

除边界、出生点和生成距离外，保存：

- `biome_id`：`windbell_meadow`、`golden_oasis` 或 `crystal_volcano`。
- 独立地面纹理、背景/地面/边框/光晕颜色。
- 装饰数量与环境粒子颜色。

`WorldRenderer` 根据生态绘制 8 类无碰撞装饰；全部处于角色下层。`EnvironmentMotes` 只负责轻量环境粒子。

### 4.2 关卡展示与轮播

`LevelPresentationCatalog` 单独保存预览纹理、预览区域、主题色和展示怪物；校验会拒绝不存在的关卡 ID、重复展示项，以及不属于该关卡怪物池的预览怪物。

`LevelSelector` 不为每一关永久创建一张卡片，而是固定复用“上一页 / 当前页 / 下一页”3 个页面节点。当前索引改变时只替换节点数据并播放 0.2 秒过渡，因此增加到 12 关或更多时，节点数量和常驻内存不随关卡数增长。切换入口统一为：

- 触摸或鼠标左右滑动。
- 左右箭头按钮。
- 键盘左右方向键。

未解锁关卡允许预览，但进入按钮保持锁定状态。关卡展示和真实战斗内容都通过稳定 `level_id` 关联，新增关卡无需修改 `game.gd`。

### 4.3 LevelContentPoolConfig

每关声明本关首次加入的技能和遗物，可通过 `inherit_from_level_id` 继承更早关卡。`LevelCatalog` 统一负责：

- 解析累计技能池和遗物池。
- 推导怪物、道具、技能和遗物的首次出现关卡。
- 校验继承方向、重复首次声明、未知 ID 和预览池外怪物。

`RunContentResolver` 将关卡累计池与玩家已发现内容合并，并过滤为当前英雄的技能。这样后期技能或遗物被发现后，重玩早期关卡仍可使用；怪物和掉落不参与这项合并，始终保持关卡本地生态。

当前递进关系：

| 关卡 | 怪物 | 掉落 | 累计技能数 | 累计遗物数 |
| --- | --- | --- | ---: | ---: |
| 风铃草原 | 张姐蛆、史莱姆 | 经验、治疗 | 2 | 2 |
| 金砂绿洲 | 增加暮翼蝠 | 增加磁吸、疾风叶 | 4 | 4 |
| 彩晶火山 | 增加陨岩巨怪 | 增加星爆糖 | 6 | 6 |

### 4.4 LootConfig

经验是必掉内容，`experience_multiplier` 由关卡决定。额外掉落使用 `DropEntryConfig[]`，每个条目包含稳定道具 ID、单次概率和单局生成上限；每次击杀只进行一次确定性随机判定，命中首个合法条目后停止，避免多个额外道具在同次击杀中叠加爆出。

道具行为由 `PickupCatalog` 定义，当前包括经验、治疗、5 秒磁吸、6 秒 `+20%` 移速和 180 范围内 35 点伤害。暂停时使用局内经过时间冻结限时效果。

### 4.5 StageConfig

每阶段保存开始时间、刷怪间隔、额外生成概率、四类怪物权重、喘息时间和 `enabled_ability_ids`。技能开放顺序由资源决定，不写死在状态机中。

### 4.6 EnemyAbilityBudgetConfig

每关独立配置：

- 开场技能保护时间。
- 同时预警总数。
- 敌方弹体总数。
- 两次新预警的最短间隔。
- 同时覆盖玩家的危险区数量。

“预警总数”和“覆盖玩家数量”按真实几何分别统计。未覆盖玩家的预警可以使用剩余总预算；warning 与 executing 阶段的危险区域都会占用覆盖预算。

## 5. 怪物技能生命周期

```text
idle/站位
  → warning/预警
  → executing/执行
  → recovery/后摇
  → cooldown/冷却
  → idle
```

关键规则：

- 进入可视区满 1.25 秒后才可开始预警；预警期间离屏立即取消。
- 冷却使用独立 `enemy_ability` 随机流产生 ±15% 确定性偏移。
- 团团滚执行期间关闭该怪物普通接触判定。
- 怪物死亡取消未执行预警；已发射弹体继续存在。
- 暂停、升级和结算停止状态机、预警动画和弹体推进。
- 精英只在基础怪物具备主动技能时继承技能和伤害倍率，且不缩短前摇与冷却；无技能精英不占用预留施法名额。

当前预警只使用珊瑚橙、奶油白、形状和动画表达：团团滚使用直线通道，暮翼光弹使用虚线弹道。

## 6. 统一玩家受击

`PlayerHit` 包含伤害、来源、类型、命中位置和击退。以下来源都进入同一入口：

- 普通接触。
- 张姐蛆冲刺。
- 暮翼光弹。

`RunSession._apply_player_hit()` 统一处理：

1. 结算状态和共享无敌帧。
2. 星潮结界吸收。
3. 声音、伤害数字和屏幕反馈。
4. 来源击退或玩家击退。
5. 生命与失败判定。

因此同帧接触与技能只能造成一次伤害；远程弹被护盾阻挡时不会击退施法者。

## 7. 单帧推进顺序

1. 累计时间并先处理胜负边界。
2. 处理阶段切换和精英事件。
3. 推进战斗特效、玩家移动和英雄被动。
4. 推进刷怪和怪物技能移动/施法。
5. 处理怪物接触候选。
6. 推进英雄技能、英雄弹体和敌方弹体。
7. 推进拾取物并刷新 HUD。

任何步骤触发升级暂停、结算或失败后，本帧后续系统立即停止，避免“弹窗出现后仍移动或受伤”。

## 8. 永久成长与持久化

`RunRecords` 对外提供：

- `progression_snapshot(hero_id)`
- `get_permanent_snapshot(hero_id)`
- `get_active_hero_id()` / `set_active_hero(hero_id)`
- `train_skill(hero_id, skill_id)`
- `reset_skill_training(hero_id)`
- `equipment_inventory_snapshot()` / `equipment_loadout_snapshot(hero_id)`
- `equip_item(hero_id, instance_id)` / `unequip_item(hero_id, slot_id)`
- `upgrade_equipment(target_instance_id, material_instance_id)` / `set_equipment_locked(instance_id, locked)`
- `discover_content(category, content_id)`
- `discovered_content_ids(category)`

`LocalProfileRepository` 保存 schema 6：稳定 `profile_id`、`revision`、英雄/关卡战绩、解锁、英雄经验、技能训练、当前英雄、装备背包/装配、奖励收据，以及五类发现数据。schema 4 的 `mastery_xp` 迁移为 `hero_xp`；schema 5 装备补齐实例品质和等级；schema 3 继续按历史通关次数补齐经验并迁移公开内容。加载时还会修复负数、越级、超预算训练、未知装备、非法品质/等级、错误槽位和重复装配。

`HeroStatResolver` 将等级、训练和装备解析为同一不可变永久快照；`PowerRatingService` 从这份快照对应的真实修正派生战力。开局只读取一次，经 `RunSession → RunWorldBuilder → Player/SkillController/PickupSystem` 注入。本局中途修改档案不会改变正在进行的战斗。

永久装备与单局遗物分别由 `EquipmentInventory` 和 `RunBuildState` 管理。新档与旧档迁移通过稳定奖励收据获得三件新手装备；三关首通奖励也使用稳定实例 ID，重复结算不会重复发放。每次胜利由 `EquipmentDropService` 独立生成 1～4 件随机品质装备；同名消耗升级与材料保护只修改装备实例。发放成功前不会写入固定奖励收据，异常冲突解除后的后续通关会自动补发。

## 9. 局内构筑与升级候选

`RunBuildState` 是单局构筑的唯一真源：

- 3 个英雄技能槽；第一槽以签名技能 I 开局。
- 6 项技能各有两条 II 级分支，共 12 条；III 级沿已选分支进化为终极。
- 4 个不同遗物槽；6 种遗物均可升至 III。
- 每局初始 1 次重抽，击败精英再增加 1 次。
- 统一派生伤害、冷却、命中间隔、范围、移速、生命和拾取范围修正。

`UpgradeChoicePlanner` 先根据英雄归属、当前内容池、槽位、等级上限和已选分支生成合法候选，再形成结构化三选一。I→II 时两条分支始终成对出现，第三项优先使用遗物；常规情况下同时保留技能成长和遗物。玩家生命低于 70% 时，应急修复进入常规候选；某类池耗尽或只剩分支二选一时，规划器也可用剩余合法内容或应急修复补位，避免升级流程中断。

每个候选带有稳定 `choice_key`、类型、内容 ID、目标等级和分支 ID。`UpgradeSystem` 只接受当前 `pending_choices` 内的键，并在应用后立即清空整组，避免伪造选择、重复提交或用过期候选突破槽位与等级上限。重抽使用同一随机流，排除当前整组且只在存在不同合法组合时消耗次数。

## 10. 图鉴发现边界

图鉴不是“到达关卡即批量解锁”，而是由实际游戏事件驱动：

- 签名技能在本局开始时发现。
- 怪物第一次实际生成时发现。
- 道具第一次实际拾取时发现。
- 技能、遗物或技能分支在升级选择真正应用后发现。

英雄始终公开；其余类别未发现时只显示剪影、“？？？”和已发现数量。技能卡公开后，两个分支仍分别保持隐藏，直到玩家在局内实际选择对应分支。结算页统计本局新发现数量。

发现数据还参与 `RunContentResolver`：后期已发现的同英雄技能和遗物可回流至早期关卡构筑池，但不会修改该关怪物或掉落池。

## 11. 随机流

| 随机流 | 使用范围 |
| --- | --- |
| `spawn` | 怪物类型、生成位置和额外生成 |
| `loot` | 掉落与拾取音调 |
| `skill` | 英雄技能目标、弹道和音调 |
| `upgrade` | 三选一候选 |
| `enemy_ability` | 怪物技能冷却偏移 |

拆分后，调整掉落概率不会改变刷怪或敌方施法序列。

## 12. 验证与结构守卫

```bash
./tools/run_tests.sh
./tools/run_visual_tests.sh
```

当前统一入口执行 26 套测试，并拒绝脚本解析错误、测试标识缺失或重复。除关卡、阶段、刷怪、怪物技能、敌弹、胜负、成长、战役、声音、比例和架构测试外，还包括：

- `test_content_pools.gd`：三关怪物/掉落池、技能/遗物继承、首次出现和零权重占位。
- `test_run_build.gd`：6 技能、12 分支、6 遗物、3/4 槽位、输出上限、严格候选和确定性重抽。
- `test_content_runtime.gd`：实际发现事件、跨关重玩、加速/范围伤害道具、拾取范围遗物和分支运行时。
- `test_power_equipment.gd`：战力黄金值、装备互斥、奖励幂等、属性快照和 schema 4→6。
- `test_equipment_progression.gd`：1～4 件保证掉落、75/20/5 品质权重、品质倍率/等级上限和同名消耗升级。
- `test_hero_rig.gd`：两名英雄、单一完整绘制组件、7 个动画状态、512 像素透明画布、统一脚底基线、镜像、暂停和整图回退。
- `test_hero_rig_tuner.gd`：2 名英雄、7 个动作、96/188/360 三档尺寸、播放暂停、从首帧重播和稳定接口边界。

`test_run_records.gd` 同时覆盖 schema 6、schema 3/4/5 迁移、发现隔离和未发现技能禁止局外训练。`test_start_ui.gd` 使用 12 个测试关卡验证轮播固定复用 3 个页面节点，并覆盖 BottomBar、角色中心、当前英雄和战力同步。

`tools/check_architecture.gd` 检查：

- `scripts/` 与 `tools/` 下每个 GDScript 不超过 250 行。
- `scripts/levels/` 不依赖 UI 或运行系统。
- `game.gd` 不包含具体关卡时长、阶段表或精英名称。

## 13. 扩展原则

- 新增怪物技能：先加入 `EnemyAbilityCatalog`，再扩展状态机执行分支和预警形状测试。
- 新增关卡：新增 `LevelConfig` 资源、展示清单项和内容池声明，再加入 `LevelCatalog`，不修改 `game.gd` 或创建新的大厅卡片类。
- 新增技能：只在 `SkillCatalog` 声明数值、两条分支和运行时键，再由目标关卡内容池声明首次出现。
- 新增遗物或道具：分别扩展 `RelicCatalog` / `PickupCatalog`，由关卡资源控制首次进入候选或掉落。
- 新增永久装备：扩展 `EquipmentCatalog`，通过 `EquipmentRewardCatalog` 声明稳定奖励，不把永久装备加入单局遗物。
- 新增英雄：提供目录、三项技能和 6 张约定命名的完整姿势帧，复用 `HeroRig2D`，不复制状态机。
- 新增存储后端：实现 `ProfileRepository`，不让战斗系统直接依赖云端 SDK。
- 新增敌方弹种：扩展 `EnemyProjectileSystem`，不向英雄弹体加入阵营分支。
