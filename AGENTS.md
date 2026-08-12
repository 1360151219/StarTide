# 《星潮守望者》Codex 迭代规则

本文件是项目的代理入口、架构地图和文档索引，适用于项目根目录及全部子目录。先读本文件，再按任务类型读取最少必要的专项文档；不要把 `docs/` 全量通读当作默认流程。

## 1. 项目速览

《星潮守望者》是使用 Godot 4.7 开发的 2D 竖屏生存肉鸽。核心循环是：大厅选择关卡与活动英雄 → 进入开放地图 → 玩家只移动、技能自动释放 → 击败敌人获取经验并三选一构筑 → 完成关卡后结算永久成长、装备与发现内容。

当前产品包含两名英雄、六项英雄技能、五个连续关卡、七类怪物、遗物与装备成长、精英及三阶段驺吾 Boss 战，并覆盖远征、角色、装备、图鉴、音频设置、暂停、升级和结算流程。

不可变产品边界：

- 保持竖屏、俯视、开放地图、自动攻击；玩家唯一持续操作是移动。
- 保持自动技能槽、三选一升级和现有关卡外主流程。
- 不新增攻击键、技能键、闪避键、卡牌出牌区或封闭竞技场。
- 保留现有英雄与怪物的头身比、五官、武器比例和标志性色块。
- 不因界面或视觉改造随意修改内容 ID、存档 Schema、战斗数值、掉落规则或音频 Cue ID。

## 2. 最小阅读路由

所有任务先读本文件；之后只按下表补充阅读。

| 任务 | 必读 | 需要时再读 |
|---|---|---|
| 运行、导出、测试、全局架构 | `README.md`、目标代码 | `tools/check_architecture.gd` |
| 玩法、战斗、单局构筑 | 目标代码、对应 `content/*.tres` / `levels/*.tres` | `docs/NUMERICAL_SYSTEMS.md` |
| 永久成长、装备、属性、战力 | `docs/NUMERICAL_SYSTEMS.md`、`scripts/profile/` 相关实现 | 对应内容资源与回归测试 |
| UI、布局、交互状态、响应式 | `docs/ART_DIRECTION.md`、`docs/UI_SPEC.md` | `docs/ASSET_MANIFEST.md`、三张参考图 |
| 角色、怪物、技能特效、环境、音频 | `docs/ART_DIRECTION.md`、`docs/ASSET_MANIFEST.md` | `docs/UI_SPEC.md` |
| 新增或替换生成素材 | 上述视觉文档、对应 `.prompts/*.md` | 三张参考图 |
| 视觉方向复盘 | `docs/VISUAL_DIRECTIONS.md` | `docs/VISUAL_AUDIT.md`、三张参考图 |
| 修复当前视觉问题 | `docs/VISUAL_AUDIT.md`、对应权威规范 | 实际运行截图 |

### 2.1 文档索引与职责

| 文件 | 唯一职责 | 性质 |
|---|---|---|
| `README.md` | 面向人的项目简介、运行、测试与导出命令 | 快速入口 |
| `docs/ART_DIRECTION.md` | 视觉命题、材质、形状、颜色、字体、角色保留、动效与禁用模式 | 视觉权威规范 |
| `docs/UI_SPEC.md` | 画布、网格、安全区、页面布局、组件状态、动效时间和验收值 | UI 权威规范 |
| `docs/ASSET_MANIFEST.md` | 当前允许存在和复用的正式图片、字体、音频与资源路径 | 资源权威清单 |
| `docs/NUMERICAL_SYSTEMS.md` | 属性、装备、技能培养、单局倍率、养成评分、采样契约及暂缓方案 | 数值权威说明 |
| `docs/VISUAL_DIRECTIONS.md` | 为什么选择 D「日光远征动画」及方向边界 | 决策记录，不是逐项实现清单 |
| `docs/VISUAL_AUDIT.md` | 当前视觉问题、优先级、保留项与下一轮验收条件 | 带日期的现状快照，不覆盖权威规范 |
| `docs/references/*.png` | 战斗、三选一、远征地图的构图、材质和氛围参考 | 审阅参考，禁止运行时引用 |
| `.prompts/*.md` | 卡牌主体、状态图标、背景、UI 构件的生成约束 | 仅在生成对应素材时读取 |

冲突时按以下顺序处理：

1. 当前玩法、数据、稳定内容 ID、存档和音频 Cue 契约。
2. 对应领域的权威规范；视觉内部为 `ART_DIRECTION.md` → `UI_SPEC.md` → `ASSET_MANIFEST.md`。
3. 当前代码的既有边界与共享实现。
4. `VISUAL_DIRECTIONS.md`、`VISUAL_AUDIT.md` 和参考图。

