import 'package:flutter/material.dart';

import '../../core/backgrounds.dart';
import '../../core/services/api_service.dart';

class SettingsPage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String backgroundAsset;
  final ValueChanged<String> onBackgroundChanged;

  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.backgroundAsset,
    required this.onBackgroundChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final api = ApiService();
  Map<String, dynamic>? health;
  bool loading = false;
  late ThemeMode _themeMode;
  late String _backgroundAsset;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _backgroundAsset = GisamBackgrounds.normalize(widget.backgroundAsset);
  }

  void _changeTheme(bool useDarkTheme) {
    final themeMode = useDarkTheme ? ThemeMode.dark : ThemeMode.light;
    setState(() => _themeMode = themeMode);
    widget.onThemeModeChanged(themeMode);
  }

  Future<void> check() async {
    setState(() => loading = true);
    try {
      health = await api.getHealth();
    } catch (_) {
      health = {'ok': false};
    }
    if (mounted) setState(() => loading = false);
  }

  void _selectBackground(String assetPath) {
    setState(() => _backgroundAsset = assetPath);
    widget.onBackgroundChanged(assetPath);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _SectionTitle(
            icon: Icons.palette_outlined,
            title: 'Personalización',
            subtitle: 'Haz que GISAM se sienta como tuyo.',
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wallpaper_outlined, color: colors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fondos de GISAM',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text('Elige uno de tus fondos guardados.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: GisamBackgrounds.options.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final option = GisamBackgrounds.options[index];
                      final selected = option.assetPath == _backgroundAsset;

                      return _ThemePreviewCard(
                        option: option,
                        selected: selected,
                        onTap: () => _selectBackground(option.assetPath),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                _themeMode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              title: const Text('Modo oscuro'),
              subtitle: Text(
                _themeMode == ThemeMode.dark
                    ? 'Vista oscura activada'
                    : 'Vista clara activada',
              ),
              value: _themeMode == ThemeMode.dark,
              onChanged: _changeTheme,
            ),
          ),
          const SizedBox(height: 14),
          _SectionTitle(
            icon: Icons.security_outlined,
            title: 'Privacidad y sistema',
            subtitle: 'Controles importantes de la aplicación.',
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Privacidad'),
              subtitle: Text(
                'GISAM debe minimizar datos y evitar usar conversaciones como entrenamiento automático.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.notifications_none),
              title: Text('Notificaciones'),
              subtitle: Text(
                'Configura recordatorios y misiones cuando el módulo esté conectado.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('Estado del servidor'),
              subtitle: Text(
                health == null
                    ? 'Sin comprobar'
                    : health!['ok'] == true
                        ? 'API conectada'
                        : 'API no disponible',
              ),
              trailing: IconButton(
                onPressed: loading ? null : check,
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final GisamBackgroundOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 3 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  option.assetPath,
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    color: Colors.black.withValues(alpha: 0.48),
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 19,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
