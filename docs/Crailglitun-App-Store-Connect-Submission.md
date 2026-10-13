# TurnScene App Store Connect 提交资料

适用于当前 TurnScene 1.0 首次提交：英文界面、iPhone、iOS 15.0 及以上，6 个主题、60 个摄影任务，无账号、广告、内购或订阅。以下英文文案可直接复制；标有“待填写”或“待确认”的内容须按开发者账号及实际运营情况补齐。此文档不代表已在 App Store Connect 填写或上传构建。

## 新建应用与基本信息

| App Store Connect 字段 | 内容 | 说明 |
| --- | --- | --- |
| Platforms | iOS | 当前仅 iPhone；Targeted Device Family 为 1 |
| Name | TurnScene | 9 字符；最终名称可用性以后台为准 |
| Primary Language | English (U.S.) | 对应当前英文界面和以下商店文案 |
| Bundle ID | com.tumo.Crailglitun | 必须选择与工程一致的已注册标识 |
| SKU | Crailglitun-TurnScene-iOS | 新建记录时可用的建议值；若已有记录，保留原 SKU |
| User Access | 按团队需要选择 Full Access 或 Limited Access | 只控制团队成员访问权限 |
| Apple ID | Apple 自动生成 | 不自行编造 |
| Subtitle | Everyday Photo Prompts | 22 字符 |
| Primary Category | Photo & Video | 按摄影引导、照片创作与导出的主要用途选择 |
| Secondary Category | Lifestyle | 可选，也可留空 |
| Version | 1.0 | 当前工程版本号 |
| Build | 1 | 当前工程构建号；最终选择后台已处理完成的实际上传构建 |
| Minimum iOS | 15.0 | 由二进制决定，非商店介绍文案 |
| License Agreement | Apple Standard EULA | 暂无自定义 EULA |
| Made for Kids | No | 普通摄影工具，不申报儿童专区 |
| Copyright | 2026 [版权持有人法定姓名或公司名称] | 待填写真实权利人；不要把方括号原样提交，也不要仅凭应用名认定权利人 |

名称和副标题各最多 30 字符；SKU 是内部标识，创建后不能修改。规则依据：[Apple App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)。

## 商店页面英文文案

### Promotional Text

150 字符，限制为 170 字符。

```text
Find a fresh photo idea in minutes. Explore 60 guided tasks, turn everyday details into photo stories, and build a personal collection on your device.
```

### Description

以下为纯文本，直接复制到描述字段。

```text
See the familiar in a new way with TurnScene.

TurnScene helps you find something worth photographing in everyday life. Choose an indoor or outdoor setting, pick a 5, 10, or 20-minute time window, and discover a guided photo task built around a subject, a format, and a creative constraint.

FIND YOUR NEXT PHOTO IDEA
Spin the three reels for a compatible task, lock choices you want to keep, or select conditions manually. Explore 60 tasks across six themes, from everyday keepsakes and window light to color, shadows, geometry, and small details.

FOLLOW A SIMPLE CREATIVE PROMPT
Each task includes practical steps and hints. Create a photo with a caption, a two-photo pairing, or a three-frame story using the in-app camera or photos you choose from your library.

MAKE IT YOUR OWN
Crop your photos, change their order, add a short caption, and choose a layout. Save drafts while you work and return to finish them later.

BUILD YOUR PERSONAL PORTFOLIO
Keep completed creations together on your device. Revisit the same task to make another version and compare how you see the subject over time.

EXPORT AND SHARE
Export individual creations or a selection of works as JPG images, then choose where to save or share them using the iOS share sheet.

CREATE WITHOUT AN ACCOUNT
No sign-up is required. Photos, captions, drafts, and creations are processed and stored on your device. TurnScene does not automatically upload your creative content to the developer. You control what you share, and feedback is sent only when you choose to send an email.

Adjust haptics, sound, and motion in Settings. Core photography tasks and local editing work offline; the online privacy policy and sending feedback require connectivity.

Export important work before deleting the app. Exported images are not editable draft backups.

Support: cressidal@trademarkroofing.homes
Privacy Policy: https://tkzcpoj.netlify.app/turnscene/privacy-policy/
```

