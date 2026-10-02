import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gisam_app/core/backgrounds.dart';
import 'package:gisam_app/core/models/gisam_models.dart';
import 'package:gisam_app/features/home/spirit_tree.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GISAM progress calculates a bounded percentage', () {
    const progress = GisamProgress(xp: 250, xpRequired: 1000);
    expect(progress.progress, 0.25);
  });

  testWidgets('El árbol espiritual anima sus pétalos sin errores',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpiritTree()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SpiritTree), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SpiritTree),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Las rutas de fondo aceptan variaciones de mayúsculas y espacios', () {
    expect(
      GisamBackgrounds.normalize('  assets/themes/theme 7.jpg  '),
      'assets/themes/Theme 7.jpg',
    );

    expect(
      GisamBackgrounds.normalize('assets/themes/theme 8.jpg'),
      'assets/themes/Theme 8.jpg',
    );
  });

  test('Los assets de inicio y navegación están incluidos en el bundle',
      () async {
    const assetPaths = [
      'assets/themes/inicio/Arbol.jpg',
      'assets/themes/inicio/Logo-inicia.jpg',
      'assets/themes/ajustes/Ajustes.jpg',
      'assets/themes/comunidad/Amigos.jpg',
      'assets/themes/ia/Chat-bot.jpg',
      'assets/themes/musica/Spotify.jpg',
      'assets/themes/perfil/Perfil.jpg',
    ];

    for (final assetPath in assetPaths) {
      await rootBundle.load(assetPath);
    }
  });
}
