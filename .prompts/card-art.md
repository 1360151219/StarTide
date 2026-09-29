# 方案 D 卡牌主体美术提示词

用途：生成技能、装备、遗物和主奖励的独立主体草图。结果只包含主体，不包含卡框、文案、数值、等级、费用、品质、按钮或场景。

视觉规则以 [ART_DIRECTION.md](../docs/ART_DIRECTION.md) 为准。一次只生成一个主体；现有角色、怪物、技能与装备优先保留，不因切换方向而重绘。

## 必填变量

| 变量 | 说明 | 示例 |
|---|---|---|
| `{{SUBJECT}}` | 唯一主体 | 星芒枪、风弦弓 |
| `{{CATEGORY}}` | 技能/武器/护甲/饰品/遗物/奖励 | 技能 |
| `{{FUNCTION}}` | 一眼应理解的功能 | 直线贯穿攻击 |
| `{{SILHOUETTE}}` | 64 px 下成立的轮廓 | 细长四棱枪头＋贯穿轴 |
| `{{MATERIAL}}` | 1～2 种主材质 | 搪瓷核心＋织带连接 |
| `{{PALETTE_ROLE}}` | ART_DIRECTION 已有颜色角色 | Morning Lake Cyan＋Deep Lake Ink |
| `{{CHROMA_KEY}}` | 主体内不使用的纯色键控背景 | `#ff00ff` |

品质只由运行时框架表达；同一主体不生成仅换色的普通、稀有和顶级版本。

## 生产提示词

```text
Use case: stylized-concept
Asset type: isolated 2D anime game card-art subject for a portrait mobile Vampire Survivors-like
Primary request: create one original {{CATEGORY}} subject, “{{SUBJECT}}”, whose gameplay function reads immediately as {{FUNCTION}}.
Subject: exactly one centered object or effect emblem; the defining 64 px silhouette is {{SILHOUETTE}}.
Style/medium: art direction D “Sunlit Expedition Animation”; clean two-to-three-tone cel shading, deep lake-ink outline, fresh natural-adventure mood, light canvas/enamel/birch construction only where structurally meaningful; polished hand-finished 2D, not 3D.
Composition/framing: square canvas; subject occupies 68%–74%; at least 15% clean padding on every side; no crop; clear center of mass; no perspective scene.
Lighting/mood: bright soft daylight; one controlled highlight; readable at icon size.
Color palette: {{PALETTE_ROLE}}; color supports but does not replace silhouette.
Materials/textures: {{MATERIAL}}; broad readable zones, restrained texture, no micro-detail.
Scene/backdrop: perfectly flat solid {{CHROMA_KEY}} chroma-key background for local extraction.
Constraints: one asset only; uniform background with no shadow, gradient, texture, reflection, floor plane, or lighting variation; do not use {{CHROMA_KEY}} inside the subject; crisp edge; preserve current game’s cute 2D anime rendering family; no frame, card, UI, text, letters, Chinese characters, numbers, Roman numerals, cost, rarity label, logo, or watermark.
Avoid: paper-cut theatre, puppet joints, SaaS cards, glassmorphism, glossy 3D plastic, photorealism, thick metal filigree, generic fantasy jewel, purple technology gradient, all-over bloom, emoji, multiple objects, decorative scene background, color-only function cues.
```

## 技能轮廓

- 星芒枪：细长四棱枪头和贯穿轴；禁止圆形法阵与粗激光。
- 寒冰斩：三道不等距弧形冰刃，终极为破口 S 形双刃；禁止完整圆环与 360°潮环。
- 霜潮脉冲：单向大块冰晶齿波前；禁止对称圆爆炸。
- 烬羽连矢：羽片沿运动方向收尖；分支用单束与扇形区分。
- 陨星雨：纵向坠落线与落点缺口；禁止普通火球。
- 凤凰之心：双翼围出心形负空间；禁止单独爱心或医疗十字。

## 交付检查

