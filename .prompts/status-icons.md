# 方案 D 状态图标提示词

用途：生成正式 Buff、Debuff、Healing、Block 和限时状态图标草图。一次只生成一个图标，不生成图标集、文字或完整 HUD。

## 语义语法

| 类别 | 外轮廓 | 动势 | 颜色角色 |
|---|---|---|---|
| Buff | 向外展开的圆角徽章、翼或叶片 | 外展上升 | Primary / Supporting |
| Debuff | 向内收束的切角徽章、钩或裂口 | 内收下压 | Danger |
| Healing | 环抱、回流、向上开放 | 回收后上升 | Healing |
| Block | 闭合盾形或叠层搪瓷牌 | 抵住冲击 | Block |
| Neutral Timer | 简洁织带或分段底形 | 逐段减少 | Secondary Text |

- 图标由 2～4 个大形构成，内部负形最多 2 处。
- 目标尺寸 24×24 px，重要状态 32×32 px；以 20 px 灰度作为最低检查。
- 倒计时刻度是独立 UI，不烘焙进图标。

## 生产提示词

```text
Use case: stylized-concept
Asset type: isolated mobile game status icon
Primary request: create one original {{STATUS_TYPE}} pictogram for “{{STATUS_NAME}}”, communicating {{MEANING}} without words.
Subject: one bold pictogram; outer silhouette {{OUTER_SHAPE}}; internal negative space {{CUTOUT}}; 2–4 large shapes only.
Style/medium: art direction D “Sunlit Expedition Animation”; flat two-to-three-tone cel-shaded enamel pictogram, deep lake-ink outline, clean negative space, fresh adventure mood, child-friendly but not childish.
Composition/framing: square; centered; icon fills 70%–76%; at least 12% padding; front-facing; no perspective.
Color palette: {{COLOR_ROLE}} plus #243C43 outline and small #FFF6E2 inner separation; color is secondary to shape.
Scene/backdrop: perfectly flat solid {{CHROMA_KEY}} chroma-key background.
Constraints: one icon only; uniform background without shadow, gradient, texture, floor, reflection, or lighting variation; do not use {{CHROMA_KEY}} inside the icon; readable at 20 px in grayscale; no text, letters, numbers, Chinese characters, font-glyph arrows, emoji, Unicode symbols, labels, external frame, UI card, logo, or watermark.
Avoid: paper-cut theatre, detailed illustration, thin lines, circular loading spinner, generic app icon, glossy 3D, glassmorphism, all-over glow, color-only meaning, multiple icons, icon sheet.
```

## 首批状态

| 状态 | 类型 | 轮廓建议 | 负形建议 |
|---|---|---|---|
| 星辉护盾 | Block | 两层闭合盾徽 | 中心四芒晶切口 |
| 烬羽动量 | Buff | 两枚向外上扬羽片 | 中央上升通道 |
| 星引磁场 | Buff | 双弧夹形、底部向上开放 | 中心菱形 |
| 加速 | Buff | 两道外展风翼 | 中央窄风道 |
| 治疗 | Healing | 双叶环抱 | 心形回流通道 |
| 受伤 | Debuff | 向内裂开的珊瑚红徽章 | 纵向断口 |

不得为了填满图标套装而新增玩法状态。

## 交付检查

- 20 px 灰度下能与同组图标区分。
- 类别不依赖色相也能被底形识别。
- 无 Emoji、字体符号、文字、数字、卡框或水印。
- 背景纯净，边缘无键色，线宽不低于目标尺寸的 2 px。
