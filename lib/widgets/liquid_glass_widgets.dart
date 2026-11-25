import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/workout_session.dart';

/// Paleta de colores extraída de tus capturas
class LiquidPalette {
  static const Color bgDark = Color(0xFF0A0A0C);
  static const Color surfaceDark = Color(0xFF151519);
  static const Color primaryOrange = Color(0xFFFF5520);
  static const Color secondaryAmber = Color(0xFFFF9F1C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9AA2);
}

/// CONTENEDOR BASE LIQUID GLASS (Desenfoque + Brillo especular + Reflejo líquido)
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? tintColor;
  final bool highlightBorder;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 24,
    this.tintColor,
    this.highlightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseTint = tintColor ?? Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseTint.withValues(alpha: 0.11),
                baseTint.withValues(alpha: 0.04),
                Colors.black.withValues(alpha: 0.25),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            border: Border.all(
              width: 1.2,
              color: highlightBorder
                  ? LiquidPalette.primaryOrange.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// WIDGET 1: Tarjeta Hero con Insignias de Racha (Inspirado en Imagen 1)
class StreakHeroLiquidCard extends StatelessWidget {
  final int currentSteps;
  final int activeDays;
  final int streakDays;

  const StreakHeroLiquidCard({
    super.key,
    required this.currentSteps,
    required this.activeDays,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      highlightBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Pasos y Actividad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down,
                      color: LiquidPalette.primaryOrange, size: 22),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      LiquidPalette.primaryOrange,
                      LiquidPalette.secondaryAmber
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LiquidPalette.primaryOrange.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_walk_rounded,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Escudo Ámbar (Días activos)
              Expanded(
                child: Row(
                  children: [
                    _ShieldBadge(
                      icon: Icons.directions_walk_rounded,
                      gradientColors: const [
                        Color(0xFFFFB703),
                        Color(0xFFFB8500),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'x$activeDays',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Días activos',
                          style: TextStyle(
                            color: LiquidPalette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Escudo Naranja/Coral (Racha seguida)
              Expanded(
                child: Row(
                  children: [
                    _ShieldBadge(
                      icon: Icons.star_rounded,
                      gradientColors: const [
                        Color(0xFFFF5520),
                        Color(0xFFD9381E),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'x$streakDays',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Seguidos',
                          style: TextStyle(
                            color: LiquidPalette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShieldBadge extends StatelessWidget {
  final IconData icon;
  final List<Color> gradientColors;

  const _ShieldBadge({required this.icon, required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

/// WIDGET 2: Gráfica Semanal con Curva Suave y Etiqueta 10k (Inspirado en Imagen 2)
class WeeklyStepsLiquidChart extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final int goalSteps;

  const WeeklyStepsLiquidChart({
    super.key,
    required this.sessions,
    this.goalSteps = 10000,
  });

  @override
  Widget build(BuildContext context) {
    // Últimos 7 registros o valores demo si aún está vacío
    final List<double> dailyValues = sessions.isEmpty
        ? [3200, 7400, 8100, 12800, 10200, 12100, 9100]
        : List.generate(7, (i) {
      if (i < sessions.length) return sessions[i].steps.toDouble();
      return 0.0;
    }).reversed.toList();

    final totalSteps =
    dailyValues.fold<double>(0, (sum, val) => sum + val).toInt();
    final avgSteps = (totalSteps / 7).toInt();

    return LiquidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$avgSteps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Prom. diario',
                    style: TextStyle(
                        color: LiquidPalette.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalSteps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Total semanal',
                    style: TextStyle(
                        color: LiquidPalette.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Semana',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 145,
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                return CustomPaint(
                  painter: _WeeklyCurvePainter(
                    values: dailyValues,
                    goalValue: goalSteps.toDouble(),
                    progress: progress,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DayLabel('D'),
                _DayLabel('L'),
                _DayLabel('M'),
                _DayLabel('X'),
                _DayLabel('J'),
                _DayLabel('V'),
                _DayLabel('S', isToday: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String text;
  final bool isToday;
  const _DayLabel(this.text, {this.isToday = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: isToday
            ? LiquidPalette.primaryOrange
            : LiquidPalette.textSecondary,
        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class _WeeklyCurvePainter extends CustomPainter {
  final List<double> values;
  final double goalValue;
  final double progress;

  _WeeklyCurvePainter({
    required this.values,
    required this.goalValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 46.0;
    final chartWidth = size.width - leftMargin;
    const maxVal = 15000.0;

    // Etiquetas eje Y (15k, 5k, 0)
    _drawText(canvas, '15k', const Offset(0, 0), LiquidPalette.textSecondary);
    _drawText(canvas, '5k', Offset(0, size.height * 0.62),
        LiquidPalette.textSecondary);
    _drawText(
        canvas, '0', Offset(0, size.height - 14), LiquidPalette.textSecondary);

    // Línea punteada de Meta (10k)
    final goalY = size.height * (1 - (goalValue / maxVal));
    final dashPaint = Paint()
      ..color = LiquidPalette.primaryOrange.withValues(alpha: 0.7)
      ..strokeWidth = 1.6;
    for (double x = leftMargin; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, goalY), Offset(x + 4, goalY), dashPaint);
    }

    // Etiqueta tipo flecha naranja "10k"
    final tagPath = ui.Path()
      ..moveTo(0, goalY - 12)
      ..lineTo(32, goalY - 12)
      ..lineTo(40, goalY)
      ..lineTo(32, goalY + 12)
      ..lineTo(0, goalY + 12)
      ..close();
    canvas.drawPath(tagPath, Paint()..color = LiquidPalette.primaryOrange);
    _drawText(canvas, '10k', Offset(5, goalY - 7), Colors.white, bold: true);

    if (values.isEmpty) return;

    // Puntos de la curva suave
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = leftMargin + (chartWidth * i / (values.length - 1));
      final clamped = (values[i] / maxVal).clamp(0.05, 1.0);
      final y = size.height - (clamped * size.height * progress);
      points.add(Offset(x, y));
    }

    final curvePath = ui.Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      curvePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    // Relleno degradado bajo la curva
    final fillPath = ui.Path.from(curvePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          LiquidPalette.primaryOrange.withValues(alpha: 0.45),
          LiquidPalette.primaryOrange.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(leftMargin, 0, chartWidth, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Línea brillante superior
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [LiquidPalette.primaryOrange, LiquidPalette.secondaryAmber],
      ).createShader(Rect.fromLTWH(leftMargin, 0, chartWidth, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(curvePath, strokePaint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeeklyCurvePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.progress != progress;
}

/// WIDGET 3: Barras Verticales Cápsula de Calorías con Estrellas (Imagen 2)
class CaloriesCapsuleBarsCard extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const CaloriesCapsuleBarsCard({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final days = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];
    // Porcentajes de cumplimiento diario (0.0 a 1.0)
    final ratios = sessions.isEmpty
        ? [0.35, 0.78, 0.58, 0.96, 0.82, 0.98, 0.72]
        : List.generate(7, (i) {
      if (i < sessions.length) {
        return (sessions[i].steps / 8000).clamp(0.15, 1.0);
      }
      return 0.15;
    }).reversed.toList();

    return LiquidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calorías',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final ratio = ratios[index];
              final reachedGoal = ratio >= 0.92;
              return Column(
                children: [
                  Container(
                    width: 24,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      width: 24,
                      height: 105 * ratio,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            LiquidPalette.primaryOrange,
                            Color(0xFFFF7847),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: reachedGoal
                            ? [
                          BoxShadow(
                            color: LiquidPalette.primaryOrange
                                .withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ]
                            : null,
                      ),
                      child: reachedGoal
                          ? const Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.star_rounded,
                              color: Colors.white, size: 14),
                        ),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[index],
                    style: const TextStyle(
                      color: LiquidPalette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// WIDGET 4: Calendario de Rachas Activas con Píldoras x5 / x7 (Imagen 1)
class MonthlyStreakCalendarCard extends StatelessWidget {
  final Set<int> completedDays;

  const MonthlyStreakCalendarCard({
    super.key,
    this.completedDays = const {4, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 24},
  });

  @override
  Widget build(BuildContext context) {
    const weekDays = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];

    return LiquidGlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.chevron_left_rounded, color: Colors.white),
              Text(
                'noviembre',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map((d) => Text(
              d,
              style: const TextStyle(
                color: LiquidPalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Fila ejemplo con píldora continua de racha x7 como en tu captura
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = i + 1;
              final isStar = day == 4;
              return _DayRingNode(
                label: '$day',
                progress: isStar ? 1.0 : 0.72,
                isCompletedStar: isStar,
              );
            }),
          ),
          const SizedBox(height: 10),
          // Píldora líquida de racha x7 (igual a tu imagen 1)
          Container(
            height: 36,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LiquidPalette.primaryOrange, Color(0xFFFF7034)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: LiquidPalette.primaryOrange.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'x7 Racha Semanal',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: Divider(color: Colors.white12)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Mejor que el 82.6% de los usuarios',
                  style: TextStyle(
                    color: LiquidPalette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayRingNode extends StatelessWidget {
  final String label;
  final double progress;
  final bool isCompletedStar;

  const _DayRingNode({
    required this.label,
    required this.progress,
    this.isCompletedStar = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompletedStar) {
      return Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: LiquidPalette.primaryOrange,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
      );
    }

    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2.8,
            backgroundColor: Colors.white12,
            valueColor:
            const AlwaysStoppedAnimation(LiquidPalette.primaryOrange),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}