import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/services/ai_service.dart';
import 'data/services/ingredient_recognizer.dart';
import 'data/services/recipe_generator.dart';
import 'providers/fridge_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/user_provider.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  // Hydrate user prefs (onboarding flag + taste profile) before first frame.
  final userProvider = UserProvider();
  await userProvider.hydrate();

  runApp(FridgenieApp(userProvider: userProvider));
}

class FridgenieApp extends StatelessWidget {
  final UserProvider userProvider;
  const FridgenieApp({super.key, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => FridgeProvider()),
        Provider<AIService>(create: (_) => AIService()),
        Provider<IngredientRecognizer>(
          create: (_) => createDefaultRecognizer(),
        ),
        Provider<RecipeGenerator?>(
          // Only available when a backend URL is configured. If null, the UI
          // hides the "Generate me a new recipe" button.
          create: (_) {
            final backend = resolveBackendUrl();
            if (backend.isEmpty) return null;
            return RecipeGenerator(backendUrl: backend);
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, RecipeProvider>(
          create: (ctx) => RecipeProvider(
            aiService: ctx.read<AIService>(),
            userProvider: ctx.read<UserProvider>(),
          ),
          update: (ctx, user, prev) =>
              prev ??
              RecipeProvider(
                aiService: ctx.read<AIService>(),
                userProvider: user,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'Fridgenie',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: generateRoute,
      ),
    );
  }
}
