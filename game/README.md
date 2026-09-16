# Godot Demo 灰盒说明

## 打开

1. 安装 Godot 4.3+（推荐 4.7.x，与 `HANDOFF.md` 一致）
2. Godot → Import / Scan → 选择文件夹：`Tgame/game`
3. 运行主场景（F5）：`scenes/act1/ward_1a.tscn`

## 1A 怎么玩

| 步骤 | 操作 |
|------|------|
| 开场 | Space/E 推进说明 |
| 起身 | 站在床边米色块上，E · 起身（未起身不能出门） |
| 可选 | E · 调查家人照片 |
| 自动 | 起身后约 2.5s：红影闪 + 粤曲占位对白 |
| 出口 | 走到左侧门，E · 离开病房 → 1A COMPLETE |

操作：`A/D` 移动 · `E` 调查 · `Space` 继续对白

## 目录

```
game/
  project.godot
  scenes/act1/ward_1a.tscn   # 主场景
  scenes/player.tscn
  scenes/ui/dialogue_box.tscn
  scripts/...
```

## 占位色块

- 灰紫：床 / 地面
- 米色标签 get_up / photo / door：可交互
- 浅色竖条：玩家

下一幕接 1B 走廊时，在出门完成处 `change_scene` 即可。
