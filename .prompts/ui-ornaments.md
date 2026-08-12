# 方案 D UI 构件提示词

用途：生成织带、浅木框、搪瓷扣、地图签、分隔件等独立构件草图。一次只生成一个组件或一种状态，不生成整页 UI 和文字。能由 Godot 稳定绘制的几何结构优先程序实现。

## 构件清单

| 构件 | 主轮廓 | 材质 | 关键限制 |
|---|---|---|---|
| 主按钮 | 横向织带或双切角木牌 | 日照金搪瓷＋浅木 | 中央留空，支持 9-slice |
| 次级按钮 | 紧凑搪瓷牌 | 暖象牙＋晨湖青 | 不使用 Accent 大面积填充 |
| 危险按钮 | 向内收束切角牌 | 帆布＋Danger 内边 | 不做网页红色胶囊 |
| 常规面板 | 双切角帆布框 | 暖象牙＋单侧织带 | 四角不复制同一花纹 |
| HUD 条 | 连续横向结构 | 深湖墨＋帆布＋搪瓷节点 | 支持共享边界 |
| Tooltip | 窄地图签＋短指向缺口 | 地图纸＋浅木夹 | 指向不侵入正文 |
| 品质方格 | 近直角 `1:1` 正方形 | 灰帆布/鲜绿搪瓷/明亮日照金 | 一/二/三层压线；只在左上变化轮廓；无底部节点或挂件 |
| 分段刻度 | 4、6 或 8 段节点 | 搪瓷＋织带 | on/off 分层，不烘焙动画 |

品质方格一次只生成一个空框状态：普通为 `#C9CDCA` 灰色单压线且无角徽，稀有为 `#42B873` 鲜绿双压线与左上单缺口，顶级为 `#F2B84B` 明亮金色三段阶梯边框与左上冠形/日轮形轮廓。底边禁止节点、圆钉、挂扣、吊坠和尾片。装备主体、文字与右上归属头像均由运行时独立叠加；归属头像复用英雄切换组件的同源裁切。

## 生产提示词

```text
Use case: stylized-concept
Asset type: isolated 2D game UI ornament for 9-slice implementation
Primary request: create one original {{COMPONENT}} in the {{STATE}} state for art direction D “Sunlit Expedition Animation”.
Subject: exactly one front-facing component; outline {{OUTLINE}}; center empty and visually calm for runtime content.
Style/medium: lightweight expedition craft; warm ivory canvas, pale birch, woven tab, restrained enamel badge, and structurally justified matte metal buckle; clean hand-finished 2D.
Composition/framing: orthographic front view; centered; 12%–16% padding; no crop; preserve {{STRETCH_ZONE}} as a low-detail stretch-safe area.
Color palette: {{COLOR_ROLES}}; one Accent cue at most; no unassigned colors.
Materials/textures: {{MATERIALS}}; broad readable zones; subtle canvas/wood grain; no baked cast shadow outside the component.
Scene/backdrop: perfectly flat solid {{CHROMA_KEY}} chroma-key background.
Constraints: one component and one state only; uniform background without shadows, gradients, texture, floor, or reflections; do not use {{CHROMA_KEY}} inside the component; no text, letters, Chinese characters, numbers, icons, emoji, labels, logo, watermark, full UI screen, card content, character, or scenery; ornament clusters remain outside the stretch zone.
Avoid: paper-cut theatre, SaaS card, default web button, glassmorphism, uniform large rounded rectangle, glossy plastic, thick gold filigree, identical decoration on all four corners, purple technology gradient, all-over glow, multiple states in one image.
```

## 状态差异

- `normal`：材质稳定，无持续光晕。
- `selected`：轮廓粗细不变，织带或扣件切换为 Primary。
- `pressed`：结构下沉 2 px，亮面收窄；不只把 normal 变暗。
- `disabled`：饱和度降低约 50%，保留结构和文字承载对比。

最终组件需在最小尺寸、标准尺寸和 1.5× 宽度下验证 9-slice；角区、扣件和纹理焦点不得进入拉伸区。

## 交付检查

- 无文字、伪文字、数字、Emoji、Logo、水印或卡牌主体。
- 品质方格为严格正方形，底边没有节点、挂扣、吊坠或尾片；普通/稀有/顶级在灰度下仍能通过一/二/三层压线和左上轮廓区分。
- 中央内容区低频，装饰未侵入触控与文字安全区。
- 四种状态在灰度下仍有结构差异。
- 键控背景纯净，边缘有足够 padding。
- 上线前完成去背、边缘收缩、9-slice 重建与多尺寸验证。
