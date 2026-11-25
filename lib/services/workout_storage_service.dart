
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_session.dart';

class WorkoutStorageService {
  static const String _historyKey = 'My Health_workout_history';

  // Obtiene todas las sesiones guardadas
  Future<List<WorkoutSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();

    final rawList = prefs.getStringList(_historyKey) ?? [];

    final sessions = rawList
        .map((item) => WorkoutSession.fromJson(item))
        .toList();

    // Ordena las sesiones de la más reciente a la más antigua
    sessions.sort(
          (a, b) => b.dateTime.compareTo(a.dateTime),
    );

    return sessions;
  }

  // Guarda una nueva sesión de entrenamiento
  Future<void> saveSession(WorkoutSession session) async {
    final prefs = await SharedPreferences.getInstance();

    final rawList = prefs.getStringList(_historyKey) ?? [];

    rawList.add(json.encode(session.toMap()));

    await prefs.setStringList(_historyKey, rawList);
  }

  // Elimina todo el historial de entrenamientos
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_historyKey);
  }
}