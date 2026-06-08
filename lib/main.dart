import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'services/config/config_repository.dart';
import 'services/chip_json_repository.dart';
import 'services/earbuds_repository.dart';
import 'state/app_state.dart';
import 'state/bt_state.dart';
import 'state/earbuds_state.dart';
import 'state/theme_controller.dart';
import 'navigation/app_url_state.dart';
import 'pages/admin_page.dart';
import 'pages/home_page.dart';
import 'theme/app_theme.dart';
import 'widgets/material_icon_font_anchor.dart';

// Toggle this flag to choose the UI language for the whole app.
// Set to `true` to force Chinese (Simplified), `false` for English.
const bool useChinese = false;
const String adminSecretKey = 'admin';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  await Future.wait([
    ConfigRepository.instance.load(),
    EarbudsRepository.instance.load(),
  ]);
  await ChipJsonRepository.instance.load();
  const appLocale = useChinese ? Locale('zh') : Locale('en');
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
        ChangeNotifierProvider(create: (_) => BTState()),
        ChangeNotifierProvider(create: (_) => EarbudsState()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) => MaterialApp(
          title: 'BES CONSUMPTION',
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
          builder: (context, child) => MaterialIconFontAnchor(
            child: child ?? const SizedBox.shrink(),
          ),
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '/');
            if (uri.path == '/admin') {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => Title(
                  color: Theme.of(context).colorScheme.primary,
                  title: AppLocalizations.of(context).browserTitleAdmin,
                  child: const AdminPage(secretKey: adminSecretKey),
                ),
              );
            }

            final pageIndex = AppUrlState.pageIndexFromPath(uri.path);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => Title(
                color: Theme.of(context).colorScheme.primary,
                title: AppLocalizations.of(context).browserTitleUser,
                child: MyHomePage(
                  initialIndex: pageIndex,
                  initialUri: uri,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
