# 国内环境构建 Release APK（Gradle + Flutter 镜像）
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"

Write-Host "FLUTTER_STORAGE_BASE_URL=$env:FLUTTER_STORAGE_BASE_URL"
Write-Host "PUB_HOSTED_URL=$env:PUB_HOSTED_URL"
Write-Host "Building APK..."

flutter pub get
# 清理跨盘符 Kotlin 增量缓存（Pub 在 C:、项目在 L: 时易残留旧插件路径）
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue
}
# 仅 arm64，体积约 18MB（真机推荐）；全架构合一包约 52MB 见 README
flutter build apk --release --target-platform android-arm64

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
    Write-Host "架构: arm64-v8a（适用于近年绝大多数 Android 手机）"
}
