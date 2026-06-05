# Android 打包速查

## 日常发布（推荐）

真机分发、门店安装，使用 **仅 arm64** 的 Release 包：

```bash
cd happyeat-app
flutter pub get
flutter build apk --release --target-platform android-arm64
```

| 项 | 值 |
| --- | --- |
| 输出文件 | `build/app/outputs/flutter-apk/app-release.apk` |
| 架构 | `arm64-v8a` |
| 典型体积 | ~18MB |
| 适用设备 | 近年绝大多数 Android 手机 |

### 国内网络构建

```powershell
cd happyeat-app
.\scripts\build-apk-cn.ps1
```

脚本等价于：设置 Flutter 国内镜像 + `flutter build apk --release --target-platform android-arm64`。

### 打包时指定正式服务器

```bash
flutter build apk --release --target-platform android-arm64 \
  --dart-define=PROD_API_URL=https://api.yourdomain.com
```

或在 `lib/core/config/api_env_config.dart` 中修改 `productionBaseUrl` 后再执行上述 build 命令。

---

## 命令对照

| 场景 | 命令 |
| --- | --- |
| **真机 APK（推荐）** | `flutter build apk --release --target-platform android-arm64` |
| 按架构拆多个 APK | `flutter build apk --release --split-per-abi` → 装 `app-arm64-v8a-release.apk` |
| 全架构合一（体积大） | `flutter build apk --release` → ~52MB |
| Google Play 上架 | `flutter build appbundle --release` |
| USB 调试安装 | `flutter run --release` |
| 安装已打好的 APK | `adb install build/app/outputs/flutter-apk/app-release.apk` |

---

## 架构说明

Flutter 默认 `flutter build apk --release`（不加参数）会打 **胖 APK**，内含多套原生库：

- `arm64-v8a` — 主流真机（约 17MB 原生库）
- `armeabi-v7a` — 老 32 位 ARM
- `x86_64` — 模拟器 / 少数设备

合计约 **52MB**。业务代码几乎不增加体积，差异来自 CPU 架构数量。

`--target-platform android-arm64` 只保留 arm64，故体积约 **18MB**。

---

## 验证

### APK 里有哪些架构（Windows PowerShell）

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$apk = "build\app\outputs\flutter-apk\app-release.apk"
$zip = [System.IO.Compression.ZipFile]::OpenRead($apk)
$zip.Entries | Where-Object { $_.FullName -match '^lib/([^/]+)/' } |
  ForEach-Object { ($_.FullName -split '/')[1] } | Sort-Object -Unique
$zip.Dispose()
```

`--target-platform android-arm64` 应只看到：`arm64-v8a`。

### 手机 CPU 架构

```bash
adb shell getprop ro.product.cpu.abi
```

结果为 `arm64-v8a` 时，安装 arm64 包即可。

---

## 测试环境（联调）

登录页不展示服务器配置。开发联调：

1. 登录页 **连续点击 H 图标 5 次**（2 秒内）
2. 在「测试环境」对话框输入地址，如 `http://192.168.1.100:8888`
3. 保存后登录；页面会显示「测试环境」标签

正式地址在 `lib/core/config/api_env_config.dart` 的 `productionBaseUrl`。

---

## 环境检查

```bash
flutter doctor
```

Android 工具链为 ✓ 后再打包。