`NUMERICAL_SYSTEMS.md` 的“当前已实现”部分必须与配置、运行时代码和测试一致；发现不一致时先确定真实运行行为，再同步单一实现与本文，不在 UI 或新文档中创建第二套公式。

## 3. 代码与数据结构

### 3.1 运行时主链路

```text
main.tscn
└── scripts/game.gd                    # 组合根：大厅、开局、暂停、升级、结算
    ├── scripts/ui/frontend_shell.gd   # 局外导航与远征确认
    ├── scripts/run/run_session.gd     # 单局生命周期与系统调度
    │   ├── run_world_builder.gd       # 组装世界和各运行时系统
    │   ├── stage_director.gd          # 关卡阶段推进
    │   ├── run_build_state.gd         # 本局技能、分支、遗物与倍率
    │   └── run_result_service.gd      # 结算、奖励与聚合样本
    ├── scripts/ui/game_hud.gd         # 战斗 HUD
    ├── scripts/ui/*_overlay.gd        # 暂停、升级、结算覆盖层
    └── scripts/run_records.gd         # 档案门面、关卡记录与局外进度
```

运行数据流：

```text
content/*.tres + levels/*.tres
        ↓ 目录类与配置校验
RunSession → RunWorldBuilder → systems / skills / passives / combat
        ↓ 状态与事件
presentation + ui
        ↓ 结算
RunResultService → RunRecords / profile
```

### 3.2 目录职责

| 路径 | 职责 | 修改边界 |
|---|---|---|
| `content/` | 英雄、敌人、敌方技能、技能、遗物、拾取、装备的全局资源 | 内容事实写在 `.tres`，不在 UI 复制 |
| `levels/` | 战役顺序与五关地图、阶段、池、掉落、精英/Boss、胜利条件 | 关卡差异优先配置化 |
| `scripts/levels/` | 关卡 Resource Schema、目录和校验器 | 只依赖配置层与目录类，不依赖运行时系统 |
| `scripts/content/` | 通用内容清单与条目配置 | 保持稳定 ID 和类型边界 |
| `scripts/run/` | 单局状态、阶段、内容解析、安全恢复、结算与平衡样本 | 编排单局，不承载具体画法 |
| `scripts/systems/` | 敌人、敌方技能、Boss、投射物、拾取和升级系统 | 通用战斗规则放这里 |
| `scripts/combat/` | 统一命中数据、承伤解析和战斗时间线 | 伤害链路只有一个入口 |
| `scripts/skills/` | 技能控制器与两名英雄的技能运行时 | 具体技能行为，不保存局外成长 |
| `scripts/passives/` | 英雄固有被动 | 不与技能或 UI 状态重复计算 |
| `scripts/presentation/` | 世界渲染、角色 Rig、敌人预警、受击和战斗反馈 | 只表达表现，不改变结算 |
| `scripts/ui/` | 局外页面、战斗 HUD、覆盖层和共享日光远征组件 | 读取领域结果，不复制公式或内容数据 |
| `scripts/profile/` | 存档 Schema、仓储、英雄成长、装备、属性解析、养成评分和发现 | 永久数据与迁移的单一入口 |
| `scripts/*.gd` | 玩家/敌人/拾取/投射物实体、目录类、音频、特效和应用门面 | 新职责优先归入已有子域 |
| `scenes/` | 正式 HeroRig 场景与角色帧调试场景 | 不维护第二套游戏流程 |
| `assets/` | 运行时美术、音频、字体和许可 | 必须登记在素材清单 |
| `tools/` | 自动测试、架构检查、截图、平衡基准、音频生成和调试工具 | 可复现输出不进入源文件 |

### 3.3 关键单一来源

- 应用编排：`scripts/game.gd`；它只连接页面与单局，不下沉系统逻辑。
- 单局编排：`scripts/run/run_session.gd`；世界组装集中在 `run_world_builder.gd`。
- 内容与关卡：`content/*.tres`、`levels/*.tres`；对应 `*_catalog.gd` 只提供稳定 ID 的只读入口。
- 永久档案：`scripts/profile/profile_schema.gd`、仓储实现与 `scripts/run_records.gd`。
- 常驻属性与战力：`hero_stat_resolver.gd`、`power_rating_config.gd`、`power_rating_service.gd`。
- 单局构筑：`scripts/run/run_build_state.gd`；UI 不维护镜像构筑状态。
- 玩家承伤：`scripts/combat/player_damage_resolver.gd`；表现层只消费最终事件。
- 视觉令牌与共享构件：现有 `SunlitFrame`、`SunlitCardStyle`、`SunlitGlyph`、`UIFactory` 等共享实现。
- 音频事件：`scripts/audio_cue_catalog.gd` 与 `AudioManager`；Cue ID 是稳定接口。

