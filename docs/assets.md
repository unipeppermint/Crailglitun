# 转场素材清单

2026-09-30 使用内置 imagegen 生成六张独立摄影风格主题图，已逐张检查并接入 Asset Catalog。不是原型截图，也不包含真实用户作品。

| 资源名 | 内容 | 用途 |
| --- | --- | --- |
| theme-old | 亚麻布上的旧陶杯 | 旧物档案封面与任务示例 |
| theme-window | 窗边玻璃花瓶与枝叶 | 窗边观察封面与任务示例 |
| theme-color | 橙色墙面与青绿门 | 颜色散步封面与任务示例 |
| theme-shadow | 墙上的枝叶投影 | 影子地图封面与任务示例 |
| theme-geometry | 弧形楼梯与圆形天窗 | 几何日常封面与任务示例 |
| theme-detail | 叶脉与水滴 | 局部世界封面与任务示例 |

位置：`Crailglitun/Assets.xcassets/theme-*.imageset/cover.jpg`。已压缩至 1400 px 长边，六张图与应用图标合计约 2.2 MB。生成原始图仍保留于生成工具目录；应用不依赖项目目录外的文件。

共同生成要求：自然摄影、真实材质、克制的米白/青绿/陶土色、无文字、无 UI、无水印；各图分别指定主体与场景。应用在主题馆与任务详情明确标注 AI 生成示例。

应用图标为代码绘制的三列窗口与斜向箭头，可使用 `scripts/create_icon.swift` 重建。界面图标均为 SF Symbols。转动音效为数学合成的短音，生成脚本可从 `scripts/create_audio.py` 同级资源流程中维护，应用使用 AVAudioPlayer 的 ambient 类别尊重设备静音。


## 2026-09-30 原型对齐补充
- `reel-cup`、`reel-window`：imagegen 生成的透明底实物素材，分别用于杯子、木窗滚轮；胶片图由 UIKit 使用现有主题照片组合绘制。
- `TurnSceneSerif.ttf`：Google Fonts Noto Serif SC 的 650 字重静态字符子集，约 219 KB，仅保留当前应用文案字符。来源 https://github.com/google/fonts/tree/main/ofl/notoserifsc ，SIL Open Font License 1.1，许可证保存在 `Crailglitun/Resources/Font-License.txt`。不依赖网络下载字体。


## 滚轮旧物与重复映射修正
- `reel-old-radio`：内置 imagegen 生成旧收音机透明素材，仅用于“旧物”；`reel-cup` 仅用于“杯子”。生成提示词见 `design/reel-old-radio-generation.md`。
- “窗边”使用窗边场景相片、“门窗”使用独立木窗、“同一位置”使用取景框与位置标记。
- “颜色”使用多色色卡、“单一颜色”使用单色水滴。
- 24 个选项均有独立绘制分支，没有继续合并素材映射。

## 2026-10-13 任务文案与字体更新

60 个任务文案更新后重新生成 `TurnSceneSerif.ttf`，当前为 277732 字节，包含新任务标题和应用文案所需字符。重建脚本为 `scripts/crailglitun_subset_font.py`，输入官方 Noto Serif SC 可变字体文件，输出 650 字重静态子集；fontTools 仅为本地素材构建工具，不进入应用运行时。字体来源与 SIL Open Font License 1.1 不变。
