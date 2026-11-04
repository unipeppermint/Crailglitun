# TurnScene 1.1 App Store Connect 提交资料

核对日期：2026-11-04。当前工程 Debug / Release 均为 **1.1 (1)**，英文界面、iPhone、iOS 15.0 及以上。原生部分包含 6 个主题、60 个摄影任务；应用还包含由服务端归因结果决定的远程网页体验、AppsFlyer、Firebase Core/Auth/Messaging、Google Sign-In、ATT、通知及定位权限流程。

本文根据本地实现更正提交资料，不代表已修改 App Store Connect、线上隐私政策或上传构建。**远程网页的实际业务、登录要求、支付/广告内容及服务端数据用途尚待确认，因此含 `[REQUIRED: ...]` 的英文草稿不能直接提交。** 原生摄影功能的本地存储、无登录要求等说明，不代表整款应用不联网、不收集数据或不存在账号功能。

## 应用与版本基本信息

| App Store Connect 字段 | 内容 | 说明 |
| --- | --- | --- |
| Platforms | iOS | 当前仅 iPhone；Targeted Device Family 为 1 |
| Name | TurnScene | 9 字符；最终名称可用性以后台为准 |
| Primary Language | English (U.S.) | 对应当前英文界面和以下商店文案 |
| Bundle ID | com.tumo.Crailglitun | 必须选择与工程一致的已注册标识 |
| SKU | Crailglitun-TurnScene-iOS | 新建记录时可用的建议值；若已有记录，保留原 SKU |
| User Access | 按团队需要选择 Full Access 或 Limited Access | 只控制团队成员访问权限 |
| Apple ID | Apple 自动生成 | 不自行编造 |
| Subtitle | Everyday Photo Prompts | 22 字符，原生摄影候选；需与完整产品定位一致 |
| Primary Category | Photo & Video（原生摄影部分适用） | 须结合远程网页实际核心体验确认整款应用分类 |
| Secondary Category | Lifestyle（待确认） | 可选，也可留空；以完整产品定位为准 |
| Version | 1.1 | 当前工程版本号，按 1.1 准备本次版本资料 |
| Build | 1 | 当前工程构建号；最终选择版本为 1.1 且已处理完成的实际上传构建 |
| Minimum iOS | 15.0 | 由二进制决定，非商店介绍文案 |
| License Agreement | Apple Standard EULA | 暂无自定义 EULA |
| Made for Kids | No | 普通摄影工具，不申报儿童专区 |
| Copyright | 2026 [版权持有人法定姓名或公司名称] | 待填写真实权利人；不要把方括号原样提交，也不要仅凭应用名认定权利人 |

名称和副标题各最多 30 字符；SKU 是内部标识，创建后不能修改。规则依据：[Apple App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)。

## 商店页面英文文案

### Promotional Text

以下 150 字符，仅描述原生摄影部分；完整产品定位确认后再决定是否保留。限制为 170 字符。

```text
Find a fresh photo idea in minutes. Explore 60 guided tasks, turn everyday details into photo stories, and build a personal collection on your device.
```

### Description

以下为原生摄影文案及在线功能草稿。补齐在线功能段落后，按两种体验的实际主要用途调整标题、篇幅及分类；不要将摄影部分单独当作整款应用的完整描述提交。

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

LOCAL PHOTOGRAPHY TOOLS
The native photography tools do not require sign-up. Photos, captions, drafts, and creations made with these tools are processed and stored on your device. These tools do not automatically upload your creative content to the developer. You control what you export and share.

ONLINE FEATURES
[REQUIRED: Describe the actual online product, its main user-facing features, when it is available, and any account or payment requirements. Explain its relationship to the photography tools.]

Adjust haptics, sound, and motion in the native Settings screen. Daily Recommendations provides access to the notification permission request; notification delivery can be managed in iOS Settings.

The app uses online services for installation attribution, sign-in, and notifications. Internet access is needed during initial setup and for online features. Native photo editing and storage happen on your device. Feedback is sent only when you choose to send an email.

Sign in with Google in Settings > Cloud Sync & Backup, then tap Back Up Now to save an editable cloud snapshot. Use the same account to restore on another device. Restoration adds new copies; edits do not sync automatically. Export Work saves JPG images instead of editable backups.

