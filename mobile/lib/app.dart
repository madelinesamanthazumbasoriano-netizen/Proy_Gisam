import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/backgrounds.dart';
import 'core/gisam_controller.dart';
import 'core/theme.dart';
import 'features/navigation/gisam_shell.dart';

class GisamApp extends StatefulWidget {
  const GisamApp({super.key});

  @override
  State<GisamApp> createState() => _GisamAppState();
}

class _GisamAppState extends State<GisamApp> {
  final controller = GisamController();
  ThemeMode _themeMode = ThemeMode.light;
  String _backgroundAsset = GisamBackgrounds.defaultAssetPath;

  @override
  void initState() {
    super.initState();
    controller.init();
    _loadThemeMode();
    _loadBackground();
  }

  Future<void> _loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final useDarkTheme = preferences.getBool('use_dark_theme') ?? false;
    if (mounted) {
      setState(
        () => _themeMode = useDarkTheme ? ThemeMode.dark : ThemeMode.light,
      );
    }
  }

  Future<void> _setThemeMode(ThemeMode value) async {
    setState(() => _themeMode = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('use_dark_theme', value == ThemeMode.dark);
  }

  Future<void> _loadBackground() async {
    final preferences = await SharedPreferences.getInstance();
    final backgroundAsset = GisamBackgrounds.normalize(
      preferences.getString('background_asset'),
    );
    if (mounted) setState(() => _backgroundAsset = backgroundAsset);
  }

  Future<void> _setBackground(String assetPath) async {
    final normalized = GisamBackgrounds.normalize(assetPath);
    setState(() => _backgroundAsset = normalized);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('background_asset', normalized);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => MaterialApp(
        title: 'GISAM',
        debugShowCheckedModeBanner: false,
        theme: GisamTheme.light(),
        darkTheme: GisamTheme.dark(),
        themeMode: _themeMode,
        home: GisamShell(
          controller: controller,
          themeMode: _themeMode,
          onThemeModeChanged: _setThemeMode,
          backgroundAsset: _backgroundAsset,
          onBackgroundChanged: _setBackground,
        ),
      ),
    );
  }
}
