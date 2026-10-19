import 'package:flutter_test/flutter_test.dart';
import 'package:gisam_app/core/backgrounds.dart';
import 'package:gisam_app/core/services/gisam_economy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guest minigame coins unlock and select a background', () async {
    final economy = GisamEconomy();
    await economy.loadForUser('guest');

    expect(
      await economy.completeMiniGame(score: 4, roundId: 'local'),
      0,
    );
    expect(
      await economy.completeMiniGame(score: 10, roundId: 'local'),
      15,
    );

    final background = GisamBackgrounds.options[1];
    expect(await economy.buyBackground(background), isFalse);
    for (var attempt = 0; attempt < 6; attempt++) {
      await economy.completeMiniGame(score: 10, roundId: 'local');
    }

    expect(await economy.buyBackground(background), isTrue);
    expect(economy.ownedBackgrounds, contains(background.assetPath));
    expect(economy.coins, 25);

    await economy.selectBackground(background.assetPath);
    expect(economy.activeBackground, background.assetPath);
  });

  test('guest earns more coins for each completed minigame progress bar',
      () async {
    final economy = GisamEconomy();
    await economy.loadForUser('guest');

    expect(await economy.completeMiniGame(score: 10, roundId: 'local'), 15);
    expect(await economy.completeMiniGame(score: 20, roundId: 'local'), 20);
    expect(await economy.completeMiniGame(score: 300, roundId: 'local'), 75);
    expect(economy.coins, 110);
  });

  test('economy state is scoped to the signed-in user', () async {
    final economy = GisamEconomy();
    await economy.loadForUser('user-one');
    await economy.completeMiniGame(score: 10, roundId: 'local');

    await economy.loadForUser('user-two');
    expect(economy.coins, 0);

    await economy.loadForUser('user-one');
    expect(economy.coins, 15);
  });
}
