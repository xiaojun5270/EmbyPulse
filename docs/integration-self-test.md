# EmbyPulse iOS 全模块联调自测清单

适用版本：
- iOS App: 当前 `ios_app` 主干版本（iOS 16.0+）
- Backend: Emby Pulse 当前部署版本

## 1. 联调准备

必备信息：
- `BASE_URL`：后端地址（例如 `http://192.168.1.10:10307`）
- Emby 管理员账号：用于 App 主登录
- 普通用户账号：用于“用户侧求片/报错”验证
- 至少 1 个有效邀请码：用于 `/api/register` 链路

推荐预置数据：
- 至少 1 条求片工单（含不同状态：待处理/处理中/已完成/已拒绝）
- 至少 1 条反馈工单
- 至少 1 周追剧日历数据
- 至少 1 个月播放历史数据（便于趋势图验证）

## 2. 执行顺序（建议）

1. 登录与会话
2. Dashboard / 日历
3. 工单（单条 + 批量）
4. 用户侧求片 / 报错
5. 用户管理 / 邀请码
6. 历史与趋势
7. 工具页全量（高级统计、质量洞察、客户端、Bot、系统设置、任务、报表）
8. 设置页（保存地址、退出）

## 3. 模块检查项

### 3.1 登录与邀请码注册

- 页面：`LoginView`
- 接口：
  - `POST /api/login`
  - `POST /api/register`

检查项：
- 输入空用户名/空密码时，登录按钮后应提示校验错误。
- 管理员账号登录成功后进入主 Tab。
- 错误密码时展示后端错误文案。
- 点击“邀请码注册账号”进入注册页。
- 注册成功后，展示 `welcome_message`，并可“一键回填登录信息”回到登录页。
- 注册时密码与确认密码不一致，需阻止提交。

异常覆盖：
- `BASE_URL` 填错：应出现网络错误，不崩溃。
- 邀请码无效：展示后端错误。

### 3.2 概览与日历

- 页面：`DashboardView` / `CalendarView`
- 接口：
  - `GET /api/stats/dashboard`
  - `GET /api/stats/live`
  - `GET /api/calendar/weekly`
  - `POST /api/calendar/config`

检查项：
- Dashboard 数据正确加载，刷新按钮可重复请求。
- 日历支持上一周/下一周/本周切换。
- 日历空日期显示“当天暂无更新”。
- 修改 TTL 后点“保存缓存配置”，提示成功并刷新周数据。

异常覆盖：
- 后端返回 `error` 字段时，页面应显示错误段落。

### 3.3 求片工单（管理端）

- 页面：`RequestsView`
- 接口：
  - `GET /api/manage/requests`
  - `POST /api/manage/requests/action`
  - `POST /api/manage/requests/batch`

检查项：
- 按状态筛选（待处理/处理中/已结束/全部）结果正确。
- 单条工单 approve/manual/finish/reject/delete 正常。
- 批量能力：
  - 全选当前筛选
  - 多选后执行 approve/manual/finish/delete
  - 批量拒绝可填写拒绝理由
- 批量完成后列表刷新、选择状态回收。

异常覆盖：
- 未选择任何工单时执行批量操作，应提示“请先选择工单”。

### 3.4 用户侧求片 + 报错

- 页面：`RequestPortalView`
- 接口：
  - `POST /api/requests/auth`
  - `GET /api/requests/check`
  - `POST /api/requests/logout`
  - `GET /api/requests/trending`
  - `GET /api/requests/search`
  - `GET /api/requests/tv/{tmdb_id}`
  - `POST /api/requests/submit`
  - `GET /api/requests/my`
  - `POST /api/requests/feedback/submit`
  - `GET /api/requests/feedback/my`

检查项：
- 普通用户登录求片系统成功后可查看热门内容。
- 搜索资源成功，电影/剧集信息显示正常。
- 剧集提交时可选季；全在库时禁止提交。
- “我的求片记录”能查看状态和拒绝原因。
- 报错提交成功后能在“我的报错记录”看到。

