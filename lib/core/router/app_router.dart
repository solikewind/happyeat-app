import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_page.dart';
import '../../features/ordering/ordering_page.dart';
import '../../features/orders/order_detail_page.dart';
import '../../features/orders/orders_page.dart';
import '../../features/profile/menu_edit_page.dart';
import '../../features/profile/menu_manage_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/profile/settlement_detail_page.dart';
import '../../features/profile/settlement_list_page.dart';
import '../../features/profile/sales_menu_detail_page.dart';
import '../../features/profile/sales_stats_page.dart';
import '../../features/shell/main_shell.dart';
import '../../features/shell/shell_page_container.dart';
import '../../features/tables/tables_page.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/utils/stats_range.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      if (auth.status == AuthStatus.unknown) return null;
      if (!auth.isLoggedIn && !loggingIn) return '/login';
      if (auth.isLoggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return ShellPageContainer(
            navigationShell: navigationShell,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const OrderingPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrdersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tables',
                builder: (context, state) => const TablesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/orders/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailPage(orderId: id);
        },
      ),
      GoRoute(
        path: '/sales-stats',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SalesStatsPage(),
        routes: [
          GoRoute(
            path: 'menus',
            builder: (context, state) {
              final range = state.extra as StatsRange?;
              return SalesMenuDetailPage(
                range: range ?? StatsRange.resolve(StatsRangePreset.today),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/menu-manage',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MenuManagePage(),
      ),
      GoRoute(
        path: '/settlements',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettlementListPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SettlementDetailPage(settlementId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/menu-edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final menuId = state.extra as String?;
          return MenuEditPage(menuId: menuId);
        },
      ),
    ],
  );
});
