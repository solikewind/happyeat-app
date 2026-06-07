import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/app_providers.dart';

class HappyEatApp extends ConsumerStatefulWidget {
  const HappyEatApp({super.key});

  @override
  ConsumerState<HappyEatApp> createState() => _HappyEatAppState();
}

class _HappyEatAppState extends ConsumerState<HappyEatApp> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<int>(
      sessionExpiredProvider,
      (prev, next) {
        if (next > 0) {
          ref.read(authProvider.notifier).logout();
        }
      },
    );
    ref.listenManual<AuthState>(
      authProvider,
      (prev, next) {
        if (prev?.isLoggedIn == true && !next.isLoggedIn) {
          clearOrderingSession(ref);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (auth.status == AuthStatus.unknown) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('HappyEat 加载中…'),
              ],
            ),
          ),
        ),
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'HappyEat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