### 3.5 反馈工单（管理端）

- 页面：`FeedbackAdminView`
- 接口：
  - `GET /api/manage/feedback`
  - `POST /api/manage/feedback/action`
  - `POST /api/manage/feedback/batch`

检查项：
- 筛选、单条处理、批量处理正常。
- 批量选择后执行状态变更成功并刷新。

### 3.6 用户管理 + 邀请码管理

- 页面：`UserManagementView`
- 接口：
  - `GET /api/manage/users`
  - `POST /api/manage/user/new`
  - `POST /api/manage/user/update`
  - `POST /api/manage/users/batch`
  - `DELETE /api/manage/user/{id}`
  - `POST /api/manage/invite/gen`
  - `GET /api/manage/invites`
  - `POST /api/manage/invites/batch`

检查项：
- 用户创建、禁用/启用、续期、删除流程正常。
- 邀请码可生成、可查询、可批量删除。

### 3.7 历史与趋势

- 页面：`HistoryTrendView`
- 接口：
  - `GET /api/users`
  - `GET /api/history/list`
  - `GET /api/stats/trend`

检查项：
- 历史列表分页“加载更多”正常。
- 按用户/关键词筛选生效。
- 日/周/月趋势图可切换并刷新。

### 3.8 工具页全量

- 页面：`UtilitiesHomeView` 下各模块

接口覆盖：
- 高级统计洞察：
  - `GET /api/stats/top_movies`
  - `GET /api/stats/top_users_list`
  - `GET /api/stats/badges`
  - `GET /api/stats/user_details`
  - `GET /api/stats/monthly_stats`
  - `GET /api/stats/recent`
  - `GET /api/stats/latest`
  - `GET /api/stats/libraries`
- 质量盘点/洞察：
  - `GET /api/insight/quality`
  - `GET /api/insight/ignores`
  - `POST /api/insight/ignore_batch`
  - `POST /api/insight/unignore_batch`
- 客户端管控：
  - `GET/POST/DELETE /api/clients/blacklist`
  - `GET /api/clients/data`
  - `POST /api/clients/execute_block`
- Bot/通知配置：
  - `GET/POST /api/bot/settings`
  - `POST /api/bot/test`
  - `POST /api/bot/test_wecom`
- 媒体库搜索：
  - `GET /api/library/search`
- 系统设置中心：
  - `GET/POST /api/settings`
  - `POST /api/settings/test_tmdb`
  - `POST /api/settings/test_mp`
  - `POST /api/settings/fix_db`
- 任务中心：
  - `GET /api/tasks`
  - `POST /api/tasks/translate`
  - `POST /api/tasks/{id}/start`
  - `POST /api/tasks/{id}/stop`
- 报表工坊：
  - `GET /api/stats/poster_data`
  - `POST /api/report/push`

检查项：
- 每个工具页均可进入、刷新、空态文案正确、错误态不崩溃。
- 所有“保存/执行/测试”按钮点击后有明确成功或失败反馈。

### 3.9 设置页

- 页面：`SettingsView`
- 检查项：
  - 服务地址保存后重开页面仍显示最新值
  - 退出登录后回到登录页

## 4. 快速回归（重点）

本轮新增能力重点回归：
- 高级统计洞察：切换用户/分类/排序/周期是否稳定刷新。
- 邀请码注册：成功后回填登录信息是否正确。
- 工单批量操作：多选状态与筛选切换后是否正确回收。
- 日历 TTL：保存后是否触发刷新、且 `current_ttl` 与选择一致。

## 5. 结果记录模板

建议记录：
- 通过：模块名 + 时间 + 环境
- 失败：模块名 + 操作步骤 + 请求参数 + 错误文案 + 截图
- 阻塞：后端数据不足/账号权限不足/网络波动
