# HappyEat App

基于 Flutter 的餐饮点餐移动端，对接 [happyeat](../happyeat) 后端 API。

## 功能


| Tab | 说明                          |
| --- | --------------------------- |
| 点餐  | 首页选桌（堂食/外带）+ 分类菜品 + 购物车；堂食首次进入自动弹出选桌 |
| 订单  | 订单列表、筛选、详情                  |
| 厅面  | 桌台状态看板（空闲/使用中/预留/清洁）+ 进行中订单；**选桌仅在点餐页** |
| 我的  | 服务器地址、健康检查、退出登录             |


## 快速开始

### 1. 启动后端

在 `happyeat` 项目根目录**先迁移数据库、再启动服务**（未迁移时点餐页拉菜单会返回 500）：

```bash
cd ../happyeat
make migrate
make run
```

服务默认监听 `http://0.0.0.0:8888`，接口前缀 `/central/v1`。

### 2. 配置 API 地址（正式 / 本地切换）

**默认连正式服务器**：修改 `lib/core/config/api_env_config.dart` 里的 `productionBaseUrl`（把 `http://YOUR_SERVER_HOST:8888` 改成你的域名或 IP）。

也可用编译参数（无需改代码）：

```bash
flutter run --dart-define=PROD_API_URL=https://api.yourdomain.com
flutter build apk --release --dart-define=PROD_API_URL=https://api.yourdomain.com
```

登录页、**我的** 页顶部有 **「正式环境 | 本地测试」** 分段按钮，一键切换地址；仍可手动改下方输入框（会记为「自定义」）。

| 环境 | 默认地址 |
| --- | --- |
| 正式环境 | `productionBaseUrl`（你配置的服务器） |
| 本地测试 | Android 模拟器 `http://10.0.2.2:8888`；真机请在 `api_env_config.dart` 填 `localDevOverride` 或 `--dart-define=LOCAL_API_URL=http://192.168.x.x:8888` |

### 3. 运行 App

```bash
cd happyeat-app
flutter pub get
flutter run
```

默认账号：`admin` / `admin123`（与后端开发登录一致）

## 真机打包与安装（Android）

### 环境准备

1. 安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)（Windows 建议勾选 Android 工具链）。
2. 终端执行 `flutter doctor`，按提示安装 Android SDK / 接受协议，直到 Android 一项为 ✓。
3. 手机：**设置 → 开发者选项 → 打开 USB 调试**（不同品牌路径略有差异）。

### 让手机能访问电脑上的后端

1. 电脑与手机连**同一 Wi‑Fi**。
2. 在项目根目录启动后端（监听 `0.0.0.0:8888`，见上文 `make run`）。
3. 查电脑局域网 IP（PowerShell）：
   ```powershell
   ipconfig
   ```
   记下当前 Wi‑Fi 的 **IPv4 地址**，例如 `192.168.1.100`。
4. 若手机浏览器打不开 `http://192.168.1.100:8888/health`，在 Windows **防火墙** 中为 8888 端口放行，或临时允许 `go run` 进程入网。
5. App 登录页「服务器地址」填：`http://192.168.1.100:8888`（不要用 `localhost` / `127.0.0.1`）。

### 方式 A：USB 直连调试（改代码最快）

```bash
cd happyeat-app
flutter pub get
flutter devices          # 确认能看到你的手机
flutter run --release    # 或省略 --release 用调试版
```

首次会在手机上安装调试包；之后改代码可继续 `flutter run`。

### 方式 B：打出 APK 安装包（发给他人或离线安装）

```bash
cd happyeat-app
flutter pub get
flutter build apk --release
```

产物路径：

`build/app/outputs/flutter-apk/app-release.apk`

安装方式任选其一：

- 数据线：`adb install build/app/outputs/flutter-apk/app-release.apk`
- 把 APK 拷到手机，在文件管理器中点击安装（需允许「未知来源」）。

体积更小可分 ABI 打包（多数手机用 arm64）：

```bash
flutter build apk --release --split-per-abi
```

会生成 `app-arm64-v8a-release.apk` 等，一般装 **arm64-v8a** 即可。

### 方式 C：上架用 AAB（Google Play）

```bash
flutter build appbundle --release
```

输出：`build/app/outputs/bundle/release/app-release.aab`

### iOS 真机（需 macOS + Xcode）

```bash
cd happyeat-app
flutter build ios --release
```

在 Xcode 打开 `ios/Runner.xcworkspace`，配置签名 Team 后 **Product → Archive** 安装到 iPhone。服务器地址同样使用电脑局域网 IP（不是 `127.0.0.1`）。

## 项目结构

```
lib/
├── core/          # 配置、网络、路由、主题
├── data/          # 模型、仓储、本地存储
├── features/      # 登录、点餐、订单、餐桌、我的
└── shared/        # 全局状态、通用组件
```

## 文档

- [实施计划详单](docs/PLAN.md)

## 技术栈

Flutter · Riverpod · go_router · dio