import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design/tokens/app_theme.dart';
import '../features/settings/theme_controller.dart';
import 'auth_gate.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';

class NovAiShopApp extends StatefulWidget {
  const NovAiShopApp({this.authStateChanges, super.key});

  final Stream<AuthState>? authStateChanges;

  @override
  State<NovAiShopApp> createState() => _NovAiShopAppState();
}

class _NovAiShopAppState extends State<NovAiShopApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final authStateChanges = widget.authStateChanges ??
        Supabase.instance.client.auth.onAuthStateChange;
    _authSubscription = authStateChanges.listen(
      (state) {
        if (state.event != AuthChangeEvent.passwordRecovery) return;
        _navigatorKey.currentState?.pushNamed(RouteNames.resetPassword);
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().mode;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'NovAiShop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const AuthGate(),
    );
  }
}