- 64×64 和灰度下类别与功能仍可辨认。
- 没有文字、数字、边框、品质、Logo 或水印。
- 键控背景四边同色，主体内部没有键色，边缘未裁切。
- 与现有同类素材的描边、光源和赛璐璐层级一致。
- 去背、边缘收缩和人工收笔完成后才可进入运行时目录。

## 运行时技能材质的通用约束

技能材质任务先读 `ART_DIRECTION.md` 的 `Combat Material VFX Standard`。卡牌模板的粗描边、图标化色块与色键背景不适用于运行时主体。运行时使用真正透明通道，受光面、厚度、属性纹理必须在实际尺寸下成立；不烘焙轨迹、范围、文字、地面或完整动画。内部运动与消散交给战斗年龄驱动的材质，不把一张图缩放旋转当作完成。批准素材写入正式路径并登记清单，保留提示词，生成源不进入运行时目录。

## 星芒枪运行时晶核（2026-09-22）

使用内置 imagegen，保留真实透明通道；正式路径 `assets/art/skills/star_lance_core.png`，导入限制 512 px 并生成 mipmap。只生成晶核，能量尾流与碎晶由运行时控制；内部晶面同时供冰刃与霜潮取样，避免另建重复冰材质。最终生产提示词：

```text
Use case: stylized-concept. Asset type: one production transparent projectile sprite for a bright hand-painted top-down 2D fantasy action game. Create a single long FOUR-FACET CYAN STAR-CRYSTAL LANCE HEAD, pointing horizontally RIGHT, on a truly transparent alpha background. 1024x1024 square canvas; object centered, from x 12% to 88%, y 38% to 62%, tip at right. Asymmetric elongated diamond silhouette, short forked rear base on the left and a sharp narrow long point on the right. Dimensional hand-painted translucent ice-crystal substance: deep petrol-teal shaded underside, turquoise middle planes, soft milky pale cyan top plane, one very small ivory specular edge; visible internal cloudy refraction and subtle fine cracks, broad tactile planes that read at 70 pixels. Polished stylized action RPG VFX material quality, consistent with daylight anime fantasy, no black outlines, not a flat vector icon. This is the SOLID CRYSTAL CORE ONLY; the engine adds animated energy. No shaft or handle, no metal, no rings, no rays, no stars orbiting it, no sparks, no trail, no glow halo, no motion lines, no cast shadow, no floor, no background scene, no text, no border, no watermark, no UI. Preserve generous transparent padding. Actual transparent background, not a checkerboard drawing.
```

## 陨星雨运行时岩核（2026-09-22）

这是独立材质主体，不套用上方卡牌描边或色键背景规则。使用内置 imagegen，保留生成的真实透明通道；正式路径为 `assets/art/skills/meteor_rain_body.png`。尾焰、烟尘、范围与光照由运行时生成，不烘焙在岩核上。最终生产提示词：

```text
Use case: stylized-concept. Asset type: production transparent sprite for a bright hand-painted 2D top-down fantasy action game. Create ONE isolated molten meteor ROCK CORE, 1024x1024 with true transparent alpha background. A chunky irregular elongated basalt stone, long axis vertical, blunt jagged broad upper half and a tapered rounded lower impact tip pointing straight down. The actual rock occupies the central 60% width and 72% height with generous clear padding. Beautiful dimensional hand-painted planes: cool dark aubergine-charcoal basalt faces, burnt-orange recessed cracks, a few thin molten-gold fissures, small pale warm hotspots at the lower rim. Strong readable volume, warm light coming from lower right, broad planes and tactile stone surface, asymmetrical silhouette. Polished stylized action RPG VFX quality. Not an icon: no thick outlines, no polygon wireframe, no graphic strokes. This sprite is the solid core ONLY, the game will add live animated flames separately. NO flames, NO trail, NO sparks, NO smoke, NO glow halo, NO ground, NO cast shadow, NO scene, NO text, NO frame, NO logo, NO watermark. Truly transparent background, not a checkerboard picture. Not photorealistic, not plastic, not glossy gem. Output the single transparent game-ready sprite.
```
