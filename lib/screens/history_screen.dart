import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../services/workout_storage_service.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historial de Rutinas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18352A),
                  ),
                ),
                if (_sessions.isNotEmpty)
                  IconButton(
                    tooltip: 'Borrar historial',
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () async {
                      await _storageService.clearHistory();
                      loadSessions();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_sessions.isNotEmpty) ...[
              _HistoryChart(sessions: _sessions.take(7).toList().reversed.toList()),
              const SizedBox(height: 14),
            ],
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions.isEmpty
                  ? const Center(
                child: Text(
                  'Aún no tienes entrenamientos registrados.\nInicia una sesión en la pestaña Telemetría.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF718078)),
                ),
              )
                  : ListView.separated(
                itemCount: _sessions.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _sessions[index];
                  final dist = item.distanceMeters >= 1000
                      ? '${(item.distanceMeters / 1000).toStringAsFixed(2)} km'
                      : '${item.distanceMeters.toStringAsFixed(1)} m';

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border:
                      Border.all(color: const Color(0xFFE1ECE6)),
                    ),
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
                                color: Color(0xFF159B68),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF159B68)
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.dominantIntensity,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF159B68),
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
            ),
          ],
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
          style: const TextStyle(fontSize: 11, color: Color(0xFF718078)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF18352A),
          ),
        ),
      ],
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _HistoryChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalSteps = sessions.fold<int>(0, (sum, item) => sum + item.steps);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1ECE6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF174B37).withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actividad reciente',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF18352A)),
              ),
              Text(
                '$totalSteps pasos',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF159B68)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 82,
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) => CustomPaint(
                painter: _HistoryBarsPainter(sessions: sessions, progress: progress),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBarsPainter extends CustomPainter {
  final List<WorkoutSession> sessions;
  final double progress;
  _HistoryBarsPainter({required this.sessions, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.isEmpty) return;
    final maxSteps = sessions.fold<int>(1, (maxValue, item) => item.steps > maxValue ? item.steps : maxValue);
    final slotWidth = size.width / sessions.length;
    final barWidth = slotWidth * 0.48;
    final baseY = size.height - 2;
    final guide = Paint()..color = const Color(0xFFEAF2ED)..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), guide);

    for (var i = 0; i < sessions.length; i++) {
      final ratio = sessions[i].steps / maxSteps;
      final barHeight = (size.height * 0.82 * ratio * progress).clamp(3.0, size.height * 0.82).toDouble();
      final left = slotWidth * i + (slotWidth - barWidth) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, baseY - barHeight, barWidth, barHeight),
        const Radius.circular(7),
      );
      final paint = Paint()
        ..color = Color.lerp(const Color(0xFFBCE8D0), const Color(0xFF159B68), (i + 1) / sessions.length)!;
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryBarsPainter oldDelegate) =>
      oldDelegate.sessions != sessions || oldDelegate.progress != progress;
}