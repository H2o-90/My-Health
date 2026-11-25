import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Solicita permisos de Ubicación y Actividad Física con diálogo explicativo previo
  static Future<bool> requestTelemetryPermissions(BuildContext context) async {
    // 1. Verificar si el servicio GPS del dispositivo está encendido
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && context.mounted) {
      await _showInfoDialog(
        context: context,
        title: 'GPS Desactivado',
        content:
        'My Health necesita que actives la ubicación (GPS) del dispositivo para trazar tu ruta en tiempo real.',
        actionLabel: 'Abrir Ajustes GPS',
        onAction: () => Geolocator.openLocationSettings(),
      );
      return false;
    }

    // 2. Verificar estado actual de permisos
    final locationStatus = await Permission.locationWhenInUse.status;
    final activityStatus = await Permission.activityRecognition.status;

    if (locationStatus.isGranted && activityStatus.isGranted) {
      return true;
    }

    // 3. Mostrar diálogo explicativo antes de solicitar permisos
    if (context.mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.sensors, color: Color(0xFF06B6D4)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Permisos de Telemetría',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'Para capturar tus pasos en tiempo real y mapear tu recorrido mediante GPS, NexPulse requiere acceso a:\n\n'
                '• Ubicación precisa (GPS en vivo)\n'
                '• Actividad física (Sensor podómetro)',
            style: TextStyle(color: Color(0xFFCBD5E1), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Conceder Permisos'),
            ),
          ],
        ),
      );

      if (proceed != true) return false;
    }

    // 4. Solicitar permisos al sistema operativo
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.activityRecognition,
    ].request();

    final locGranted =
        statuses[Permission.locationWhenInUse]?.isGranted ?? false;
    final actGranted =
        statuses[Permission.activityRecognition]?.isGranted ?? false;

    if (locGranted && actGranted) {
      return true;
    }

    // 5. Manejo de rechazo permanente
    final permanentlyDenied =
        (statuses[Permission.locationWhenInUse]?.isPermanentlyDenied ?? false) ||
            (statuses[Permission.activityRecognition]?.isPermanentlyDenied ??
                false);

    if (permanentlyDenied && context.mounted) {
      await _showInfoDialog(
        context: context,
        title: 'Permisos Bloqueados',
        content:
        'Has denegado permanentemente los permisos de ubicación o actividad física. Habilítalos manualmente en la configuración de la aplicación.',
        actionLabel: 'Ir a Configuración',
        onAction: () => openAppSettings(),
      );
    }

    return false;
  }

  static Future<void> _showInfoDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String actionLabel,
    required VoidCallback onAction,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Color(0xFFCBD5E1))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: const Color(0xFF0F172A),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onAction();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}