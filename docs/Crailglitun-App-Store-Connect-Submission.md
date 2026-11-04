# TurnScene 1.1 App Store Connect 提审资料

更新日期：2026-11-04。适用当前工程 **1.1 (1)**。本文提供可复制的英文文案、审核信息和隐私申报基线；与应用内 Help、Privacy 的登录及备份描述一致。

未知资料按要求留空。远程网页业务本次不展开，相关空白不表示应用没有这些功能。以下文案与隐私政策为发布草稿，填写空白并核对最终构建后使用。本次不提交 App Store Connect、不上传构建、不发布网页。

## 应用信息

| 字段 | 内容 | 备注 |
| --- | --- | --- |
| Name | TurnScene | 9 字符 |
| Subtitle | Everyday Photo Prompts | 22 字符 |
| Primary Language | English (U.S.) | 英文界面及本次英文文案 |
| Bundle ID | com.szg.AFTesk | 与当前 Debug、Release 工程一致；本次仅更正文档 |
| Version | 1.1 | 当前版本号 |
| Build | 1 | 上传后选择对应的已处理构建 |
| Platform | iOS | iPhone，iOS 15.0 及以上 |
| Primary Category | Photo & Video | 原生摄影功能对应的候选分类 |
| Secondary Category | | 可选 |
| SKU | | 保留后台已有值 |
| Apple ID | | 从 App Store Connect 读取 |
| Seller / Legal Entity | | 发布主体法定名称 |
| Copyright | | 填写 2026 及真实版权持有人 |
| Privacy Policy URL | https://tkzcpoj.netlify.app/turnscene/privacy-policy/ | 当前应用链接；需发布本次更新后核对 |
| Support URL | | 填写公开可用的支持页面 |
| Marketing URL | | 可选 |
| Privacy Choices URL | | 可选 |
| Price / Territories | | 按实际发行计划填写 |
| Release Option | Manually release this version | 建议审核通过后手动发布 |

名称、副标题上限各 30 字符；Bundle ID 应与构建一致，SKU 保留既有记录。[Apple 应用信息字段](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)

## 商店英文文案

以下覆盖已确认的原生摄影、账号控制和 Google 云备份。远程网页介绍留空，完整产品描述由发布人补齐。

### Promotional Text

```text
Find a fresh photo idea in minutes. Explore 60 guided tasks, create your own photo stories, and save an editable cloud backup with your Google account.
```

### Description

```text
See the familiar in a new way with TurnScene.

Find something worth photographing in everyday life. Choose Indoors or Outdoors, pick a 5, 10, or 20-minute time window, and discover a photo task built around a subject, a format, and a creative constraint.

FIND YOUR NEXT PHOTO IDEA
Explore 60 tasks across six themes. Spin the three reels, lock choices you want to keep, or select conditions manually.

CAPTURE AND CREATE
Follow practical steps to create a photo with a caption, a two-photo pairing, or a three-frame story. Take photos with the camera or choose images from your library.

EDIT AND KEEP YOUR WORK
Crop and reorder photos, add captions, choose a layout, and save drafts. Keep finished creations in Portfolio, revisit a task, and compare different versions.

EXPORT AND SHARE
Export individual creations or a selection of works as JPG images, then choose where to save or share them using the iOS share sheet.

CLOUD SYNC & BACKUP
Sign in with Google and tap Back Up Now to save an editable snapshot of your work, drafts, photos, and editing details. Use the same Google account on another device to restore your backup. Restoring adds new copies and keeps existing work. Backups are manual; later changes do not sync automatically.

ACCOUNT CONTROLS
Manage your sign-in from Settings > Cloud Sync & Backup. Sign Out returns you to the sign-in screen. Account removal is available through Delete Account & Cloud Data. Work already saved on your device remains available.

YOUR SETTINGS
Adjust haptics, sound, and motion. Daily Recommendations lets you request notification permission; manage notification delivery in iOS Settings.

The photography tools do not require an account. They save your work on your device without automatic upload. Cloud backup, sign-in, online services, and initial setup require an internet connection. Exported JPGs do not contain the full editable backup.

Support: cressidal@trademarkroofing.homes
Privacy Policy: https://tkzcpoj.netlify.app/turnscene/privacy-policy/
```

远程网页介绍：


### Keywords

```text
photography,inspiration,creative,journal,challenge,camera,composition,collage,storytelling,portfolio
```

### What’s New in Version 1.1

```text
Cloud Sync & Backup is now available in Settings. Sign in with Google to save editable backups and restore them on another device.

Manage your sign-in with Sign Out and Delete Account & Cloud Data. Apple sign-in is available through the native iOS sign-in flow.

Updated Help and Privacy information, along with notification and tracking permission flows.
```

更新说明按本次开发内容编写；发布人核对上一上架版本后使用。其他版本变更：


Promotional Text 上限 170 字符，Description 上限 4,000 字符，Keywords 上限 100 字节；关键词不重复应用名或公司名。[Apple 版本字段说明](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)

