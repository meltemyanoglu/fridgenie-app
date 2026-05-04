import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class WelcomePage extends StatefulWidget {
  final String name;
  final ValueChanged<String> onChanged;

  const WelcomePage({
    super.key,
    required this.name,
    required this.onChanged,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHPadding,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.huge),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: AppColors.leafGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('🧞', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Hi, I\'m Fridgenie.', style: AppTypography.wordmark),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tell me your name and I\'ll start learning what you love to cook.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            controller: _ctrl,
            onChanged: widget.onChanged,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Your name',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
