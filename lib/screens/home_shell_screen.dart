
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

  static const Color primaryGreen = Color(0xFF159B68);
  static const Color darkGreen = Color(0xFF064E3B);
  static const Color backgroundColor = Color(0xFFF5FAF7);

  final List<String> _titles = [
    'Mi actividad',
    'Mi historial',
    'Mi perfil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MY HEALTH',
              style: TextStyle(
                color: darkGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                color: Color(0xFF174B37),
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: darkGreen,
                size: 25,
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

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(25),
          ),
          child: NavigationBar(
            height: 75,
            labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected) ? primaryGreen : const Color(0xFF718078),
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            )),
            backgroundColor: Colors.white,
            elevation: 0,

            indicatorColor: const Color(0xFFD1FAE5),

            labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,

            selectedIndex: _selectedIndex,

            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },

            destinations: const [
              NavigationDestination(
                icon: Icon(
                  Icons.monitor_heart_outlined,
                  size: 25,
                ),
                selectedIcon: Icon(
                  Icons.monitor_heart_rounded,
                  color: primaryGreen,
                  size: 27,
                ),
                label: 'Actividad',
              ),

              NavigationDestination(
                icon: Icon(
                  Icons.history_rounded,
                  size: 25,
                ),
                selectedIcon: Icon(
                  Icons.history_rounded,
                  color: primaryGreen,
                  size: 27,
                ),
                label: 'Historial',
              ),

              NavigationDestination(
                icon: Icon(
                  Icons.person_outline_rounded,
                  size: 25,
                ),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: primaryGreen,
                  size: 27,
                ),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}