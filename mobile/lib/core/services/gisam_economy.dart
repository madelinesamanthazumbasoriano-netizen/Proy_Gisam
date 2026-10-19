import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backgrounds.dart';

class GisamPetOption {
  final String id;
  final String name;
  final String sprite;
  final int price;

  const GisamPetOption({
    required this.id,
    required this.name,
    required this.sprite,
    required this.price,
  });
}

class GisamEconomy extends ChangeNotifier {
  static const pets = [
    GisamPetOption(
      id: 'cat',
      name: 'Michi',
      sprite: 'assets/themes/pets/mascotas/gato/quieto.png',
      price: 0,
    ),
  ];

  String _userId = 'guest';
  int coins = 0;
  Set<String> ownedBackgrounds = {GisamBackgrounds.defaultAssetPath};
  Set<String> ownedPets = {};
  String activeBackground = GisamBackgrounds.defaultAssetPath;
  String? activePet;
  bool isLoading = false;
  String? persistenceError;

  bool get _usesFirestore => _userId != 'guest' && Firebase.apps.isNotEmpty;

  Future<void> loadForUser(String userId) async {
    _userId = userId.isEmpty ? 'guest' : userId;
    coins = 0;
    ownedBackgrounds = {GisamBackgrounds.defaultAssetPath};
    ownedPets = {};
    activeBackground = GisamBackgrounds.defaultAssetPath;
    activePet = null;
    isLoading = true;
    persistenceError = null;
    notifyListeners();
    try {
      if (_usesFirestore) {
        await _call('initializeGameState');
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('game')
            .doc('state')
            .get();
        final data = snapshot.data();
        _readState(data ?? const {});
      } else {
        final preferences = await SharedPreferences.getInstance();
        _readState({
          'coins': preferences.getInt(_key('coins')) ?? 0,
          'ownedBackgrounds':
              preferences.getStringList(_key('backgrounds')) ?? [],
          'ownedPets': preferences.getStringList(_key('pets')) ?? [],
          'activeBackground': preferences.getString(_key('activeBackground')),
          'activePet': preferences.getString(_key('activePet')),
        });
        await _persist();
      }
    } catch (error) {
      persistenceError = error.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _readState(Map<String, dynamic> data) {
    coins = (data['coins'] as num?)?.toInt() ?? 0;
    ownedBackgrounds = {
      GisamBackgrounds.defaultAssetPath,
      ...((data['ownedBackgrounds'] as List<dynamic>?)?.whereType<String>() ??
          const <String>[]),
    };
    ownedPets =
        (data['ownedPets'] as List<dynamic>?)?.whereType<String>().toSet() ??
            {};
    final requestedBackground = data['activeBackground'] as String?;
    activeBackground = ownedBackgrounds.contains(requestedBackground)
        ? requestedBackground!
        : GisamBackgrounds.defaultAssetPath;
    final requestedPet = data['activePet'] as String?;
    activePet = ownedPets.contains(requestedPet) &&
            pets.any((pet) => pet.id == requestedPet)
        ? requestedPet
        : null;
  }

  String _key(String field) => 'gisam_${_userId}_$field';

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_key('coins'), coins);
    await preferences.setStringList(
        _key('backgrounds'), ownedBackgrounds.toList());
    await preferences.setStringList(_key('pets'), ownedPets.toList());
    await preferences.setString(_key('activeBackground'), activeBackground);
    if (activePet case final pet?) {
      await preferences.setString(_key('activePet'), pet);
    } else {
      await preferences.remove(_key('activePet'));
    }
  }

  Future<void> selectBackground(String assetPath) async {
    if (!ownedBackgrounds.contains(assetPath)) {
      throw StateError('Este fondo todavía no se ha desbloqueado.');
    }
    final previous = activeBackground;
    if (_usesFirestore) {
      try {
        final result = await _call('setActiveBackground', {
          'assetPath': assetPath,
        });
        _readRemoteState(result);
        persistenceError = null;
        notifyListeners();
        return;
      } catch (error) {
        persistenceError = error.toString();
        rethrow;
      }
    }
    activeBackground = assetPath;
    try {
      await _persist();
      persistenceError = null;
      notifyListeners();
    } catch (error) {
      activeBackground = previous;
      persistenceError = error.toString();
      rethrow;
    }
  }