Support: cressidal@trademarkroofing.homes
Privacy Policy: https://tkzcpoj.netlify.app/turnscene/privacy-policy/
```

### Keywords

以下为原生摄影部分的候选关键词，正好 100 个 ASCII 字节；需结合远程产品调整。不要添加空格、换行或尾随逗号。

```text
photography,inspiration,creative,journal,challenge,camera,composition,collage,storytelling,portfolio
```

### URLs 与版本其他字段

| 字段 | 填写内容 |
| --- | --- |
| Privacy Policy URL | https://tkzcpoj.netlify.app/turnscene/privacy-policy/ |
| Support URL | 待验证正式支持页；现有候选为 https://tkzcpoj.netlify.app/turnscene/privacy-policy/#contact ，须确认公开可访问且包含有效支持方式 |
| Marketing URL | 可留空，尚未提供正式产品官网 |
| Privacy Choices URL | 如提供，填写覆盖账号、归因、推送及其他实际数据处理的公开管理或联系页面；不能只依据本地作品删除说明填写 |
| What’s New in This Version | 按 1.1 更新填写，见下方草稿；发布差异须与实际上一版核对 |
| Routing App Coverage File | 不适用，不上传 |
| App Clip、iMessage、Apple Watch 专属资料 | 当前不适用 |
| App Preview 视频 | 可选；如提供，应体现 1.1 的实际体验 |

Support URL 必须通向可用的联系方式，不能把 `mailto:` 当成支持网站，也不要填写尚未部署的 `/support/` 地址。本次工具未能读取上述线上隐私页面，未确认其最新正文及联系段落；提交前需实际打开核对，并补齐 AppsFlyer、Firebase、Google 登录、自建归因服务、远程网页的数据用途、保存和删除方式。

### What’s New in Version 1.1

以下是已知权限流程的英文草稿；需结合实际上一版和远程网页变化补齐，不能把未修复的启动或网页加载问题写成已修复。

```text
Updated notification and privacy permission flows.
Use Daily Recommendations in the native Settings screen to request notification permission. Notification delivery remains manageable in iOS Settings.
[REQUIRED: Add the actual online product features and other changes introduced in version 1.1.]
```

描述上限为 4,000 字符；关键词上限为 100 字节。1.1 若为已上架应用的更新，需要填写该版本的更新内容；是否已有上架版本不能仅从工程版本号推定。规则依据：[Apple Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)。

## App Review Information

### 审核联系人与登录信息

| 字段 | 填写内容 |
| --- | --- |
| First Name | [待填写：审核联系人的真实名字] |
| Last Name | [待填写：审核联系人的真实姓氏] |
| Phone Number | [待填写：国际格式联系电话，例如 +86 后接实际号码] |
| Email | cressidal@trademarkroofing.homes，仅在此邮箱有人接收审核邮件时使用；否则改为实际审核联系人邮箱 |
| Sign-in required | 原生摄影无需登录，云备份需要 Google 登录。Apple 按钮只完成本机原生授权并显示成功提示，不提供云备份访问；远程网页要求另行补齐 |
| Username / Password | 说明云备份的 Google 登录方式及测试步骤；远程网页如另需账号，应提供有效演示账号或可用演示方式 |
| Attachment | 如附演示视频，使用最终 1.1 构建录制两种实际体验；视频不能替代可供审核的功能和账号 |

联系人资料是给审核团队使用的，不能用虚构姓名或电话号码代替。[Apple 审核信息字段](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)。

### Notes

以下按实际启动代码说明两种体验。提交前必须补齐远程网页业务、访问方式和必要账号，验证审核人员可以访问全部功能；不能只给出原生摄影步骤。现行 2.3.1 要求具体说明新功能并可供审核，2.5.19 禁止隐藏或未披露功能。ATT 弹窗不代替这些披露。[Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

```text
TurnScene 1.1 includes native photography tools and a remotely hosted web experience.

Launch behavior:
AppsFlyer and Firebase are configured during launch. ATT is requested when undetermined after the launch screen becomes visible and the app is active. AppsFlyer starts when its session is ready, and first-open attribution runs independently of the ATT response. The app proceeds to its destination when attribution resolves, even while ATT is unanswered. Notification and location prompts wait until ATT is resolved.

The first-open service can return a product URL, opened in WKWebView and cached for later launches. A resolved flow without a URL, or a failed request without a cached URL, opens the native photography interface. There is no manual switch between experiences.

