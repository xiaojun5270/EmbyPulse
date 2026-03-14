# EmbyPulse iOS

SwiftUI (iOS 16+) 客户端骨架，当前已实现：

- 登录（对接 `/api/login`）
- Dashboard 基础数据（`/api/stats/dashboard`）
- 实时播放列表（`/api/stats/live`）
- 追剧日历（`/api/calendar/weekly`）
- 日历缓存配置（`/api/calendar/config`，TTL 调整）
- 求片工单管理（`/api/manage/requests` + `/api/manage/requests/action`）
- 求片工单批量操作（`/api/manage/requests/batch`）
- 用户侧求片（登录、热门、搜索、选季提交、我的记录）
- 邀请码注册（`/api/register`，返回推荐访问地址与欢迎语）
- 用户侧报错反馈（提交 + 我的反馈追踪）
- 管理端反馈工单（筛选、单条/批量处理）
- 用户管理（用户创建/启停用/续期/到期日/重置密码/删除）
- 邀请码管理（生成、列表、删除、批量删除）
- 播放历史（`/api/history/list`，支持筛选与分页）
- 数据趋势图（`/api/stats/trend`，Swift Charts 渲染）
- 高级统计洞察（热门内容/活跃用户/月度趋势/勋章/设备偏好/最近动态/最新入库/媒体库）
- 媒体库搜索（`/api/library/search`）
- 客户端管控（黑名单、设备统计、阻断执行）
- 质量盘点/洞察（`/api/insight/quality` + 忽略回收站管理）
- Bot/通知配置（Telegram + 企业微信 + Webhook 地址管理）
- 系统设置中心（`/api/settings` + TMDB/MP 测试 + 数据库体检修复）
- 任务中心（`/api/tasks` + 启停 + 任务别名）
- 报表工坊（`/api/report/preview` + `/api/report/push` + 统计摘要）
- 本地服务地址配置与会话退出

## 生成项目

```bash
cd ios_app
xcodegen generate
```

## 构建

```bash
xcodebuild -project EmbyPulseiOS.xcodeproj -scheme EmbyPulseiOS -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
```

## 联调自测

- 手工联调清单：`docs/integration-self-test.md`
- API 冒烟脚本：`scripts/api_smoke_test.sh`

只读冒烟示例：

```bash
BASE_URL=http://127.0.0.1:10307 ADMIN_USER=admin ADMIN_PASS=yourpass \
./scripts/api_smoke_test.sh
```

包含写操作（可选）：

```bash
RUN_MUTATING=1 BASE_URL=http://127.0.0.1:10307 ADMIN_USER=admin ADMIN_PASS=yourpass \
./scripts/api_smoke_test.sh
```
