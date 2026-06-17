import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/routing/app_route_registry.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'pages/startup_page.dart';

class KlinikApp extends StatelessWidget {
  const KlinikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeServiceInstance.notifier,
      builder: (context, _) {
        final mode = ThemeServiceInstance.notifier.mode;
        return MaterialApp(
          title: 'SinShe Jaya Abadi',
          debugShowCheckedModeBanner: false,
          locale: const Locale('id', 'ID'),
          supportedLocales: const [
            Locale('id', 'ID'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: mode,
          initialRoute: StartupPage.routeName,
          routes: buildLegacyRoutes(),
        );
      },
    );
  }
}

/// Singleton accessor for the global [ThemeNotifier].
class ThemeServiceInstance {
  ThemeServiceInstance._();
  static final ThemeNotifier notifier = ThemeNotifier();
}
