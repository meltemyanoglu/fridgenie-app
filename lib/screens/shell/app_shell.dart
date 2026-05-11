import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_colors.dart';
import '../grocery/grocery_screen.dart';
import '../home/home_screen.dart';
import '../pantry/pantry_screen.dart';
import '../profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _showNav = true;

  void _setNavVisible(bool visible) {
    if (_showNav == visible) return;
    setState(() => _showNav = visible);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <_NavItem>[
      const _NavItem(icon: Icons.home_rounded, label: 'Home'),
      const _NavItem(icon: Icons.kitchen_rounded, label: 'Fridge'),
      const _NavItem(icon: Icons.shopping_cart_outlined, label: 'List'),
      const _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      // Listens to vertical scroll direction across child screens and
      // hides the bottom navigation bar when scrolling down,
      // shows it again when scrolling up to maximize content space.
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.vertical) return false;

          if (notification.direction == ScrollDirection.reverse) {
            _setNavVisible(false);
          } else if (notification.direction == ScrollDirection.forward) {
            _setNavVisible(true);
          }

          return false;
        },
        child: Stack(
          children: [
            IndexedStack(
              index: _index,
              children: [
                HomeScreen(onOpenPantry: () => setState(() => _index = 1)),
                const PantryScreen(),
                const GroceryScreen(),
                const ProfileScreen(),
              ],
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: 14,
              right: 14,
              bottom: _showNav ? 8 : -110,
              child: SafeArea(
                top: false,
                child: Container(
                  height: 78,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(tabs.length, (i) {
                      final selected = _index == i;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _index = i;
                              _showNav = true;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.all(3),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primarySurface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}