### Keywords

以下正好 100 个 ASCII 字节；不要添加空格、换行或尾随逗号。

```text
photography,inspiration,creative,journal,challenge,camera,composition,collage,storytelling,portfolio
```

### URLs 与版本其他字段

| 字段 | 填写内容 |
| --- | --- |
| Privacy Policy URL | https://tkzcpoj.netlify.app/turnscene/privacy-policy/ |
| Support URL | 优先使用独立支持页的真实公开地址；目前已有页面的联系段落可作为现有联系方式入口：https://tkzcpoj.netlify.app/turnscene/privacy-policy/#contact |
| Marketing URL | 可留空，尚未提供正式产品官网 |
| Privacy Choices URL | 可留空；隐私政策内已有本地删除与隐私联系说明 |
| What’s New in This Version | 首次提交 1.0 无此字段，不必填写 |
| Routing App Coverage File | 不适用，不上传 |
| App Clip、iMessage、Apple Watch 专属资料 | 当前不适用 |
| App Preview 视频 | 可选，首发可不提供 |

Support URL 必须通向可用的联系方式，不能把 `mailto:` 当成支持网站，也不要填写尚未部署的 `/support/` 地址。当前隐私政策联系段落能展示邮箱，但作为长期支持页面，建议增加常见问题、反馈方式和数据恢复说明后使用独立 URL。

描述上限为 4,000 字符；关键词上限为 100 字节。首次版本无 What’s New 字段。规则依据：[Apple Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)。

## App Review Information

### 审核联系人与登录信息

| 字段 | 填写内容 |
| --- | --- |
| First Name | [待填写：审核联系人的真实名字] |
| Last Name | [待填写：审核联系人的真实姓氏] |
| Phone Number | [待填写：国际格式联系电话，例如 +86 后接实际号码] |
| Email | cressidal@trademarkroofing.homes，仅在此邮箱有人接收审核邮件时使用；否则改为实际审核联系人邮箱 |
| Sign-in required | 不勾选 |
| Username / Password | 留空；应用无账号系统 |
| Attachment | 通常可留空；若附演示视频，使用最终构建录制的真实流程 |

联系人资料是给审核团队使用的，不能用虚构姓名或电话号码代替。[Apple 审核信息字段](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)。

### Notes

```text
TurnScene is a photography prompt and local photo creation app for iPhone. No account, login, subscription, or in-app purchase is required.

Suggested review flow:
1. On the TurnScene home screen, choose Indoors or Outdoors and a 5, 10, or 20-minute time window.
2. Tap Spin, or select reel choices manually, then open the task preview. Reels select compatible photography prompts; there are no wagers, prizes, virtual currency, gambling, or casino gameplay.
3. Tap Start Creating. Add a photo for each step using Take Photo or Choose from Library. Camera access is optional; library import remains available if camera access is denied. Camera capture requires a physical device with a camera.
4. Crop or reorder photos, add a caption, and tap Save Work. Confirm the save, then view the creation in Portfolio.
5. Open a saved creation to use Export Work or Try This Task Again. Settings also provides batch export and storage management.

The app includes 6 themes and 60 bundled photography tasks. The bundled theme cover images are illustrative assets, not user creations. The app does not offer an image-generation service or automatically evaluate user photos.

Photos, captions, drafts, and finished creations are stored locally. Core tasks and editing work offline. The online privacy policy and email feedback require connectivity. There is no public feed, user-to-user messaging, advertising SDK, analytics SDK, or developer-operated photo upload service.

Privacy policy: Home > Settings > Privacy > View Full Privacy Policy. The full policy opens in an in-app WKWebView.

Feedback: Home > Settings > Feedback. Enter an email address and description, then tap Submit Feedback. This prepares an email for the user to review and send using the system mail composer or an available email app. It is not a server submission form. If no email app can open, the user can copy the feedback and support address. Canceling the mail composer preserves the form while the feedback screen remains open. Photos and app data are not automatically attached.

Local data can be managed in Settings > Storage and on creation detail pages. Exported JPG images do not restore editable drafts.

Support: cressidal@trademarkroofing.homes
Privacy policy: https://tkzcpoj.netlify.app/turnscene/privacy-policy/
```

