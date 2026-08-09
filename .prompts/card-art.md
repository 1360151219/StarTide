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
- 日轮守卫：离散节点和明显缺口；禁止完整常亮圆环。
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