Online product and review access:
[REQUIRED: Describe the web product and all significant features, including any advertising, payments, or regulated content.]
[REQUIRED: Explain production routing conditions and reproducible access to both experiences in this build.]
[REQUIRED: Provide the domain, review steps, required demo credentials or demo mode, and account deletion steps if applicable.]

The web bridge supports Google/Firebase login and FCM tokens. On entry, the web controller requests notification permission if undetermined, followed by location permission if eligible. Specify login requirements above.

Native photography review flow:
1. Choose Indoors or Outdoors and a 5, 10, or 20-minute task. Tap Spin or select conditions manually. The native reels select photo prompts, with no wagers, prizes, or gambling.
2. Tap Start Creating. Take a photo on a physical device or choose photos from the library. Import remains available if camera permission is denied.
3. Crop or reorder photos, add a caption, and tap Save Work. View the result in Portfolio, then Export Work or Try This Task Again.
4. In Settings, turn on Daily Recommendations to request notification permission if undetermined. Turning it off only saves the native UI preference; it does not revoke system permission or disable web push. No daily local recommendation is scheduled.

The native tools include 6 themes and 60 tasks. Cover images are illustrative assets. Native photography requires no account and keeps photos, captions, drafts, and work locally, without automatic upload. Local deletion does not delete online records. Startup depends on network services; offline first-launch access is not guaranteed.

Attribution and services:
AppsFlyer measures installation attribution and sessions. The separate first-open request to https://attributionsolutions.com/tracking-api/attribution/first-open sends an installation identifier, AppsFlyer UID, available IDFV, web user agent, and available attribution fields. SDK integrations are configured before choosing the destination and also apply to native launches.

Native Settings provides Storage, batch export, and Privacy > View Full Privacy Policy. Exported JPGs are not editable backups.

Cloud Sync & Backup uses Google/Firebase sign-in. The separate native Apple authorization displays a local "Backup Successful" message after authorization; it does not create a cloud account, upload data or enable backup access. Apple sign-in is remembered locally; Sign Out or confirming Delete Account clears that local state. Both account controls remain visible, disabled when signed out or busy. Back Up Now uploads photos, work, drafts and editing metadata to private account storage. Restore adds new copies. Individual backup deletion, sign-out and account deletion are available. Upload is manual; app edits do not sync automatically.

Feedback: Settings > Feedback prepares an email for the user to review and send. If email is unavailable, the user can copy the message and support address. Photos and app data are not automatically attached.

