import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

void main() {
  runApp(const MainApp());
}

const _railExtendedKey = 'navigation_rail_extended';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(ThemeData.light().textTheme);
    return MaterialApp(
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.system,
      home: const MainScaffold(),
    );
  }
}

enum RailDestination { home, customization }

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  RailDestination _selectedDestination = RailDestination.home;
  bool _railExtended = true;

  @override
  void initState() {
    super.initState();
    _loadRailState();
  }

  Future<void> _loadRailState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _railExtended = prefs.getBool(_railExtendedKey) ?? true;
    });
  }

  Future<void> _saveRailState(bool extended) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_railExtendedKey, extended);
  }

  void _toggleRail() {
    setState(() {
      _railExtended = !_railExtended;
      _saveRailState(_railExtended);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: _railExtended,
            leading: IconButton(
              icon: Icon(
                _railExtended ? Icons.chevron_left : Icons.chevron_right,
              ),
              onPressed: _toggleRail,
              tooltip: _railExtended ? 'Minimize' : 'Expand',
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: Text('Customization'),
              ),
            ],
            selectedIndex: _selectedDestination.index,
            onDestinationSelected: (index) {
              setState(() {
                _selectedDestination = RailDestination.values[index];
              });
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppBar(
                  title: Text(
                    _selectedDestination == RailDestination.home
                        ? 'Home'
                        : 'Customization',
                  ),
                ),
                Expanded(
                  child: _selectedDestination == RailDestination.home
                      ? const _HomeBody()
                      : const _CustomizationBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home'),
    );
  }
}

class _CustomizationBody extends StatelessWidget {
  const _CustomizationBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Customization settings'),
    );
  }
}
