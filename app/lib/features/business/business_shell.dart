import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../landing_screen.dart';
import 'customers_tab.dart';
import 'dashboard_tab.dart';
import 'editor_tab.dart';
import 'scanner_tab.dart';

class BusinessShell extends StatefulWidget {
  const BusinessShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<BusinessShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();

    if (!session.isLoggedIn) {
      return const LandingScreen();
    }

    final pages = [
      DashboardTab(onEditProgram: () => setState(() => _index = 1)),
      const EditorTab(),
      ScannerTab(active: _index == 2),
      const CustomersTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: SellaColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style_rounded),
              label: 'Tarjeta',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_rounded),
              selectedIcon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Escanear',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Clientes',
            ),
          ],
        ),
      ),
    );
  }
}
