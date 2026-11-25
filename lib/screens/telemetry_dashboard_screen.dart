import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:ui' as ui;
import '../models/user_model.dart';
import '../models/workout_session.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../services/workout_storage_service.dart';

class TelemetryDashboardScreen extends StatefulWidget {
  final bool isTabActive;
  final VoidCallback onSessionSaved;

  const TelemetryDashboardScreen({
    super.key,
    required this.isTabActive,
    required this.onSessionSaved,
  });

  @override
  State<TelemetryDashboardScreen> createState() =>
      _TelemetryDashboardScreenState();
}

class _TelemetryDashboardScreenState extends State<TelemetryDashboardScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  final _storageService = WorkoutStorageService();
  final MapController _mapController = MapController();

  UserModel? _currentUser;

  // Estado de sesión de entrenamiento
  bool _isWorkoutRunning = false;
  bool _isPausedByLifecycle = false;
  int _elapsedSeconds = 0;
  Timer? _clockTimer;

  // Subscripciones de Hardware
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<Position>? _gpsSub;

  // Datos de Acelerómetro
  double _ax = 0.0, _ay = 0.0, _az = 0.0;
  double _accelMagnitude = 9.8;
  String _currentIntensity = 'Descanso';
  final Map<String, int> _intensityCounts = {
    'Descanso': 0,
    'Caminata': 0,
    'Trote': 0,
  };

  // Datos de Giroscopio
  double _gx = 0.0, _gy = 0.0, _gz = 0.0;

  // Datos de Podómetro
  int? _initialRawSteps;
  int _sessionSteps = 0;

  // Datos de GPS y Mapa
  LatLng _currentLatLng = const LatLng(19.4326, -99.1332); // Coordenada inicial por defecto
  bool _hasGpsFix = false;
  final List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUser();
  }

  @override
  void didUpdateWidget(covariant TelemetryDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Optimización de batería al cambiar de pestaña en NavigationBar
    if (oldWidget.isTabActive && !widget.isTabActive && _isWorkoutRunning) {
      _pauseHardwareStreams();
      setState(() => _isPausedByLifecycle = true);
    } else if (!oldWidget.isTabActive &&
        widget.isTabActive &&
        _isWorkoutRunning &&
        _isPausedByLifecycle) {
      _resumeHardwareStreams();
      setState(() => _isPausedByLifecycle = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isWorkoutRunning) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pauseHardwareStreams();
      if (mounted) {
        setState(() => _isPausedByLifecycle = true);
      }
    } else if (state == AppLifecycleState.resumed &&
        widget.isTabActive &&
        _isPausedByLifecycle) {
      _resumeHardwareStreams();
      if (mounted) {
        setState(() => _isPausedByLifecycle = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelAllSubscriptions();
    _clockTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getRegisteredUser();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _startWorkout() async {
    final granted = await PermissionService.requestTelemetryPermissions(context);
    if (!granted) return;

    setState(() {
      _isWorkoutRunning = true;
      _isPausedByLifecycle = false;
      _elapsedSeconds = 0;
      _initialRawSteps = null;
      _sessionSteps = 0;
      _routePoints.clear();
      _intensityCounts.updateAll((key, value) => 0);
    });

    _startClockTimer();
    _resumeHardwareStreams();
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPausedByLifecycle && mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _resumeHardwareStreams() {
    _cancelAllSubscriptions();

    // 1. Acelerómetro (Sensores Plus)
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((event) {
      final magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      // Descontamos gravedad base (~9.8 m/s²) para medir aceleración dinámica neta
      final dynamicAccel = (magnitude - 9.81).abs();

      String intensity;
      if (dynamicAccel < 1.3) {
        intensity = 'Descanso';
      } else if (dynamicAccel < 4.2) {
        intensity = 'Caminata';
      } else {
        intensity = 'Trote';
      }

      _intensityCounts[intensity] = (_intensityCounts[intensity] ?? 0) + 1;

      if (mounted) {
        setState(() {
          _ax = event.x;
          _ay = event.y;
          _az = event.z;
          _accelMagnitude = magnitude;
          _currentIntensity = intensity;
        });
      }
    });

    // 2. Giroscopio (Sensores Plus)
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((event) {
      if (mounted) {
        setState(() {
          _gx = event.x;
          _gy = event.y;
          _gz = event.z;
        });
      }
    });

    // 3. Podómetro (Pedometer)
    _stepSub = Pedometer.stepCountStream.listen(
          (StepCount event) {
        if (!mounted) return;
        setState(() {
          _initialRawSteps ??= event.steps;
          final delta = event.steps - _initialRawSteps!;
          _sessionSteps = delta >= 0 ? delta : 0;
        });
      },
      onError: (_) {
        // Algunos emuladores no reportan hardware step counter; se mantiene en 0 sin romper la UI
      },
    );

    // 4. GPS y Geolocalización en Tiempo Real (Geolocator)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // Actualiza cada 3 metros de desplazamiento
    );

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) {
      final newPoint = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentLatLng = newPoint;
          _hasGpsFix = true;
          _routePoints.add(newPoint);
        });
        _mapController.move(newPoint, 16.8);
      }
    });
  }

  void _pauseHardwareStreams() {
    _cancelAllSubscriptions();
  }

  void _cancelAllSubscriptions() {
    _accelSub?.cancel();
    _accelSub = null;
    _gyroSub?.cancel();
    _gyroSub = null;
    _stepSub?.cancel();
    _stepSub = null;
    _gpsSub?.cancel();
    _gpsSub = null;
  }

  Future<void> _stopAndSaveWorkout() async {
    _clockTimer?.cancel();
    _cancelAllSubscriptions();

    // Determinar intensidad predominante
    String dominant = 'Descanso';
    int maxSamples = -1;
    _intensityCounts.forEach((key, count) {
      if (count > maxSamples) {
        maxSamples = count;
        dominant = key;
      }
    });

    final stride = _currentUser?.strideLengthMeters ?? 0.74;
    final estimatedDistance = _sessionSteps * stride;

    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      durationSeconds: _elapsedSeconds,
      steps: _sessionSteps,
      distanceMeters: estimatedDistance,
      dominantIntensity: dominant,
      routePoints: List<LatLng>.from(_routePoints),
    );

    await _storageService.saveSession(session);

    if (!mounted) return;
    setState(() {
      _isWorkoutRunning = false;
      _isPausedByLifecycle = false;
    });

    widget.onSessionSaved();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entrenamiento guardado en el Historial local.'),
        backgroundColor: Color(0xFF159B68),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Color _intensityColor(String intensity) {
    switch (intensity) {
      case 'Trote':
        return const Color(0xFF159B68);
      case 'Caminata':
        return const Color(0xFF159B68);
      default:
        return const Color(0xFF718078);
    }
  }

  String _deviceTiltLabel() {
    if (_gx.abs() < 0.25 && _gy.abs() < 0.25) return 'Estable / Horizontal';
    if (_gx > 0.25) return 'Inclinación Frontal (Pitch +)';
    if (_gx < -0.25) return 'Inclinación Posterior (Pitch -)';
    if (_gy > 0.25) return 'Rotación Derecha (Roll +)';
    return 'Rotación Izquierda (Roll -)';
  }


  @override
  Widget build(BuildContext context) {
    final stride = _currentUser?.strideLengthMeters ?? 0.74;
    final distanceMeters = _sessionSteps * stride;
    final distanceText = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(2)} km'
        : '${distanceMeters.toStringAsFixed(1)} m';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera y estado de batería/sensores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Telemetría en Vivo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18352A),
                      ),
                    ),
                    Text(
                      _isWorkoutRunning
                          ? (_isPausedByLifecycle
                          ? 'Sensores en pausa (Ahorro de batería)'
                          : 'Capturando hardware en tiempo real')
                          : 'Listo para iniciar sesión',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isWorkoutRunning
                            ? const Color(0xFF159B68)
                            : const Color(0xFF718078),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF159B68)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 18, color: Color(0xFF159B68)),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_elapsedSeconds),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: Color(0xFF18352A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mapa GPS Interactivo (OpenStreetMap + Polyline)
            Container(
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE1ECE6)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLatLng,
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.My health',
                      ),
                      if (_routePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: const Color(0xFF159B68),
                              strokeWidth: 5.0,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLatLng,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF159B68)
                                    .withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.my_location,
                                  color: Color(0xFF159B68),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5FAF7).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _hasGpsFix
                            ? 'GPS: ${_currentLatLng.latitude.toStringAsFixed(5)}, ${_currentLatLng.longitude.toStringAsFixed(5)}'
                            : 'GPS: Esperando señal satelital...',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF159B68),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tarjeta 1: Podómetro y Distancia
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'PASOS SESIÓN',
                    value: '$_sessionSteps',
                    subtitle: 'Sensor Podómetro',
                    icon: Icons.directions_walk,
                    accentColor: const Color(0xFF159B68),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'DISTANCIA EST.',
                    value: distanceText,
                    subtitle: 'Zancada: ${(stride * 100).toInt()} cm',
                    icon: Icons.straighten,
                    accentColor: const Color(0xFF159B68),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tarjeta 2: Acelerómetro Triaxial e Intensidad
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE1ECE6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.speed, color: Color(0xFF159B68), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Acelerómetro Triaxial (m/s²)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF18352A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _intensityColor(_currentIntensity)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _intensityColor(_currentIntensity),
                          ),
                        ),
                        child: Text(
                          _currentIntensity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _intensityColor(_currentIntensity),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _AxisBadge(label: 'Eje X', value: _ax),
                      _AxisBadge(label: 'Eje Y', value: _ay),
                      _AxisBadge(label: 'Eje Z', value: _az),
                      _AxisBadge(label: '|Mag|', value: _accelMagnitude),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tarjeta 3: Giroscopio y Orientación
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE1ECE6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.screen_rotation_alt,
                              color: Color(0xFF159B68), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Giroscopio (rad/s)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF18352A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _deviceTiltLabel(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF718078),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _AxisBadge(label: 'Pitch (X)', value: _gx),
                      _AxisBadge(label: 'Roll (Y)', value: _gy),
                      _AxisBadge(label: 'Yaw (Z)', value: _gz),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Gráfica animada con lecturas actuales de acelerómetro y giroscopio
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE1ECE6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF174B37).withValues(alpha: 0.045),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.show_chart_rounded, color: Color(0xFF159B68)),
                      SizedBox(width: 8),
                      Text(
                        'Lecturas de movimiento',
                        style: TextStyle(
                          color: Color(0xFF18352A),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Magnitud actual de los sensores',
                    style: TextStyle(color: Color(0xFF718078), fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 112,
                    width: double.infinity,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeOutCubic,
                      builder: (context, progress, child) {
                        return CustomPaint(
                          painter: _SensorTrendPainter(
                            values: [
                              _ax.abs(), _ay.abs(), _az.abs(),
                              _gx.abs(), _gy.abs(), _gz.abs(),
                            ],
                            progress: progress,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Eje X', style: TextStyle(fontSize: 10, color: Color(0xFF718078))),
                      Text('Eje Y', style: TextStyle(fontSize: 10, color: Color(0xFF718078))),
                      Text('Eje Z', style: TextStyle(fontSize: 10, color: Color(0xFF718078))),
                      Text('Giro X/Y/Z', style: TextStyle(fontSize: 10, color: Color(0xFF718078))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botón Principal de Control
            SizedBox(
              height: 54,
              child: _isWorkoutRunning
                  ? FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _stopAndSaveWorkout,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text(
                  'Finalizar y Guardar Sesión',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
                  : FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF159B68),
                  foregroundColor: const Color(0xFFF5FAF7),
                ),
                onPressed: _startWorkout,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text(
                  'Iniciar Entrenamiento',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF718078),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18352A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: accentColor),
          ),
        ],
      ),
    );
  }
}

