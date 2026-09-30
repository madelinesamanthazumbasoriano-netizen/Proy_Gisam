import 'package:flutter/material.dart';

import '../../core/backgrounds.dart';
import '../../core/gisam_asset_icon.dart';
import '../../core/gisam_controller.dart';
import '../chatbot/chatbot_page.dart';
import '../community/community_page.dart';
import '../friends/friends_page.dart';
import '../game/game_page.dart';
import '../home/home_page.dart';
import '../music/music_page.dart';
import '../profile/profile_page.dart';
import '../settings/settings_page.dart';
import '../store/store_page.dart';

class GisamShell extends StatefulWidget {
  final GisamController controller;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String backgroundAsset;
  final ValueChanged<String> onBackgroundChanged;

  const GisamShell({
    super.key,
    required this.controller,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.backgroundAsset,
    required this.onBackgroundChanged,
  });

  @override
  State<GisamShell> createState() => _GisamShellState();
}

class _GisamShellState extends State<GisamShell> {
  int index = 0;

  List<Widget> get pages => [
        HomePage(controller: widget.controller),
        FriendsPage(controller: widget.controller),
        MusicPage(controller: widget.controller),
        CommunityPage(),
        ChatbotPage(controller: widget.controller),
      ];

  void _openPage(Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GisamBackground(
          assetPath: widget.backgroundAsset,
          child: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return GisamBackground(
      assetPath: widget.backgroundAsset,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 8,
          leading: Builder(
            builder: (context) => IconButton(
              tooltip: 'Abrir menú',
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: const EdgeInsets.all(8),
              icon: const GisamAssetIcon(
                assetPath: 'assets/themes/Menu.jpg',
                size: 32,
                borderRadius: 10,
              ),
            ),
          ),
          title: const Text(
            'Semi_Gisam',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colors.surface.withValues(alpha: 0.82),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 19,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
        drawer: NavigationDrawer(
          backgroundColor: colors.surface.withValues(alpha: 0.96),
          selectedIndex: null,
          onDestinationSelected: (value) {
            switch (value) {
              case 0:
                Navigator.pop(context);
                setState(() => index = 0);
                return;
              case 1:
                _openPage(ProfilePage(controller: widget.controller));
                return;
              case 2:
                _openPage(const StorePage());
                return;
              case 3:
                _openPage(
                  SettingsPage(
                    themeMode: widget.themeMode,
                    onThemeModeChanged: widget.onThemeModeChanged,
                    backgroundAsset: widget.backgroundAsset,
                    onBackgroundChanged: widget.onBackgroundChanged,
                  ),
                );
                return;
              case 4:
                _openPage(const GamePage());
                return;
            }
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/themes/inicio/Logo-inicia.jpg',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semi_Gisam',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text('Tu espacio, a tu manera'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 6, 16, 8),
              child: Text(
                'Explorar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            NavigationDrawerDestination(
              icon: GisamAssetIcon(
                assetPath: 'assets/themes/inicio/Arbol.jpg',
              ),
              selectedIcon: GisamAssetIcon(
                assetPath: 'assets/themes/inicio/Arbol.jpg',
                selected: true,
              ),
              label: const Text('Inicio'),
            ),
            NavigationDrawerDestination(
              icon: GisamAssetIcon(
                assetPath: 'assets/themes/perfil/Perfil.jpg',
              ),
              selectedIcon: GisamAssetIcon(
                assetPath: 'assets/themes/perfil/Perfil.jpg',
                selected: true,
              ),
              label: const Text('Perfil'),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront),
              label: const Text('Tienda'),
            ),
            NavigationDrawerDestination(
              icon: GisamAssetIcon(
                assetPath: 'assets/themes/ajustes/Ajustes.jpg',
              ),
              selectedIcon: GisamAssetIcon(
                assetPath: 'assets/themes/ajustes/Ajustes.jpg',
                selected: true,
              ),
              label: const Text('Ajustes'),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.sports_esports_outlined),
              selectedIcon: const Icon(Icons.sports_esports),
              label: const Text('Videojuego'),
            ),
          ],
        ),
        body: IndexedStack(
          index: index,
          children: pages,
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Hablar con GISAM',
          onPressed: () => setState(() => index = 4),
          child: const GisamAssetIcon(
            assetPath: 'assets/themes/ia/Chat-bot.jpg',
            size: 32,
            borderRadius: 10,
          ),
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: colors.surface.withValues(alpha: 0.88),
            elevation: 0,
            indicatorColor: colors.primaryContainer.withValues(alpha: 0.92),
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(
                icon: GisamAssetIcon(
                  assetPath: 'assets/themes/inicio/Arbol.jpg',
                ),
                selectedIcon: GisamAssetIcon(
                  assetPath: 'assets/themes/inicio/Arbol.jpg',
                  selected: true,
                ),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: GisamAssetIcon(
                  assetPath: 'assets/themes/comunidad/Amigos.jpg',
                ),
                selectedIcon: GisamAssetIcon(
                  assetPath: 'assets/themes/comunidad/Amigos.jpg',
                  selected: true,
                ),
                label: 'Amigos',
              ),
              NavigationDestination(
                icon: GisamAssetIcon(
                  assetPath: 'assets/themes/musica/Spotify.jpg',
                ),
                selectedIcon: GisamAssetIcon(
                  assetPath: 'assets/themes/musica/Spotify.jpg',
                  selected: true,
                ),
                label: 'Música',
              ),
              NavigationDestination(
                icon: GisamAssetIcon(
                  assetPath: 'assets/themes/comunidad/Amigos.jpg',
                ),
                selectedIcon: GisamAssetIcon(
                  assetPath: 'assets/themes/comunidad/Amigos.jpg',
                  selected: true,
                ),
                label: 'Comunidad',
              ),
              NavigationDestination(
                icon: GisamAssetIcon(
                  assetPath: 'assets/themes/ia/Chat-bot.jpg',
                ),
                selectedIcon: GisamAssetIcon(
                  assetPath: 'assets/themes/ia/Chat-bot.jpg',
                  selected: true,
                ),
                label: 'IA',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
