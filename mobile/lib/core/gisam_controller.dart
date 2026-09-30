import 'package:flutter/foundation.dart';

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

  Future<void> init() async {
    try {
      userId = await users.getUserId();

      await refreshProfile();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    final data = await api.getProfile(userId);

    progress = GisamProgress.fromJson(
      data['progress'],
    );

    missions = (data['missions'] as List<dynamic>)
        .map(
          (e) => GisamMission.fromJson(e),
        )
        .toList();

    friends = await api.getFriends(userId);

    notifyListeners();
  }

  Future<Map<String, dynamic>> chat(
    String message,
  ) async {
    final data = await api.sendMessage(
      userId,
      message,
    );

    await refreshProfile();

    return data;
  }

  Future<void> completeMission(
    String id,
  ) async {
    await api.completeMission(
      userId,
      id,
    );

    await refreshProfile();
  }

  Future<void> addFriend(
    String friendId,
  ) async {
    await api.linkFriend(
      userId,
      friendId,
    );

    await refreshProfile();
  }
}