  Future<bool> buyBackground(GisamBackgroundOption option) async {
    if (ownedBackgrounds.contains(option.assetPath)) return false;
    if (coins < option.price) return false;
    if (_usesFirestore) {
      final result = await _call('purchaseBackground', {
        'assetPath': option.assetPath,
      });
      _readRemoteState(result);
      persistenceError = null;
      notifyListeners();
      return result['purchased'] == true;
    }
    final oldCoins = coins;
    coins -= option.price;
    ownedBackgrounds = {...ownedBackgrounds, option.assetPath};
    try {
      await _persist();
      persistenceError = null;
      notifyListeners();
      return true;
    } catch (error) {
      coins = oldCoins;
      ownedBackgrounds = {...ownedBackgrounds}..remove(option.assetPath);
      persistenceError = error.toString();
      rethrow;
    }
  }

  Future<bool> adoptPet(GisamPetOption pet) async {
    if (_usesFirestore) {
      final result = await _call('adoptPet', {'petId': pet.id});
      _readRemoteState(result);
      persistenceError = null;
      notifyListeners();
      return result['adopted'] == true;
    }
    if (ownedPets.contains(pet.id)) {
      activePet = pet.id;
      await _persist();
      notifyListeners();
      return true;
    }
    if (coins < pet.price) return false;
    final oldCoins = coins;
    coins -= pet.price;
    ownedPets = {...ownedPets, pet.id};
    activePet = pet.id;
    try {
      await _persist();
      persistenceError = null;
      notifyListeners();
      return true;
    } catch (error) {
      coins = oldCoins;
      ownedPets = {...ownedPets}..remove(pet.id);
      activePet = null;
      persistenceError = error.toString();
      rethrow;
    }
  }

  Future<void> selectPet(String? petId) async {
    if (petId != null && !ownedPets.contains(petId)) {
      throw StateError('Primero debes adoptar esta mascota.');
    }
    final previous = activePet;
    if (_usesFirestore) {
      try {
        final result = await _call('setActivePet', {'petId': petId});
        _readRemoteState(result);
        persistenceError = null;
        notifyListeners();
        return;
      } catch (error) {
        persistenceError = error.toString();
        rethrow;
      }
    }
    activePet = petId;
    try {
      await _persist();
      notifyListeners();
    } catch (error) {
      activePet = previous;
      persistenceError = error.toString();
      rethrow;
    }
  }

  Future<String> startMiniGame() async {
    if (!_usesFirestore) return 'local';
    final result = await _call('startMiniGame');
    final roundId = result['roundId'];
    if (roundId is! String || roundId.isEmpty) {
      throw StateError('Firebase no devolvió un identificador de partida.');
    }
    return roundId;
  }

  Future<int> completeMiniGame({
    required int score,
    required String roundId,
  }) async {
    if (_usesFirestore) {
      final result = await _call('claimMiniGameReward', {
        'score': score,
        'roundId': roundId,
      });
      _readRemoteState(result);
      persistenceError = null;
      notifyListeners();
      return (result['reward'] as num?)?.toInt() ?? 0;
    }
    final completedBars = score ~/ 10;
    final reward = score < 5
        ? 0
        : score < 10
            ? 8
            : (15 + (completedBars > 1 ? completedBars - 1 : 0) * 5)
                .clamp(0, 75)
                .toInt();
    if (reward == 0) return 0;
    coins += reward;
    try {
      await _persist();
      persistenceError = null;
      notifyListeners();
      return reward;
    } catch (error) {
      coins -= reward;
      persistenceError = error.toString();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, Object?> parameters = const {},
  ]) async {
    final result =
        await FirebaseFunctions.instance.httpsCallable(name).call(parameters);
    final data = result.data;
    if (data is! Map) {
      throw StateError(
          'La función Firebase $name devolvió una respuesta inválida.');
    }
    return data.cast<String, dynamic>();
  }

  void _readRemoteState(Map<String, dynamic> response) {
    final state = response['state'];
    if (state is! Map) {
      throw StateError(
          'La función Firebase no devolvió el estado del usuario.');
    }
    _readState(state.cast<String, dynamic>());
  }
}
