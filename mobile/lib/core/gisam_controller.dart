import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/gisam_models.dart';
import 'services/api_service.dart';
import 'services/user_service.dart';

class GisamController extends ChangeNotifier {
  final ApiService api;
  final UserService users;

  GisamController({
    ApiService? api,
    UserService? users,
  })  : api = api ?? ApiService(),
        users = users ??
            UserService(
              baseUrl: ApiService.baseUrl,
            );

  String userId = '';

  GisamProgress progress = const GisamProgress();

  List<GisamMission> missions = [];

  List<dynamic> friends = [];

  bool loading = true;

  String? error;

  Future<void> init({String? initialUserId}) async {
    try {
      userId = initialUserId ?? await users.getUserId();

      await refreshProfile();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> useUser(String nextUserId) async {
    userId = nextUserId;
    try {
      await refreshProfile();
      error = null;
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (_usesFirebaseProfile) {
      final snapshot = await _gameState.get();
      final data = snapshot.data() ?? const <String, dynamic>{};
      progress = GisamProgress.fromJson(
        (data['progress'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
            const {},
      );
      final statuses = (data['missionStatus'] as Map<dynamic, dynamic>?)
              ?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      missions = _defaultMissions
          .map((mission) => mission.copyWith(
                completed: statuses[mission.id] == true,
              ))
          .toList(growable: false);
    } else if (userId == 'usuario_demo') {
      await _loadGuestProfile();
    } else {
      final data = await api.getProfile(userId);
      progress = GisamProgress.fromJson(data['progress']);
      missions = (data['missions'] as List<dynamic>)
          .map((e) => GisamMission.fromJson(e))
          .toList();
    }

    if (_usesFirebaseProfile) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();
      friends = snapshot.docs
          .map((document) => {'id': document.id})
          .toList(growable: false);
    } else if (userId == 'usuario_demo') {
      friends = [];
    } else {
      friends = await api.getFriends(userId);
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>> chat(
    String message,
  ) async {
    if (userId == 'usuario_demo') {
      throw StateError('Inicia sesión con Google para usar el chat.');
    }
    final data = await api.sendMessage(
      userId,
      message,
    );
    if (_usesFirebaseProfile) {
      await _completeFirebaseMission('chat');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('chatHistory')
          .add({
        'message': message,
        'response': data['response'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await refreshProfile();

    return data;
  }

  Future<void> completeMission(
    String id,
  ) async {
    if (_usesFirebaseProfile) {
      await _completeFirebaseMission(id);
    } else if (userId == 'usuario_demo') {
      await _completeGuestMission(id);
    } else {
      await api.completeMission(userId, id);
    }
    await refreshProfile();
  }

  Future<void> addFriend(
    String friendId,
  ) async {
    if (_usesFirebaseProfile) {
      if (friendId == userId) {
        throw ArgumentError('No puedes agregarte a ti mismo');
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendId)
          .set({
        'friendUid': friendId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (userId == 'usuario_demo') {
      throw StateError('Inicia sesión con Google para agregar amistades.');
    } else {
      await api.linkFriend(userId, friendId);
    }

    await refreshProfile();
  }

  static const _defaultMissions = [
    GisamMission(id: 'chat', title: 'Hablar con GISAM', xp: 50),
    GisamMission(id: 'tree', title: 'Cuidar el árbol', xp: 30),
    GisamMission(id: 'activity', title: 'Completar una actividad', xp: 40),
    GisamMission(id: 'music', title: 'Escuchar música', xp: 20),
  ];

  bool get _usesFirebaseProfile =>
      userId != 'usuario_demo' && Firebase.apps.isNotEmpty;

  DocumentReference<Map<String, dynamic>> get _gameState =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('game')
          .doc('state');

  Future<void> _loadGuestProfile() async {
    final preferences = await SharedPreferences.getInstance();
    progress = GisamProgress(
      level: preferences.getInt('guest_level') ?? 1,
      xp: preferences.getInt('guest_xp') ?? 0,
      xpRequired: preferences.getInt('guest_xp_required') ?? 1000,
      water: preferences.getInt('guest_water') ?? 50,
      health: preferences.getInt('guest_health') ?? 50,
      happiness: preferences.getInt('guest_happiness') ?? 50,
    );
    final completed =
        preferences.getStringList('guest_completed_missions')?.toSet() ?? {};
    missions = _defaultMissions
        .map((mission) => mission.copyWith(
              completed: completed.contains(mission.id),
            ))
        .toList(growable: false);
  }

  Future<void> _completeGuestMission(String id) async {
    final matchingMissions =
        missions.where((mission) => mission.id == id).toList();
    if (matchingMissions.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Misión desconocida');
    }
    final mission = matchingMissions.first;
    if (mission.completed) return;

    var xp = progress.xp + mission.xp;
    var level = progress.level;
    var requiredXp = progress.xpRequired;
    while (xp >= requiredXp) {
      xp -= requiredXp;
      level++;
      requiredXp = 1000 + (level - 1) * 250;
    }
    progress = progress.copyWith(
      level: level,
      xp: xp,
      xpRequired: requiredXp,
      water: id == 'tree' ? (progress.water + 10).clamp(0, 100).toInt() : null,
      health: id == 'tree' ? (progress.health + 3).clamp(0, 100).toInt() : null,
      happiness: id == 'chat'
          ? (progress.happiness + 4).clamp(0, 100).toInt()
          : id == 'music'
              ? (progress.happiness + 2).clamp(0, 100).toInt()
              : null,
    );
    missions = missions
        .map((item) => item.id == id ? item.copyWith(completed: true) : item)
        .toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('guest_level', progress.level);
    await preferences.setInt('guest_xp', progress.xp);
    await preferences.setInt('guest_xp_required', progress.xpRequired);
    await preferences.setInt('guest_water', progress.water);
    await preferences.setInt('guest_health', progress.health);
    await preferences.setInt('guest_happiness', progress.happiness);
    await preferences.setStringList(
      'guest_completed_missions',
      missions.where((item) => item.completed).map((item) => item.id).toList(),
    );
  }

  Future<void> _completeFirebaseMission(String id) async {
    final matchingMissions =
        _defaultMissions.where((item) => item.id == id).toList();
    if (matchingMissions.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Misión desconocida');
    }
    await FirebaseFunctions.instance
        .httpsCallable('completeMission')
        .call({'missionId': id});
  }
}
