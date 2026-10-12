import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'data/services/ai_service.dart';
import 'data/services/device_id.dart';
import 'data/services/fridgenie_api.dart';
import 'data/services/ingredient_recognizer.dart';
import 'data/services/worker_fridgenie_api.dart';
import 'providers/fridge_provider.dart';
import 'providers/grocery_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/user_provider.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Hydrate user prefs (onboarding flag + taste profile) before first frame.
  final userProvider = UserProvider();
  await userProvider.hydrate();

  final api = await _createApi();
  runApp(FridgenieApp(userProvider: userProvider, api: api));
}

/// Builds the Worker client, or returns null to run in demo mode.
Future<FridgenieApi?> _createApi() async {
  if (!AppConfig.isBackendConfigured) {
    debugPrint('[Fridgenie] Backend not configured: running in demo mode.');
    return null;
  }
  final prefs = await SharedPreferences.getInstance();
  debugPrint('[Fridgenie] Backend: ${AppConfig.backendUri.host}');
  return WorkerFridgenieApi(
    baseUri: AppConfig.backendUri,
    appToken: AppConfig.appToken,
    deviceId: await DeviceId.loadOrCreate(prefs),
  );
}

class FridgenieApp extends StatelessWidget {
  final UserProvider userProvider;

  /// Real AI client; null runs the app in demo mode (used by tests too).
  final FridgenieApi? api;

  const FridgenieApp({super.key, required this.userProvider, this.api});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => FridgeProvider()),
        ChangeNotifierProvider(create: (_) => GroceryProvider()),

        // Offline recipe brain: suggestions, fallbacks, tips.
        Provider<AIService>(create: (_) => AIService()),

        // Real AI via the Worker; null means demo mode.
        Provider<FridgenieApi?>(
          create: (_) => api,
          dispose: (_, client) => client?.close(),
        ),

        Provider<IngredientRecognizer>(
          create: (ctx) => createDefaultRecognizer(ctx.read<FridgenieApi?>()),
        ),

        ChangeNotifierProvider<RecipeProvider>(
          create: (ctx) => RecipeProvider(
            aiService: ctx.read<AIService>(),
            userProvider: ctx.read<UserProvider>(),
            api: ctx.read<FridgenieApi?>(),
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
