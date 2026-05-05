import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// A premium "grocery basket" hero card for the home screen.
///
/// Visual contract:
///   • The basket image sits at the absolute bottom of the z-stack — it acts
///     as the backdrop for the pile.
///   • Every ingredient (taller items like spaghetti / leeks, plus stickers
///     and stuff resting in the basket) is rendered ON TOP of the basket so
///     the user can drag any of them around.
///   • The title + subtitle live in a header strip ABOVE the play area; items
///     are clamped to the play area and can never overlap the text.
class InteractiveBasket extends StatefulWidget {
  const InteractiveBasket({super.key});

  @override
  State<InteractiveBasket> createState() => _InteractiveBasketState();
}

class _InteractiveBasketState extends State<InteractiveBasket>
    with SingleTickerProviderStateMixin {
  // Card geometry. Header is reserved for the title; items can never enter it.
  static const double _cardHeight = 360;
  static const double _headerHeight = 70;

  // Inner padding around the play area.
  static const double _padH = 14;
  static const double _padBottom = 16;

  late final AnimationController _floatController;

  // The full pile, rendered ON TOP of the basket. Positions are stored as
  // fractional offsets (0..1) of the play area so the layout works on any
  // phone width. The list order is the z-order: later items draw above
  // earlier ones (the active item floats to the top while being dragged).
  final List<_BasketItem> _items = [
    _BasketItem(
      id: 'spring',
      imagePath: 'assets/images/spring.png',
      relPos: const Offset(0.78, 0.02),
      size: 110,
      rotation: 0.18,
    ),
    _BasketItem(
      id: 'cornflakes',
      imagePath: 'assets/images/cornflakes.png',
      relPos: const Offset(0.04, 0.10),
      size: 86,
      rotation: -0.16,
    ),
    _BasketItem(
      id: 'oliveoil',
      imagePath: 'assets/images/oliveoil.png',
      relPos: const Offset(0.30, 0.04),
      size: 100,
      rotation: -0.05,
    ),
    _BasketItem(
      id: 'goodbites',
      imagePath: 'assets/images/goodbites.png',
      relPos: const Offset(0.46, 0.08),
      size: 86,
      rotation: 0.02,
    ),
    _BasketItem(
      id: 'pasta',
      imagePath: 'assets/images/pasta.png',
      relPos: const Offset(0.62, 0.16),
      size: 90,
      rotation: 0.16,
    ),
    _BasketItem(
      id: 'bagel',
      imagePath: 'assets/images/bagel.png',
      relPos: const Offset(0.55, 0.32),
      size: 56,
      rotation: 0.10,
    ),
    _BasketItem(
      id: 'crema',
      imagePath: 'assets/images/crema.png',
      relPos: const Offset(0.66, 0.40),
      size: 56,
      rotation: -0.05,
    ),
    _BasketItem(
      id: 'banana',
      imagePath: 'assets/images/banana.png',
      relPos: const Offset(0.74, 0.58),
      size: 80,
      rotation: -0.08,
    ),
    _BasketItem(
      id: 'meat',
      imagePath: 'assets/images/meat.png',
      relPos: const Offset(0.40, 0.44),
      size: 110,
      rotation: 0.06,
    ),
    _BasketItem(
      id: 'bread',
      imagePath: 'assets/images/bread.png',
      relPos: const Offset(0.22, 0.58),
      size: 96,
      rotation: -0.04,
    ),
    // ── Decorative stickers ────────────────────────────────────────────
    _BasketItem(
      id: 'mango',
      imagePath: 'assets/images/mango.png',
      relPos: const Offset(0.46, 0.08),
      size: 64,
      rotation: -0.06,
    ),
    _BasketItem(
      id: 'watermelon',
      imagePath: 'assets/images/watermelon.png',
      relPos: const Offset(0.02, 0.36),
      size: 60,
      rotation: -0.12,
    ),
    _BasketItem(
      id: 'strawberry',
      imagePath: 'assets/images/strawberry.png',
      relPos: const Offset(0.04, 0.78),
      size: 58,
      rotation: 0.10,
    ),
    _BasketItem(
      id: 'pink',
      imagePath: 'assets/images/pink.png',
      relPos: const Offset(0.50, 0.80),
      size: 80,
      rotation: -0.05,
    ),
  ];

  // ID of the item currently being dragged (so we can lift it visually and
  // bring it to the top of the z-order). Cleared on pan-end.
  String? _draggingId;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _cardHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEAF8E7),
            Color(0xFFFFF5D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Stack(
          children: [
            // ── Header strip (above the play area, items can't reach it).
            const Positioned(
              left: 18,
              right: 18,
              top: 14,
              child: _Header(),
            ),

            // ── Play area: basket at the bottom, items dragged on top.
            Positioned(
              left: _padH,
              right: _padH,
              top: _headerHeight,
              bottom: _padBottom,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  // While dragging, lift the active item to the top of the
                  // z-order so it visually pops above the rest of the pile.
                  final ordered = [..._items];
                  if (_draggingId != null) {
                    final idx =
                        ordered.indexWhere((i) => i.id == _draggingId);
                    if (idx != -1) {
                      final lifted = ordered.removeAt(idx);
                      ordered.add(lifted);
                    }
                  }

                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // 1. Basket — absolute bottom of the stack.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Center(
                            child: Transform.rotate(
                              angle: -0.04,
                              child: Image.asset(
                                'assets/images/basket.png',
                                width: w * 0.94,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. Every ingredient on top of the basket.
                      ...ordered.map((it) => _buildItem(it, w, h)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(_BasketItem item, double areaW, double areaH) {
    return _DraggableBasketItem(
      key: ValueKey(item.id),
      item: item,
      controller: _floatController,
      isDragging: _draggingId == item.id,
      onDragStart: () => setState(() => _draggingId = item.id),
      onDragEnd: () => setState(() => _draggingId = null),
      onMove: (delta) {
        // Convert percentage → px, apply delta, clamp to play area, convert
        // back to percentage. This is the guarantee that items can never
        // climb into the title region or fall off the card edge.
        final maxX = areaW - item.size;
        final maxY = areaH - item.size;
        final currentX = item.relPos.dx * maxX;
        final currentY = item.relPos.dy * maxY;
        final newX = (currentX + delta.dx).clamp(0.0, maxX);
        final newY = (currentY + delta.dy).clamp(0.0, maxY);
        setState(() {
          item.relPos = Offset(
            maxX > 0 ? newX / maxX : 0,
            maxY > 0 ? newY / maxY : 0,
          );
        });
      },
      areaW: areaW,
      areaH: areaH,
    );
  }
}

class _BasketItem {
  final String id;
  final String imagePath;
  Offset relPos; // fractional position in play area, 0..1 on each axis
  final double size;
  final double rotation;

  _BasketItem({
    required this.id,
    required this.imagePath,
    required this.relPos,
    required this.size,
    required this.rotation,
  });
}

class _DraggableBasketItem extends StatelessWidget {
  final _BasketItem item;
  final AnimationController controller;
  final bool isDragging;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final ValueChanged<Offset> onMove;
  final double areaW;
  final double areaH;

  const _DraggableBasketItem({
    super.key,
    required this.item,
    required this.controller,
    required this.isDragging,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onMove,
    required this.areaW,
    required this.areaH,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Soft hover bob, paused while dragging so the pointer feels precise.
        final floatY = isDragging
            ? 0.0
            : math.sin(controller.value * math.pi * 2) *
                _floatAmplitude(item.id);

        final maxX = areaW - item.size;
        final maxY = areaH - item.size;
        final px = item.relPos.dx * maxX;
        final py = item.relPos.dy * maxY;

        return Positioned(
          left: px,
          top: py + floatY,
          width: item.size,
          height: item.size,
          child: child!,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => onDragStart(),
        onPanEnd: (_) => onDragEnd(),
        onPanCancel: onDragEnd,
        onPanUpdate: (d) => onMove(d.delta),
        child: AnimatedScale(
          scale: isDragging ? 1.10 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: Transform.rotate(
            angle: item.rotation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDragging ? 0.22 : 0.12,
                    ),
                    blurRadius: isDragging ? 22 : 14,
                    offset: Offset(0, isDragging ? 14 : 8),
                  ),
                ],
              ),
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tiny per-item phase variation so they don't bob in perfect sync.
  double _floatAmplitude(String id) {
    return 1.6 + (id.hashCode % 4) * 0.4;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your fridge basket',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Drag items around to rearrange your pile',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
