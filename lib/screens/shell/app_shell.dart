import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../discover/suggestions_screen.dart';
import '../home/home_screen.dart';
import '../pantry/pantry_screen.dart';
import '../profile/profile_screen.dart';

/// Top-level shell with bottom navigation. Holds Home, Discover, Pantry,
/// Profile tabs in an IndexedStack so each preserves its scroll/state.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <_NavItem>[
      const _NavItem(
        icon: Icons.home_rounded,
        label: 'Home',
      ),
      const _NavItem(
        icon: Icons.explore_rounded,
        label: 'Discover',
      ),
      const _NavItem(
        icon: Icons.kitchen_rounded,
        label: 'Fridge',
      ),
      const _NavItem(
        icon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenPantry: () => setState(() => _index = 2)),
          const SuggestionsScreen(),
          const PantryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = _index == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _index = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primarySurface
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tabs[i].icon,
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.textTertiary,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
