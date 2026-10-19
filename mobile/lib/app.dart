import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/gisam_controller.dart';
import 'core/services/firebase_account_service.dart';
import 'core/services/gisam_economy.dart';
import 'core/theme.dart';
import 'features/navigation/gisam_shell.dart';

class GisamApp extends StatefulWidget {
  const GisamApp({super.key});

  @override
  State<GisamApp> createState() => _GisamAppState();
}

class _GisamAppState extends State<GisamApp> {
  final controller = GisamController();
  final economy = GisamEconomy();
  final accounts = GisamAccountService();
  ThemeMode _themeMode = ThemeMode.light;
  GisamAccount? _account;
  String? _accountError;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await GisamFirebaseConfig.initialize();
      _account = accounts.currentAccount;
      final userId = _account?.uid ?? 'guest';
      await economy.loadForUser(userId);
      await controller.init(initialUserId: _account?.uid);
    } catch (error) {
      _accountError = error.toString();
      if (_account == null) {
        await economy.loadForUser('guest');
        await controller.init();
      } else {
        await controller.init(initialUserId: _account!.uid);
      }
    }
    if (mounted) setState(() {});
  }

  Future<GisamAccount> _signIn() async {
    final account = await accounts.signInWithGoogle();
    if (mounted) {
      setState(() {
        _account = account;
        _accountError = null;
      });
    }
    await economy.loadForUser(account.uid);
    await controller.useUser(account.uid);
    return account;
  }

  Future<void> _signOut() async {
    await accounts.signOut();
    if (mounted) setState(() => _account = null);
    await economy.loadForUser('guest');
    await controller.useUser('usuario_demo');
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, economy]),
      builder: (_, __) => MaterialApp(
        title: 'GISAM',
        debugShowCheckedModeBanner: false,
        theme: GisamTheme.light(),
        darkTheme: GisamTheme.dark(),
        themeMode: _themeMode,
        home: GisamShell(
          controller: controller,
          economy: economy,
          account: _account,
          accountError: _accountError,
          onSignIn: _signIn,
          onSignOut: _signOut,
          themeMode: _themeMode,
          onThemeModeChanged: _setThemeMode,
          backgroundAsset: economy.activeBackground,
        ),
      ),
    );
  }
}
