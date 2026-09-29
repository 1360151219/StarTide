# 星潮守望者

《星潮守望者》是使用 Godot 4.7 开发的 2D 竖屏生存肉鸽。玩家只负责移动和走位，英雄自动释放技能；击败怪物获得经验，通过三选一完成局内构筑，并在关卡外管理角色与装备。

## 当前内容

- 两名英雄：星潮守望者、烬羽游侠。
- 六项英雄技能、分支强化、固有被动与三槽自动释放。
- 五个连续解锁关卡：风铃草原、黄金绿洲、水晶火山、五色云林、千里云庭。
- 七类怪物、七套数据驱动敌方技能、阶段、精英与三阶段驺吾 Boss 战。
- 五类拾取、遗物、七件装备与永久成长。
- 远征地图、角色与装备、图鉴、音频设置、三选一、暂停和结算流程。
- 大厅、五个生态与驺吾试炼的独立音乐，以及 60 个分级音效 Cue。
- 寒冰斩使用加速切入、弯曲随挥、滞后尾迹与破碎冰屑收尾；霜潮脉冲使用与 0.36 秒命中波前同步的径向破口潮环、分支素材与 Lv5 星海冰冠。
- 烬羽连矢使用分支化羽刃与独立命中，陨星在 340 ms 落地帧完成范围峰值，凤凰双翼在 180 ms 完整展开并同步结算。
- 陨星雨使用独立熔岩岩核、内部翻卷的尾焰、爆发后冷却的火烟、贴地尘浪与抛射碎岩；范围冲击在落地后 56 ms 内抵达外沿，余烬 720 ms 内清理，支持暂停冻结和角色保护区。
- 其余五项英雄技能沿用材质特效标准：四棱星晶与能量尾流、冰刃与霜潮内部折光、流动火羽、凤凰羽焰和属性命中碎片；制作前从 `AGENTS.md` 进入美术规范的 `Combat Material VFX Standard`。
- 其余技能采用飞行距离驱动尾迹、错相羽梢、径向碎冰、加速陨落与翼根展翼；七套敌方技能统一真实进度预警，并分别保留扬尘、蝠翼、风刃、落印及五采尾流的轮廓。

## 运行

使用 Godot 4.7 打开项目根目录并运行 `main.tscn`。

命令行启动：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

## 架构

```text
main.tscn
└── scripts/game.gd                 # 应用编排：大厅、局内、暂停、升级、结算
	├── scripts/run/                # 单局状态、阶段、构筑、内容解析与结算
	├── scripts/systems/            # 敌人、投射物、拾取与升级系统
	├── scripts/skills/             # 两名英雄的技能运行时
	├── scripts/passives/           # 英雄固有被动
	├── scripts/presentation/       # 世界、角色、预警和战斗反馈
	├── scripts/ui/                 # 远征、角色、图鉴、HUD 与覆盖层
	└── scripts/profile/            # 本地档案、装备、成长与发现
```

数据与运行时分离：

```text
content/*.tres                      # 英雄、敌人、技能、遗物、拾取、装备
levels/campaign_main.tres           # 关卡顺序与通关链
levels/level_*.tres                 # 地图、阶段、掉落、精英/Boss 与胜利条件
scripts/*_catalog.gd                # 稳定 ID 到数据资源的只读入口
```

约束：

- `Game` 只负责编排，不复制单局系统逻辑。
- 关卡与内容参数来自 `.tres`，界面不硬编码关卡展示副本。
- 局外英雄选择只有 `CharacterPage` 一条流程；远征页读取档案中的当前英雄。
- 运行时文字、数字、关卡钉和状态由节点绘制，不烘焙进背景图。
- 内容 ID、存档 Schema 与音频 Cue 是稳定接口，视觉迭代不得随意改名。

## 目录

```text
assets/                 当前运行时美术、音频、字体与许可
content/                全局内容资源
levels/                 战役和关卡资源
scenes/                 正式场景与角色帧预览工具
scripts/                运行时代码
tools/                  自动测试、截图、音频生成与诊断工具
docs/                   当前设计原则与三张正式审阅图
.prompts/               当前方向的素材生成提示词
preview/responsive/     四档响应式截图基线
```

