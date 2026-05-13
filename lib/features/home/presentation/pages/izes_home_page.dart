import 'package:flutter/material.dart';

import '../../../../core/config/backend_config.dart';
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

  @override
  Widget build(BuildContext context) {
    final clientLabel = BackendConfig.hasClientId
        ? BackendConfig.clientId
        : 'cliente nao configurado';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IZES', style: Theme.of(context).textTheme.titleLarge),
            Text(clientLabel, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(
                Icons.eco_outlined,
                size: 16,
                color: IzesColors.green,
              ),
              label: Text(
                BackendConfig.hasAppToken ? 'app token ativo' : 'sem app token',
              ),
            ),
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
                  'Cliente',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(clientLabel),
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
