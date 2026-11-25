import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../services/workout_storage_service.dart';
import '../widgets/liquid_glass_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storageService = WorkoutStorageService();
  List<WorkoutSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  Future<void> loadSessions() async {
    final data = await _storageService.getSessions();
    if (!mounted) return;
    setState(() {
      _sessions = data;
      _loading = false;
    });
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y • $h:$min';
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.7, -0.5),
          radius: 1.2,
          colors: [
            Color(0x33FF5520), // Halo naranja neón difuminado
            Color(0xFF0A0A0C), // Negro profundo
          ],
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Historial y Analítica',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_sessions.isNotEmpty)
                    IconButton(
                      tooltip: 'Borrar historial',
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFFF5520)),
                      onPressed: () async {
                        await _storageService.clearHistory();
                        loadSessions();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Widgets Liquid Glass inspirados en tus capturas
              WeeklyStepsLiquidChart(sessions: _sessions),
              const SizedBox(height: 14),
              CaloriesCapsuleBarsCard(sessions: _sessions),
              const SizedBox(height: 14),
              const MonthlyStreakCalendarCard(),
              const SizedBox(height: 20),

              const Text(
                'Sesiones Guardadas',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              if (_sessions.isEmpty)
                const LiquidGlassCard(
                  child: Text(
                    'Aún no tienes entrenamientos registrados.\nInicia una sesión en la pestaña Actividad.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9A9AA2)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _sessions[index];
                    final dist = item.distanceMeters >= 1000
                        ? '${(item.distanceMeters / 1000).toStringAsFixed(2)} km'
                        : '${item.distanceMeters.toStringAsFixed(1)} m';

                    return LiquidGlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(item.dateTime),
                                style: const TextStyle(
                                  color: Color(0xFFFF9F1C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5520)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFF5520)
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  item.dominantIntensity,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF5520),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              _StatPill(
                                label: 'Duración',
                                value:
                                _formatDuration(item.durationSeconds),
                              ),
                              _StatPill(
                                label: 'Pasos',
                                value: '${item.steps}',
                              ),
                              _StatPill(
                                label: 'Distancia',
                                value: dist,
                              ),
                              _StatPill(
                                label: 'Puntos GPS',
                                value: '${item.routePoints.length}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9A9AA2)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}