## App Privacy 填写方案

当前反馈表单会把用户邮箱和描述放入邮件，并由用户主动发送。开发者收到后即可保留这些信息。因此建议申报以下两项，不直接把当前版本填成 Data Not Collected。

| 问题或数据项 | 建议答案 |
| --- | --- |
| Do you or your third-party partners collect data from this app? | Yes，按反馈邮件披露方案填写 |
| Contact Info → Email Address | 勾选 |
| User Content → Customer Support | 勾选 |
| 上述两项的用途 | App Functionality，用于回应反馈与提供支持 |
| 上述两项是否 linked to the user | Yes，反馈内容与邮箱关联；无应用账号不等于匿名 |
| 上述两项是否用于 Tracking | No |
| Third-Party Advertising / Developer’s Advertising or Marketing | 不勾选 |
| Analytics / Product Personalization / Other Purposes | 在仅用于处理支持请求的运营方式下不勾选 |
| Photos or Videos | 仅在设备上拍摄、导入、处理与保存的作品，不因本地访问而勾选收集 |
| Precise / Coarse Location | 不勾选；室内外是用户手动选项，无定位权限 |
| Device ID、User ID、Purchases、Usage Data、Diagnostics | 当前应用未实现对应收集，不勾选 |

这是基于当前应用与“反馈仅用于客户支持”的填写方案。如果将支持邮件用于产品使用分析、营销或其他用途，必须补充实际用途。如果由托管网页或新增服务长期收集其他数据，也需补充相应类型。

Apple 对偶发、非主要功能且完全自愿的反馈设有“可选披露”条件，但必须同时满足其全部条件，包括清晰显示身份和每次主动提交。不能仅以“用户自愿发送”推定豁免。这里采用明确披露邮箱和客户支持的方案。[Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)。

提交前核对两处：Netlify 托管页面是否启用了分析或额外数据收集；构建的隐私报告与商店标签是否准确反映同一数据流。当前 `PrivacyInfo.xcprivacy` 的 collected data 列表为空，不能据此自动得出“所有渠道均不收集数据”。保留已声明的 UserDefaults required-reason API；隐私清单与商店标签应分别按 Apple 定义核对，不能互相替代。

## 年龄分级问卷

以下基于当前内置摄影任务、静态示例图和功能。最终分级由 Apple 计算；预计为 4+，不把预计结果当作已取得的评级。

| 问卷项目 | 当前建议 |
| --- | --- |
| Parental Controls | No |
| Age Assurance | No |
| Unrestricted Web Access | No，前提是在线页面继续仅提供隐私说明及联系信息，不变成自由浏览入口 |
| User-Generated Content | No，无面向其他用户广泛发布内容的社区；本地创作和系统分享不构成应用内公开内容平台 |
| Social Media | No |
| Social Media Disabled for Users Under 13 | 不适用；没有社交媒体功能，不宣称已实现年龄验证 |
| Messaging and Chat | No，无用户间聊天；向开发者发支持邮件不是聊天社区 |
| Advertising | No |
| Profanity or Crude Humor | None |
| Horror/Fear Themes | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Medical or Treatment Information | None |
| Health or Wellness Topics | No / None，按界面提供的选项选择 |
| Mature or Suggestive Themes | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Guns or Other Weapons | None |
| Simulated Gambling | None |
| Gambling | No |
| Contests | None / No，按界面提供的选项选择 |
| Loot Boxes | No |
| 更高年龄限制或覆盖分级 | 当前无额外最低年龄政策，不主动提高分级 |
| Made for Kids | No |

