import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_env_config.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/app_providers.dart';

/// 登录页隐藏入口：连点顶部品牌图标 5 次后打开，配置测试服务器地址。
Future<void> showLoginTestEnvDialog(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  final urlCtrl = TextEditingController(text: settings.apiBaseUrl);

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.developer_mode_outlined, color: AppColors.warning),
          SizedBox(width: 8),
          Text('测试环境'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '仅供开发/联调使用。保存后本次登录将连接该地址。',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                labelText: '测试服务器地址',
                hintText: 'http://192.168.1.100:8888',
                helperText: ApiEnvConfig.localHelperText(),
                helperMaxLines: 3,
                filled: true,
                fillColor: AppStyles.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    urlCtrl.text = ApiEnvConfig.localBaseUrl;
                  },
                  child: const Text('填入本地默认'),
                ),
                OutlinedButton(
                  onPressed: () {
                    urlCtrl.text = AppConfig.defaultApiBaseUrl;
                  },
                  child: const Text('恢复正式环境'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('保存'),
        ),
      ],
    ),
  );

  if (saved != true) {
    urlCtrl.dispose();
    return;
  }

  final url = urlCtrl.text.trim();
  urlCtrl.dispose();
  if (url.isEmpty) return;

  await ref.read(settingsProvider.notifier).persistBaseUrl(url);
  if (context.mounted) {
    final env = ref.read(settingsProvider).env;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切换为 ${ApiEnvConfig.envLabel(env)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

bool isLoginTestEnvironment(SettingsState settings) {
  return settings.env != ApiEnvironment.production;
}
