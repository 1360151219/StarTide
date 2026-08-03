# 装备图标

六枚装备图标由 Codex 内置 `image_gen` 生成，完整去背图集保存在 `source/equipment_icons_atlas.png`。

生成要求：原创儿童向奇幻移动游戏风格，明亮手绘 Q 版赛璐璐、圆润深青轮廓、柔和金属与宝石高光；六件装备按 3×2 网格独立排布在 `#ff00ff` 色键背景上，不包含文字、人物、边框、Logo 或水印。色键使用 `imagegen/scripts/remove_chroma_key.py` 清除后，再裁切为目录同名 PNG。
