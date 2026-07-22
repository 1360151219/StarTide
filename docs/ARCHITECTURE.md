# 《星潮守望者》架构说明

> 适用版本：Godot 4.7 / 三关 MVP v2
> 更新日期：2026-07-18

## 1. 架构目标

1. 关卡、英雄、怪物和技能数值分别只有一个可信来源。
2. 英雄投射物只处理“英雄攻击怪物”，敌方弹体使用独立系统。
3. 接触、冲刺、范围技能和敌弹统一生成 `PlayerHit`，由 `RunSession._apply_player_hit()` 结算。
4. 战斗只消费开局时取得的永久成长快照，不直接读写档案。
5. 每个第一方 GDScript 不超过 250 行；配置层不反向依赖 UI 或运行系统。

## 2. 依赖关系

```text
main.tscn
  └─ game.gd（组合根）
      ├─ StartScreen → LevelPreview → HeroSelector / HeroTrainingPanel
      ├─ HUD / Pause / Upgrade / Result / Compendium
      ├─ AudioManager / CombatEffects / CombatFeedback
      └─ RunSession
          ├─ RunState / StageDirector / RunResultService
          └─ RunWorldBuilder
              ├─ Player
              ├─ EnemySystem ─ EnemySpawner
              ├─ EnemyAbilitySystem ─ EnemyTelegraphRenderer
              ├─ EnemyProjectileSystem
              ├─ ProjectileSystem（英雄弹体）
              ├─ PickupSystem / UpgradeSystem
              ├─ SkillController / PassiveController
              └─ WorldRenderer ─ EnvironmentMotes

RunRecords
  └─ ProfileRepository
      └─ LocalProfileRepository（schema 3）

LevelCatalog
  └─ levels/*.tres
      └─ LevelConfig
          ├─ MapConfig
          ├─ DifficultyConfig
          ├─ LootConfig
          ├─ EnemyAbilityBudgetConfig
          ├─ StageConfig[]
          ├─ EliteConfig
          ├─ VictoryConfig
          └─ RewardConfig
```

## 3. 关键模块

| 模块 | 主要文件 | 职责 |
| --- | --- | --- |
| 组合根 | `scripts/game.gd` | 创建服务与 UI、启动会话、暂停/恢复、升级与结算路由 |
| 关卡配置 | `scripts/levels/`、`levels/*.tres` | 地图、阶段、怪物权重、预算、精英、胜负与奖励 |
| 单局编排 | `scripts/run/run_session.gd` | 单帧推进顺序、统一受击、升级暂停、胜负边界 |
| 世界装配 | `scripts/run/run_world_builder.gd` | 创建本局节点并注入配置、随机流和成长快照 |
| 怪物域 | `enemy_system.gd`、`enemy_spawner.gd`、`enemy.gd` | 生成、移动、接触、受伤、死亡和精英实例 |
| 怪物技能 | `enemy_ability_catalog.gd`、`enemy_ability_system.gd`、`enemy_ability_rules.gd` | 技能配置、状态机、站位、预算与几何规则 |
| 敌方弹体 | `enemy_projectile_system.gd`、`enemy_projectile.gd` | 敌弹数量限制、连续碰撞、命中和生命周期 |
| 英雄技能 | `scripts/skills/`、`projectile_system.gd` | 技能冷却、弹道、范围伤害和技能视觉 |
| 永久成长 | `scripts/profile/`、`run_records.gd` | schema 3、熟练度、等级、技能点、训练和迁移 |
| 表现层 | `scripts/presentation/`、`scripts/ui/` | 三套生态、预警、HUD、反馈和覆盖层 |
| 数据目录 | `hero_catalog.gd`、`enemy_catalog.gd`、`enemy_ability_catalog.gd` | 静态数值与稳定 ID |

## 4. 关卡配置

### 4.1 MapConfig

除边界、出生点和生成距离外，保存：

- `biome_id`：`windbell_meadow`、`golden_oasis` 或 `crystal_volcano`。
- 独立地面纹理、背景/地面/边框/光晕颜色。
- 装饰数量与环境粒子颜色。

`WorldRenderer` 根据生态绘制 8 类无碰撞装饰；全部处于角色下层。`EnvironmentMotes` 只负责轻量环境粒子。

### 4.2 StageConfig

每阶段保存开始时间、刷怪间隔、额外生成概率、四类怪物权重、喘息时间和 `enabled_ability_ids`。技能开放顺序由资源决定，不写死在状态机中。

### 4.3 EnemyAbilityBudgetConfig

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
- 技能执行期间关闭该怪物普通接触判定。
- 怪物死亡取消未执行预警；已发射弹体继续存在。
- 暂停、升级和结算停止状态机、预警动画和弹体推进。
- 精英继承基础怪物技能和伤害倍率，但不缩短前摇与冷却。

预警只使用珊瑚橙、奶油白、形状和动画表达：直线通道、圆形落点、虚线弹道、扇形拍击。

## 6. 统一玩家受击

`PlayerHit` 包含伤害、来源、类型、命中位置和击退。以下来源都进入同一入口：

- 普通接触。
- 张姐蛆冲刺。
- 史莱姆跃落。
- 暮翼光弹。
- 巨怪扇形拍击。

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
- `train_skill(hero_id, skill_id)`
- `reset_skill_training(hero_id)`

`LocalProfileRepository` 保存 schema 3：稳定 `profile_id`、`revision`、英雄/关卡战绩、解锁、熟练度和技能训练。旧档按历史通关次数迁移熟练度，并修复负数、越级与超预算数据。

开局只读取一次成长快照，经 `RunSession → RunWorldBuilder → Player/SkillController` 注入。本局中途修改档案不会改变正在进行的战斗。

## 9. 随机流

| 随机流 | 使用范围 |
| --- | --- |
| `spawn` | 怪物类型、生成位置和额外生成 |
| `loot` | 掉落与拾取音调 |
| `skill` | 英雄技能目标、弹道和音调 |
| `upgrade` | 三选一候选 |
| `enemy_ability` | 怪物技能冷却偏移 |

拆分后，调整掉落概率不会改变刷怪或敌方施法序列。

## 10. 验证与结构守卫

```bash
./tools/run_tests.sh
./tools/run_visual_tests.sh
```

当前统一入口执行 15 套测试，并拒绝脚本解析错误、测试标识缺失或重复。覆盖关卡、阶段、刷怪、四项怪物技能、几何预算、敌弹连续碰撞、胜利边界、schema 3 迁移、英雄成长、技能数值契约、两步开始流程、战役、声音、4 种屏幕比例和架构边界。

`tools/check_architecture.gd` 检查：

- `scripts/` 与 `tools/` 下每个 GDScript 不超过 250 行。
- `scripts/levels/` 不依赖 UI 或运行系统。
- `game.gd` 不包含具体关卡时长、阶段表或精英名称。

## 11. 扩展原则

- 新增怪物技能：先加入 `EnemyAbilityCatalog`，再扩展状态机执行分支和预警形状测试。
- 新增关卡：新增 `.tres` 并加入 `LevelCatalog`，不修改 `game.gd`。
- 新增存储后端：实现 `ProfileRepository`，不让战斗系统直接依赖云端 SDK。
- 新增敌方弹种：扩展 `EnemyProjectileSystem`，不向英雄弹体加入阵营分支。
