# 《星潮守望者》架构说明

> 适用版本：Godot 4.7 / 当前三关 MVP  
> 文档日期：2026-07-15

## 1. 架构目标

当前架构围绕四个约束设计：

1. 关卡内容与运行逻辑分离。地图、时长、阶段、刷怪、精英、胜利和奖励全部来自 `LevelConfig` 资源。
2. 英雄、怪物和关卡数值各有单一来源，运行时只消费配置，不复制数值表。
3. 单局流程按职责拆分，`game.gd` 只负责装配和界面路由，不承载战斗算法。
4. 每个第一方 GDScript 不超过 250 行，配置层不依赖 UI 或运行系统。

## 2. 总体依赖关系

```text
main.tscn
  └─ game.gd（组合根）
      ├─ StartScreen / HUD / Pause / Upgrade / Result
      ├─ AudioManager / CombatEffects / CombatFeedback
      └─ RunSession
          ├─ RunState
          ├─ StageDirector
          ├─ RunWorldBuilder
          │   ├─ Player
          │   ├─ EnemySystem ─ EnemySpawner
          │   ├─ ProjectileSystem
          │   ├─ PickupSystem
          │   ├─ SkillController ─ 英雄技能运行时
          │   ├─ PassiveController ─ 英雄被动运行时
          │   └─ WorldRenderer
          └─ RunResultService ─ RunRecords

LevelCatalog
  └─ levels/*.tres
      └─ LevelConfig
          ├─ MapConfig
          ├─ DifficultyConfig
          ├─ LootConfig
          ├─ StageConfig[]
          ├─ EliteConfig
          ├─ VictoryConfig
          └─ RewardConfig
```

运行模块可以读取配置层；配置层不能反向依赖 UI、战斗系统或具体场景节点。

## 3. 模块边界

| 模块 | 主要文件 | 负责 | 不负责 |
| --- | --- | --- | --- |
| 组合根 | `scripts/game.gd` | 创建服务和 UI、启动会话、暂停/恢复、升级与结算界面路由 | 关卡数值、刷怪算法、技能伤害 |
| 关卡配置 | `scripts/levels/`、`levels/*.tres` | 关卡结构、资源校验、难度插值、压力评估 | 节点创建、UI 展示、战斗推进 |
| 单局编排 | `scripts/run/run_session.gd` | 单帧推进顺序、系统间信号、胜负边界 | 具体怪物、投射物或技能算法 |
| 单局状态 | `scripts/run/run_state.gd` | 时间、击杀、等级、经验、暂停、胜负、精英状态 | 持久化和画面表现 |
| 阶段导演 | `scripts/run/stage_director.gd` | 阶段切换、喘息窗口、精英一次性触发 | 实际生成怪物 |
| 世界装配 | `scripts/run/run_world_builder.gd` | 从英雄与关卡配置创建本局节点和系统 | 每帧战斗逻辑 |
| 怪物域 | `scripts/systems/enemy_system.gd`、`enemy_spawner.gd`、`enemy.gd` | 生成、移动、接触候选、受伤、死亡、精英实例 | 胜负结算、升级候选 |
| 技能域 | `scripts/skills/`、`projectile_system.gd` | 技能冷却、释放、弹道、范围伤害和技能视觉 | 英雄升级候选和关卡难度 |
| 被动域 | `scripts/passives/` | 两名英雄固有机制及结算统计 | 主动技能和存档 |
| 掉落域 | `scripts/systems/pickup_system.gd` | 经验、治疗、磁吸掉落与收集 | 经验等级公式和升级 UI |
| 升级域 | `scripts/systems/upgrade_system.gd` | 三选一构建、文本和强化应用 | 经验累计和界面布局 |
| 表现层 | `scripts/presentation/`、`scripts/ui/` | 地图绘制、HUD、菜单、反馈与覆盖层 | 关卡规则判定 |
| 屏幕布局 | `screen_layout.gd`、`design_frame.gd`、`safe_area.gd` | 逻辑设计框、全屏覆盖、物理安全区坐标转换 | 具体界面内容 |
| 数据目录 | `hero_catalog.gd`、`enemy_catalog.gd` | 英雄、技能和普通怪物基础数值 | 单局可变状态 |
| 持久化 | `scripts/run_records.gd` | 英雄/关卡战绩、解锁链、上次选择 | 战斗过程状态 |

