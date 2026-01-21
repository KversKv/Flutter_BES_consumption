import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'pages/home_page.dart';

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
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'BES CONSUMPTION (Demo)',
        // Respect the forced locale from `main` (English / Chinese)
        locale: locale,
        supportedLocales: const [
          Locale('en'),
          Locale('zh'),
        ],
        // our simple delegate + Flutter built-in delegates
        localizationsDelegates: [
          appLocalizationsDelegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}
