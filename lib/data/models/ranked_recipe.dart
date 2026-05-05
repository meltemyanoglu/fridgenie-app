// The canonical `RankedRecipe` class lives in `ai_service.dart` (next to the
// service that produces it). This file used to hold a stale, conflicting
// definition; we keep it as a thin re-export so any stray import still
// resolves to the right type.
export '../services/ai_service.dart' show RankedRecipe;
