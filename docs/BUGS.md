# HappyEat Bug 记录

> 全栈项目（Flutter App + Go 后端）线上/联调中发现的问题与修复记录。  
> **用途**：排障留痕、回归参考、**面试时讲「真实踩坑与排查过程」**。  
> 新 Bug 修复后请按下方模板追加一条，不要另开文件。

---

## 索引

| ID | 日期 | 模块 | 标题 | 状态 |
|----|------|------|------|------|
| BUG-001 | 2026-06 | App · Shell | Tab 切换同步 Riverpod 报错 | 已修复 |
| BUG-002 | 2026-06 | App · 加菜 | 规格加价（如 +1 元）加菜后订单未加价 | 已修复 |
| BUG-003 | 2026-06 | App · 菜单图 | 菜单封面滑到才加载、签名 URL 导致缓存失效 | 已优化 |
| BUG-004 | 2026-06 | App · 点餐 | 堂食新单下单后购物车清空但桌台仍保留 | 已修复 |
| BUG-005 | 2026-06 | App · 会话 | 登出 / 退出加菜后会话状态未清空 | 已修复 |

---

## 记录模板（复制使用）

```markdown
### BUG-XXX · 简短标题

- **日期**：
- **模块**：App / 后端 / Web / 全栈
- **现象**：（用户看到什么）
- **复现**：（最少步骤）
- **根因**：（技术原因，1～3 句）
- **修复**：（改了哪些文件/接口，要点即可）
- **验证**：（怎么确认修好）
- **面试可讲**：（排查思路、设计教训、为什么这样修）
```

---

## BUG-001 · Tab 切换同步 Riverpod 报错

- **日期**：2026-06
- **模块**：App · `main_shell.dart`
- **现象**：切换底栏 Tab 时偶发红屏，Riverpod 提示在 widget 生命周期内非法修改 provider。
- **复现**：底栏切换 Tab，`MainShell` 的 `didUpdateWidget` 里直接写 `shellTabIndexProvider`。
- **根因**：在 `didUpdateWidget` 同步阶段触发 provider 更新，Riverpod 不允许在 build/layout 过程中改状态。
- **修复**：将 `_syncTabIndex()` 放到 `WidgetsBinding.instance.addPostFrameCallback`，等当前帧结束再同步索引。
- **验证**：快速切换点餐/订单/厅面/我的，无红屏。
- **面试可讲**：
  - Flutter 生命周期 vs 状态管理框架约束；
  - 「UI 驱动状态」和「状态驱动 UI」的边界；
  - 用 post-frame 延迟是常见解法，但要避免一帧内 UI 与 state 不一致的闪烁（本场景可接受）。

**相关文件**：`lib/features/shell/main_shell.dart`

---

## BUG-002 · 加菜时规格加价未计入订单单价

- **日期**：2026-06
- **模块**：全栈 · 加菜 / 改单（`PUT /order/:id`）
- **现象**：选带「+1 元」规格的菜品加菜，购物车显示价格正确，提交后订单明细仍是基础价，少 1 元。
- **复现**：
  1. 打开进行中订单 → 加菜；
  2. 选有规格加价的菜（如 +1 元）；
  3. 确认加菜 → 看订单详情该行 `unit_price`。
- **根因**（双端）：
  1. **App**：`OrderUpdateItems.toJson()` 在有 `menu_id` 时只提交 `menu_id`、`quantity`、`spec_info`，**未提交**含规格加价的 `unit_price`；
  2. **后端**：`updateorderlogic.go` 收到 `menu_id` 后固定用 `menuEnt.Price`（基础价），**忽略**规格 `price_delta` 与客户端单价。
  - 对比：**新下单** `POST /orders` 会传 `unit_price`，所以仅「加菜/改单」路径有问题。
- **修复**：
  1. **App** `lib/shared/utils/order_update_items.dart`：有 `menu_id` 时一并提交 `unit_price`（购物车已算好基础价 + 规格加价）；
  2. **后端** `app/internal/logic/order/menuitemprice.go` + `updateorderlogic.go`：
     - 优先使用客户端 `unit_price`（> 0）；
     - 否则按 `spec_info`（如 `辣度:微辣 份量:大份`）匹配菜单规格，累加 `price_delta`。
- **验证**：
  - 选 +1 元规格加菜 → 订单行单价 = 基础价 + 1；
  - 改单后总金额、厨房小票与购物车一致；
  - `go test ./internal/logic/order/ -run MenuUnitPrice` 通过。
- **面试可讲**：
  - **前后端契约不一致**：同一业务（行单价）在「创建」与「更新」两条 API 路径上行为不同，属于典型集成 Bug；
  - **排查方法**：对比购物车（客户端正确）→ 请求体（缺字段）→ 后端分支（只用 menu 表价）；
  - **修复策略**：客户端传权威单价 + 服务端按 spec 兜底，避免只信一端；
  - 可延伸：金额应用整数分、幂等、改单 diff 打印（本项目厨房打印已有 diff 逻辑）。

**相关文件**：

- App：`lib/shared/utils/order_update_items.dart`、`lib/features/ordering/ordering_page.dart`（加购时 `priceDelta` 计算）
- 后端：`app/internal/logic/order/updateorderlogic.go`、`app/internal/logic/order/menuitemprice.go`

---

## BUG-003 · 菜单封面滑到才出现 / 重复下载