## App Review Information

### 联系人与演示账号

| 字段 | 填写内容 |
| --- | --- |
| First Name | |
| Last Name | |
| Phone Number | |
| Email | |
| Sign-in required | 云备份需要 Google 登录；摄影工具无需登录。最终填写须覆盖全部需登录功能 |
| Demo Username | |
| Demo Password | |
| Additional Account Instructions | |
| Attachment | |

审核电话使用带国家区号的国际格式。为需登录功能提供审核可用且不会过期的测试账号或演示方式；使用第三方单点登录也需要提供测试所需信息。[Apple 审核信息字段](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)

### Notes

以下为已确认功能的英文审核说明。网页业务及访问方式留空，按最终提交版本补充。

```text
TurnScene 1.1 provides native photography tasks, local photo editing, export, and optional Google cloud backups. A remote web experience may also be selected during initial setup.

NATIVE PHOTOGRAPHY
1. Choose Indoors or Outdoors and a 5, 10, or 20-minute task. Tap Spin or select conditions manually. The reels select photography prompts.
2. Tap Start Creating. Take a photo on a physical device or choose photos from the library. Library import remains available if camera permission is declined.
3. Crop or reorder photos, add a caption, and save the work. Open Portfolio to view, compare, or export creations as JPG images.

CLOUD BACKUP AND ACCOUNTS
Open Settings > Cloud Sync & Backup. Sign in with the Google demo account provided in App Review Information. Tap Back Up Now to upload an editable snapshot. Use Refresh Backups and Restore to retrieve it. Restore adds new copies without replacing existing local work. Changes do not sync automatically.

Sign Out keeps cloud backups. Delete Account & Cloud Data asks for Google identity verification, deletes the cloud backups and Firebase app account, and keeps local work. Deleting an app account does not delete the person's Google account.

The Apple button opens the native iOS authorization flow and remembers sign-in on the device. Successful authorization returns to the signed-in account view without an alert. Tapping Back Up Now or Refresh Backups while signed in with Apple displays "Cloud backup is currently unavailable. Please try again later." These Apple actions do not access cloud storage. Sign Out or confirming account removal clears that local sign-in. Google is the account used for cloud backup and restore.

PERMISSIONS AND SERVICES
The app requests ATT during startup when the choice is undetermined and iOS allows it. Denying tracking does not prevent access. Initial attribution and destination loading do not wait for the ATT response. AppsFlyer and Firebase are initialized during launch.

Daily Recommendations in Settings requests notification permission when undetermined. Its off state does not revoke system permission or stop existing web notifications; delivery can be managed in iOS Settings. The online experience can also request notification and location permissions. The photography task's Indoors/Outdoors choice does not use device location.

Settings > Privacy includes the full privacy policy link. Settings > Feedback prepares an email for the user to review and send.

REMOTE EXPERIENCE
The first-open service may return a web URL, which is cached for later launches. A resolved flow with no URL, or a failed request with no cached URL, opens the native photography interface. There is no manual switch between experiences.
Product and domain:
Review access instructions:
Additional demo account:

Support: cressidal@trademarkroofing.homes
```

Notes 上限为 **4,000 字节**。上述文字不承诺审核结果；最终构建的功能与审核信息应一致。[Apple Notes 字段](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)

## App Privacy 填写基线

首题 **Do you or your third-party partners collect data from this app? → Yes**。以下按已确认的云备份、登录和 SDK 整理；用途须合并所有实际使用来源。

### 云备份与账户数据

| App Store Connect 数据类型 | 用途 | Linked to User | 当前依据 |
| --- | --- | --- | --- |
| Contact Info → Name | App Functionality | Yes | Google 账户提供的姓名 |
| Contact Info → Email Address | App Functionality | Yes | Google 账户邮箱；另包含主动发送支持邮件的邮箱 |
| Identifiers → User ID | App Functionality；SDK 分析用途另核对 | Yes | Firebase UID、Google 用户标识用于认证和备份访问 |
| User Content → Photos or Videos | App Functionality | Yes | 主动云备份上传的照片 |
| User Content → Other User Content | App Functionality | Yes | 文字说明、草稿、布局和编辑信息 |
| User Content → Customer Support | App Functionality | Yes | 用户主动发送的反馈；是否符合可选披露条件需另核对 |

