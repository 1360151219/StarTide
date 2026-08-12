# 方案 D 战斗背景提示词

用途：生成风铃草原、黄金绿洲、水晶火山、五色云林、千里云庭的纯环境参考、地面草图和装饰簇。背景必须服务开放式 Vampire Survivors-like 战斗，不生成封闭竞技场、角色、怪物、技能或 HUD。

## 已采用：远征大厅运行时地图底板

模式：以 `docs/references/map-reference.png` 的清透赛璐璐、俯视自然地貌和连续路线关系为风格参考，重新组织五生态构图；不复制参考图中的运行时动态内容。

```text
Create a clean 9:16 runtime route-map environment background for a mobile 2D anime roguelite in art direction D “Sunlit Expedition Animation”. Use a strict top-down hand-painted geography with five connected ecological masses following one readable expedition path from bottom to top: windbell meadow near (270,626), golden oasis near (420,514), crystal volcano near (340,382), five-color cloudwood near (172,264), and thousand-mile cloud court near (320,132). Connect them with a winding river, forest trail and pale cloud road without enclosing any area. Keep generous low-detail clearings around all five coordinates for runtime destination pins and hero overlays. Fresh cel-animation color grouping, soft daylight, shallow natural texture, readable terrain masses, one continuous world extending to all four edges. Environment only: no hero, character, monster, boss, destination pin, lock badge, compass UI, title plaque, page number, quest panel, bottom navigation, start button, text, number, logo, watermark, arena boundary, paper-cut theatre, SaaS card, glassmorphism, purple technology gradient, photorealism, or 3D plastic rendering.
```

运行时输出：`assets/art/sunlit/backgrounds/expedition_route_map.png`。该图只承载环境，所有关卡状态与交互均由 Godot 节点绘制。

## 通用变量

| 变量 | 说明 |
|---|---|
| `{{BIOME}}` | 生态名称 |
| `{{GROUND_MASSES}}` | 2～4 个主要地表色块 |
| `{{PROP_CLUSTERS}}` | 3～5 个成簇装饰类型 |
| `{{FAR_SHAPES}}` | 低对比远层阴影或地标 |
| `{{PALETTE}}` | 生态色板；不得替代 UI 语义色 |
| `{{READABILITY_NOTES}}` | 玩家附近降噪要求 |

## 纯环境参考提示词

```text
Use case: stylized-concept
Asset type: 9:16 portrait top-down 2D game environment implementation reference for a mobile Vampire Survivors-like
Primary request: create a pure open-field environment plate for {{BIOME}} in art direction D “Sunlit Expedition Animation”.
Scene/backdrop: {{GROUND_MASSES}} with {{PROP_CLUSTERS}} and restrained {{FAR_SHAPES}}; one continuous traversal field extending beyond all four edges.
Style/medium: softly hand-painted natural environment, clean cel-animation color grouping, bright diffused daylight, fresh optimistic expedition mood, implementation-readable shapes, child-friendly but not childish.
Composition/framing: strict top-down gameplay view, portrait 9:16. Keep the central 35% and several broad traversal corridors low-frequency for player, enemies, pickups, telegraphs, and damage numbers. Concentrate decorative clusters toward edges and quiet corners. No single central scenic object.
Lighting/mood: clear daylight and soft ambient shadows; medium-high overall brightness; no cinematic darkness or heavy vignette.
Color palette: {{PALETTE}}; danger red, healing green, skill cyan, and sunlight-gold UI accents must remain distinguishable from the ground.
Materials/textures: broad painted grass/sand/rock masses, restrained natural grain, shallow water or crystal where relevant; no glossy plastic or photoreal material scan.
Constraints: environment only; {{READABILITY_NOTES}}; no visible safety circle; no arena boundary, lane, wall, closed room, proscenium, curtain, foreground frame, central platform, character, enemy, weapon, projectile, pickup, UI, HUD, icon, card, text, number, logo, or watermark. Do not make the entire image glow.
Avoid: paper-cut theatre, SaaS styling, sci-fi neon, purple technology gradients, photorealism, pixel art, high-frequency noise, identical scattered decorations, black-screen darkness, gameplay-obscuring vignette.
```

