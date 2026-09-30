import '../models/gisam_models.dart';

class ProgressService {
  GisamProgress progress = const GisamProgress();

  List<GisamMission> missions = const [
    GisamMission(id: 'chat', title: 'Hablar con GISAM', xp: 50),
    GisamMission(id: 'tree', title: 'Cuidar el árbol', xp: 30),
    GisamMission(id: 'activity', title: 'Completar una actividad', xp: 40),
    GisamMission(id: 'music', title: 'Escuchar música', xp: 20),
  ];

  void completeMission(String id) {
    final index = missions.indexWhere((m) => m.id == id);
    if (index < 0 || missions[index].completed) return;

    final mission = missions[index];
    missions = [
      for (var i = 0; i < missions.length; i++)
        i == index ? mission.copyWith(completed: true) : missions[i],
    ];

    var xp = progress.xp + mission.xp;
    var level = progress.level;
    var required = progress.xpRequired;

    while (xp >= required) {
      xp -= required;
      level++;
      required = 1000 + (level - 1) * 250;
    }

    progress = progress.copyWith(level: level, xp: xp, xpRequired: required);
  }
}
