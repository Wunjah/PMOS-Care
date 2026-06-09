import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/localization/translations.dart';
import 'core/network/network_info.dart';

class PMOSCareApp extends ConsumerWidget {
  const PMOSCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentLanguage = ref.watch(languageProvider);
    
    // Watch connectivity status to show a non-disruptive banner if offline
    final connectionState = ref.watch(networkStatusProvider);

    return MaterialApp.router(
      title: 'PMOS Care',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      
      // Theme system configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Localization config
      locale: Locale(currentLanguage.name),
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      // Display dynamic overlay banner when network drops
      builder: (context, child) {
        return Scaffold(
          body: Column(
            children: [
              if (connectionState.valueOrNull == NetworkStatus.offline)
                Container(
                  color: AppTheme.glycemicMedium,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  alignment: Alignment.center,
                  child: Text(
                    context.translate('offline_banner'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}