## 生态定义

### 风铃草原

- 地表：晨光草浪、低饱和路径、少量浅水洼。
- 装饰簇：蓝紫铃花、白色小花、木路标、风车投影、圆润石块。
- 色板：草叶绿、晨湖青、暖阳黄；危险珊瑚红必须明显跳出。
- 中心不均匀铺花；水洼不得与范围预警同轮廓。

### 黄金绿洲

- 地表：暖沙丘、压低对比的旅行路径、青绿水脉。
- 装饰簇：旅行旗、耐旱植物、浅木路标、石柱残片、绿洲水边。
- 色板：暖沙金、灰湖青、绿松水色；避免整屏橙黄导致危险失效。
- 碎石只成簇出现，不均匀撒满地面。

### 水晶火山

- 地表：炭灰岩板、低亮珊瑚裂隙、少量冷色反光。
- 装饰簇：蓝绿晶体、黑曜石块、灰烬草、热气孔、远层火山影。
- 色板：炭灰、珊瑚红、蓝绿晶；裂隙常态亮度低于敌方预警。
- 保持空气感与天空反光，不做暗黑洞穴。

### 五色云林

- 地表：浅绿林地、低频云雾、自然曲折的林间通路。
- 装饰簇：五色叶冠、桦木根系、小片苔藓、云纹浅水、远层树影。
- 色板：叶绿、晨湖青、暖阳金、少量靛蓝与低饱和珊瑚；珊瑚色不得形成扇形、圆形或连续危险边。
- 中心和侧向穿行路线保持低频，不绘制可见安全扇区。

### 千里云庭

- 地表：象牙云石、青绿浅水、开阔天光与少量金色风草。
- 装饰簇：磨砂云门、低矮风旗、浅木栏桩、细长云影、远层浮石。
- 色板：暖象牙、雾青、叶绿、日照金；五色只做细小环境回声，不能抢占驺吾纹带。
- 保留长直与环形穿行空间，但不烘焙冲刺通道、尾扫缺口、落点或封闭 Boss 平台。

## 可平铺地面提示词补充

```text
Asset type: seamless square top-down game ground texture
Composition/framing: orthographic top-down; no focal object; edge values and forms continue seamlessly; large low-frequency variation only.
Constraints: seamless on all four edges; no props, paths, rings, borders, text, or baked player readability circle; no obvious repeating flower/stone motif.
```

地面完成后必须进行 3×3 重复检查。玩家附近降噪由运行时 shader/渲染器完成，不烘焙进平铺纹理。

## 装饰簇提示词补充

```text
Asset type: isolated top-down 2D environment prop cluster
Subject: exactly one cohesive cluster of {{PROP_CLUSTER}}, designed to sit below characters and combat effects.
Composition/framing: top-down; cluster occupies 65%–75%; generous padding; clear edge; no central gameplay marker.
Scene/backdrop: perfectly flat solid {{CHROMA_KEY}} chroma-key background.
Constraints: one cluster only; no character, enemy, pickup, telegraph, UI, text, logo, or watermark; no cast shadow outside the cluster; do not use {{CHROMA_KEY}} in the subject.
```

## 交付检查

- 中央 35% 与主要穿行区低频、无固定亮地标。
- 地图延伸至四边，没有道路围栏、竞技场边界或前景画框。
- 环境色与危险、治疗、冰霜、火焰及主操作保持分离。
- 无角色、敌人、技能、拾取物、HUD、文字、数字、Logo 或水印。
- 地面通过 3×3 重复检查；装饰簇通过透明边缘和目标尺寸检查。
- 参考图必须拆层并人工收笔，不能直接作为运行时平铺底图。