## 4. 实现约束

- `Game` 是组合根；不要把生成、伤害、技能、关卡参数等系统逻辑塞回 `game.gd`。
- `scripts/levels/` 是配置层，只能依赖关卡配置和目录类；不得反向依赖 `systems/`、`skills/`、`ui/` 等运行时模块。
- 脚本以组合和窄职责为主；`tools/check_architecture.gd` 当前要求 `scripts/` 与 `tools/` 内单个 GDScript 不超过 250 行。
- 内容、关卡、属性、掉落和 UI 展示都读取既有单一来源；禁止平行索引、镜像状态和页面硬编码副本。
- 新组件先明确职责与状态边界；能扩展共享组件时，不新增平行组件。
- 静态背景只承载环境；交互、文字、数字、角色、关卡状态、危险和本地化内容由 Godot 节点绘制。
- 局外英雄选择只通过角色页和档案中的活动英雄完成，不恢复旧英雄选择或培养副本。
- 纯审计、报告或方案任务不得擅自修改游戏逻辑。

## 5. 视觉与资源摘要

唯一视觉方向是 D「日光远征动画」：清透赛璐璐、自然手绘、轻量远征装备材质和读战优先。材质限于浅色帆布、桦木、搪瓷、磨砂金属扣、织带、绳结和少量旧地图纸；每页只允许一个日照金主操作，危险红只表达真实危险。

角色、敌人、危险、拾取物和伤害反馈优先于环境装饰。技能依靠轮廓、轨迹和命中节奏区分，品质依靠边框层数、左上轮廓和揭示节奏区分，不能只换颜色。

禁止 SaaS 后台、白色卡片海、通用网页按钮、统一大圆角、玻璃拟态、紫色科技渐变、满屏发光、剪纸影戏、人偶关节、暗色幕布、写实 3D 塑料、Emoji 正式图标和混用不同 AI 渲染风格。

资源规则：

- 优先复用 `ASSET_MANIFEST.md` 中的正式素材和共享程序组件；新增、替换或删除正式素材时同步更新清单。
- 生成图不得包含文字、伪文字、数字、品质、按钮文案、Logo 或水印。
- 生成源、色键图、图集母版、中间图、普通审阅截图、构建包和导出目录不得进入项目源文件。
- `docs/references/` 只保留三张正式审阅图；`preview/` 只提交 `.gdignore` 和 `responsive/*.png` 四张响应式基线。
- 不创建重复素材、仅换色版本、`final2` 文件或第二套相同职责的目录。

## 6. 验证入口

- 全量自动检查：`./tools/run_tests.sh`。
- 视觉像素检查：`./tools/run_visual_tests.sh`；只有人工确认改动正确后才更新基线。
- 架构边界：`tools/check_architecture.gd`，已由全量测试覆盖。
- 数值改动先跑对应的 `test_power_equipment.gd`、`test_run_build.gd`、`test_run_balance_sample.gd` 或关卡测试，再跑全量检查。
- 视觉改动必须实际运行受影响页面，检查 540×960、540×1170、540×1200、720×960 四档画布和 Safe Area，并确认运行时未引用 `docs/references/`、`preview/` 或生成源文件。
- 小型纯文档改动只需检查差异；不要为此启动游戏或更新视觉基线。

## 7. 文档维护

固定文档结构如下：

```text
docs/
├── ART_DIRECTION.md
├── UI_SPEC.md
├── ASSET_MANIFEST.md
├── NUMERICAL_SYSTEMS.md
├── VISUAL_DIRECTIONS.md
├── VISUAL_AUDIT.md
└── references/
    ├── battle-reference.png
    ├── reward-reference.png
    └── map-reference.png

.prompts/
├── card-art.md
├── status-icons.md
├── backgrounds.md
└── ui-ornaments.md
```

- 不为一次迭代新增报告、历史方案副本、平行规范或重复索引；需要追溯时使用 Git 历史。
- 方向、颜色、字体、形状、材质、公式、资源路径或稳定契约变化时，直接更新对应单一来源并同步修正引用。
- 只有目录职责、入口文件、文档角色或长期边界发生变化时才更新本文件；具体功能细节留在代码、数据和专项规范中。
