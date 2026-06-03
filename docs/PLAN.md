# HappyEat App — Flutter 手机点餐端实施计划

> 版本：v1.0  
> 日期：2026-04-27  
> 目标：基于现有 `happyeat` 后端 API，开发面向店员/前厅的移动端点餐 App（参考 Web 点餐台 + 美团/饿了么交互习惯）。

---

## 1. 项目定位


| 维度       | 说明                                         |
| -------- | ------------------------------------------ |
| **产品名**  | HappyEat App（餐饮点餐助手）                       |
| **用户**   | 餐厅店员、收银、服务员（B 端工具，非 C 端顾客自助扫码）             |
| **核心场景** | 选桌 → 浏览菜单 → 加购 → 下单 → 查单 → 跟进出餐状态          |
| **后端**   | 复用 `happyeat` 已有 REST API（`/central/v1`）   |
| **对标**   | Web `OrderDesk` 业务能力 + 美团商家端/饿了么零售的移动端操作效率 |


**与 Web 的差异（刻意优化）：**

- Web：横向 Tabs 分类 + 右侧固定购物车栏（桌面宽屏）
- App：**左侧竖向分类导航** + 右侧菜品列表 + **底部悬浮购物车条**（单手操作、小屏友好）
- Web：管理后台功能多；App：**只保留点餐相关四大 Tab**，不做菜单/权限后台管理

---

## 2. 技术选型


| 类别    | 选型                                                  | 理由                                  |
| ----- | --------------------------------------------------- | ----------------------------------- |
| 框架    | **Flutter 3.x**                                     | 一套代码 iOS/Android，UI 定制能力强           |
| 语言    | **Dart 3**                                          | 与 Flutter 生态一致                      |
| 路由    | **go_router**                                       | 声明式路由，支持深链、登录守卫                     |
| 状态    | **Riverpod 2**                                      | 类型安全、易测、适合 API + 购物车全局态             |
| 网络    | **dio**                                             | 拦截器、JWT、超时、重试                       |
| 本地存储  | **shared_preferences** + **flutter_secure_storage** | Token 安全存储                          |
| JSON  | **freezed** + **json_serializable**                 | 与后端 DTO 对齐、不可变模型                    |
| UI 组件 | **Material 3** + 少量自定义                              | 主色对齐 Web：`#1677ff`（日）/ `#60a5fa`（夜） |
| 图片    | **cached_network_image**                            | 菜单图缓存                               |
| 国际化   | 先 **zh_CN**                                         | 后续可扩展                               |


**最低环境：**

- Flutter SDK ≥ 3.16
- Dart ≥ 3.2
- Android minSdk 21 / iOS 12+

---

## 3. 信息架构（四大 Tab）

```
┌─────────────────────────────────────────┐
│  AppBar（店名 / 当前桌号 / 搜索）          │
├──────┬──────────────────────────────────┤
│ 分类 │  菜品列表（主内容区）               │  ← 默认首页：点餐
│ 导航 │                                   │
│ 栏   │                                   │
├──────┴──────────────────────────────────┤
│  🛒 3件 ¥68.00          [去结算]         │  ← 底部购物车条
├─────────────────────────────────────────┤
│  点餐 │  订单 │  餐桌 │  我的              │  ← BottomNavigationBar
└─────────────────────────────────────────┘
```

### Tab 1：点餐（首页，默认）

**参考：** Web `OrderDesk` + 美团外卖商家「加菜」页


| 区域       | 功能                                                  |
| -------- | --------------------------------------------------- |
| 顶栏       | 门店名、当前订单类型（堂食/外带）、已选桌号快捷入口、菜品搜索                     |
| 左侧分类栏    | 竖向列表，宽 ~72–88dp；首项「全部」；点击切换右侧列表；当前项高亮+指示条           |
| 右侧菜品区    | 列表卡片（图左文右）：名称、价格、规格摘要、数量步进器、「选规格」                   |
| 规格弹层     | BottomSheet：按 `spec_type` 分组单选（辣度/大小/加料），加价展示 `+¥x` |
| 底部购物车条   | 左：件数+合计；右：「去结算」；点击展开购物车抽屉                           |
| 购物车抽屉    | 明细列表、改数量、删项、备注、实收金额（可选）、提交订单                        |
| 可选增强（P2） | 语音点餐（对齐 Web STT，需平台权限）                              |


**交互细节（对标主流 App）：**

