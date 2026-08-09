# 方案 D 战斗背景提示词

用途：生成风铃草原、黄金绿洲、水晶火山的纯环境参考、地面草图和装饰簇。背景必须服务开放式 Vampire Survivors-like 战斗，不生成封闭竞技场、角色、怪物、技能或 HUD。

## 已采用：远征大厅运行时地图底板

模式：编辑 `docs/references/map-reference.png`，保留三生态构图与清透赛璐璐画风，移除所有运行时动态内容。

```text
Edit the provided 9:16 “Sunlit Expedition Animation” route-map concept into a clean runtime environment background for a mobile 2D anime roguelite. Preserve the same top-down hand-painted geography, palette, lighting and composition: crystal volcano in the upper area, golden oasis at mid-right, windbell meadow at lower-left, connected by the winding road and river. Remove every hero, character, monster, destination pin, lock badge, compass UI, title plaque, page number, quest panel, bottom navigation, start button, text, number, logo and watermark. Reconstruct the scenery naturally behind all removed elements so the result is one continuous illustrated world map extending to all four edges. Keep generous low-detail areas at the three destination positions for runtime markers and character overlays. Maintain fresh cel-animation color grouping, soft daylight, readable terrain masses, shallow painted texture and no visible arena boundary. Environment only; no paper-cut theatre, no SaaS cards, no glassmorphism, no purple technology gradient, no baked UI, no fake text, no photorealism, no 3D plastic rendering.
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