构建产物、Android 模板、临时文件、设计源和普通审阅截图不属于项目源文件，统一写入被忽略的 `build/`、`tmp/` 或 `preview/` 非基线区域。

## 测试

运行全部自动检查：

```bash
./tools/run_tests.sh
```

当前测试覆盖：

- 关卡目录、内容池、阶段、生成、敌方技能、Boss 状态机与胜利条件。
- 存档迁移、成长、战力、装备、技能、单局安全和内容发现。
- 远征页、角色页、图鉴、表现系统、音频与主流程冒烟。
- 540×960、540×1170、540×1200、720×960 四档响应式布局。
- 首次三选一的第二技能、摇杆幅度、技能就绪、轨迹命中顺序、真实治疗与屏外强敌指引。
- 代码规模、配置隔离和组合边界。

视觉像素基线：

```bash
./tools/run_visual_tests.sh
```

只有确认视觉改动正确时才更新基线：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tools/test_responsive_screenshots.gd -- --update
```

生成当前关键页面截图：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tools/capture_previews.gd
```

角色完整帧预览器位于 `scenes/tools/hero_rig_tuner.tscn`，在 Godot 中打开后按 F6。

其余保留的手动 QA 入口：`capture_biomes.gd` 检查五生态，`capture_stage_previews.gd` 检查阶段与强敌，`capture_star_effects.gd` 检查星潮技能，`capture_hero_rig_tuner.gd` 检查角色帧预览器，`report_balance.gd` 输出关卡压力。

战斗体验复核使用 `capture_combat_experience.gd`：在四档画布和模拟 Safe Area 中记录两名英雄的真实施放关键帧、满级技能叠加与屏外精英指引，输出至被忽略的 `preview/combat_experience/`。该工具使用受控构筑与静止靶群检查视觉，不作为自然通关或胜率样本。

其他五项英雄技能与七套敌方技能使用 `capture_skill_motion.gd` 复核。启动时加 `--fixed-fps 60`；工具参数 `--all-sizes --moving --overlap` 检查四档画布、安全区、移动和敌我特效重叠，`--level=1`～`5` 检查等级，`--subject=技能或分支ID` 筛选，`--sequence` 每 3 个模拟帧保存一帧（20 fps 审阅序列）。默认输出为被忽略的 `preview/skill_motion/`；使用临时档案与受控技能施放，不作为性能或通关样本。

陨星专项可加 `--subject=meteor_rain --cycles=3 --stacked --map=level_03` 检查连续释放、烬羽三技能叠加和火山场景；`--target-distance=36` 检查贴身落点的角色保护区。单次记录延长到 1.5 秒，以覆盖末枚陨星的完整余烬清理。

寒冰斩专项复核使用 `Godot --path . --fixed-fps 60 --script res://tools/capture_frost_slash.gd -- --all-sizes`，覆盖五个等级、四档画布和模拟安全区；追加 `--sequence` 保存完整 60 fps 帧序列，`--moving` 检查移动施放，`--output=res://tmp/...` 可指定对照输出目录。默认关键帧保存在被忽略的 `preview/frost_slash/`。

## 导出

Android 与 Web 均使用 `export_presets.cfg`。构建结果统一进入 `build/`：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-debug "com.xingchao.guardian" "build/android/星潮守望者.apk"
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-debug "Web" "build/web/index.html"
```

## 设计规范

执行顺序：

1. [美术方向](docs/ART_DIRECTION.md)
2. [UI 规范](docs/UI_SPEC.md)
3. [运行时素材清单](docs/ASSET_MANIFEST.md)
4. [视觉审计](docs/VISUAL_AUDIT.md)
5. [视觉方向决策](docs/VISUAL_DIRECTIONS.md)

未来 Codex 迭代的默认规则入口为根目录 `AGENT.md`，兼容自动发现入口为 `AGENTS.md`。
