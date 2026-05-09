import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'state/earbuds_state.dart';
import 'state/theme_controller.dart';
import 'pages/home_page.dart';
import 'theme/app_theme.dart';

// Toggle this flag to choose the UI language for the whole app.
// Set to `true` to force Chinese (Simplified), `false` for English.
const bool useChinese = false;

void main() {
  const appLocale = useChinese ?  Locale('zh') :  Locale('en');
  runApp(MyApp(locale: appLocale));
}

class MyApp extends StatelessWidget {
  final Locale? locale;

  const MyApp({super.key, this.locale});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => EarbudsState()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) => MaterialApp(
          title: 'BES CONSUMPTION (Demo)',
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          localizationsDelegates: [
            appLocalizationsDelegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLight(),
          darkTheme: AppTheme.buildDark(),
          themeMode: themeCtrl.mode,
          home: const MyHomePage(),
        ),
      ),
    );
  }
}