Support: cressidal@trademarkroofing.homes
Privacy policy: https://tkzcpoj.netlify.app/turnscene/privacy-policy/
```

## App Privacy 填写方案

不能沿用“仅收集反馈邮件”的 1.0 填法。填写范围需包含原生功能、远程网页、自己的服务端以及所有已集成 SDK；不能因为用户进入原生页面、拒绝 ATT 或没有使用登录，就把整款应用填成 Data Not Collected。是否属于 Apple 所定义的收集，需结合离开设备后的访问和保存方式确认。[Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

### 本地代码已确认的数据流

| 来源 | 已确认行为 |
| --- | --- |
| AppsFlyer | 启动时初始化，SDK 会话就绪后启动，不等待 ATT 选择；归因/深度链接结果参与首次打开请求，进入原生页面也会运行 |
| 自建首次打开接口 | 向 `attributionsolutions.com` 发送 `appInstanceId`、`ua`、`appsflyer_id`、可用时的 `deviceId`（IDFV）和 SDK 返回的归因字段；并非所有这些字段都发送给 AppsFlyer |
| Native cloud backups | Google sign-in exchanges credentials for a Firebase Auth session; Back Up Now uploads native photos, works and drafts to Firebase Storage under the account UID. Account identifiers and provided name/email are processed for authentication. Storage rules, provider setup and signing must be validated before release. |
| Firebase Messaging / APNs | 启动时配置并注册远程推送，使用 APNs/FCM 安装令牌；B 面可以收到 FCM Token。注册令牌与允许横幅/声音的通知权限是不同步骤 |
| Google Sign-In / Firebase Auth | 网页调用桥接后发起 Google 登录；可交换 Firebase 凭证并向网页返回登录令牌。登录用途不能写成“应用没有账号系统” |
| 定位 | B 面请求使用期间定位权限。原生请求器没有读取或上传坐标的实现；网页定位、SDK 粗略位置及后端用途另行核对，不能据此断言整款应用不收集位置 |
| 原生摄影 | 本地保存照片、文字、草稿和作品；用户主动导出分享。此结论不覆盖远程网页可能存在的上传功能 |
| 反馈邮件 | 用户确认发送后，支持方可收到邮箱及反馈正文；取消邮件不发送 |

代码依据：`Crailglitun/AppIntegrations/AppIntegrationService.swift`、`Attribution/AttributionCoordinator.swift`、`Attribution/FirstOpen/FirstOpenRequestMetadataProvider.swift`（后两项相对于 AppIntegrations）、`Crailglitun/CrailglitunPushService.swift`、`Crailglitun/WebExperienceViewController.swift`。

### 数据类型与填写依据

下表是 1.1 的核对基线，不是未经后台核实即可整表照填的答案。每种数据须分别确认用途、是否关联用户及是否用于 Tracking；无账号不等于无设备关联。

| 问题或数据项 | 当前填写依据 |
| --- | --- |
| Do you or your third-party partners collect data from this app? | Yes；应覆盖归因、身份认证、通知等服务，不能仅申报邮件 |
| Identifiers → Device ID | 应纳入：AppsFlyer UID、IDFV、应用安装标识、推送安装令牌等；按归因/分析/推送实际用途填写，不能统一标成不收集或不关联 |
| Identifiers → User ID | Google/Firebase 登录包含用户标识，需按认证及其他实际用途申报；匿名安装标识也须按含义核对分类 |
| Contact Info → Email Address / Name | Google 账户提供的姓名与邮箱用于认证及云备份访问，关联账户；另计用户主动发送的反馈邮箱。原生 Apple 流程不请求姓名或邮箱 |
| User Content → Customer Support | 邮件反馈按 App Functionality、关联用户处理；如符合 Apple 全部可选披露条件，才另行评估豁免 |
| Usage Data → Product Interaction / Other Usage Data | AppsFlyer SDK 清单含 Product Interaction / Analytics；Google Sign-In 清单含 Other Usage Data。核对会话及网页事件，不再统一填 No |
| Diagnostics → Other Diagnostic Data | Firebase Auth/Installations/Messaging 的随包清单有相应声明；结合实际采集配置填写，不因未集成 Crashlytics 就全部排除 |
| Location → Coarse Location | Google Sign-In 随包清单声明粗略位置，其说明提及 IP 推断位置用于防欺诈；另外核对网页和归因服务的 IP/位置用途 |
| Location → Precise Location | 请求定位权限本身不证明收集坐标；需确认远程网页、SDK 和后端是否接收/保存精确位置后填写 |
| Contact Info → Phone Number / Other Data Types | Google Sign-In 清单含这些类别，需按实际授权范围及服务配置核对；不凭原生界面没有输入框直接排除 |
| User Content → Other User Content | 云备份上传文字说明、草稿及编辑信息，按 App Functionality、关联账户申报 |
| Photos or Videos | 已确认：云备份会上传照片，按 App Functionality、关联账户申报；原生编辑仍可只在本机进行 |
| Purchases / Financial Info / Advertising Data 等 | 本地无 StoreKit 购买链路，不能据此排除远程网页付款、广告或其他数据；实际网页业务待确认 |
| Analytics / Advertising / Product Personalization | 归因、会话分析及产品 URL 选择需要按实际目的核对；不再统一填“不勾选”。广告用途与应用界面是否展示广告是不同问题 |

Firebase 的认证和通知数据说明见 [Firebase App Store data collection](https://firebase.google.com/docs/ios/app-store-data-collection)；Google 登录的数据说明见 [Google Sign-In app privacy](https://developers.google.com/identity/sign-in/ios/app-privacy)。本表中的 SDK 清单事实来自当前安装版本，不代表所有可选数据已经在本应用每次运行中采集。

### Tracking、ATT 与隐私清单

当前 AppsFlyer 完整版 iOS SDK 清单声明 `NSPrivacyTracking = true`，Device ID 为 linked / tracking、用途为 Third-Party Advertising，Product Interaction 用于 Analytics。应用自己的 `PrivacyInfo.xcprivacy` 已为云备份声明 User ID、Name、Email Address、Photos or Videos 和 Other User Content，均关联用户、用于 App Functionality，云备份本身不用于 Tracking。**不能把本功能的 tracking=false 扩展为整款应用“不追踪”，也不能把 SDK 通用清单当作已核实的服务端使用事实。** 应按实际 SDK 配置、合作方共享方式和自建接口用途核对，并查看最终归档聚合隐私报告。

ATT 方面，请求时机仍为启动页可见且应用活跃时。SDK 会话和首次归因不等待 ATT 选择；A/B 入口确定后即可展示，网页也可在弹窗仍显示时加载，系统弹窗本身仍拦截底层操作。自建首次打开请求目前没有根据未决定或拒绝状态去除 IDFV、AppsFlyer UID、UA 等字段。首次会话早于授权时不会取得已授权的 IDFA，这可能影响归因结果；不能写成“所有 SDK/数据发送都在用户允许后才开始”或“拒绝后不再发送任何数据”。这些数据是否构成跨公司追踪取决于实际用途；最终 Tracking 答案不能单凭存在弹窗决定。

IDFA 也不能继续固定填 No：工程使用 AppsFlyer 完整版，未显式禁用广告标识采集。需核对授权/拒绝下的 SDK 行为、归因后台及实际传输；不能因业务 Swift 代码未直接调用 IDFA 就声明整个应用不使用它。

## 年龄分级问卷

需覆盖原生内容和远程网页全部可访问内容；远程业务尚未确认，**当前不能给整款应用预判 4+ 或整表填写 No / None**。以下保留原生部分可确认的事实，最终分级由完整问卷计算。

| 问卷项目 | 当前建议 |
| --- | --- |
| Parental Controls / Age Assurance | 原生无此功能；需核对网页是否提供，不能宣称已实现年龄验证 |
| Unrestricted Web Access | 待确认网页能否浏览任意外部内容；B 面不是仅显示隐私政策的页面 |
| User-Generated Content / Social Media | 原生作品仅本地保存和系统分享；网页社区、发布或社交能力待确认 |
| Messaging and Chat | 原生仅支持邮件反馈；网页聊天能力待确认 |
| Advertising | 原生界面未实现广告展示；网页广告待确认，不能依据是否有归因 SDK 直接决定 |
| Profanity / Horror / Alcohol / Medical / Health / Sexual Content / Violence / Weapons 等内容频率 | 原生摄影素材未见相应内容；需逐项审查远程内容后填写整款应用的频率 |
| Simulated Gambling / Gambling / Contests / Loot Boxes | 原生滚轮仅选择摄影任务；网页是否包含相应内容待确认，不沿用原生结论 |
| 更高年龄限制或覆盖分级 | 结合远程业务、地区要求及实际最低年龄政策确认 |
| Made for Kids | No |

三列原生滚轮是摄影任务选择器；WKWebView 的存在也不自动等于无限制浏览。两项均应按实际可访问功能判断，不能用原生页面的结论覆盖未知网页内容。规则依据：[Apple 年龄分级定义](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)。

## 加密与出口合规

当前应用使用 WKWebView / URLSession 的 HTTPS、Google 登录和 Firebase 等第三方服务。业务代码未见自定义密码算法；是否仅依赖系统加密应结合最终归档及 SDK 实现核对，不能再仅凭隐私网页推断整包没有第三方实现。

| 问题类型 | 对应回答 |
| --- | --- |
| 是否使用加密，包括系统提供的加密 | Yes，包含 HTTPS / 登录服务 |
| 是否自行实现专有或非标准加密 | 业务代码未见；仍应核对最终 SDK 组成 |
| 是否实现或包含系统之外的标准加密算法 | 待最终归档与 SDK 资料核对，不把“未见自写算法”当作答案 |
| 是否使用非豁免加密 / 是否需要证明材料 | 按实际加密方式和该构建问卷确认；若确认仅使用系统豁免加密，再选择对应答案 |

后续依赖或协议变更时应重新核对。当前 Info.plist 未设置 `ITSAppUsesNonExemptEncryption`；可以在后台完成问卷，确认豁免后另行决定是否将该键设为 NO。本次仅准备资料，没有修改发布配置。[Apple 加密说明](https://developer.apple.com/documentation/Security/complying-with-encryption-export-regulations)、[出口合规填写流程](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation/)。

## 截图与商店素材

当前是 iPhone App。准备最终 1.1 的英文真实截图。下表仅为原生摄影候选画面；须补充远程产品的主要真实功能并按整款应用的核心体验排序，不能只用摄影截图描述不同的网页产品，也不把设计稿当作已实现功能。

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
| Price | 核对已有应用的实际价格；1.1 不擅自改变商业方案，网页收费方式也需确认 |
| Countries or Regions | 待确认实际销售地区，不默认勾选全球 |
| Distribution Method | 建议 Public，即普通公开 App Store 发行 |
| Version Release | 建议 Manually release this version，审核通过后由你决定正式发布时间 |
| Pre-Order | 若为已上架应用的 1.1 更新，不按首次发布预购填写 |
| Phased Release | 如后台提供，按 1.1 更新的发布计划决定是否启用 |
| In-App Purchases / Subscriptions | 原生未实现 StoreKit；网页是否销售或解锁数字内容待确认，不能据此直接填整款应用无购买 |
| Game Center | 不启用 |
| Advertising Identifier / IDFA（若显示） | 待核对 AppsFlyer 完整版和实际归因配置；不能继续固定填 No，详见隐私部分 |
| Apple Silicon Mac / Apple Vision Pro availability | 需单独检查后台可用性选择；iPhone target 不等于这些渠道自动关闭。未经兼容性验证不主动扩大分发范围 |
| Tax Category | 保留适用的软件类默认类别；如改为付费，以账号实际税务情况确认 |
| Digital Goods and Services 问卷 | 原生提供摄影内容与工具；网页业务、销售、订阅、外部付款及登录后解锁情况待确认。按完整产品和后台问题定义填写，不能只凭原生无内购回答 No |

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
| 受监管医疗器械声明 | 原生摄影工具无诊疗功能；确认远程产品也无相关用途后，按完整产品实际情况填写 |
| Agreements / Tax / Banking | 由账号持有人完成适用协议、税务及银行信息，不能从代码推定已完成 |

依据：[Apple DSA 交易商要求](https://developer.apple.com/cn/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)、[Apple 应用信息及地区要求](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)。

## Accessibility 可选声明

暂不仅凭代码中的辅助功能标签就宣称所有功能通过 VoiceOver、Voice Control、Larger Text 或 Sufficient Contrast 标准。应用虽包含减少动态效果选项，但应覆盖任务选择、拍摄导入、裁剪、保存、导出及反馈等常用流程后再填写支持的标签。当前主体界面采用固定浅色调，隐私网页支持深色模式不等于整款应用支持 Dark Interface。

Accessibility URL 没有专属页面时留空。规则依据：[Apple Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)。

## 提交前需要补齐的内容

1. 审核联系人的真实姓名、国际格式电话，以及确认可收信的审核邮箱。
2. 版权持有人真实姓名或公司名称；如有第三方素材，确认许可覆盖发行用途。
3. 确认应用价格、销售地区和发行方式，以及适用的 DSA、备案和账号合规资料。
4. 补齐远程网页实际业务、路由条件、审核入口、登录/演示账号、支付和广告信息，完成 Description、What’s New 与 Notes 中的 `[REQUIRED: ...]`，确认同一提交构建的两种体验均可审核。
5. 核对 SDK/归因后台、网页及自建服务的数据用途、关联和保存方式，完成隐私标签，并同步公开隐私政策。应用内 Settings 的隐私摘要和仓库中的 `docs/Crailglitun-privacy-policy.html` 已补充已知在线服务与权限行为；HTML 源文件更新不代表线上页面已发布，远程网页实际业务及服务端用途仍需补齐。
6. 验证正式 Support URL、Privacy Policy URL 及支持邮箱；本次未确认线上页面最新内容可用。
7. 上传实际 App Store 构建并等待处理完成。工程当前为 **1.1 (1)**；如构建号需递增，按既有发布流程处理。本次未更改版本号、构建号、签名、Bundle ID 或发布配置。
8. 上传覆盖完整产品的真实截图，完成隐私、年龄与加密问卷；不要套用旧的纯摄影/无 SDK/4+ 结论。
9. 真机验证 ATT 允许与拒绝、原生通知开关、B 面推送接收与点击、Google/Firebase 登录、定位请求，以及摄影、导出、隐私网页和邮件反馈。现有模拟器构建不等于这些流程已验证。
10. 替换所有占位信息并核对最终版本，再由负责人执行 Add for Review 和提交。本文仅准备资料，未执行后台修改、提交或发布。
