import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'data/services/ai_service.dart';
import 'data/services/device_id.dart';
import 'data/services/fridgenie_api.dart';
import 'data/services/ingredient_recognizer.dart';
import 'data/services/worker_fridgenie_api.dart';
import 'data/storage/local_store.dart';
import 'data/storage/store_migrations.dart';
import 'providers/fridge_provider.dart';
import 'providers/grocery_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/user_provider.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Open storage once before the first frame so every provider loads
  // synchronously and no early tap can be lost.
  final store = await LocalStore.open();
  StoreMigrations.run(store);

  runApp(FridgenieApp(store: store, api: _createApi(store)));
}

/// Builds the Worker client, or returns null to run in demo mode.
FridgenieApi? _createApi(LocalStore store) {
  if (!AppConfig.isBackendConfigured) {
    debugPrint('[Fridgenie] Backend not configured: running in demo mode.');
    return null;
  }
  debugPrint('[Fridgenie] Backend: ${AppConfig.backendUri.host}');
  return WorkerFridgenieApi(
    baseUri: AppConfig.backendUri,
    appToken: AppConfig.appToken,
    deviceId: DeviceId.loadOrCreate(store),
  );
}

class FridgenieApp extends StatelessWidget {
  final LocalStore store;

  /// Real AI client; null runs the app in demo mode (used by tests too).
  final FridgenieApi? api;

  const FridgenieApp({super.key, required this.store, this.api});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStore>.value(value: store),
        ChangeNotifierProvider(create: (_) => UserProvider(store)),
        ChangeNotifierProvider(create: (_) => FridgeProvider(store)),
        ChangeNotifierProvider(create: (_) => GroceryProvider(store)),

        // Offline recipe brain: suggestions, fallbacks, tips.
        Provider<AIService>(create: (_) => AIService()),

        // Real AI via the Worker; null means demo mode. The client lives as
        // long as the app process, so it is shared as a value, not disposed.
        Provider<FridgenieApi?>.value(value: api),

        Provider<IngredientRecognizer>(
          create: (ctx) => createDefaultRecognizer(ctx.read<FridgenieApi?>()),
        ),

        ChangeNotifierProvider<RecipeProvider>(
          create: (ctx) => RecipeProvider(
            aiService: ctx.read<AIService>(),
            userProvider: ctx.read<UserProvider>(),
            store: store,
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
