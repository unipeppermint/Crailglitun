# 转场素材清单


### 参考图版：暖阳下的日常观察（2026-10-13）

根据用户提供的 `1.png`，采用暖阳、复古收音机、陶杯和三格胶片构图，胶片主题为窗光、叶脉与花影。通过内置 imagegen 生成并进行一次取景留白修正。上一版相机源图另存为 `output/imagegen/crailglitun-icon-vintage-camera.png`；当前源文件 `output/imagegen/crailglitun-icon-source.png`，正式资源 `Crailglitun/Assets.xcassets/AppIcon.appiconset/icon.png`。不修改应用内文案。

生成提示词：

> Use case: logo-brand, richly detailed photographic iOS app icon. Input image 1 is a STYLE AND SUBJECT REFERENCE, not a target to copy unchanged. Create one new finished square app icon for TurnScene, a creative photography app about everyday observation, keepsakes, light and small discoveries. Faithfully retain the reference's warm golden sunlight, tactile realism, nostalgic cozy still-life feeling, cognac-brown vintage radio, speckled ivory ceramic coffee cup, and dark photographic film strip. Redesign the composition specifically for a small app icon: one compact beautifully crafted leather-and-brass vintage radio occupies the upper-left and central back of the composition, with a large easily readable woven speaker grille and two ivory knobs; one ivory ceramic coffee cup sits in front on the lower-right, visible oval dark coffee surface and complete handle safely within the canvas; one short elegantly leaning dark film strip with exactly three clear picture frames crosses the lower-left foreground. The film frames depict three simple everyday observation subjects: window light, a leaf detail, and a soft flower shadow, not tourist scenery. Keep the radio, cup and film in a tight coherent triangular group, clearly separated by warm light and soft shadows. A very small blurred sprig of cream flowers in the upper-right adds delicacy, never dominates. Background: softly blurred sunlit window, honey-colored tabletop and a little linen, warm cream and caramel tones with restrained sage-green bokeh. Cinematic editorial still-life photography, beautifully rendered material detail, natural warm lens light, rich highlights, believable depth. More organized and iconic than the reference, but equally warm and richly detailed. Main object group fills about 85% of the square, with important shapes and cup handle kept clear of corners for iOS masking. No central camera, no abstract logo, no text, no letters, no legible dial numbers, no logos, no watermark, no UI, no icon-sheet or device mockup. 1024x1024 full-bleed opaque square; background reaches all edges; no premade outer rounded corners or outer border. Exactly one final image.

留白修正提示词：

> Refine this finished TurnScene app-icon artwork with ONLY a framing correction. Preserve exactly the warm golden photographic style, brown vintage radio, ivory speckled coffee cup, three-frame dark film strip, window light, leaf and flower-shadow pictures, colors and material detail. Pull the camera back about 14 percent so the three main objects as a group are smaller and centered, with approximately 8 percent breathing space at the left and right edges. Restore and show the entire coffee-cup handle: no part of the radio, cup handle, or film strip may touch or be cut by the square edges. Keep the entire three-frame film strip inside the canvas. Extend the existing softly blurred sunlit window, tabletop and linen naturally to fill the newly visible edges. Keep bright warm sunlight and all key objects large, detailed and coherent, with no added objects. This is intended for an iOS app icon, so keep important objects comfortably clear of the four corners under system rounded masking. No text, no logos, no watermark, no exterior border, no baked-in rounded corners. Full-bleed opaque 1024x1024 square. Exactly one image.


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

## 2026-10-13 新应用图标

新图标采用深青绿底、错位的米白取景框与橙色太阳，替换原三列滚轮图标。通过内置 imagegen 生成，原始素材保存在 `output/imagegen/crailglitun-icon-source.png`；正式图标为 `Crailglitun/Assets.xcassets/AppIcon.appiconset/icon.png`。`scripts/create_icon.swift` 现在负责将此素材转换为 1024 × 1024、sRGB、无透明通道 PNG，可重新运行，未添加运行时依赖。

生成提示词：