class _AxisBadge extends StatelessWidget {
  final String label;
  final double value;

  const _AxisBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF718078)),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
            color: Color(0xFF18352A),
          ),
        ),
      ],
    );
  }
}

class _SensorTrendPainter extends CustomPainter {
  final List<double> values;
  final double progress;

  _SensorTrendPainter({required this.values, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8F0EB)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;
    final maxValue = math.max(1.0, values.reduce((a, b) => a > b ? a : b)).toDouble();
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalized = (values[i] / maxValue).clamp(0.05, 1.0).toDouble();
      final y = size.height - (normalized * (size.height * 0.82)) - 5;
      points.add(Offset(x, y));
    }

    final visibleCount = (points.length * progress).ceil().clamp(1, points.length).toInt();
    final visible = points.take(visibleCount).toList();
    final path = ui.Path()
      ..moveTo(visible.first.dx, visible.first.dy);
    for (var i = 1; i < visible.length; i++) {
      final previous = visible[i - 1];
      final current = visible[i];
      final controlX = (previous.dx + current.dx) / 2;
      path.cubicTo(controlX, previous.dy, controlX, current.dy, current.dx, current.dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF159B68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF159B68);
    for (final point in visible) {
      canvas.drawCircle(point, 3.5, dotPaint);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = const Color(0xFF159B68).withValues(alpha: 0.13)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SensorTrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.progress != progress;
}