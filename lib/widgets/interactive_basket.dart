import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class InteractiveBasket extends StatefulWidget {
  const InteractiveBasket({super.key});

  @override
  State<InteractiveBasket> createState() => _InteractiveBasketState();
}

class _InteractiveBasketState extends State<InteractiveBasket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  final List<_BasketItem> _items = [
    _BasketItem(
      id: 'oliveoil',
      imagePath: 'assets/images/oliveoil.png',
      position: Offset(130, 28),
      size: 58,
      rotation: -0.08,
    ),
    _BasketItem(
      id: 'goodbites',
      imagePath: 'assets/images/goodbites.png',
      position: Offset(186, 30),
      size: 70,
      rotation: 0.02,
    ),
    _BasketItem(
      id: 'pasta',
      imagePath: 'assets/images/pasta.png',
      position: Offset(250, 38),
      size: 68,
      rotation: 0.18,
    ),
    _BasketItem(
      id: 'spring',
      imagePath: 'assets/images/spring.png',
      position: Offset(285, 82),
      size: 92,
      rotation: 0.12,
    ),
    _BasketItem(
      id: 'cornflakes',
      imagePath: 'assets/images/cornflakes.png',
      position: Offset(28, 84),
      size: 70,
      rotation: -0.18,
    ),
    _BasketItem(
      id: 'bread',
      imagePath: 'assets/images/bread.png',
      position: Offset(82, 126),
      size: 82,
      rotation: -0.08,
    ),
    _BasketItem(
      id: 'meat',
      imagePath: 'assets/images/meat.png',
      position: Offset(176, 122),
      size: 92,
      rotation: 0.12,
    ),
    _BasketItem(
      id: 'crema',
      imagePath: 'assets/images/crema.png',
      position: Offset(222, 104),
      size: 58,
      rotation: -0.05,
    ),
    _BasketItem(
      id: 'strawberry',
      imagePath: 'assets/images/strawberry.png',
      position: Offset(20, 150),
      size: 54,
      rotation: 0.12,
    ),
    _BasketItem(
      id: 'watermelon',
      imagePath: 'assets/images/watermelon.png',
      position: Offset(18, 44),
      size: 56,
      rotation: -0.12,
    ),
    _BasketItem(
      id: 'mango',
      imagePath: 'assets/images/mango.png',
      position: Offset(96, 8),
      size: 58,
      rotation: -0.08,
    ),
    _BasketItem(
      id: 'pink',
      imagePath: 'assets/images/pink.png',
      position: Offset(235, 165),
      size: 72,
      rotation: -0.03,
    ),
  ];

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

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 290,
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            top: 16,
            child: Text(
              'Your fridge basket',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          Positioned(
            left: 18,
            top: 44,
            child: Text(
              'Drag items around · tap to remove',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 8,
            child: Transform.rotate(
              angle: -0.08,
              child: Image.asset(
                'assets/images/basket.png',
                height: 185,
                fit: BoxFit.contain,
              ),
            ),
          ),

          ..._items.map(
            (item) => _FloatingBasketItem(
              key: ValueKey(item.id),
              item: item,
              controller: _floatController,
              onRemove: () => _removeItem(item.id),
              onMove: (delta) {
                setState(() {
                  item.position += delta;
                });
              },
            ),
          ),

          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                '${_items.length} items',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBasketItem extends StatefulWidget {
  final _BasketItem item;
  final AnimationController controller;
  final VoidCallback onRemove;
  final ValueChanged<Offset> onMove;

  const _FloatingBasketItem({
    super.key,
    required this.item,
    required this.controller,
    required this.onRemove,
    required this.onMove,
  });

  @override
  State<_FloatingBasketItem> createState() => _FloatingBasketItemState();
}

class _FloatingBasketItemState extends State<_FloatingBasketItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final floatY = math.sin(widget.controller.value * math.pi * 2) * 2.5;

        return Positioned(
          left: widget.item.position.dx,
          top: widget.item.position.dy + floatY,
          child: child!,
        );
      },
      child: GestureDetector(
        onTap: widget.onRemove,
        onPanStart: (_) => setState(() => _pressed = true),
        onPanEnd: (_) => setState(() => _pressed = false),
        onPanCancel: () => setState(() => _pressed = false),
        onPanUpdate: (details) => widget.onMove(details.delta),
        child: AnimatedScale(
          scale: _pressed ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: Transform.rotate(
            angle: widget.item.rotation,
            child: Container(
              width: widget.item.size,
              height: widget.item.size,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.13),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                widget.item.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BasketItem {
  final String id;
  final String imagePath;
  Offset position;
  final double size;
  final double rotation;

  _BasketItem({
    required this.id,
    required this.imagePath,
    required this.position,
    required this.size,
    required this.rotation,
  });
}