以上云备份操作本身不用于 Tracking。Apple 登录标识由本应用仅保存在设备上；这部分本地存储不作为应用上传的云端账户数据申报。隐私标签应包含第三方 SDK 的采集，不能仅根据是否有上传按钮判断。[Apple 数据收集定义与本地处理说明](https://developer.apple.com/app-store/app-privacy-details/)

### SDK 和归因数据

| 数据类型 | 当前安装依赖中的依据 | 填写处理 |
| --- | --- | --- |
| Identifiers → Device ID | AppsFlyer UID、IDFV、安装标识、FCM/APNs 令牌；AppsFlyer 清单声明 Device ID 关联用户、用于 Tracking 和 Third-Party Advertising | 需申报；合并分析、功能及实际广告衡量用途。Tracking 的最终选择： |
| Usage Data → Product Interaction | AppsFlyer 清单声明 Analytics | 纳入分析用途，核对是否与其他标识关联 |
| Usage Data → Other Usage Data | Google Sign-In 清单声明 Analytics，关联用户 | 按实际配置纳入 |
| Diagnostics → Other Diagnostic Data | Firebase Auth、Installations、Messaging 有相关声明 | 按具体 SDK 的 Analytics / App Functionality 用途合并 |
| Location → Coarse Location | Google Sign-In 可按 IP 推断粗略位置，用于防欺诈 | 核对登录及归因服务的实际用途后填写 |
| Contact Info → Phone Number / Other Data Types | Google Sign-In 清单包含相关类别 | 实际授权范围及服务采集是否涉及： |
| Location → Precise Location | 当前原生请求器只请求权限，没有读取坐标的代码 | 实际网络或 SDK 采集情况： |
| 其他数据 | 本次未展开的业务数据 | |

SDK 清单是核对依据，不直接替代实际数据使用核查。Firebase 的披露说明要求按实际启用的 SDK 与功能判断；Google 文档说明登录标识及 IP 粗略位置用途。[Firebase 数据披露说明](https://firebase.google.com/docs/ios/app-store-data-collection)、[Google Sign-In 数据说明](https://developers.google.com/identity/sign-in/ios/app-privacy)

### Tracking 和 ATT

当前 AppsFlyer SDK 清单声明 `NSPrivacyTracking = true`。应用自身清单中云备份数据的 `tracking=false` 不代表所有集成服务均不追踪。最终答案须核对归因后台、广告伙伴共享及自建接口用途；不能只根据是否弹出 ATT 判断。

首次归因不等待 ATT 选择，并会使用安装标识、AppsFlyer UID、可用 IDFV、UA 和归因字段。隐私文案不写成“允许 ATT 后才发送所有数据”。IDFA 的实际使用与最终 Tracking 申报留给后台确认。

苹果将跨公司数据关联用于定向广告或广告衡量，以及向数据经纪商共享数据纳入 Tracking；网页内数据流也属于隐私申报范围。[Apple Tracking 定义](https://developer.apple.com/app-store/app-privacy-details/#tracking)

## 截图与其他提交项目

准备最终版本的英文真实截图，建议包含任务选择、主题、任务详情、编辑、Portfolio、Google 云备份及账号控制。当前是 iPhone App；可按后台必填尺寸准备 **1206 × 2622** 竖图。每种设备尺寸 1–10 张，PNG 或 JPEG，无透明通道。[Apple 截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)

| 项目 | 当前资料或待填写内容 |
| --- | --- |
| App Icon | 工程中的 1024 × 1024 AppIcon，随构建提交 |
| Age Rating | 留空，按完整内容问卷计算；不预填 4+ |
| Made for Kids | 原生摄影产品不以儿童专区为定位；最终选择： |
| In-App Purchases / Subscriptions | 原生未接入 StoreKit；完整产品答案： |
| Export Compliance | 使用 HTTPS、认证和云服务；按最终归档填写加密问卷，不能写成完全不使用加密 |
| Content Rights | |
| EU DSA Trader Status / 联系资料 | |
| 适用地区的备案或资质 | |
| Agreements / Tax / Banking | |
| Accessibility 声明 | 仅申报经实际验证的支持项 |

年龄分级依据完整问卷，出口加密材料是否豁免按构建使用的技术判断。[Apple 年龄分级定义](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)、[Apple 加密资料](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation/)

## 隐私政策与发布前填写项

英文政策文件：[Crailglitun-privacy-policy.html](Crailglitun-privacy-policy.html)。提供照片和作品、登录、云备份、设备与归因数据、权限、第三方服务、保留与删除、安全及联系条款。

- 发布主体、审核联系人、电话、支持网站及演示账号按上表补齐。
- 政策的经营主体名称、联系地址、在线业务补充说明、归因及其他服务记录保留期限留空。填写后再发布至 Privacy Policy URL；本地 HTML 更新不代表线上已更新。本次工具未能读取当前公开地址，不能确认其内容和可用性。
- Firebase Google 登录、Storage 规则、真实上传与恢复、账号删除由后台配置及真机联调确认；账号删除还须覆盖实际业务保存的其他个人数据。
- 当前 Apple 原生授权仅维持本地登录，云备份仍使用 Google 账户。第三方登录的等效选项要求需按最终提供的功能核对，见 [Apple 4.8](https://developer.apple.com/app-store/review/guidelines/#login-services)。
- 远程网页业务及审核访问资料本次留空，不作为已完成项。

完成空白项后，在 App Store Connect 选择实际构建、保存隐私答案、上传截图，再执行 Add for Review。上述材料尚未在后台填写或提交。
