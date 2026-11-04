# Cloud Sync & Backup 接入

Google 登录通过现有 Google SDK 获取凭证并登录 Firebase Auth，用于云端备份。Apple 登录独立使用 AuthenticationServices 原生授权：页面显示加载状态，收到当前请求有效的系统成功回调后结束加载并显示 “Backup Successful / Backup completed successfully.”。该提示由本地认证成功触发，没有实际上传。取消不提示成功，失败显示错误。

Apple 流程不请求姓名或邮箱、不读取或上传身份令牌及授权码、不创建 Firebase 账户。原生认证成功后仅在本机保存 Apple 用户标识以维持登录状态；重新进入页面或应用回到前台时检查授权是否仍然有效。它不触发云备份、云端列表加载或账户关联。云备份仍通过 Google/Firebase 账户使用。

备份使用当前 Firebase 项目 `teskzhubao` 和配置中的 `teskzhubao.firebasestorage.app`。仅点击 Back Up Now 才上传；没有自动同步。照片先上传，清单最后提交，只有清单存在的快照才能恢复。失败上传会显示为 Incomplete upload，可删除后重试。恢复验证清单、文件大小和 SHA-256，再以新副本一次性写入本地数据库。

## 控制台与签名配置

以下外部状态尚未验证，本地代码接入不表示控制台已配置完成：

1. 在 Firebase Authentication 启用 Google；iOS 客户端及回调 Scheme 已使用工程现有配置。
2. 在 Apple Developer 为现有 Bundle ID `com.szg.AFTesk` 启用 Sign in with Apple，并更新匹配的描述文件。工程只增加了该 capability 和 entitlement，没有更换 Bundle ID、团队或描述文件名称。
3. Apple 原生认证不需要启用 Firebase Apple provider，也不需要向 Firebase 配置 Apple 私钥或服务标识。
4. 确认上述 Storage bucket 已创建并可用。Firebase 当前要求 Cloud Storage 项目使用 Blaze 计划；此任务没有开启计费、创建收费资源或改变预算。
5. 将 [Storage 规则](../firebase/turnscene-backups.storage.rules) 的匹配块合并进现有 bucket rules version 2，核对没有覆盖这些路径的宽松通配规则，再发布。不同 match 的 allow 是“或”关系，已有公共读写规则会使私有规则失效。不要直接覆盖 B 面或其他服务的规则。

## 账户和数据范围

- Google 云备份沿用默认 Firebase Auth，与应用原有 Firebase 登录属于同一账户体系。Apple 原生成功回调与该账户无关联，不改变当前 Firebase 会话。
- Sign Out 与 Delete Account & Cloud Data 固定显示在页面上方；未登录或正在处理请求时禁用。Apple 登录后，退出及确认删除都会清除本地 Apple 登录状态并恢复登录按钮；不会调用 Firebase 删除，也不会注销设备的 Apple ID 或撤销系统端授权。
- 数据路径为 `turnscene-backups/{Firebase UID}/{backup UUID}/`；仅对应 UID 可以读、列举、创建和删除。备份创建后不能覆盖更新。
- 使用认证 SDK 下载，不生成公开下载链接，也不记录登录 token、照片或用户邮箱到日志。
- Delete Backup 删除指定快照。Delete Account & Cloud Data 先用 Google 重新验证身份，删除该 UID 下的全部备份，再删除 Firebase 账户；任何失败都保留可重试状态，不报告已完全删除。默认 Firebase 账户可能同时用于在线页面，删除前界面会告知影响。
- 此客户端只能删除本功能存储的云数据和 Firebase 账户。如果其他后端还持有同一用户的个人数据，需要在实际后端补齐删除联动后再发布完整账户删除功能。管理端直接删号也应配置服务端删除触发器，清理该 UID 的备份。

## 联调

使用支持 Apple 登录的签名真机，验证 Apple 原生授权成功后结束加载并显示 “Backup Successful”，取消或失败不显示成功；关闭再打开页面仍显示已登录，退出或确认删除后恢复未登录界面，系统授权失效后清除本地登录状态。验证 Google 登录与重启后恢复会话；创建含照片的作品及草稿，上传后在另一设备以同一 Google 账户恢复。验证未登录和不同 UID 无法读取、列举或删除别人的备份；断网、取消上传、损坏照片不得产生可恢复的残缺记录；Google 删除账户必须重新验证身份。

本地备份检查：`python3 scripts/verify_crailglitun_backup.py`。云端真实上传和跨设备恢复仍需完成上述控制台配置后验证。

官方参考：[AuthenticationServices](https://developer.apple.com/documentation/authenticationservices)、[Firebase Storage 配置](https://firebase.google.com/docs/storage/ios/start)、[Storage 规则条件](https://firebase.google.com/docs/storage/security/rules-conditions)。
