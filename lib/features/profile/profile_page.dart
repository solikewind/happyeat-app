import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/api_env_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/api_env_switch.dart';
import '../../shared/widgets/app_brand_avatar.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _urlCtrl = TextEditingController();
  bool? _healthOk;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlCtrl.text = ref.read(settingsProvider).apiBaseUrl;
      _checkHealth();
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    try {
      final client = ref.read(apiClientProvider);
      final ok = await client.checkHealth();
      if (mounted) setState(() => _healthOk = ok);
    } catch (_) {
      if (mounted) setState(() => _healthOk = false);
    }
  }

  Future<void> _saveUrl() async {
    await ref.read(settingsProvider.notifier).persistBaseUrl(_urlCtrl.text);
    ref.invalidate(apiClientProvider);
    await _checkHealth();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('服务器地址已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const AppBrandAvatar(size: 48, borderRadius: 18),
              title: const Text('店员账号'),
              subtitle: Text('角色：${auth.role ?? '—'}'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    '经营统计',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('每日销量、营业额与菜品明细'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/sales-stats'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.success,
                    ),
                  ),
                  title: const Text(
                    '菜单管理',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('添加、修改菜品与封面'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/menu-manage'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '服务器设置',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ApiEnvSwitch(
                    urlController: _urlCtrl,
                    onUrlSynced: () {
                      ref.invalidate(apiClientProvider);
                      _checkHealth();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlCtrl,
                    decoration: InputDecoration(
                      hintText: ApiEnvConfig.productionBaseUrl,
                      suffixIcon: _healthOk == null
                          ? null
                          : Icon(
                              _healthOk! ? Icons.check_circle : Icons.error,
                              color: _healthOk!
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '当前：${settings.apiBaseUrl}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _checkHealth,
                        child: const Text('检测连接'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saveUrl,
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('关于'),
                  subtitle: Text('HappyEat App v1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    '退出登录',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () => ref.read(authProvider.notifier).logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
