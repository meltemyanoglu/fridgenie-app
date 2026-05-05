import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// A premium, layered "grocery basket" hero card that lives at the top of the
/// home screen. Items are arranged in z-layers (some sit BEHIND the basket so
/// they look like they're piled inside it; others sit IN FRONT so they look
/// like they're spilling forward or stuck on as labels).
///
/// Users can drag any item around within a bounded play area below the title,
/// and the items respect their original layer so the composition stays
/// believable. Layout is responsive — positions are expressed as percentages
/// of the available drag area.
class InteractiveBasket extends StatefulWidget {
  const InteractiveBasket({super.key});

  @override
  State<InteractiveBasket> createState() => _InteractiveBasketState();
}

class _InteractiveBasketState extends State<InteractiveBasket>
    with SingleTickerProviderStateMixin {
  // Overall card height — enough to fit title + basket pile without crowding.
  static const double _cardHeight = 360;

  // Header (title + subtitle) reserves the top of the card. Items can never
  // enter this region — that's the whole point of the bounded drag.
  static const double _headerHeight = 78;

  // Inner padding around the drag region.
  static const double _padH = 14;
  static const double _padBottom = 16;

  late final AnimationController _floatController;

  // The full pile, in z-order. Earlier items are drawn first.
  // `layer` decides whether an item renders BEHIND or IN FRONT of the basket
  // body. Positions are stored as fractional offsets (0..1) of the drag area
  // so the layout is responsive to different phone widths.
  final List<_BasketItem> _items = [
    // ── BACK LAYER (tall things standing in the basket / sticking out the back)
    _BasketItem(
      id: 'spring',
      imagePath: 'assets/images/spring.png',
      relPos: const Offset(0.78, 0.02),
      size: 110,
      rotation: 0.18,
      layer: _Layer.back,
    ),
    _BasketItem(
      id: 'oliveoil',
      imagePath: 'assets/images/oliveoil.png',
      relPos: const Offset(0.34, 0.06),
      size: 70,
      rotation: -0.05,
      layer: _Layer.back,
    ),
    _BasketItem(
      id: 'goodbites',
      imagePath: 'assets/images/goodbites.png',
      relPos: const Offset(0.46, 0.10),
      size: 86,
      rotation: 0.02,
      layer: _Layer.back,
    ),
    _BasketItem(
      id: 'pasta',
      imagePath: 'assets/images/pasta.png',
      relPos: const Offset(0.62, 0.14),
      size: 90,
      rotation: 0.16,
      layer: _Layer.back,
    ),
    _BasketItem(
      id: 'cornflakes',
      imagePath: 'assets/images/cornflakes.png',
      relPos: const Offset(0.10, 0.16),
      size: 86,
      rotation: -0.16,
      layer: _Layer.back,
    ),
    _BasketItem(
      id: 'bagel',
      imagePath: 'assets/images/bagel.png',
      relPos: const Offset(0.55, 0.32),
      size: 60,
      rotation: 0.10,
      layer: _Layer.back,
    ),

    // ── FRONT LAYER (things resting on the basket front + decorative stickers)
    _BasketItem(
      id: 'meat',
      imagePath: 'assets/images/meat.png',
      relPos: const Offset(0.42, 0.50),
      size: 110,
      rotation: 0.06,
      layer: _Layer.front,
    ),
    _BasketItem(
      id: 'bread',
      imagePath: 'assets/images/bread.png',
      relPos: const Offset(0.20, 0.58),
      size: 96,
      rotation: -0.04,
      layer: _Layer.front,
    ),
    _BasketItem(
      id: 'crema',
      imagePath: 'assets/images/crema.png',
      relPos: const Offset(0.65, 0.42),
      size: 56,
      rotation: -0.05,
      layer: _Layer.front,
    ),
    _BasketItem(
      id: 'banana',
      imagePath: 'assets/images/banana.png',
      relPos: const Offset(0.32, 0.34),
      size: 70,
      rotation: -0.10,
      layer: _Layer.front,
    ),

    // ── Decorative stickers (sit on top of everything)
    _BasketItem(
      id: 'mango',
      imagePath: 'assets/images/mango.png',
      relPos: const Offset(0.45, 0.00),
      size: 64,
      rotation: -0.06,
      layer: _Layer.front,
    ),
    _BasketItem(
      id: 'watermelon',
      imagePath: 'assets/images/watermelon.png',
      relPos: const Offset(0.02, 0.30),
      size: 60,
      rotation: -0.12,
      layer: _Layer.front,
    ),
    _BasketItem(
      id: 'strawberry',
      imagePath: 'assets/images/strawberry.png',
      relPos: const Offset(0.04, 0.78),
      size: 58,
      rotation: 0.10,
      layer: _Layer.front,
    ),
    _BasketItem(
      id: 'pink',
      imagePath: 'assets/images/pink.png',
      relPos: const Offset(0.62, 0.78),
      size: 80,
      rotation: -0.05,
      layer: _Layer.front,
    ),
  ];

  // Track which item the user is currently moving (so we can lift it visually
  // and bring it to the top of its layer). Cleared on pan-end.
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
            // ── Title area (above the drag bounds — items can't reach it).
            Positioned(
              left: 18,
              right: 18,
              top: 14,
              child: _Header(),
            ),

            // ── Items counter pill (top-right of the card).
            Positioned(
              right: 14,
              top: 14,
              child: _ItemsBadge(count: _items.length),
            ),

            // ── Drag area (everything below the header).
            Positioned(
              left: _padH,
              right: _padH,
              top: _headerHeight,
              bottom: _padBottom,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  // Sort: back items first, then the basket, then front items.
                  // Within a layer, the currently-dragging item floats to the
                  // top of its layer for crisp z-order feedback.
                  final back = _items.where((i) => i.layer == _Layer.back).toList()
                    ..sort((a, b) {
                      if (a.id == _draggingId) return 1;
                      if (b.id == _draggingId) return -1;
                      return 0;
                    });
                  final front = _items.where((i) => i.layer == _Layer.front).toList()
                    ..sort((a, b) {
                      if (a.id == _draggingId) return 1;
                      if (b.id == _draggingId) return -1;
                      return 0;
                    });

                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // BACK items — render before the basket so they look
                      // like they're sitting inside it from the rear.
                      ...back.map((it) => _buildItem(it, w, h)),

                      // The basket itself, centered along the bottom edge.
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
                                width: w * 0.92,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // FRONT items — render after the basket so they sit on
                      // top of the basket front face, plus decorative stickers.
                      ...front.map((it) => _buildItem(it, w, h)),
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
        // Convert current item position from percentage → pixels, apply the
        // drag delta in pixels, then clamp to the drag area minus item size,
        // and finally convert back to percentage so nothing can spill into
        // the title region or off the card edge.
        final currentX = item.relPos.dx * (areaW - item.size);
        final currentY = item.relPos.dy * (areaH - item.size);
        final newX = (currentX + delta.dx).clamp(0.0, areaW - item.size);
        final newY = (currentY + delta.dy).clamp(0.0, areaH - item.size);
        setState(() {
          item.relPos = Offset(
            (areaW - item.size) > 0 ? newX / (areaW - item.size) : 0,
            (areaH - item.size) > 0 ? newY / (areaH - item.size) : 0,
          );
        });
      },
      areaW: areaW,
      areaH: areaH,
    );
  }
}

enum _Layer { back, front }

class _BasketItem {
  final String id;
  final String imagePath;
  Offset relPos; // fraction of drag area: 0..1
  final double size;
  final double rotation;
  final _Layer layer;

  _BasketItem({
    required this.id,
    required this.imagePath,
    required this.relPos,
    required this.size,
    required this.rotation,
    required this.layer,
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
        // Soft hover bob — paused while the user is actively dragging so the
        // pointer position never feels jittery.
        final floatY = isDragging
            ? 0.0
            : math.sin(controller.value * math.pi * 2) *
                _floatAmplitude(item.id);

        // Convert percentage position back to pixels.
        final px = item.relPos.dx * (areaW - item.size);
        final py = item.relPos.dy * (areaH - item.size);

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
                      alpha: isDragging ? 0.22 : 0.13,
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

  // Tiny per-item phase variation so they don't all bob in perfect sync.
  double _floatAmplitude(String id) {
    return 1.6 + (id.hashCode % 4) * 0.4;
  }
}

class _Header extends StatelessWidget {
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

class _ItemsBadge extends StatelessWidget {
  final int count;
  const _ItemsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧺', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            '$count items',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
