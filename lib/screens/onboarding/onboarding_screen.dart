import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/enums.dart';
import '../../providers/user_provider.dart';
import '../../routes.dart';
import '../../widgets/animated_blob.dart';
import '../../widgets/primary_button.dart';
import 'pages/welcome_page.dart';
import 'pages/dietary_page.dart';
import 'pages/skill_page.dart';
import 'pages/cuisines_page.dart';
import 'pages/mood_page.dart';
import 'pages/finish_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _index = 0;

  // Local state collected during onboarding, committed on finish.
  String _name = '';
  Set<DietaryPreference> _dietary = {DietaryPreference.noRestrictions};
  CookingSkill _skill = CookingSkill.comfortable;
  Set<CuisineType> _cuisines = {};
  Mood _mood = Mood.cozy;

  static const _total = 6;

  void _next() {
    if (_index < _total - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_index > 0) {
      _ctrl.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finish() {
    final user = context.read<UserProvider>();
    user.setName(_name.isEmpty ? 'Chef' : _name);
    user.setDietary(_dietary);
    user.setSkill(_skill);
    user.setFavoriteCuisines(_cuisines.isEmpty ? {CuisineType.italian} : _cuisines);
    user.setMood(_mood);
    user.completeOnboarding();
    Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
  }

  bool get _canContinue {
    switch (_index) {
      case 0:
        return _name.trim().isNotEmpty;
      case 1:
        return _dietary.isNotEmpty;
      case 2:
        return true;
      case 3:
        return _cuisines.isNotEmpty;
      case 4:
        return true;
      default:
        return true;
    }
  }

  String get _ctaLabel {
    if (_index == _total - 1) return 'Cook with me ✨';
    return 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned(
            top: -120,
            right: -80,
            child: AnimatedBlob(
              size: 360,
              colors: [AppColors.primarySurface, AppColors.background],
            ),
          ),
          const Positioned(
            bottom: -100,
            left: -120,
            child: AnimatedBlob(
              size: 380,
              colors: [AppColors.citrusSurface, AppColors.background],
              duration: Duration(seconds: 12),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHPadding, 12, AppSpacing.pageHPadding, 6),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        opacity: _index == 0 ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          onPressed: _index == 0 ? null : _back,
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _Progress(progress: (_index + 1) / _total),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _ctrl,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      WelcomePage(
                        name: _name,
                        onChanged: (v) => setState(() => _name = v),
                      ),
                      DietaryPage(
                        selected: _dietary,
                        onChanged: (s) => setState(() => _dietary = s),
                      ),
                      SkillPage(
                        selected: _skill,
                        onChanged: (s) => setState(() => _skill = s),
                      ),
                      CuisinesPage(
                        selected: _cuisines,
                        onChanged: (s) => setState(() => _cuisines = s),
                      ),
                      MoodPage(
                        selected: _mood,
                        onChanged: (m) => setState(() => _mood = m),
                      ),
                      FinishPage(
                        name: _name,
                        skill: _skill,
                        cuisines: _cuisines,
                        mood: _mood,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHPadding,
                      8,
                      AppSpacing.pageHPadding,
                      24),
                  child: PrimaryButton(
                    label: _ctaLabel,
                    icon: _index == _total - 1
                        ? Icons.auto_awesome_rounded
                        : Icons.arrow_forward_rounded,
                    onPressed: _canContinue ? _next : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final double progress;
  const _Progress({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.outline,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          width: 120 * progress.clamp(0.0, 1.0),
          decoration: BoxDecoration(
            gradient: AppColors.leafGradient,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
