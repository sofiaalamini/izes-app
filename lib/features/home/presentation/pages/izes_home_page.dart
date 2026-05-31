import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../monitoring/presentation/pages/monitoring_page.dart';

enum HomeSection {
  dashboard('Dashboard', Icons.home_rounded),
  alerts('Alertas', Icons.warning_amber_rounded),
  monitoring('Clima', Icons.water_drop_rounded),
  ai('Assistente IA', Icons.chat_bubble_outline_rounded);

  const HomeSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class IzesHomePage extends StatefulWidget {
  const IzesHomePage({super.key});

  @override
  State<IzesHomePage> createState() => _IzesHomePageState();
}

class _IzesHomePageState extends State<IzesHomePage> {
  final AuthService _authService = AuthService();
  HomeSection _section = HomeSection.dashboard;

  static const _primarySections = [
    HomeSection.dashboard,
    HomeSection.alerts,
    HomeSection.monitoring,
    HomeSection.ai,
  ];

  Widget _pageForSection(HomeSection section) {
    switch (section) {
      case HomeSection.dashboard:
        return const DashboardPage();
      case HomeSection.alerts:
        return const AlertsPage();
      case HomeSection.monitoring:
        return const MonitoringPage();
      case HomeSection.ai:
        return const AiAssistantPage();
    }
  }

  String _subtitleForSection(HomeSection section) {
    switch (section) {
      case HomeSection.dashboard:
        return 'Resumo do dia';
      case HomeSection.alerts:
        return 'Prioridades do campo';
      case HomeSection.monitoring:
        return 'Clima e sensores';
      case HomeSection.ai:
        return 'Orientacao rapida';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userLabel = user?.nome.isNotEmpty == true ? user!.nome : 'IZES';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IZES', style: Theme.of(context).textTheme.titleLarge),
            Text(
              _subtitleForSection(_section),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _authService.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ListTile(
                title: Text(
                  userLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(user?.email ?? ''),
                trailing: TextButton(
                  onPressed: _authService.logout,
                  child: const Text('Sair'),
                ),
              ),
              const Divider(),
              ...HomeSection.values.map(
                (item) => ListTile(
                  leading: Icon(
                    item.icon,
                    color: item == _section
                        ? IzesColors.green
                        : IzesColors.muted,
                  ),
                  title: Text(item.label),
                  selected: item == _section,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _section = item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _pageForSection(_section),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _primarySections.indexOf(_section),
        onDestinationSelected: (index) {
          setState(() => _section = _primarySections[index]);
        },
        destinations: _primarySections
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