- 分类与列表 **联动滚动**：右侧滚动时左侧分类自动高亮（`ScrollablePositionedList` 或锚点 Map）
- 加购成功：**轻微震动 + SnackBar**「已添加 xxx」
- 同菜品不同规格：**购物车合并键** = `menuId + specInfo`（与 Web 一致）
- 价格展示：后端分为单位，App 统一 `分→元` 显示（`¥12.50`）

### Tab 2：订单

**参考：** Web `OrderManage` + 美团「订单」列表


| 功能        | 说明                                 |
| --------- | ---------------------------------- |
| 状态筛选      | 顶部 Chip：全部 / 待处理 / 制作中 / 已完成 / 已取消 |
| 订单卡片      | 单号、桌号、类型、状态 Tag、金额、时间、菜品摘要         |
| 详情页       | 明细项、备注、状态时间线、操作按钮（按权限）             |
| 下拉刷新 + 分页 | 对接 `GET /orders`                   |
| 空态        | 插图 +「暂无订单」                         |


**状态映射（与后端一致）：**


| 后端 status | 展示文案 | 颜色  |
| --------- | ---- | --- |
| created   | 待接单  | 橙   |
| paid      | 已支付  | 蓝   |
| preparing | 制作中  | 紫   |
| completed | 已完成  | 绿   |
| cancelled | 已取消  | 灰   |


### Tab 3：餐桌

**参考：** Web `TableManage` / `TableFloorMap` 简化版


| 功能       | 说明                                       |
| -------- | ---------------------------------------- |
| 视图切换     | 列表 / 网格（按区域分类折叠）                         |
| 桌台卡片     | 桌号、容量、状态（空闲/使用中/预留）、当前订单数                |
| 选桌绑定     | 点击桌台 → 设为「当前桌」→ 回到点餐 Tab 自动带入 `table_id` |
| 扫码入桌（P2） | 解析桌台 `qr_code` 字段                        |
| 筛选       | 按 `category_id`、状态、桌号搜索                  |


**状态色：**

- `free` / 空闲 → 绿
- `occupied` / 使用中 → 红
- 其他 → 灰

### Tab 4：我的


| 功能     | 说明                               |
| ------ | -------------------------------- |
| 用户信息   | 用户名、角色（JWT `role` / `user_code`） |
| 快捷设置   | API 地址（开发态）、主题明/暗、关于             |
| 订单类型默认 | 记住上次「堂食/外带」                      |
| 退出登录   | 清 Token，回登录页                     |
| 版本信息   | App 版本 + 后端 health 检测            |


---

## 4. 后端 API 对接清单

**Base URL：** `{host}/central/v1`  
**鉴权：** `Authorization: Bearer {access_token}`（除登录外）

### 4.1 认证


| 方法   | 路径            | App 用途 |
| ---- | ------------- | ------ |
| POST | `/auth/login` | 登录页    |


### 4.2 点餐核心


| 方法   | 路径                 | App 用途                              |
| ---- | ------------------ | ----------------------------------- |
| GET  | `/menu/categories` | 左侧分类栏                               |
| GET  | `/menus`           | 菜品列表（`category` / `category_id` 筛选） |
| GET  | `/menu/:id`        | 菜品详情（可选）                            |
| GET  | `/tables`          | 餐桌 Tab + 下单选桌                       |
| POST | `/orders`          | 提交订单                                |


**创建订单请求体（与 Web 对齐）：**

```json
{
  "order_type": "dine_in | takeaway",
  "table_id": "123",           // 堂食必填
  "items": [
    {
      "menu_name": "宫保鸡丁",
      "quantity": 2,
      "unit_price": 2800,      // 确认与后端单位：分
      "spec_info": "辣度:中辣 规格:大份"
    }
  ],
  "total_amount": 5600,
  "actual_amount": 5600,
  "remark": "少葱"
}
```

### 4.3 订单


| 方法  | 路径                  | App 用途        |
| --- | ------------------- | ------------- |
| GET | `/orders`           | 订单列表          |
| GET | `/order/:id`        | 订单详情          |
| PUT | `/order/:id/status` | 状态变更（店员权限，P1） |


### 4.4 暂不接入（Web 管理向）

- IAM / RBAC 管理接口（App 只消费登录 Token，不做权限矩阵编辑）
- 菜单/规格 CRUD
- 工作台 `/workbench/orders`（可用订单列表+状态筛选替代）

### 4.5 金额单位约定（实施前必须确认）

- 后端 `menutypes.api` 注明价格为 **分**；Web 前端部分逻辑按 **元** 处理。
- **里程碑 0** 用真实接口跑通一条下单，在 `ApiClient` 层统一 `Money` 工具类，避免 App/Web 不一致。

---

## 5. 项目目录结构（规划）