> Use case: logo-brand. Create a finished premium iOS app icon asset for TurnScene, a quiet creative photography app about seeing everyday life from a fresh angle. Square 1024x1024 full-bleed opaque canvas. A deep muted teal background (#245955), with an exceptionally crisp, bold geometric central symbol: two slightly offset picture/viewfinder frames suggesting a subtle turn of perspective, a warm ivory foreground frame and a vivid warm orange rear accent. Within the central opening, a single orange sun and one restrained abstract diagonal ivory landscape plane. The final silhouette should be distinctive, simple, balanced and instantly readable at 60px. Minimal sophisticated editorial graphic design, generous spacing, rounded geometric corners on the symbol, precise optical alignment, mostly flat colors with at most a very subtle tonal depth. Symbol fills roughly 66 percent of the square, centered. No text, no letters, no watermark, no UI, no icon grid, no phone mockup, no outside border, no outer rounded-square mask: the teal background extends to all four square edges. Deliver exactly one icon, not a presentation sheet.

验证：Release 真机目标与模拟器构建均通过；图标为 1024 × 1024、无 Alpha；已在 iPhone SE 模拟器应用资源库确认系统圆角与小尺寸显示。日志：`output/validation/icon-release-build.log`、`icon-simulator-build.log`；截图：`output/validation/icon-installed.png`。

### 图标再次调整：旋转取景窗（2026-10-13）

根据用户反馈，当前正式图标改为鲜橙背景、米白与深青绿相扣的旋转取景窗，采用简洁轮廓与轻微浮雕层次。上一版相框风景图标源文件另存为 `output/imagegen/crailglitun-icon-photo-frame.png`；当前源文件及正式图标路径不变。通过内置 imagegen 生成，打包脚本保持 1024 × 1024、sRGB 和无透明通道。

本版生成提示词：

> Create one outstanding, finished iOS app icon for TurnScene, a creative photography prompt app about changing your point of view. This must feel like a memorable custom brand mark, not a generic photos/gallery icon. Art direction: bold minimalist sculptural geometry, beautifully balanced, tactile satin finish with very subtle dimensional depth, crisp clean edges. Full-bleed warm vivid vermilion-orange background, gently lighter near upper left, no noise. Center one large iconic rotating viewfinder symbol, composed of TWO broad interlocking bent ribbons / rounded L-shaped brackets arranged in a quarter-turn flow: the upper-left ribbon is warm ivory and the lower-right ribbon is deep dark petrol teal. The ribbons together define a tilted square opening in the center, with deliberate narrow orange separation between the two ribbons. This should suggest a camera frame turning to discover a new perspective, without literal cameras, circular camera lenses, landscape pictograms, sun disks, mountains, photographs or arrows. Strong unified silhouette, thick substantial shapes, subtly softened corners, striking ivory/teal contrast. Polished restrained 3D relief: shallow extrusion, very soft short contact shadow, light from upper left, no plastic shine. Centered with generous safe margins, symbol about 64% of canvas width. Think premium independent creative-tool identity, visually clear and distinctive at 48 pixels. 1024x1024 square opaque image. Background must reach every edge of the square; do not bake in external rounded corners. No letters, no text, no watermark, no mockup, no border, no grid. Exactly one final icon.

### 图标细节版：复古相机（2026-10-13）

根据“太简单”的反馈，当前图标改为深青绿皮革机身、香槟金金属边框、暖橙握柄的复古相机，镜头带窗光反射，后方露出一张夕阳照片。使用内置 imagegen 生成。上一版源图保存为 `output/imagegen/crailglitun-icon-rotating-frame.png`，当前图标源文件和正式资源路径不变。

本版提示词：

> Create a single gorgeous, richly crafted iOS app icon for TurnScene, an artistic everyday photography app. The previous icon was too simple and abstract; this new design should have tangible detail, personality and beautiful materials while reading clearly at app-icon size. Subject: one bespoke compact vintage camera, viewed from slightly above in a restrained three-quarter perspective, filling about 76% of the square. Camera body in deep petrol-teal pebbled leather, warm brushed champagne-metal top plate and trim, a burnt-orange leather grip accent on the right. Large beautifully modeled optical lens in the center, concentric precision-machined dark metal and champagne rings, deep blue-green glass with a subtle warm amber reflection of a sunlit window. Small mechanical shutter button and a knurled dial, a little rectangular viewfinder. Behind the camera, only a small partially visible cream photo-print corner, with an understated warm sunset tint, to suggest keeping discoveries. Premium stylized 3D illustration, collectible crafted object, sophisticated cinematic studio lighting from upper left, soft realistic shadows, tactile leather and brushed metal, restrained highlights, rich dimensional detail without tiny labels or clutter. Camera floats slightly above a warm ivory-to-pale-apricot backdrop with a gentle warm glow, making the teal body stand out. Balanced centered composition with generous corner safety margins, front lens is the strong focal point. Professional finished application icon, charming and elegant, not a flat glyph or abstract logo. Full-bleed opaque 1024x1024 square canvas; the background fills all four edges; do not bake in an outer rounded-square mask or border. No text, no letters, no digits, no manufacturer logos, no watermarks, no phone mockup, no collage, no extra icons. Exactly one finished app icon.

## 2026-10-13 用户提供的启动图

原图 `launch.png`（1206 × 2622）完整复制到 `Crailglitun/Assets.xcassets/CrailglitunLaunch.imageset/launch.png`，内容未修改。系统 `LaunchScreen.storyboard` 添加铺满根视图的 UIImageView，使用等比填充，短屏仅裁切上下背景，TurnScene 标题完整保留。不新增启动倒计时或延迟。

Release 真机目标及模拟器构建通过；在专用 iPhone SE 和 iPhone 17 Pro 模拟器实际验证启动图。模拟器测试包单独使用 ad-hoc 签名，保证 SplashBoard 能验证启动页资源，未修改项目签名设置。截图：`output/validation/launch-se.png`、`launch-fullscreen.png`；构建日志：`launch-release-build.log`、`launch-simulator-build.log`。
