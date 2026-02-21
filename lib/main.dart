import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
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
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _railExtended = prefs.getBool(_railExtendedKey) ?? true;
        });
      }
    } catch (_) {
      // SharedPreferences may not be available (e.g. web, some IDEs)
      // Keep default: rail extended
    }
  }

  Future<void> _saveRailState(bool extended) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_railExtendedKey, extended);
    } catch (_) {
      // Silently ignore if persistence isn't available
    }
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
            leading: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                IconButton(
                  icon: Icon(
                    _railExtended
                        ? Symbols.left_panel_close
                        : Symbols.left_panel_open,
                  ),
                  onPressed: _toggleRail,
                  tooltip: _railExtended ? 'Minimize' : 'Expand',
                ),
              ],
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Symbols.home),
                selectedIcon: Icon(Symbols.home, fill: 1),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Symbols.tune),
                selectedIcon: Icon(Symbols.tune, fill: 1),
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