```
happyeat-app/
├── docs/
│   └── PLAN.md                 # 本文档
├── lib/
│   ├── main.dart
│   ├── app.dart                # MaterialApp + 主题 + 路由
│   ├── core/
│   │   ├── config/             # 环境配置、常量
│   │   ├── network/            # dio、拦截器、ApiClient
│   │   ├── router/             # go_router 定义
│   │   ├── theme/              # 颜色、字号、间距
│   │   └── utils/              # 金额、日期、debounce
│   ├── data/
│   │   ├── models/             # freezed DTO
│   │   ├── repositories/       # MenuRepo、OrderRepo、TableRepo、AuthRepo
│   │   └── local/              # token、preferences
│   ├── features/
│   │   ├── auth/               # 登录
│   │   ├── ordering/           # 点餐首页（分类+列表+购物车）
│   │   ├── orders/             # 订单列表+详情
│   │   ├── tables/             # 餐桌
│   │   └── profile/            # 我的
│   ├── shared/
│   │   ├── widgets/            # 通用组件（价格标签、状态 Chip、空态）
│   │   └── providers/          # 全局：auth、cart、currentTable
│   └── l10n/                   # 文案（可选）
├── assets/
│   └── images/                 # logo、空态插图
├── test/
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

---

## 6. 核心数据模型（Dart）


| 模型                   | 主要字段                                                            |
| -------------------- | --------------------------------------------------------------- |
| `MenuCategory`       | id, name, sort                                                  |
| `Menu`               | id, name, price, categoryId, image, specs[]                     |
| `MenuSpec`           | specType, specValue, priceDelta                                 |
| `Table`              | id, code, status, capacity, categoryId                          |
| `CartItem`           | menuId, name, unitPrice, quantity, specInfo, image              |
| `Order`              | id, orderNo, status, orderType, tableCode, items[], totalAmount |
| `CreateOrderRequest` | 与 API 一致                                                        |


**全局状态：**

- `CartNotifier`：购物车增删改、合计、持久化（进程内）
- `CurrentTableNotifier`：当前选中桌台
- `OrderTypeNotifier`：dine_in / takeaway
- `AuthNotifier`：token、role、登录态

---

## 7. UI/UX 设计规范

### 7.1 视觉（对齐 happyeat-web）


| Token | 值         |
| ----- | --------- |
| 主色    | `#1677FF` |
| 成功    | `#52C41A` |
| 警告    | `#FAAD14` |
| 错误    | `#FF4D4F` |
| 背景    | `#F4F7FB` |
| 卡片圆角  | 12–16dp   |
| 分类栏宽  | 80dp      |


### 7.2 组件清单

- `CategorySidebar` — 左侧分类
- `MenuListItem` — 菜品行
- `SpecPickerSheet` — 规格选择底部弹层
- `CartBar` — 底部购物车条
- `CartSheet` — 购物车详情
- `OrderCard` — 订单卡片
- `TableGridTile` — 桌台格子
- `StatusChip` — 订单/桌台状态
- `MoneyText` — 统一金额展示

### 7.3 手势与反馈

- 列表下拉刷新
- 购物车抽屉拖拽关闭
- 提交订单：全屏 Loading + 成功跳转订单详情
- 网络错误：顶部 Banner + 重试按钮

---

## 8. 开发阶段与里程碑

### 阶段 0：工程初始化（1–2 天）

- `flutter create happyeat_app` 并迁入 `happyeat-app/`
- 配置 `pubspec.yaml` 依赖
- 主题、路由骨架、环境配置（dev/prod baseUrl）
- dio + JWT 拦截器 + 401 跳登录
- 健康检查 `GET /health`

**交付：** 可启动空壳 App，能 ping 通后端

---

### 阶段 1：认证 + 点餐主流程 MVP（5–7 天）

- 登录页（dev 账号提示：admin / admin123）
- 底部 4 Tab 导航
- 点餐页：分类栏 + 菜品列表 + 搜索
- 规格选择 + 加购物车
- 底部购物车条 + 抽屉
- 选桌（简易 BottomSheet）+ 堂食/外带切换
- 提交订单 `POST /orders`

**交付：** 完成「登录 → 点菜 → 下单」闭环

---

### 阶段 2：订单 + 餐桌（3–4 天）

- 订单列表（分页、状态筛选）
- 订单详情页
- 餐桌列表/网格 + 选桌绑定全局态
- 点餐页顶栏显示当前桌号

**交付：** 四大 Tab 功能完整可用

---

### 阶段 3：体验打磨（3–4 天）

