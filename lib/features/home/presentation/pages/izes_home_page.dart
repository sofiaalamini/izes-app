import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/offline_banner.dart';
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
        return 'Orientação rápida';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userLabel = user?.nome.isNotEmpty == true ? user!.nome : 'IZES';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/branding/logo_mark.png', height: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _section.label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: IzesColors.cream,
                    ),
                  ),
                  Text(
                    _subtitleForSection(_section),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: IzesColors.cream.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Center(
              child: Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: IzesColors.cream.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: IzesColors.cream.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    userLabel.trim().isEmpty
                        ? 'I'
                        : userLabel.trim().substring(0, 1).toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: IzesColors.cream,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: IzesColors.greenDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset('assets/branding/logo_full.png', height: 44),
              ),
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
                  selectedTileColor: IzesColors.greenSoft,
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
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _pageForSection(_section)),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: IzesColors.surface,
          border: Border(top: BorderSide(color: IzesColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _primarySections.indexOf(_section),
          onDestinationSelected: (index) {
            setState(() => _section = _primarySections[index]);
          },
          destinations: _primarySections
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon, size: 20),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