## 4. 关卡配置模型

### 4.1 LevelConfig

| 字段 | 含义 |
| --- | --- |
| `level_id`、`order` | 稳定标识和战役顺序 |
| `difficulty_rating` | 开始页显示的 1～10 难度评级，不直接参与战斗公式 |
| `display_name`、`subtitle`、`description` | 玩家可见文案 |
| `map` | 地图边界、出生点、刷怪距离和视觉色调 |
| `duration` | 关卡时间边界 |
| `initial_enemy_count`、`max_enemies` | 初始数量和场上数量上限 |
| `difficulty` | 普通怪物生命、速度、伤害的全局线性倍率 |
| `loot` | 治疗、磁吸概率与效果、拾取范围 |
| `stages` | 按开始时间排序的阶段列表 |
| `elite` | 精英生成、属性和击败奖励 |
| `victory` | 胜利模式、完美结算和标题 |
| `reward` | 关卡奖励文案及下一关解锁目标 |

`LevelConfig.stage_end_time(index)` 用下一阶段的 `start_time` 推导当前阶段结束时间；最后阶段以关卡 `duration` 结束。阶段配置不重复保存结束时间，避免两个字段不一致。

### 4.2 MapConfig

`map_id`、名称、地面纹理、`world_bounds`、玩家出生点、普通/精英生成距离区间，以及背景、地面、边框、光晕颜色。运行时由 `WorldRenderer` 绘制边界和重复地面纹理，由玩家、相机和刷怪器共同读取同一边界。刷怪器会在安全边距内重采样，并按配置距离与当前视口半对角线中的较大值生成，避免超长屏直接看到怪物出生；`depth_index()` 将不同高度的地图统一映射到画布深度范围，避免纵向地图出现层级夹断。

### 4.3 DifficultyConfig

分别保存生命、速度和伤害的起始/结束倍率。任意时刻的倍率为：

```text
progress = clamp(elapsed / duration, 0, 1)
multiplier = lerp(start, end, progress)
```

普通怪物实际属性等于 `EnemyCatalog` 基础属性乘对应倍率。精英再乘 `EliteConfig` 中的独立倍率。

### 4.4 StageConfig

每阶段保存稳定 ID、名称、说明、开始时间、刷怪间隔起止值、额外生成概率、三类怪物权重和切换后的喘息时间。刷怪间隔在该阶段内线性插值；一次刷新生成 1 只，并以 `extra_spawn_chance` 概率额外生成 1 只。

所有怪物权重必须非负且合计为 1。阶段开始时间必须递增，第一阶段必须从 0 秒开始，喘息时间不能覆盖整个阶段。

### 4.5 EliteConfig

保存是否启用、生成时间、基础怪物类型、显示名称、生命/速度/伤害/半径/视觉倍率、经验、额外升级次数和磁吸时长。`StageDirector` 保证同一局只触发一次，`EnemySystem` 负责创建实际节点。

### 4.6 VictoryConfig

当前支持三种模式：

- `survive_duration`：到达关卡时长即胜利。
- `defeat_elite`：击败精英立即胜利。
- `survive_and_defeat_elite`：同时满足击败精英和到达时长。

`perfect_requires_elite` 只控制完美结算标题，不改变普通胜利条件。失败、普通胜利和完美胜利标题也由配置提供。

### 4.7 RewardConfig

保存奖励 ID、名称、说明和 `unlock_level_id`。胜利时 `RunRecords` 根据该字段解锁下一关；第三关的解锁目标为空。当前奖励是战役推进和结算文案，不是背包物品或可装备资产。

## 5. 单局生命周期

### 5.1 启动

1. `StartScreen` 从 `LevelCatalog` 读取三关，并通过 `RunRecords` 禁用未解锁按钮。
2. `game.gd` 校验关卡存在且已解锁，创建 `RunSession`。
3. `RunSession.configure()` 重置状态，配置阶段导演，并调用 `RunWorldBuilder`。
4. 世界装配器注入当前英雄、关卡和四条随机流，创建玩家、相机、战斗系统、技能、被动和地图表现。
5. `EnemySystem` 按 `initial_enemy_count` 预生成敌人，HUD 显示当前关卡、阶段和胜利提示。

### 5.2 每帧推进顺序

`RunSession.advance()` 的顺序固定为：