三列滚轮是任务选择器，没有下注、筹码、输赢或奖品，不能只因为有 Spin 按钮就申报模拟赌博。WKWebView 的存在也不自动等于无限制浏览；当前控制器允许 HTTP/HTTPS 链接导航，因此托管内容若增加外部浏览入口，需要重新评估。规则依据：[Apple 年龄分级定义](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)。

## 加密与出口合规

当前应用通过系统 WKWebView 加载 HTTPS 页面，没有自定义加密算法或第三方加密库。

| 问题类型 | 对应回答 |
| --- | --- |
| 是否使用加密，包括系统提供的加密 | Yes，HTTPS 使用系统加密 |
| 是否自行实现专有或非标准加密 | No |
| 是否实现或包含系统之外的标准加密算法 | No |
| 若选项询问以上两类算法，并提供 None of the algorithms mentioned above | 选择该项，含义是未实现列举的算法，不是声称 HTTPS 没有加密 |
| 是否使用非豁免加密 | 按当前实现为 No |
| 是否需要上传加密证明材料 | 仅使用系统加密通常可豁免，按该构建问卷的最终结果处理 |

若未来添加第三方加密库、VPN 或自定义协议，须重新判断。当前 Info.plist 未设置 `ITSAppUsesNonExemptEncryption`；可以在后台完成问卷，确认豁免后另行决定是否将该键设为 NO。本次仅准备资料，没有修改发布配置。[Apple 加密说明](https://developer.apple.com/documentation/Security/complying-with-encryption-export-regulations)、[出口合规填写流程](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation/)。

## 截图与商店素材

当前是 iPhone App。准备最终应用的英文真实截图，不使用参考图中的游戏反馈界面，也不把设计稿当作已实现功能。

| 顺序 | 建议画面 | 可用英文标题 |
| --- | --- | --- |
| 1 | 首页三列任务选择器及任务预览 | Find Your Next Photo Idea |
| 2 | 六个主题的 Themes 页面 | Explore Six Creative Themes |
| 3 | 任务详情的分步提示 | Turn Small Moments Into Stories |
| 4 | 已导入照片的裁剪与编辑页面 | Make Every Frame Your Own |
| 5 | 有真实演示作品的 Portfolio | Build Your Personal Collection |
| 6 | 同题作品对照或导出预览 | Revisit, Compare, and Share |

建议准备 6 张。Apple 每个设备尺寸允许 1–10 张，使用 PNG 或 JPEG，无透明通道。当前文档要求至少提供 iPhone Dynamic Island 中等显示尺寸截图，可用 1206 × 2622 竖图；如后台另显示大尺寸栏位，再提供对应真实布局的 1320 × 2868 竖图。以提交界面的必填栏为准，不拉伸图片。当前未开启 iPad 原生支持，无需添加 iPad 专属产品截图。[Apple 截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)。

应用已有 1024 × 1024 图标：`Crailglitun/Assets.xcassets/AppIcon.appiconset/icon.png`，随构建提交。上传前验证最终图标无透明区域、构建中显示正确。本次没有生成商店截图或审核演示视频。

## 价格与发行

| 字段 | 建议或待确认内容 |
| --- | --- |
| Price | 建议首发 Free；这是商业选择，需你确认，无内购不代表必须免费 |
| Countries or Regions | 待确认实际销售地区，不默认勾选全球 |
| Distribution Method | 建议 Public，即普通公开 App Store 发行 |
| Version Release | 建议 Manually release this version，审核通过后由你决定正式发布时间 |
| Pre-Order | 首发建议不启用 |
| Phased Release | 首次发布不需要按更新灰度发布配置 |
| In-App Purchases / Subscriptions | 当前无，不创建商品 |
| Game Center | 不启用 |
| Advertising Identifier / IDFA（若显示） | No，当前应用未读取 IDFA，不用于广告追踪 |
| Apple Silicon Mac / Apple Vision Pro availability | 需单独检查后台可用性选择；iPhone target 不等于这些渠道自动关闭。未经兼容性验证不主动扩大分发范围 |
| Tax Category | 保留适用的软件类默认类别；如改为付费，以账号实际税务情况确认 |
| Digital Goods and Services 问卷 | 如后台未出现，无需填写。已知事实是应用包含免费摄影内容与工具，无内购、订阅、外部购买或登录后解锁。若问题问“是否销售”，按当前免费方案回答 No；若问“是否消费或访问数字商品与服务”，需按该问题定义选择，不能仅凭免费就回答 No，也不能虚构 IAP 支付方式 |

数字商品与服务问题取决于发行和收费方式：[Apple Digital Goods and Services questionnaire](https://developer.apple.com/help/app-store-connect/manage-app-information/complete-the-digital-goods-and-services-questionnaire/)。

## 主体与地区合规信息

| 项目 | 当前处理 |
| --- | --- |
| Content Rights | 确认全部素材、字体及文字的使用权后填写。若后台询问包含第三方内容，按实际授权内容回答 Yes 并确认有权使用，不机械地选 No |
| 素材授权依据 | 项目记录主题图为生成素材，图标为代码绘制，字体为 Noto Serif SC 子集，附 SIL OFL 1.1 许可证；详见 `docs/assets.md` 和字体许可文件 |
| Seller / Developer Name | 来自开发者账号与合法主体；应用名称不能替代法定主体 |
| EU DSA trader status | 待主体确认是否属于 trader；不能因为个人账号或免费应用就自动填 non-trader |
| Trader 联系信息 | 需要时填写并验证真实地址、电话、邮箱；这组资料可能向欧盟用户公开，与私有审核联系人用途不同 |
| 中国大陆发行 | 如适用，提供与主体和应用信息一致的 ICP 备案及后台要求的材料；没有材料时先明确销售地区，不编造备案号 |
| 受监管医疗器械声明 | 当前摄影工具无诊疗功能，不属于医疗器械；如后台显示该问卷按实际填写 No |
| Agreements / Tax / Banking | 由账号持有人完成适用协议、税务及银行信息，不能从代码推定已完成 |

依据：[Apple DSA 交易商要求](https://developer.apple.com/cn/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)、[Apple 应用信息及地区要求](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)。

## Accessibility 可选声明

暂不仅凭代码中的辅助功能标签就宣称所有功能通过 VoiceOver、Voice Control、Larger Text 或 Sufficient Contrast 标准。应用虽包含减少动态效果选项，但应覆盖任务选择、拍摄导入、裁剪、保存、导出及反馈等常用流程后再填写支持的标签。当前主体界面采用固定浅色调，隐私网页支持深色模式不等于整款应用支持 Dark Interface。

Accessibility URL 没有专属页面时留空。规则依据：[Apple Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)。

## 提交前需要补齐的内容

1. 审核联系人的真实姓名、国际格式电话，以及确认可收信的审核邮箱。
2. 版权持有人真实姓名或公司名称；如有第三方素材，确认许可覆盖发行用途。
3. 确认应用价格、销售地区和发行方式，以及适用的 DSA、备案和账号合规资料。
4. 选择并验证正式 Support URL；现有隐私页面的联系段落可访问，但建议准备专门支持内容。
5. 上传实际 App Store 构建并等待处理完成。工程当前为 1.0 (1)；若该构建号已经使用，按既有发布流程递增后上传，不能选旧版本替代最新反馈页面。
6. 上传最终应用截图，完成隐私、年龄与加密问卷；将任何界面提示的缺失字段补齐。
7. 真机验证拍照、拒绝相机后的导入、照片编辑与导出、隐私网页、邮件草稿与取消行为，确认支持邮箱确实可接收邮件。现有模拟器编译和局部界面检查不等于这些真机验证已完成。
8. 核对所有占位信息都已替换，点击 Add for Review 后再提交审核。本文仅准备填写材料，未代为执行提交或发布。