- **日期**：2026-06
- **模块**：App · 点餐列表
- **现象**：菜单图片要滑到可见才加载；来回滚动像「没缓存」，反复空白再出来。
- **复现**：进入点餐页，快速上下滑菜单列表；或刷新菜单后再次进入。
- **根因**：
  1. `ListView` 懒加载，条目进屏才开始请求（预期行为）；
  2. 后端 COS **签名 URL** 约 10 分钟过期，默认按 URL 做缓存 key，刷新菜单后 URL 变化 → **缓存 miss**，同一张图重复下载；
  3. 原图分辨率远大于 84×84 展示尺寸，解码慢。
- **修复**（`lib/shared/widgets/menu_cover_image.dart`）：
  - 稳定 `cacheKey`（`menu.id` / `object_id`）；
  - `memCacheWidth` / `maxWidthDiskCache` 按展示尺寸解码；
  - 菜单拉取后 `warmCache` 预加载前若干张。
- **验证**：同一菜品第二次滚入应秒出；弱网下先占位再淡入。
- **面试可讲**：
  - 移动端列表性能：懒加载 + 预加载平衡；
  - CDN/签名 URL 对客户端缓存的影响；
  - 用 cacheKey 与尺寸限制解耦「URL 变但内容不变」的问题。

**相关文件**：`lib/shared/widgets/menu_cover_image.dart`、`lib/features/ordering/ordering_page.dart`

---

## BUG-004 · 堂食新单下单后桌台未清空

- **日期**：2026-06
- **模块**：App · 点餐 / 购物车
- **现象**：堂食下单成功，购物车已空，顶部仍显示上一单的桌台（如「大厅-A1」），下一单容易误用同一桌。
- **复现**：堂食选桌 → 加菜 → 确认下单 → 回到点餐页或看顶栏桌台 chip。
- **根因**：`currentTableProvider` 仅在 `cart_sheet` 内清一次；弹窗关闭 / 切 Tab 时机下，点餐页 `OrderModeBar` 偶发未同步，或旧包未包含清桌逻辑。
- **修复**：
  - 抽取 `clearSelectedTable(ref)`；
  - 下单成功后在购物车 + **点餐页回调** 双处清桌，并 `postFrameCallback` 再清一次；
  - 跳转订单 Tab 改用 `StatefulNavigationShell.goBranch`。
- **验证**：堂食新单下单后顶栏显示「选餐桌」；加菜模式下单后桌台不变。
- **面试可讲**：全局 UI 状态要在「拥有该 UI 的页面」和「提交组件」两侧同步；异步 + 弹窗场景用 post-frame 兜底。

**相关文件**：`lib/shared/providers/app_providers.dart`、`lib/features/ordering/widgets/cart_sheet.dart`、`lib/features/ordering/ordering_page.dart`

---

## BUG-005 · 登出 / 退出加菜后会话状态未清空

- **日期**：2026-06
- **模块**：App · 认证 / 加菜 / 点餐会话
- **现象**：
  1. 退出登录后重新登录，购物车、桌台、加菜模式仍保留上一账号（或上一操作）的状态；
  2. 从订单进入加菜模式后点「退出」，顶栏仍显示原单桌台，容易误开新单到错误桌。
- **复现**：
  1. 选桌加菜 → 我的 → 退出登录 → 换账号登录 → 点餐页仍见旧购物车/桌台；
  2. 订单详情 → 加菜 → 顶栏出现桌台 → 点「退出」→ 桌台 chip 仍在。
- **根因**：
  1. `authProvider.logout()` 只清 token，未重置 `cartProvider` / `currentTableProvider` / `addToOrderProvider`；
  2. `AddToOrderBanner` 退出时只清购物车和加菜会话，未清 `currentTableProvider`（加菜流程会从原单同步桌台）。
- **修复**：
  1. 新增 `clearOrderingSession(ref)`，统一清购物车、桌台、加菜模式，并将订单类型恢复为堂食；
  2. `app.dart` 监听 `authProvider`：从已登录变为未登录时调用（覆盖手动退出与 401）；
  3. 加菜顶栏「退出」改为调用 `clearOrderingSession`。
- **验证**：
  - 有购物车/选桌/加菜模式中退出登录 → 再登录后会话为空；
  - 加菜模式点「退出」→ 顶栏显示「选餐桌」。
- **面试可讲**：
  - 认证状态与业务会话状态要分离，但登出时必须一并重置业务态；
  - 用 `authProvider` 监听比在 `logout()` 里散落清理更稳（401 与手动退出同一路径）；
  - 加菜会「借用」桌台 UI，退出路径要与进入路径对称清理。

**相关文件**：`lib/shared/providers/app_providers.dart`、`lib/app.dart`、`lib/features/ordering/widgets/add_to_order_banner.dart`

---

## 待记录 / 已知限制

| 说明 | 备注 |
|------|------|
| 经营统计无专用 API | 客户端分页拉订单后聚合；订单量大时可能慢 |
| 已完成订单「删除」 | 依赖后端状态机 `completed → cancelled`，需部署对应版本 |
| iOS 桌面图标 | 当前主要维护 Android 矢量启动图 |

---

## 维护约定

1. 每修一个 Bug，在 **索引表** 加一行，在正文按模板写一节。
2. ID 递增：`BUG-004`、`BUG-005` …
3. 写清 **现象 → 根因 → 修复 → 验证**，面试只讲第三节也能讲完整。
4. 全栈 Bug 同时写 App 与后端路径，方便对照 PR。