1. 累计时间并先处理胜利/超时边界。
2. 处理阶段切换和精英事件。
3. 推进战斗特效与英雄被动。
4. 移动玩家并限制在地图边界内。
5. 刷新并移动怪物，处理接触伤害。
6. 推进技能、投射物和掉落物。
7. 广播状态变化，刷新 HUD。

时间边界先于接触伤害处理，因此到达生存关卡终点的同一帧不会再被接触伤害反转为失败。

### 5.3 阶段与大步长

`StageDirector.advance()` 使用循环跨越所有已经到达的阶段，不假设每帧最多切换一次。测试工具可以直接推进几十秒，仍不会遗漏中间阶段；精英事件有独立布尔门闩，最多触发一次。

### 5.4 升级与暂停

拾取经验后，`RunState` 可以一次累计多个待升级次数。每次弹出一个三选一，选择后若仍有待升级次数则继续弹出，否则恢复会话。手动暂停和升级暂停都由会话状态控制，HUD 会取消虚拟摇杆输入。

### 5.5 结算与进度

`RunResultService` 根据关卡胜利配置生成标题和说明，再调用 `RunRecords.record_level_run()`：

- 英雄战绩与关卡战绩分别累计。
- 首次通关用于结算奖励提示。
- 胜利后根据 `unlock_level_id` 解锁下一关。
- 记录最后使用的英雄和关卡，支持同配置再战。

## 6. 随机性隔离

组合根创建四个独立的 `RandomNumberGenerator`：

| 随机流 | 使用范围 |
| --- | --- |
| `spawn` | 怪物类型、生成角度与距离、额外生成 |
| `loot` | 治疗/磁吸掉落及拾取音调 |
| `skill` | 技能目标分布、弹道和技能效果 |
| `upgrade` | 三选一候选抽取 |

拆分随机流可以避免“调整掉落概率导致刷怪序列变化”一类隐式耦合，也便于使用固定种子测试。

## 7. 持久化边界

`RunRecords` 使用 `user://run_records.cfg`，当前 schema 为 2。持久化内容包括：

- 两名英雄各自的出征、通关、精英击败、最佳击杀、最高等级、最长生存时间。
- 三个关卡各自的同类战绩。
- `LevelCatalog` 当前全部关卡的解锁布尔值。
- 上次选择的英雄和关卡。

第一关始终解锁；无效英雄/关卡 ID 会回退到默认值；读取损坏配置时使用空记录安全启动。声音设置独立保存在 `user://audio_settings.cfg`。

## 8. 结构守卫

`tools/check_architecture.gd` 自动检查：

- `scripts/` 与 `tools/` 下每个 GDScript 不超过 250 行。
- `scripts/levels/` 不引用 `scripts/ui/` 或 `scripts/systems/`。
- `game.gd` 不重新出现关卡时长、阶段表或具体精英名称等硬编码。

该守卫不能识别全部职责泄漏，因此新功能仍应先选择正确模块，而不是只以行数为拆分依据。

## 9. 新增关卡流程

1. 在 `levels/` 新建一个 `LevelConfig` `.tres`，完整配置 Map、Difficulty、Loot、Stages、Elite、Victory、Reward。
2. 将资源加入 `scripts/levels/level_catalog.gd` 的 `LEVELS`，保持 `order` 连续且 ID 唯一。
3. 在前一关奖励中填写新关卡的 `unlock_level_id`；`RunRecords` 会自动从 `LevelCatalog.ids()` 建立记录和解锁字段，无需维护第二份 ID 列表。
4. 保证第一阶段从 0 秒开始、权重合计 1、喘息时间短于阶段、精英时间位于关卡时长内、解锁目标存在。
5. 扩展关卡目录、胜利和战役冒烟测试，再执行完整验证命令。

如果新关卡只改变数值、边界和色调，不需要修改 `game.gd`、`RunSession` 或 UI。只有新增规则类型，例如新的胜利模式或地图机关，才应扩展对应配置类型和独立运行模块。

## 10. 验证命令

```bash
./tools/run_tests.sh
```

统一入口会加载项目、执行 10 组测试，并拒绝引擎错误、测试缺失和重复标记；响应式测试覆盖 4 种竖屏/平板比例、全屏背景、交互安全区和物理像素转换。对应覆盖范围详见根目录 [README](../README.md)；关卡数值和压力模型详见 [关卡数值设计](LEVEL_DESIGN.md)。