- 分类-列表联动滚动
- 骨架屏 / 加载态 / 空态 / 错误态
- 暗色主题（可选）
- 订单状态变更（若账号有权限）
- 备注、实收金额（对齐 Web）
- 基本 widget 测试 + 1–2 条集成测试

**交付：** 可给店员试用的 Beta 版

---

### 阶段 4：增强（按需）

- 扫码绑定桌台（`mobile_scanner`）
- 语音点餐（平台 STT）
- 离线菜单缓存
- 推送通知（订单状态）
- iOS / Android 打包签名、内测分发

---

## 9. 页面线框（文字版）

### 9.1 登录

```
┌─────────────────────┐
│      HappyEat       │
│   餐饮点餐助手       │
│  ┌───────────────┐  │
│  │ 用户名         │  │
│  └───────────────┘  │
│  ┌───────────────┐  │
│  │ 密码           │  │
│  └───────────────┘  │
│  [ 服务器地址 ⚙ ]    │  ← 仅 debug
│     [ 登 录 ]        │
└─────────────────────┘
```

### 9.2 点餐首页

```
┌──────────────────────────────────┐
│ 快乐餐厅  │ 堂食·A12桌 ▼  │ 🔍   │
├────┬─────────────────────────────┤
│全部 │ ┌────┐ 宫保鸡丁           │
│热菜 │ │图片│ ¥28  [−] 1 [+]     │
│凉菜 │ └────┘ [选规格]           │
│主食●│ ┌────┐ 鱼香肉丝           │
│饮品 │ │图片│ ¥22  [−] 0 [+]     │
├────┴─────────────────────────────┤
│ 🛒 已选 3 件  ¥78.00   [去结算]  │
├──────────────────────────────────┤
│ 点餐● │ 订单 │ 餐桌 │ 我的        │
└──────────────────────────────────┘
```

### 9.3 购物车抽屉

```
┌──────────────────────────────────┐
│ 购物车                    [清空]  │
│ 宫保鸡丁 中辣大份    ¥32  [−][2][+]│
│ 可乐                ¥6   [−][1][+]│
│ ─────────────────────────────── │
│ 备注 [________________]          │
│ 实收 ¥[38.00]                    │
│ 合计 ¥38.00                      │
│        [ 确认下单 ]               │
└──────────────────────────────────┘
```

---

## 10. 风险与对策


| 风险              | 对策                                                       |
| --------------- | -------------------------------------------------------- |
| 金额单位不一致         | 阶段 0 用 Postman/真机打一条订单验证                                 |
| Casbin 权限导致 403 | App 使用有 `order_desk:create` / `orders:view` 的账号；403 友好提示 |
| 真机访问 localhost  | 默认 baseUrl 用电脑局域网 IP；设置页可改                               |
| 菜单图跨域/HTTPS     | 图片加载失败占位图（Web 已有同样处理）                                    |
| 分类过多左侧栏过长       | 独立滚动 + 选中项自动 scrollIntoView                              |


---

## 11. 验收标准（V1）

1. 店员可登录并 4 Tab 切换流畅
2. 点餐页左侧分类、右侧列表、底部购物车与 Web 业务能力一致
3. 可选桌台完成堂食下单，外带可不选桌
4. 订单 Tab 可查看历史订单及详情
5. 餐桌 Tab 可选桌并反映到点餐页
6. 我的 Tab 可退出登录、配置服务地址（调试）
7. Android 真机连接局域网后端完整跑通

---

## 12. 下一步行动（确认计划后执行）

1. 执行 `flutter create` 初始化工程
2. 搭建 `core/network` + `go_router` + 登录页
3. 实现 **阶段 1 MVP**（点餐闭环优先）
4. 联调时对照 `happyeat-web/src/pages/OrderDesk.tsx` 逐项对齐业务规则

---

## 附录 A：与 happyeat-web 功能映射


| Web 页面                          | App Tab/页面 | 说明            |
| ------------------------------- | ---------- | ------------- |
| OrderDesk                       | 点餐         | 核心对齐，布局改为移动端  |
| OrderManage                     | 订单         | 只读+状态操作，无批量导出 |
| TableManage / TableFloorMap     | 餐桌         | 简化为选桌，不做 CRUD |
| Login                           | 登录         | 一致            |
| Home / Workbench / MenuManage 等 | 不实现        | 管理类留在 Web     |


## 附录 B：建议 pubspec 依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  dio: ^5.4.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  cached_network_image: ^3.3.1
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.8
  freezed: ^2.4.7
  json_serializable: ^6.7.1
  flutter_test:
    sdk: flutter
```

---

*文档维护：随开发进展更新 checkbox 与 API 变更。*