import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gisam_app/core/backgrounds.dart';
import 'package:gisam_app/core/gisam_controller.dart';
import 'package:gisam_app/core/models/gisam_models.dart';
import 'package:gisam_app/core/services/gisam_economy.dart';
import 'package:gisam_app/features/game/game_page.dart';
import 'package:gisam_app/features/home/home_page.dart';
import 'package:gisam_app/features/home/spirit_tree.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GISAM progress calculates a bounded percentage', () {
    const progress = GisamProgress(xp: 250, xpRequired: 1000);
    expect(progress.progress, 0.25);
  });

  testWidgets('El árbol de la foto anima pétalos y muestra aliento al tocarlo',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpiritTree()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SpiritTree), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/themes/inicio/Arbol.jpg',
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SpiritTree),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(SpiritTree));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Un mensaje para ti'), findsOneWidget);
    expect(
        find.text('Cada pequeño paso también te acerca a donde quieres estar.'),
        findsOneWidget);

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
      'assets/themes/inicio/Inicio.png',
      'assets/themes/tienda/tienda.png',
      'assets/themes/ajustes/Ajustes.jpg',
      'assets/themes/comunidad/Amigos.jpg',
      'assets/themes/ia/Chat-bot.jpg',
      'assets/themes/musica/Spotify.jpg',
      'assets/themes/perfil/Perfil.jpg',
      'assets/themes/pets/mascotas/gato/quieto.png',
    ];

    for (final assetPath in assetPaths) {
      await rootBundle.load(assetPath);
    }
  });

  testWidgets('Inicio muestra a la mascota incluso antes de adoptarla',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          controller: GisamController(),
          economy: GisamEconomy(),
        ),
      ),
    );

    expect(find.text('Conoce a Michi'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/themes/pets/mascotas/gato/quieto.png',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Minijuegos ofrece Tetris y puzzle con barra de progreso',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(economy: GisamEconomy()),
      ),
    );

    expect(find.text('Tetris'), findsOneWidget);
    expect(find.text('Puzzle'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
