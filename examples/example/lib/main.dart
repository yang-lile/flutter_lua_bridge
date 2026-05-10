import 'package:flutter/material.dart';

import 'bridge/basic_bridge_demo.dart';
import 'game/game_demo_page.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const List<Locale> _localeOptions = [Locale('zh'), Locale('en')];

  Locale _locale = const Locale('zh');

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(localeOptions: _localeOptions, currentLocale: _locale, onLocaleChanged: _setLocale),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<Locale> localeOptions;
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  const HomePage({super.key, required this.localeOptions, required this.currentLocale, required this.onLocaleChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  num? luaVersion;
  int? fetchAValue;
  int? bValue;

  void onPressed() {
    try {
      final result = BasicBridgeDemo.run();
      setState(() {
        luaVersion = result.luaVersion;
        fetchAValue = result.a;
        bValue = result.b;
      });
    } catch (e) {
      debugPrint('Bridge demo error: $e');
    }
  }

  static String _localeLabel(Locale locale) {
    return switch (locale.languageCode) {
      'zh' => '中文',
      'en' => 'English',
      _ => locale.languageCode,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const textStyle = TextStyle(fontSize: 25);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language, color: Colors.black),
            tooltip: l10n.switchLanguage,
            initialValue: widget.currentLocale,
            onSelected: widget.onLocaleChanged,
            itemBuilder: (context) => widget.localeOptions
                .map((locale) => PopupMenuItem(value: locale, child: Text(_localeLabel(locale))))
                .toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            spacing: 10,
            children: [
              Text(l10n.testListTitle, style: textStyle, textAlign: TextAlign.center),
              Text(l10n.testListSubtitle, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
              const Divider(),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.code, color: Colors.blue),
                  title: Text(l10n.bridgeBasicTest),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.luaVersion} = $luaVersion'),
                      Text('${l10n.randomValueA}: $fetchAValue'),
                      Text('${l10n.randomValueB}: $bValue'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                    onPressed: onPressed,
                    tooltip: l10n.runBridgeTest,
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.gamepad, color: Colors.orange),
                  title: Text(l10n.gameDemoTest),
                  subtitle: Text(l10n.gameDemoSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameDemoPage()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
