import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../data/mock/mock_ingredients.dart';
import '../data/models/ingredient.dart';

// Public — callers can extend the magnet list
class MagnetItem {
  final String key;
  final String emoji;
  final String? imagePath; // e.g. 'assets/magnets/cat.png'
  const MagnetItem({required this.key, required this.emoji, this.imagePath});
}

class FridgeDoorWidget extends StatefulWidget {
  final Set<String> inventoryIds;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelected;
  final VoidCallback? onScanTap;

  const FridgeDoorWidget({
    super.key,
    required this.inventoryIds,
    required this.selectedIds,
    required this.onToggleSelected,
    this.onScanTap,
  });

  @override
  State<FridgeDoorWidget> createState() => _FridgeDoorWidgetState();
}

class _FridgeDoorWidgetState extends State<FridgeDoorWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _isDoorOpen = false;

  // Placed magnets: key → normalized position (0–1) on the fridge area
  final Map<String, Offset> _placements = {};

  // All magnets available in the tray
  static const _trayMagnets = [
    MagnetItem(key: 'm1',  emoji: '🧲', imagePath: 'assets/magnets/magnet1.png'),
    MagnetItem(key: 'm2',  emoji: '🧲', imagePath: 'assets/magnets/magnet2.png'),
    MagnetItem(key: 'm3',  emoji: '🧲', imagePath: 'assets/magnets/magnet3.png'),
    MagnetItem(key: 'm4',  emoji: '🧲', imagePath: 'assets/magnets/magnet4.png'),
    MagnetItem(key: 'm5',  emoji: '🧲', imagePath: 'assets/magnets/magnet5.png'),
    MagnetItem(key: 'm6',  emoji: '🧲', imagePath: 'assets/magnets/magnet6.png'),
    MagnetItem(key: 'm7',  emoji: '🧲', imagePath: 'assets/magnets/magnet7.png'),
    MagnetItem(key: 'm8',  emoji: '🧲', imagePath: 'assets/magnets/magnet8.png'),
    MagnetItem(key: 'm9',  emoji: '🧲', imagePath: 'assets/magnets/magnet9.png'),
    MagnetItem(key: 'm10', emoji: '🧲', imagePath: 'assets/magnets/magnet10.png'),
    MagnetItem(key: 'm11', emoji: '🧲', imagePath: 'assets/magnets/magnet11.png'),
    MagnetItem(key: 'm12', emoji: '🧲', imagePath: 'assets/magnets/magnet12.png'),
    MagnetItem(key: 'm13', emoji: '🧲', imagePath: 'assets/magnets/magnet13.png'),
    MagnetItem(key: 'm14', emoji: '🧲', imagePath: 'assets/magnets/magnet14.png'),
    MagnetItem(key: 'm15', emoji: '🧲', imagePath: 'assets/magnets/magnet15.png'),
    MagnetItem(key: 'm16', emoji: '🧲', imagePath: 'assets/magnets/magnet16.png'),
    MagnetItem(key: 'm17', emoji: '🧲', imagePath: 'assets/magnets/magnet17.png'),
    MagnetItem(key: 'm18', emoji: '🧲', imagePath: 'assets/magnets/magnet18.png'),
    MagnetItem(key: 'm19', emoji: '🧲', imagePath: 'assets/magnets/magnet19.png'),
    MagnetItem(key: 'm20', emoji: '🧲', imagePath: 'assets/magnets/magnet20.png'),
    MagnetItem(key: 'm21', emoji: '🧲', imagePath: 'assets/magnets/magnet21.png'),
    MagnetItem(key: 'm22', emoji: '🧲', imagePath: 'assets/magnets/magnet22.png'),
    MagnetItem(key: 'm23', emoji: '🧲', imagePath: 'assets/magnets/magnet23.png'),
    MagnetItem(key: 'm24', emoji: '🧲', imagePath: 'assets/magnets/magnet24.png'),
    MagnetItem(key: 'm25', emoji: '🧲', imagePath: 'assets/magnets/magnet25.png'),
    MagnetItem(key: 'm26', emoji: '🧲', imagePath: 'assets/magnets/magnet26.png'),
    MagnetItem(key: 'm27', emoji: '🧲', imagePath: 'assets/magnets/magnet27.png'),
  ];

  // Default positions for newly placed magnets (cycles if more than list length)
  static const _defaultPositions = [
    Offset(0.10, 0.10), Offset(0.55, 0.08), Offset(0.65, 0.48),
    Offset(0.08, 0.58), Offset(0.38, 0.68), Offset(0.60, 0.72),
    Offset(0.28, 0.30), Offset(0.70, 0.20), Offset(0.42, 0.12),
    Offset(0.18, 0.80), Offset(0.50, 0.40), Offset(0.78, 0.62),
    Offset(0.22, 0.50), Offset(0.45, 0.80), Offset(0.68, 0.32),
    Offset(0.12, 0.35), Offset(0.55, 0.55), Offset(0.32, 0.18),
    Offset(0.75, 0.75), Offset(0.05, 0.70), Offset(0.48, 0.25),
    Offset(0.62, 0.15), Offset(0.20, 0.65), Offset(0.40, 0.50),
    Offset(0.72, 0.45), Offset(0.15, 0.22), Offset(0.58, 0.85),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isDoorOpen = !_isDoorOpen);
    _isDoorOpen ? _ctrl.forward() : _ctrl.reverse();
  }

  void _toggleMagnet(String key) {
    setState(() {
      if (_placements.containsKey(key)) {
        _placements.remove(key);
      } else {
        final idx = _placements.length % _defaultPositions.length;
        _placements[key] = _defaultPositions[idx];
      }
    });
  }

  void _moveMagnet(String key, double dx, double dy) {
    // Mutates map synchronously so subsequent pan deltas read fresh value
    setState(() => _placements[key] = Offset(dx, dy));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Fridge body ──────────────────────────────────────────────────
        Container(
          height: 420,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: _FridgeInterior(
                        inventoryIds: widget.inventoryIds,
                        selectedIds: widget.selectedIds,
                        onToggleSelected: widget.onToggleSelected,
                        onScanTap: widget.onScanTap,
                        onClose: _toggle,
                        isOpen: _isDoorOpen,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _anim,
                      builder: (ctx, child) => Transform.translate(
                        offset: Offset(-w * _anim.value, 0),
                        child: _FridgeDoor(
                          allMagnets: _trayMagnets,
                          placements: _placements,
                          onMoveMagnet: _moveMagnet,
                          doorWidth: w,
                          onTapHandle: _toggle,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Magnet tray ──────────────────────────────────────────────────
        _MagnetTray(
          magnets: _trayMagnets,
          placements: _placements,
          onToggle: _toggleMagnet,
        ),
      ],
    );
  }
}

// ── Door ──────────────────────────────────────────────────────────────────────

class _FridgeDoor extends StatelessWidget {
  final List<MagnetItem> allMagnets;
  final Map<String, Offset> placements;
  final void Function(String key, double dx, double dy) onMoveMagnet;
  final double doorWidth;
  final VoidCallback onTapHandle;

  const _FridgeDoor({
    required this.allMagnets,
    required this.placements,
    required this.onMoveMagnet,
    required this.doorWidth,
    required this.onTapHandle,
  });

  static const _freezerH = 72.0;
  static const _dividerH = 5.0;
  static const _totalH   = 420.0;
  static const _fridgeH  = _totalH - _freezerH - _dividerH;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: doorWidth,
      height: _totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Body gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFADC7A8), Color(0xFF88A884), Color(0xFF5E8060)],
                ),
              ),
            ),
          ),

          // Freezer compartment
          Positioned(
            top: 0, left: 0, right: 0, height: _freezerH,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6F9472), Color(0xFF517354)],
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 22, height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
          ),

          // Divider
          Positioned(
            top: _freezerH, left: 0, right: 0, height: _dividerH,
            child: Container(color: Colors.black.withValues(alpha: 0.28)),
          ),

          // Placed magnets — draggable
          for (final entry in placements.entries)
            Builder(builder: (ctx) {
              final magnet = allMagnets.firstWhere(
                (m) => m.key == entry.key,
                orElse: () => MagnetItem(key: entry.key, emoji: '📌'),
              );
              final pos = entry.value;
              final left = pos.dx * doorWidth - 24;
              final top  = _freezerH + _dividerH + pos.dy * _fridgeH - 24;

              return Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final cur = placements[entry.key]!;
                    final dx = (cur.dx + details.delta.dx / doorWidth).clamp(0.0, 0.90);
                    final dy = (cur.dy + details.delta.dy / _fridgeH).clamp(0.0, 0.90);
                    onMoveMagnet(entry.key, dx, dy);
                  },
                  child: _MagnetWidget(
                    emoji: magnet.emoji,
                    imagePath: magnet.imagePath,
                  ),
                ),
              );
            }),

          // Gloss sheen
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.07),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Chrome handle
          Positioned(
            right: 14, top: 120,
            child: GestureDetector(
              onTap: onTapHandle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 16, height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFB8B8B8), Color(0xFFFFFFFF), Color(0xFF989898)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(-3, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Open hint
          Positioned(
            bottom: 14, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'tap handle to peek inside →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Magnet tray ───────────────────────────────────────────────────────────────

class _MagnetTray extends StatelessWidget {
  final List<MagnetItem> magnets;
  final Map<String, Offset> placements;
  final void Function(String key) onToggle;

  const _MagnetTray({
    required this.magnets,
    required this.placements,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            '🧲  Magnets · tap to stick, drag to move',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: magnets.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final m = magnets[i];
              final placed = placements.containsKey(m.key);
              return GestureDetector(
                onTap: () => onToggle(m.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: placed
                        ? AppColors.primarySurface
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: placed ? AppColors.primary : AppColors.outline,
                      width: placed ? 2.0 : 1.2,
                    ),
                    boxShadow: placed
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      m.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                m.imagePath!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => Text(
                                  m.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            )
                          : Text(m.emoji, style: const TextStyle(fontSize: 24)),
                      if (placed)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Interior ──────────────────────────────────────────────────────────────────

class _FridgeInterior extends StatelessWidget {
  final Set<String> inventoryIds;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelected;
  final VoidCallback? onScanTap;
  final VoidCallback onClose;
  final bool isOpen;

  const _FridgeInterior({
    required this.inventoryIds,
    required this.selectedIds,
    required this.onToggleSelected,
    required this.onClose,
    required this.isOpen,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final inventory = MockIngredients.all
        .where((i) => inventoryIds.contains(i.id))
        .toList();

    final n = inventory.length;
    final s1End = (n / 3).ceil().clamp(0, n);
    final s2End = (s1End + ((n - s1End) / 2).ceil()).clamp(0, n);
    final shelf1 = inventory.sublist(0, s1End);
    final shelf2 = inventory.sublist(s1End, s2End);
    final shelf3 = inventory.sublist(s2End);

    return Container(
      color: const Color(0xFFF2F6F2),
      child: Stack(
        children: [
          Column(
            children: [
              // Vent
              Container(
                height: 18,
                color: const Color(0xFFE6EDE6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(10, (_) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 3, height: 3,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB4CCB4), shape: BoxShape.circle,
                    ),
                  )),
                ),
              ),
              Expanded(child: _ShelfContent(
                items: shelf1,
                selectedIds: selectedIds,
                onTap: onToggleSelected,
              )),
              _WireShelf(),
              Expanded(child: _ShelfContent(
                items: shelf2,
                selectedIds: selectedIds,
                onTap: onToggleSelected,
              )),
              _WireShelf(),
              Expanded(child: _ShelfContent(
                items: shelf3,
                selectedIds: selectedIds,
                onTap: onToggleSelected,
              )),
              _WireShelf(),
              Expanded(child: _ShelfContent(
                items: const [],
                selectedIds: selectedIds,
                onTap: onToggleSelected,
                scanTap: onScanTap,
              )),
              // Crisper drawer
              Container(
                height: 48,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEEBDE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCADDCA), width: 1),
                ),
                child: const Center(
                  child: Text(
                    '🥦  Crisper drawer',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A987A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Close button
          if (isOpen)
            Positioned(
              top: 24, right: 10,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCCDDCC), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left_rounded, size: 14, color: Color(0xFF5A8060)),
                      Text(
                        'close',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5A8060),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (inventory.isEmpty)
            Positioned.fill(child: _EmptyState(onScanTap: onScanTap)),
        ],
      ),
    );
  }
}

class _ShelfContent extends StatelessWidget {
  final List<Ingredient> items;
  final Set<String> selectedIds;
  final void Function(String) onTap;
  final VoidCallback? scanTap;

  const _ShelfContent({
    required this.items,
    required this.selectedIds,
    required this.onTap,
    this.scanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 4, runSpacing: 4,
              children: items.map((ing) {
                final sel = selectedIds.contains(ing.id);
                return GestureDetector(
                  onTap: () => onTap(ing.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primarySurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.primary : const Color(0xFFDDEEDD),
                        width: sel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ing.emoji, style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          ing.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: sel ? AppColors.primaryDark : const Color(0xFF445544),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (scanTap != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: scanTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8, offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.center_focus_strong_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WireShelf extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFCDD8CD),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 4, offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onScanTap;
  const _EmptyState({this.onScanTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F6F2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🥺', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            'Your fridge is empty!',
            style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF5A8060),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add ingredients below or scan your fridge',
            style: TextStyle(fontSize: 11, color: Color(0xFF8AAA8A)),
          ),
          if (onScanTap != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onScanTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  '📸  Scan my fridge',
                  style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Magnet widget ─────────────────────────────────────────────────────────────

class _MagnetWidget extends StatelessWidget {
  final String emoji;
  final String? imagePath;
  const _MagnetWidget({required this.emoji, this.imagePath});

  @override
  Widget build(BuildContext context) {
    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.28),
      blurRadius: 6,
      offset: const Offset(1, 2),
    );

    if (imagePath != null) {
      return Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [shadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            imagePath!,
            width: 48, height: 48,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, st) =>
                _EmojiMagnet(emoji: emoji, shadow: shadow),
          ),
        ),
      );
    }
    return _EmojiMagnet(emoji: emoji, shadow: shadow);
  }
}

class _EmojiMagnet extends StatelessWidget {
  final String emoji;
  final BoxShadow shadow;
  const _EmojiMagnet({required this.emoji, required this.shadow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [shadow],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}
