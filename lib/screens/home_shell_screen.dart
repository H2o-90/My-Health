import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'telemetry_dashboard_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  int _historyRefreshToken = 0;

  static const Color primaryOrange = Color(0xFFFF5520);
  static const Color amberGlow = Color(0xFFFF9F1C);
  static const Color backgroundColor = Color(0xFF0A0A0C);

  final List<String> _titles = [
    'Mi actividad',
    'Mi historial',
    'Mi perfil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MY HEALTH',
              style: TextStyle(
                color: primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: primaryOrange.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: primaryOrange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: primaryOrange,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TelemetryDashboardScreen(
            isTabActive: _selectedIndex == 0,
            onSessionSaved: () {
              setState(() {
                _historyRefreshToken++;
              });
            },
          ),
          HistoryScreen(
            key: ValueKey(_historyRefreshToken),
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151519).withValues(alpha: 0.78),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              height: 74,
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: primaryOrange.withValues(alpha: 0.22),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                  color: states.contains(WidgetState.selected)
                      ? primaryOrange
                      : const Color(0xFF9A9AA2),
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.monitor_heart_outlined,
                      size: 25, color: Color(0xFF9A9AA2)),
                  selectedIcon: Icon(Icons.monitor_heart_rounded,
                      color: primaryOrange, size: 27),
                  label: 'Actividad',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_rounded,
                      size: 25, color: Color(0xFF9A9AA2)),
                  selectedIcon: Icon(Icons.history_rounded,
                      color: primaryOrange, size: 27),
                  label: 'Historial',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded,
                      size: 25, color: Color(0xFF9A9AA2)),
                  selectedIcon:
                  Icon(Icons.person_rounded, color: primaryOrange, size: 27),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}