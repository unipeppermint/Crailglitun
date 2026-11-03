# 转场项目文档

本目录汇总转场的产品方案、原型图和技术方案，供产品、设计与 iOS 开发共同使用。当前采用轻量 Slot 三列滚轮，通过对象、方式、限制生成生活观察与摄影创作任务，完成后保存为个人作品。

整理日期：2026 年 9 月 30 日。文档基线：v1.0。产品与原型文档保留设计基线，当前已经完成 UIKit 首版实现。实际功能、构建结果、测试证据和待验证项以 [实现与验证记录](implementation-report.md) 为准。

## 阅读顺序

| 文档 | 内容 |
| --- | --- |
| [产品方案](./product-plan.md) | 用户场景、核心流程、首版范围、页面与验收标准 |
| [原型与交互说明](./prototype-guide.md) | 当前视觉基准、三版原型、交互状态与待补页面 |
| [技术方案](./technical-plan.md) | UIKit 架构、滚轮实现、规则引擎、存储与验证 |

## 当前设计基准

当前原型为[轻量滚轮与设置页](../design/prototypes/turnscene-light-slot-settings-20260930.png)。

![转场轻量滚轮与设置页](/Users/mac/Desktop/Projects/Crailglitun/design/prototypes/turnscene-light-slot-settings-20260930.png)

- 首页：三列轻量滚轮，点击按钮触发，支持锁定条件。
- 主导航：转场、主题馆、作品集。
- 设置：从首页右上角齿轮进入。
- 视觉：米白、橙色与低饱和青绿；已移除拉杆和厚重机械外壳。
- 技术：Swift、UIKit、iOS 14 起、本地优先，首版使用系统框架。

旧的三环转盘和机械 Slot 图保留作为设计演进记录，不作为当前首页实现依据。原型是静态图片，页面交互和功能范围以文档为准。

## 当前工程与后续工作

当前工程为 Swift + UIKit 纯代码首版，使用 Core Data 和本地素材文件，最低支持 iOS 15.0。AppIntegrations 所需的 AppsFlyer、Firebase Core/Auth/Messaging 和 Google Sign-In 通过 CocoaPods 接入。

首次拉取或变更依赖后，在项目根目录执行 `pod install`，然后打开 `Crailglitun.xcworkspace` 进行编译。提交 `Podfile`、`Podfile.lock` 和 workspace；`Pods/` 由 CocoaPods 安装，不纳入版本管理。AppsFlyer 使用 7.x，以匹配现有会话启动接口。

已接入六个主题、60 个任务、摄影封面与应用图标。后续需真机检查相机、触感与性能，并试做任务、确认正式名称与支持联系方式。详见 [素材清单](assets.md) 和 [实现与验证记录](implementation-report.md)。

## 归因启动与网页接入

`AppDelegate` 与 AFTesk 一致，只初始化 `AppIntegrationService`（AppsFlyer、Firebase、Google Sign-In）。`SceneDelegate` 连接 Scene 并转交冷启动 URL、URL Scheme、Universal Link 回调；`CrailglitunStartupRouter` 创建以 `AttributionViewController` 为根的导航栈，`CrailglitunMainViewFactory` 构建原有原生主页。导航栏隐藏，保留当前应用的启动背景与网页安全区域布局。

`AttributionViewController` 的网页跳转方法沿用 AFTesk：已有 HTTP／HTTPS productURL 时直接安排 push 网页；无地址时继续等待归因和首次打开接口，收到地址后再跳转。没有最少 1 秒展示、额外 8 秒截止或自定义 15 秒请求超时；归因回调收集窗口仍使用参考项目原有的 3 秒。为保留当前应用的原生默认主页，首次接口失败、完成但无有效地址、之前已完成上报但无缓存，或未配置 AppsFlyer App ID 时，进入原有原生主页。

`WebExperienceViewController.swift` 以 AFTesk 参考实现为基础，仅增加用户要求的网页首次加载前 ATT 请求：控制器可见且应用处于 active 状态时，未决定权限才请求；允许、拒绝或受限均继续加载网页，已有决定时直接加载。页面只发起一次初始加载，定位权限请求安排在 ATT 处理完成之后，避免两个系统授权弹窗冲突。原生主页不触发 ATT。Info.plist 已加入 `NSUserTrackingUsageDescription`；AppsFlyer 和首次归因接口的启动时机保持原有流程。

网页使用默认状态栏行为，WebView 四边约束到 `safeAreaLayoutGuide`，保留安全区域。WebNativeBridge 和定位权限申请类同步参考实现，Info.plist 已加入对应定位用途说明。网页加载、跨域跳转、新窗口、Google/Firebase 登录、FCM token 回调及 Cookie 操作均沿用参考逻辑；移除了额外的导航拦截、20 秒加载超时、网页失败回原生以及网页推送跳转。网页失败只记录日志；启动阶段没有有效 productURL 时仍进入原生主页。`storageGetItem` 与参考项目一样保留为空操作。

联调继续沿用 AFTesk 的 AppsFlyer、Firebase 和 Google 配置。Associated Domains 与参考项目一致，为 `applinks:tetst-dingg.onelink.me`。本次没有调整工程已有的 Bundle ID、签名团队或描述文件设置。

推送相关实现与参考项目一致：通过 `AppIntegrationService.fetchMessagingToken` 获取 FCM token，没有额外的 APNs 注册服务、通知代理或推送点击路由。已移除 `CrailglitunPushService`、`CrailglitunURLPolicy`、`CrailglitunLaunchDecision` 及针对旧策略的检查脚本。`AppIntegrations` 中的归因、首次接口和地址缓存实现与参考项目一致。

依赖按当前 iOS 15／Xcode 26.6 环境选择 CocoaPods 可用的最新稳定版本：AppsFlyer 7.0.4、FirebaseCore 12.19.3、FirebaseAuth／FirebaseMessaging 12.19.0、GoogleSignIn 10.1.0。Firebase 13 起不再通过 CocoaPods 发布，因此继续使用 Pod 支持的版本；具体解析结果以 `Podfile.lock` 为准。
