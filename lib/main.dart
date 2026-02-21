import 'package:flutter/material.dart';

import 'theme.dart';

void main() {
  runApp(const MainApp());
}

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

enum DrawerSection { home, customization }

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  DrawerSection _selectedSection = DrawerSection.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSection == DrawerSection.home ? 'Home' : 'Customization'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              selected: _selectedSection == DrawerSection.home,
              onTap: () {
                setState(() => _selectedSection = DrawerSection.home);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Customization'),
              selected: _selectedSection == DrawerSection.customization,
              onTap: () {
                setState(() => _selectedSection = DrawerSection.customization);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _selectedSection == DrawerSection.home
          ? const _HomeBody()
          : const _CustomizationBody(),
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
