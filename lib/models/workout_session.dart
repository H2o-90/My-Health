import 'dart:convert';
import 'package:latlong2/latlong.dart';

class WorkoutSession {
  final String id;
  final DateTime dateTime;
  final int durationSeconds;
  final int steps;
  final double distanceMeters;
  final String dominantIntensity;
  final List<LatLng> routePoints;

  const WorkoutSession({
    required this.id,
    required this.dateTime,
    required this.durationSeconds,
    required this.steps,
    required this.distanceMeters,
    required this.dominantIntensity,
    required this.routePoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'steps': steps,
      'distanceMeters': distanceMeters,
      'dominantIntensity': dominantIntensity,
      'routePoints': routePoints
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    final rawPoints = (map['routePoints'] as List<dynamic>? ?? []);
    return WorkoutSession(
      id: map['id'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      durationSeconds: map['durationSeconds'] ?? 0,
      steps: map['steps'] ?? 0,
      distanceMeters: (map['distanceMeters'] ?? 0.0).toDouble(),
      dominantIntensity: map['dominantIntensity'] ?? 'Descanso',
      routePoints: rawPoints
          .map((p) => LatLng(
        (p['lat'] as num).toDouble(),
        (p['lng'] as num).toDouble(),
      ))
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory WorkoutSession.fromJson(String source) =>
      WorkoutSession.fromMap(json.decode(source));
}