import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/settlement_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/table_repository.dart';
import 'settings_provider.dart';

/// 401 时递增，由 App 监听后执行 logout。
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  final settings = ref.watch(settingsProvider);
  final storageAsync = ref.watch(tokenStorageProvider);
  final storage = storageAsync.value;
  if (storage == null) {
    throw StateError('TokenStorage not ready');
  }
  return ApiClient(
    config: AppConfig(apiBaseUrl: settings.apiBaseUrl),
    storage: storage,
    onUnauthorized: () async {
      await storage.clearToken();
      ref.read(sessionExpiredProvider.notifier).state++;
    },
  );
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(apiClientProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepository(ref.watch(apiClientProvider));
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(apiClientProvider));
});

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return SettlementRepository(ref.watch(apiClientProvider));
});
