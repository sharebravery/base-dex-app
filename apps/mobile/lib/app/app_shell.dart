import 'package:dex_app/core/responsive.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = windowClassForWidth(constraints.maxWidth);
        final destinations = [
          NavigationDestination(
            icon: const Icon(Icons.show_chart),
            label: context.l10n.market,
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz),
            label: context.l10n.trade,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            label: context.l10n.portfolio,
          ),
        ];

        if (windowClass == WindowClass.compact) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              destinations: destinations,
              onDestinationSelected: navigationShell.goBranch,
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final destination in destinations)
                    NavigationRailDestination(
                      icon: destination.icon,
                      label: Text(destination.label),
                    ),
                ],
                onDestinationSelected: navigationShell.goBranch,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: navigationShell),
            ],
          ),
        );
      },
    );
  }
}
