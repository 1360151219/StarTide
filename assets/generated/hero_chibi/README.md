# Q版英雄完整帧

运行时只加载 `star_warden/` 与 `ember_ranger/` 下的六张透明完整角色帧。每帧为
512×512，脚底统一落在 y=488；角色节点原点因此可以稳定放在脚底。

动作映射：

- `idle`：菜单与战斗待机。
- `run_contact`、`run_pass`：两帧循环跑步。
- `cast`：施法或射击关键姿势。
- `hit`：受击关键姿势。
- `victory`：菜单互动与胜利关键姿势。

`source/` 保存生成图集和去背中间产物，并通过 `.gdignore` 排除在 Godot 导入与移动端
导出之外。需要重新切帧时执行：

```bash
/Users/bytedance/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  tools/extract_chibi_hero_frames.py
```
