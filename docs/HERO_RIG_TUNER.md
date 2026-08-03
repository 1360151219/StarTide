# 英雄帧动画预览器

## 用途

`HeroRigTuner` 已从骨骼调参器迁移为桌面帧动画验收工具。它不修改角色资源，只通过 `HeroRig2D` 的稳定运行接口检查：

- 两名英雄。
- 菜单待机、菜单互动、战斗待机、奔跑、施法、受击和胜利七个状态。
- 96 像素实战尺寸、188 像素角色中心尺寸和 360 像素美术检查尺寸。
- 动作播放、暂停和从首帧重播。

运行资源：

```text
res://scenes/tools/hero_rig_tuner.tscn
```

在 Godot 文件系统中双击该场景并按 `F6`，或使用：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/tools/hero_rig_tuner.tscn
```

## 操作

1. 选择英雄。
2. 选择要检查的动作。
3. 依次使用实战、角色中心和美术检查三档尺寸观察角色。
4. 点击“暂停预览”检查当前轮廓。
5. 点击“从首帧重播”重新观察一次性动作。

预览画布中的青色横线表示脚底基线，竖线表示角色中心。切换英雄、动作和显示尺寸后，角色脚底都不应离开横线。

## 验收重点

- 头、肩、手臂和躯干保持连续，不出现悬空关节。
- 武器被手掌自然握持，动作过程中不穿过身体。
- 双腿方向和前后关系稳定，不发生左右腿身份交换。
- 衣摆、鞋和腿部已经合成，不出现错误图层覆盖。
- 每一帧的脚底落点稳定，角色不会上下抖动。
- 轮廓尺寸连续，不出现头部、武器或发型突然缩放。
- 96 像素时身份和动作仍然可辨认，188 像素时没有裁切，360 像素时没有明显边缘瑕疵。

## 架构边界

预览器只依赖：

```text
configure
play_state
set_active
available_states
```

它不读取角色骨骼、身体部件或动画实现节点，也不提供资源保存能力。角色由骨骼动画迁移到完整帧动画时，预览器无需跟随内部实现变化。

Android 导出规则会排除 `tools/*` 和 `scenes/tools/*`，因此本工具不属于移动端发布内容。

## 验证

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/test_hero_rig_tuner.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1180x720 --script res://tools/capture_hero_rig_tuner.gd
```

自动化测试覆盖两名英雄、七个动作、三档尺寸、播放暂停、从首帧重播和稳定接口边界。人体结构、握持姿势与逐帧一致性仍需通过预览器进行人工视觉验收。
