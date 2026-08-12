# 《星潮守望者》运行时素材清单

> 方向：D「日光远征动画」  
> 状态：当前工作区唯一素材基线  
> 视觉标准：[ART_DIRECTION.md](./ART_DIRECTION.md)  
> UI 标准：[UI_SPEC.md](./UI_SPEC.md)

本清单只记录当前运行时、导出、自动化测试和正式设计审阅所需素材。未列出的旧方案、生成源图、中间图、导出包和一次性审阅图不得留在项目工作区；需要追溯时使用 Git 历史。

## 1. 入库规则

- `docs/references/` 只保存三张正式审阅图，不得被运行时代码引用。
- 运行时图片只保存最终裁切版本；生成源、色键图、图集母版和处理中间件不入库。
- 文字、数字、品质、按钮文案和倒计时由 Godot 渲染，不烘焙进图片。
- 可稳定程序绘制的边框、扣件、分隔线、进度与简单图标优先使用共享组件。
- 新素材使用语义文件名与稳定路径，不使用 `final2`、模型名、日期或随机编号。
- 新增、替换或删除正式素材时，必须同步更新本文件。

## 2. 当前目录

```text
assets/
├── art/
│   ├── app_icon.png
│   ├── characters/        # 角色展示图
│   ├── enemies/           # 怪物正面与侧面图
│   ├── environment/       # 五生态战斗地面
│   ├── items/             # 物品图集
│   ├── pickups/           # 拾取物
│   ├── skills/            # 六项技能图标
│   ├── sunlit/backgrounds/# 当前远征地图环境底板
│   └── ui/                # 首页与角色中心正式 UI 位图
├── audio/                 # 7 条音乐与 56 个 Cue
├── fonts/                 # 三套运行时字体及许可
└── generated/
    ├── equipment/         # 七件装备图标
    ├── hero_chibi/        # 两名英雄各六张完整动作帧
    └── ui/                # 胜利徽章
```

## 3. 应用、字体与许可

| 路径 | 用途 |
|---|---|
| `assets/art/app_icon.png` | 项目与 Android 启动图标 |
| `assets/fonts/NotoSansSC-Regular.otf` | 正文、按钮、数字、战斗文字 |
| `assets/fonts/NotoSerifSC-UI.otf` | 展示标题与章节标题 |
| `assets/fonts/SmileySans-Oblique.otf` | 远征页面标题、关卡名、主操作与短属性标题 |
| `assets/fonts/NotoSansSC-OFL.txt` | Noto Sans SC 许可 |
| `assets/fonts/NotoSerifSC-OFL.txt` | Noto Serif SC 许可 |
| `assets/fonts/SmileySans-OFL.txt` | Smiley Sans v2.0.1 的 SIL Open Font License 1.1 |

