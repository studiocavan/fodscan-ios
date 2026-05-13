# FodScan

iOS app for scanning grocery items and getting an instant verdict on whether they're safe for someone on a strict low-FODMAP diet (SIBO context).

## Goals

- Work offline by default — ingredients mode requires no network
- Scan a product in under one second from camera-up to verdict on screen
- Personal tool first, open sourced. Built for two users (me and my wife)
- Use platform-native APIs throughout. No third-party dependencies

## Non-goals

- Recipe logging, meal planning, symptom tracking. The existing app handles this
- Multi-user features, social, sharing
- Android support (revisit later if needed)
- Generic dietary restrictions beyond low-FODMAP

## Architecture overview

Two scan modes, one shared FODMAP engine.

**Ingredients mode (default)**
Point camera at an ingredient panel, tap Analyze. VisionKit captures and OCR's the text, runs it through the local FODMAP engine. Fully offline. Target: under 400ms total.

**Barcode mode (requires internet)**
Scan UPC, look up in Open Food Facts, get ingredients string. Cached locally after first hit so repeat scans are offline. Target: 200-500ms on first scan, <50ms on cache hit.

**FODMAP engine**
Normalize ingredient text, run against bundled ruleset, return verdict. Runs on-device for both modes. Target: under 50ms.

**Apple Intelligence explanation (opt-in per scan)**
On supported devices (iPhone 15 Pro and later), an "Explain" button on the verdict screen uses the on-device Foundation Models framework to explain the verdict in plain language. No network call, no API key required.

## Tech stack

- iOS 17+ (iPhone target, do not block iPad)
- Swift 5.10+, SwiftUI
- VisionKit `DataScannerViewController` for barcode + text capture
- FoundationModels for on-device LLM explanation (iOS 18.1+, Apple Intelligence devices only)
- Swift Concurrency throughout (async/await, actors for shared state)
- SwiftData for local persistence (scan history, product cache, user overrides)
- URLSession for Open Food Facts (barcode mode only)
- No third-party dependencies

## Verdict model

Four states with associated colors:

- `safe` (green): all ingredients match low-FODMAP-safe entries or are unknown-but-benign
- `caution` (yellow): contains dose-dependent, ambiguous, or hidden-source ingredients
- `avoid` (red): contains at least one high-confidence high-FODMAP ingredient
- `unknown` (gray): not enough info to decide

A single `avoid` hit dominates the verdict. Multiple `caution` hits stay `caution`. The verdict view shows which ingredient(s) triggered which level, never just the overall color.

## FODMAP ruleset

Bundled as `FodScan/Resources/fodmap_ingredients.json`. Schema:

```json
{
  "version": "2026-05-12",
  "entries": [
    {
      "name": "garlic",
      "aliases": ["garlic powder", "garlic extract", "dehydrated garlic", "roasted garlic", "garlic salt"],
      "status": "avoid",
      "category": "fructan",
      "notes": "High-FODMAP at any dose. Garlic-infused oil is safe (fructans are not oil-soluble)."
    }
  ]
}
```

Categories covered: fructan, gos, lactose, excess_fructose, polyol, hidden_source.

Matching uses whole-word boundary checks to avoid false positives (e.g. "corn" not firing inside "acorn" or "popcorn").

## Ingredient matching

Pipeline:
1. Lowercase, strip punctuation except commas and parentheses
2. Split on commas, respecting parenthetical groupings (sub-ingredients, recurse)
3. Strip "may contain" allergen statements
4. Strip "contains X% or less of:" preambles (keep the ingredients after)
5. For each token, run whole-word match against entries + aliases
6. Aggregate: highest severity wins overall, return all matched ingredients with reasons

## Data sources

### Open Food Facts (https://world.openfoodfacts.org)

- Free, open, ODbL licensed — attribution required (credit in Settings)
- Endpoint: `GET /api/v2/product/{barcode}.json`
- Fields needed: `ingredients_text`, `product_name`, `brands`
- Cache responses in SwiftData keyed by barcode. Refresh on explicit pull-to-refresh
- User-Agent: `FodScan/1.0 (com.studiocavan.fodscan)`

## Persistence (SwiftData)

Entities:

- `ScanRecord`: timestamp, barcode (nullable), product name, verdict, flagged ingredients
- `ProductCache`: barcode, product name, brand, ingredients text, fetched_at *(not yet implemented)*
- `IngredientOverride`: ingredient name, status, note *(not yet implemented)*

## Permissions

- `NSCameraUsageDescription`: "Scan product barcodes and ingredient labels"

No location, contacts, tracking, or analytics.

## Project structure

```
FodScan/
  App/
    FodScanApp.swift
    AppContainer.swift
  Features/
    Home/
      HomeView.swift
    Scanner/
      ScannerView.swift
      ScannerViewModel.swift
      DataScannerRepresentable.swift
    Verdict/
      VerdictView.swift
      IngredientBreakdownView.swift
    History/
      HistoryView.swift
    Explore/
      ExploreSafeFoodsView.swift
    MealPrep/
      MealPrepView.swift
    Settings/
      SettingsView.swift
  Core/
    FodmapEngine/
      FodmapEngine.swift
      IngredientNormalizer.swift
      RulesetLoader.swift
      VerdictStatus.swift
    OpenFoodFacts/
      OpenFoodFactsClient.swift
      OFFProduct.swift
    LLM/
      OnDeviceLLMClient.swift
    Persistence/
      Models.swift
      Persistence.swift
  Resources/
    fodmap_ingredients.json
    Assets.xcassets/
Tests/
  FodmapEngineTests.swift
  IngredientNormalizerTests.swift
  OpenFoodFactsClientTests.swift
```

## Milestones

**M1–M4: Complete**
Scanner, OFF integration, FODMAP engine, OCR ingredients mode.

**M5: Persistence — in progress**
`ScanRecord` and history view done. `ProductCache` (offline barcode repeat scans) and `IngredientOverride` (safe-for-me / trigger-for-me) still to implement.

**M6: TestFlight + grocery store test**
Archive, upload, invite wife. Real-world test trip.

**M7: Polish**
Empty states, network error handling, scan haptics, dark mode pass, OFF attribution in Settings, product cache, ingredient overrides.

## Open questions

1. **Phase**: strict elimination or reintroduction? Affects whether dose-dependent items default to caution or avoid
2. **Personal triggers** beyond standard low-FODMAP?
3. **Erythritol stance**: technically allowed in small doses for many. Currently defaulting to caution
4. **Explore Safe Foods**: browse ruleset by category — useful for grocery planning without scanning
5. **Meal Prep**: feature not yet designed — what should it do?

## Future maybes

- Apple Watch companion: red/green haptic when verdict lands
- Celiac mode: separate gluten ruleset, flag both in one scan for mixed households
- iCloud sync of overrides and history across devices
- Upstream fixes to Open Food Facts when entries are wrong
- Recipe scanning: OCR a recipe card, surface issues, suggest swaps

## References

- Open Food Facts API: https://wiki.openfoodfacts.org/API
- VisionKit DataScannerViewController: https://developer.apple.com/documentation/visionkit/datascannerviewcontroller
- FoundationModels: https://developer.apple.com/documentation/foundationmodels
- Monash University FODMAP program: https://www.monashfodmap.com
