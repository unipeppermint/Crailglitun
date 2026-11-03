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

`AppDelegate` 初始化 `AppIntegrationService`（AppsFlyer、Firebase、Google Sign-In），并转交 APNs 注册成功／失败回调。`SceneDelegate` 连接 Scene 并转交冷启动通知及 URL Scheme 等生命周期回调；`CrailglitunStartupRouter` 创建以 `AttributionViewController` 为根的导航栈，`CrailglitunMainViewFactory` 构建原有原生主页。导航栏隐藏，保留当前应用的启动背景与网页安全区域布局。

`AttributionViewController` 的网页跳转方法沿用 AFTesk：已有 HTTP／HTTPS productURL 时直接安排 push 网页；无地址时继续等待归因和首次打开接口，收到地址后再跳转。没有最少 1 秒展示、额外 8 秒截止或自定义 15 秒请求超时；归因回调收集窗口仍使用参考项目原有的 3 秒。为保留当前应用的原生默认主页，首次接口失败、完成但无有效地址、之前已完成上报但无缓存，或未配置 AppsFlyer App ID 时，进入原有原生主页。

`WebExperienceViewController.swift` 以 AFTesk 参考实现为基础，按用户要求增加 ATT 与通知授权：控制器可见且应用处于 active 状态时，先处理 ATT；允许、拒绝或受限均继续加载网页，已有决定时直接加载。网页开始加载时检查通知权限，仅未决定时申请；处理完通知授权后再请求定位。原生主页不触发这些授权，通知拒绝或注册失败不阻断网页。ATT 和定位用途说明由现有 Target 构建设置写入最终 Info.plist；AppsFlyer 和首次归因接口的启动时机保持原有流程。

网页使用默认状态栏行为，WebView 四边约束到 `safeAreaLayoutGuide`，保留安全区域。WebNativeBridge 和定位权限申请类同步参考实现。网页加载、跨域跳转、新窗口、Google/Firebase 登录、FCM token 回调格式及 Cookie 操作均沿用参考逻辑。网页失败只记录日志；启动阶段没有有效 productURL 时仍进入原生主页。`storageGetItem` 与参考项目一样保留为空操作。

联调使用当前工程中的 AppsFlyer 配置、首次打开接口及已更新的 GoogleService-Info.plist。已按需求移除 Associated Domains 能力，当前不通过 OneLink Universal Links 唤起应用。工程已有的 Bundle ID、签名团队及描述文件由打包流程处理。

## Firebase 推送

按用户要求补齐 `CrailglitunPushService`：Firebase 初始化后设置 Messaging／通知代理并注册 APNs；该步骤不弹通知授权。APNs token 转交 Firebase 后才获取 FCM token，后续刷新由 MessagingDelegate 接收。保留 Firebase 默认 method swizzling，不新增静默推送或富媒体通知扩展。

通知权限只由 `WebExperienceViewController` 在首次加载网页时触发。首次可允许或拒绝，已决定时不再弹窗；与 ATT、定位串行处理，不增加网页等待。前台显示横幅、声音、通知列表和角标；点击通知清除角标并回到当前 productURL 主页。冷启动时暂存点击意图，等原有归因／网页导航就绪后处理一次；不读取推送中的任意 URL，也不改变原生默认主页的兜底逻辑。

H5 继续使用 `getFcmToken`，传入 `{ callback: "函数名" }` 或回调名字符串；成功返回 FCM token，失败仍返回 `failure: ...` 字符串。APNs 尚未就绪时等待注册回调，最多 20 秒返回可重试错误，不阻塞网页；失败后再次调用或应用回到前台可重试。

网页加载完成和 token 刷新时，额外发送 `window` 事件 `fcmTokenUpdated`，token 位于 `event.detail.token`。H5 应在已有 getFcmToken 成功回调和此事件中，将 token 幂等绑定到实际业务后端；登录用户切换、退出时也由 H5／后端处理对应绑定与解绑。工程未提供原生 token 上报接口，因此没有编造上传地址。示例监听：

```javascript
window.addEventListener('fcmTokenUpdated', function (event) {
    // 将 event.detail.token 交给现有业务接口，绑定当前登录用户。
});
```

当前 FirebaseMessaging 的 `token(completion:)` 已标记弃用，但 H5 协议要求 FCM token；新的 `register(completion:)` 使用不同的 Firebase Installation ID，暂不替换后端协议。客户端不打印完整 token，也不把 token 保存到 UserDefaults。

Target 已启用 Push Notifications 并添加标准 `aps-environment` entitlement；最终 APNs 环境由 Xcode 签名／导出及描述文件决定。真机端到端验证仍需在 Firebase 控制台上传有效 APNs 认证密钥，并使用支持推送的描述文件，由 H5／后台保存 token 后发送测试通知。模拟器通知验证不能替代 FCM → APNs → 真机验证。官方接入说明：[Firebase Apple 推送](https://firebase.google.com/docs/cloud-messaging/ios/get-started)。

2026-11-03 验证：最终 Debug 模拟器构建、Release 真机架构免签名构建通过。独立模拟器验证原生主页不弹授权、ATT → 通知 → 定位的顺序、通知允许／拒绝时网页继续加载、已有授权决定时不重复弹窗、前台通知横幅及 APNs 失败时 H5 错误回调。16 项临时状态测试覆盖点击暂存／去重／重入、FCM token 更新与失效、多请求完成、失败与超时恢复，全部通过；临时测试入口已从应用移除。测试包未签名，未取得可用于真实投递的 FCM token；系统通知点击的完整交互和实际云端投递仍待签名真机联调。

依赖按当前 iOS 15／Xcode 26.6 环境选择 CocoaPods 可用的最新稳定版本：AppsFlyer 7.0.4、FirebaseCore 12.19.3、FirebaseAuth／FirebaseMessaging 12.19.0、GoogleSignIn 10.1.0。Firebase 13 起不再通过 CocoaPods 发布，因此继续使用 Pod 支持的版本；具体解析结果以 `Podfile.lock` 为准。