Smiley Sans 使用[官方 v2.0.1 发行包](https://github.com/atelier-anchor/smiley-sans/releases/tag/v2.0.1)中的未修改 OTF；文件 SHA-256 为 `139b5dcbe70d6d52de85a62d148784c6af4bd161e38fdb62ba0c1e7e5065fca6`，并随包保留 OFL 许可与 Reserved Font Name 要求。

字体角色只由 [ART_DIRECTION.md](./ART_DIRECTION.md) 定义；不得再引入未使用的可变字体副本。

## 4. 角色与怪物

### 4.1 角色展示图

| 角色 | 路径 | 规则 |
|---|---|---|
| 星潮守望者 | `assets/art/characters/star_tide_warden.png` | 保留造型、比例、五官、服装和武器 |
| 烬羽游侠 | `assets/art/characters/emberwing_ranger.png` | 保留造型、比例、五官、服装和武器 |

局外页面优先复用 HeroRig 动作帧；展示图只用于图鉴、状态与确认等需要清晰头像的场景。

### 4.2 英雄动作帧

| 英雄 | 目录 | 当前帧 |
|---|---|---|
| 星潮守望者 | `assets/generated/hero_chibi/star_warden/` | `idle`、`run_contact`、`run_pass`、`cast`、`hit`、`victory` |
| 烬羽游侠 | `assets/generated/hero_chibi/ember_ranger/` | `idle`、`run_contact`、`run_pass`、`cast`、`hit`、`victory` |

共 12 张最终帧。源图集和色键中间图不属于运行时资产，不得重新放回该目录。

### 4.3 怪物

| 怪物 | 正面 | 侧面 |
|---|---|---|
| 青叶团团 | `assets/art/enemies/green_grub.png` | `assets/art/enemies/green_grub_side.png` |
| 星蚀史莱姆 | `assets/art/enemies/starblight_slime.png` | `assets/art/enemies/starblight_slime_side.png` |
| 暮翼蝠 | `assets/art/enemies/duskwing_bat.png` | `assets/art/enemies/duskwing_bat_side.png` |
| 陨岩巨怪 | `assets/art/enemies/meteor_brute.png` | `assets/art/enemies/meteor_brute_side.png` |
| 云角鹿 | `assets/art/enemies/cloud_hart.png` | `assets/art/enemies/cloud_hart_side.png` |
| 铃羽鸢 | `assets/art/enemies/bellfeather_kite.png` | `assets/art/enemies/bellfeather_kite_side.png` |
| 千里巡守·驺吾 | `assets/art/enemies/zouwu.png` | `assets/art/enemies/zouwu_side.png` |

普通、技能与精英状态复用主体图，通过运行时徽记、轮廓、色阶和短动画表达，不复制换色版本。

## 5. 技能、装备与拾取物

### 5.1 技能图标

以下六张图为唯一技能图标主体：

- `assets/art/skills/star_lance.png`
- `assets/art/skills/sun_orbit.png`
- `assets/art/skills/frost_tide.png`
- `assets/art/skills/ember_volley.png`
- `assets/art/skills/meteor_rain.png`
- `assets/art/skills/phoenix_heart.png`

卡框、品质、等级和冷却由运行时组件表达，不复制带底框版本。

### 5.2 装备

| 装备 | 路径 |
|---|---|
| 学徒星杖 | `assets/generated/equipment/apprentice_starwand.png` |
| 风弦弓 | `assets/generated/equipment/windstring_bow.png` |
| 草原护甲 | `assets/generated/equipment/meadow_guard.png` |
| 晶纹背心 | `assets/generated/equipment/crystal_vest.png` |
| 风铃护符 | `assets/generated/equipment/windbell_charm.png` |
| 时砂护符 | `assets/generated/equipment/timeglass_charm.png` |
| 千里风印 | `assets/generated/equipment/thousand_mile_windseal.png` |

不同品质复用同一主体图；运行时方格统一为 `1:1` 正方形：`common` 使用灰色单压线，`rare` 使用鲜绿双压线与左上缺口，`top` 使用明亮金色三段边框与左上冠形徽记，均不带底部节点或挂件。已装备归属头像由运行时叠加，不复制进装备主体或品质框素材。

### 5.3 拾取物与物品图集

| 路径 | 用途 |
|---|---|
| `assets/art/pickups/experience_shard.png` | 经验拾取与结算经验图标 |
| `assets/art/pickups/healing_heart.png` | 治疗拾取与恢复选项 |
| `assets/art/pickups/magnet_charm.png` | 磁吸拾取 |
| `assets/art/items/item_atlas.png` | 遗物与没有独立主体图的物品区域 |

加速、爆破、锁定、空槽、声音、暂停和装备部位由正式程序图标绘制；首页导航与设置入口使用下节登记的正式 UI 位图，不得用 Emoji 代替。

## 6. 场景与 UI 位图

| 路径 | 用途 | 边界 |
|---|---|---|
| `assets/art/environment/windbell_meadow_floor.png` | 风铃草原战斗地面 | 中心降噪由运行时完成 |
| `assets/art/environment/golden_oasis_floor.png` | 黄金绿洲战斗地面 | 暖色不得吞没火焰和危险 |
| `assets/art/environment/crystal_volcano_floor.png` | 水晶火山冷灰岩板战斗地面 | 中心低频；晶簇稀疏；裂隙常态亮度低于危险预警 |
| `assets/art/environment/fivecolor_cloudwood_floor.png` | 五色云林战斗地面 | 日光林地与低频云雾；五色点缀不复用危险预警轮廓 |
| `assets/art/environment/thousand_mile_court_floor.png` | 千里云庭战斗地面 | 象牙云石与青绿浅水；不烘焙冲刺通道、平台边界或落点 |
| `assets/art/sunlit/backgrounds/expedition_route_map.png` | 远征大厅五生态环境底板 | 无角色、关卡钉、文字和导航 |
| `assets/art/ui/battle/battle_status_frame.png` | 战斗顶部连续状态栏空白底框 | 运行时叠加等级、生命、经验、时间、击败与暂停 Glyph；不烘焙文字、数值、图标或填充状态 |
| `assets/art/ui/battle/battle_progress_frame.png` | 战斗远征进度织带空白底框 | 运行时叠加路径段、阶段节点、标记与状态；不烘焙进度、文字或图标 |
| `assets/art/ui/home/expedition_brief_frame.png` | 首页关卡信息牌 | 统一承载名称、页码、战力与奖励分区，不烘焙数据 |
| `assets/art/ui/home/home_compass_banner.png` | 首页左上远征罗盘挂旗 | 替代程序圆角方形入口；不承载文字或点击状态 |
| `assets/art/ui/home/brief_icon_recommended.png` | 关卡信息牌建议评分图标 | 闭合盾形，20 px 灰度下与养成评分区分 |
| `assets/art/ui/home/brief_icon_power.png` | 关卡信息牌养成评分图标 | 交叉双刃轮廓，不烘焙数值 |
| `assets/art/ui/home/brief_icon_first_clear.png` | 关卡信息牌首通状态图标 | 路标旗与罗盘负形，不烘焙状态文字 |
| `assets/art/ui/home/brief_icon_reward.png` | 关卡信息牌奖励物图标 | 帆布包裹轮廓，不绑定具体奖励 ID |
| `assets/art/ui/home/start_button_frame.png` | 首页“出发”罗盘主按钮底框 | 唯一日照金主操作；运行时叠加文案与状态 |
| `assets/art/ui/home/start_button_sail.png` | 首页“出发”帆船徽记 | 与主按钮底框分层，禁用态由运行时控制 |
| `assets/art/ui/home/route_pin_available.png` | 首页路线标志普通/未解锁底框 | 中央叠加生态或锁定图标；锁定态运行时降饱和 |
| `assets/art/ui/home/route_pin_selected.png` | 首页路线标志进行中底框 | 日照金选中态，与普通态共享尺寸和轮廓 |
| `assets/art/ui/home/route_icon_meadow.png` | 风铃草原路线图标 | 仅表达生态，不承载关卡状态 |
| `assets/art/ui/home/route_icon_oasis.png` | 金砂绿洲路线图标 | 仅表达生态，不承载关卡状态 |
| `assets/art/ui/home/route_icon_volcano.png` | 彩晶火山路线图标 | 仅表达生态，不承载关卡状态 |
| `assets/art/ui/home/route_icon_cloudwood.png` | 五色云林路线图标 | 叶冠与流云轮廓，不承载关卡状态 |
| `assets/art/ui/home/route_icon_cloudcourt.png` | 千里云庭路线图标 | 云门与长风轮廓，不承载关卡状态 |
| `assets/art/ui/home/route_icon_locked.png` | 未解锁路线状态图标 | 正式挂锁语义，不使用 Emoji 或文字烘焙 |
| `assets/art/ui/home/nav_flag_normal.png` | 首页底部导航普通织带旗 | 空白中央由运行时叠加图标，不烘焙页面状态 |
| `assets/art/ui/home/nav_flag_selected.png` | 首页底部导航选中织带旗 | 与普通态共享轮廓，使用象牙帆布和双层压线表达选中 |
| `assets/art/ui/home/nav_icon_character.png` | 首页角色入口图标 | 无文字、徽章或按钮底框 |
| `assets/art/ui/home/nav_icon_expedition.png` | 首页远征入口图标 | 无文字、徽章或按钮底框 |
| `assets/art/ui/home/nav_icon_compendium.png` | 首页图鉴入口图标 | 无文字、徽章或按钮底框 |
| `assets/art/ui/home/settings_medallion.png` | 首页及共享紧凑设置入口 | 60×60 运行时显示；点击状态由 Godot 控制 |
| `assets/art/ui/character/character_camp_backdrop.png` | 角色中心日光营地环境底板 | 仅承载环境；全屏背景层切换，不烘焙角色、文字、装备或交互状态 |
| `assets/art/ui/character/hero_stage_frame.png` | 角色中心桦木帆布英雄台 | 透明中央由运行时叠加 HeroRig、装备槽与养成评分；不烘焙内容数据 |
| `assets/art/ui/character/character_title_plaque.png` | 角色中心空白标题签 | 运行时叠加页面标题；不烘焙文字 |
| `assets/art/ui/character/hero_stage_canvas.png` | 英雄台帆布内衬 | 位于桦木框与运行时角色之间；不包含角色、装备或数值 |
| `assets/art/ui/character/power_plate_frame.png` | 英雄台等级与战力空白底框 | 左侧等级区与右侧战力区由运行时叠加字体和数字；不烘焙文案或数值 |
| `assets/art/ui/character/inventory_tray_frame.png` | 五列装备背包托盘 | 运行时叠加筛选、品质格、数量与详情抽屉 |
| `assets/art/ui/character/quality_cell_common.png` | 普通品质正方形格 | 灰色单层压线，无品质文字、装备主体和底部节点 |
| `assets/art/ui/character/quality_cell_rare.png` | 稀有品质正方形格 | 鲜绿双层压线与左上缺口，无装备主体和底部节点 |
| `assets/art/ui/character/quality_cell_top.png` | 顶级品质正方形格 | 明亮金色三段边框与左上日轮，无装备主体和底部节点 |
| `assets/art/ui/character/filter_icon_all.png` | 装备背包全部筛选图标 | 四格轮廓，不烘焙按钮底框或文字 |
| `assets/art/ui/character/filter_icon_weapon.png` | 装备背包武器筛选图标 | 交叉武器轮廓，不烘焙按钮底框或文字 |
| `assets/art/ui/character/filter_icon_armor.png` | 装备背包护甲筛选图标 | 护甲轮廓，不烘焙按钮底框或文字 |
| `assets/art/ui/character/filter_icon_charm.png` | 装备背包饰品筛选图标 | 新月护符轮廓，不烘焙按钮底框或文字 |
| `assets/generated/ui/victory_crest.png` | 胜利与高价值奖励徽章 | 不作为普通装饰重复使用 |

程序组件 `SunlitFrame`、`SunlitCardStyle`、`SunlitGlyph` 和 `SunlitLockBadge` 负责边框、状态、触控与响应式，不生成整页 UI 位图。

## 7. 音频

### 7.1 音乐

| 场景 | 路径 |
|---|---|
| 远征大厅 | `assets/audio/bgm_lobby.wav` |
| 风铃草原 | `assets/audio/bgm_windbell.wav` |
| 黄金绿洲 | `assets/audio/bgm_oasis.wav` |
| 水晶火山 | `assets/audio/bgm_volcano.wav` |
| 五色云林 | `assets/audio/bgm_cloudwood.wav` |
| 千里云庭 | `assets/audio/bgm_cloudcourt.wav` |
| 驺吾试炼 | `assets/audio/bgm_zouwu_trial.wav` |

### 7.2 Cue

`assets/audio/` 中除上述 7 条音乐外保留 56 个由 `scripts/audio_cue_catalog.gd` 明确引用的 Cue，覆盖：

- UI 选择、确认、导航、打开、返回、锁定、装备、技能培养和升级。
- 经验、治疗、磁吸、加速、爆破与通用拾取。
- 玩家受伤、敌人击败、通用命中与危险预警。
- 青叶团团冲刺、暮翼蝠光弹、阶段、精英、胜利与失败。
- 云角鹿回风角、铃羽鸢落印，以及驺吾登场、冲刺、尾扫、云印和认可。
- 六项技能施放，以及冰霜、陨星和凤凰的独立命中。

音频路径和 Cue ID 是稳定接口。`tools/generate_audio.py` 是当前波形再生成工具；替换内容不得改变事件时机、总线、优先级和并发契约。
当前正式音频使用帆布摩擦、轻木敲击、搪瓷清音、阻尼短弦和自然风声五类基础音色；七条 BGM 共享短动机，但按大厅、五个生态和驺吾试炼分别使用独立调式、节奏密度与环境层。

## 8. 正式审阅图

| 路径 | 用途 |
|---|---|
| `docs/references/battle-reference.png` | 战斗层级、开放混战、HUD 与三槽材质参考 |
| `docs/references/reward-reference.png` | 三选一结构、品质层级与帆布卡参考 |
| `docs/references/map-reference.png` | 基础生态关系、路线、局外层级与氛围参考；运行时延展至五生态 |

三张图均为 941×1672 竖屏概念图，只用于方向判断。运行时不得直接切用整张设计稿，也不得照搬其中的烘焙动态内容。

## 9. 素材变更验收

- 运行时不存在对 `docs/references/`、`preview/` 或生成源文件的资源引用。
- 每项正式素材至少有一个运行时、导出、测试或许可用途。
- 新图在目标尺寸、50%、32/64 px 和灰度下通过辨识检查。
- 无伪文字、水印、色键残留、脏边、重复副本和只换色版本。
- 角色和怪物保留身份，描边、光源、接地阴影和场景色阶一致。
- 删除素材后进行全项目残留引用检查与全量测试。
