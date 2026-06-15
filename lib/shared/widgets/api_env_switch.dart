import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_env_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_providers.dart';

/// 正式环境 / 本地测试 切换条（登录页、我的页共用）
class ApiEnvSwitch extends ConsumerWidget {
  const ApiEnvSwitch({
    super.key,
    this.urlController,
    this.onUrlSynced,
  });

  /// 切换后同步到地址输入框
  final TextEditingController? urlController;
  final VoidCallback? onUrlSynced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final env = settings.env;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ApiEnvironment>(
          segments: const [
            ButtonSegment(
              value: ApiEnvironment.production,
              label: Text('正式环境'),
              icon: Icon(Icons.cloud_outlined),
            ),
            ButtonSegment(
              value: ApiEnvironment.local,
              label: Text('本地测试'),
              icon: Icon(Icons.developer_mode_outlined),
            ),
          ],
          selected: env == ApiEnvironment.custom ? {} : {env},
          onSelectionChanged: (selected) async {
            if (selected.isEmpty) return;
            final next = selected.first;
            await ref.read(settingsProvider.notifier).switchEnvironment(next);
            urlController?.text = ref.read(settingsProvider).apiBaseUrl;
            onUrlSynced?.call();
          },
        ),
        if (env != ApiEnvironment.production) ...[
          const SizedBox(height: 6),
          Text(
            env == ApiEnvironment.custom
                ? '当前为自定义地址（与预设环境不一致）'
                : '当前：${ApiEnvConfig.envLabel(env)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
