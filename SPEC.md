# Low-FODMAP Scanner

iOS app for scanning grocery items and getting an instant verdict on whether they're safe for someone on a strict low-FODMAP diet (SIBO context).

## Goals

- Scan a product in under one second from camera-up to verdict on screen
- Work offline for the common case (90%+ of scans should not need a network call)
- Personal tool first, not a productized app. Built for two users (me and my wife)
- Use platform-native APIs for speed, fall back to LLM only when genuinely needed

## Non-goals

- Recipe logging, meal planning, symptom tracking. The existing app she uses handles this
- Multi-user features, social, sharing
- Android support (revisit later if needed)
- Generic dietary restrictions beyond low-FODMAP

## Architecture overview

Four-tier resolution, fastest to slowest. Each tier only runs if the previous one cannot resolve.

**Tier 1: Barcode → Open Food Facts**
Scan UPC, look up in OFF, get ingredients string. Cached locally after first hit. Network round trip only on cache miss. Target: 200-500ms.

**Tier 2: On-device OCR**
For unlabeled products or OFF misses, capture ingredient panel with VisionKit text recognition. All local, no network. Target: 100-300ms.

**Tier 3: Local FODMAP engine**
Normalize ingredient text, run against bundled ruleset, return verdict. Target: under 50ms.

**Tier 4: LLM fallback (opt-in per scan)**
For ambiguous results or "explain this verdict" requests, send ingredient text (not image) to Claude Haiku via Anthropic API. Not on the hot path. Target: 1-2s.

## Tech stack

- iOS 17+ (iPhone target, do not block iPad)
- Swift 5.10+, SwiftUI
- VisionKit `DataScannerViewController` for barcode + text capture in one session
- Swift Concurrency throughout (async/await, actors for shared state)
- SwiftData for local persistence (scan history, product cache, user overrides)
- URLSession async API for OFF and Anthropic calls
- No third-party dependencies for v1. Adding a dep is a deliberate decision

## Verdict model

Four states with associated colors:

- `safe` (green): all ingredients match low-FODMAP-safe entries or are unknown-but-benign
- `caution` (yellow): contains dose-dependent, ambiguous, or hidden-source ingredients
- `avoid` (red): contains at least one high-confidence high-FODMAP ingredient
- `unknown` (gray): not enough info to decide. Suggest manual check or LLM fallback

A single `avoid` hit dominates the verdict. Multiple `caution` hits stay `caution`. The verdict view shows which ingredient(s) triggered which level, never just the overall color.

## FODMAP ruleset

Bundled as `Resources/fodmap_ingredients.json`. Schema:

```json
{
  "version": "2026-05-01",
  "entries": [
    {
      "name": "garlic",
      "aliases": ["garlic powder", "garlic extract", "dehydrated garlic", "roasted garlic", "garlic salt"],
      "status": "avoid",
      "category": "fructan",
      "notes": "High-FODMAP at any dose. Garlic-infused oil is safe (fructans are not oil-soluble)."
    },
    {
      "name": "natural flavors",
      "aliases": ["natural flavor", "natural flavoring"],
      "status": "caution",
      "category": "hidden_source",
      "notes": "Often contains onion or garlic derivatives. Contact manufacturer for certainty."
    }
  ]
}
```

Bootstrap seed list by category:

- **Fructans**: onion (all forms), garlic, leek, shallot, wheat (above trace), rye, barley, inulin, chicory root
- **GOS**: lentils (above small portion), chickpeas (above small portion), kidney beans, soy beans
- **Lactose**: milk, cream, yogurt, soft cheese, milk solids, whey concentrate
- **Excess fructose**: honey, agave, HFCS, apple, pear, mango, watermelon
- **Polyols**: sorbitol, mannitol, xylitol, isomalt, maltitol, erythritol (often tolerated, default caution)
- **Hidden sources**: natural flavors, spices, seasonings, vegetable broth

This list is a starting point. Expect to iterate based on actual labels encountered in real grocery trips.

## Ingredient matching

The FODMAP engine takes a raw ingredient string and returns a list of matches with status.

Pipeline:
1. Lowercase, strip punctuation except commas and parentheses
2. Split on commas, respecting parenthetical groupings (parentheticals are sub-ingredients, recurse into them)
3. For each token, run normalized substring match against entries + aliases
4. Aggregate: highest severity wins overall, return all matched ingredients with their reasons

Edge cases to handle:
- "Contains 2% or less of: X, Y, Z" should still be parsed
- "May contain" allergen statements are not ingredients, skip them
- Trace amounts ("wheat starch") vs material amounts (wheat flour as primary) is hard to distinguish from a label alone. Default trace-ish phrasing to caution

## Data sources

### Open Food Facts (https://world.openfoodfacts.org)

- Free, open, no auth required
- Endpoint: `GET /api/v2/product/{barcode}.json`
- Fields needed: `ingredients_text`, `product_name`, `brands`, `image_url`
- Cache responses indefinitely keyed by barcode. Refresh on explicit user pull-to-refresh
- Be a good citizen: set a meaningful User-Agent identifying the app

### Anthropic API (Tier 4 fallback)

- Model: Claude Haiku 4.5 (`claude-haiku-4-5-20251001`)
- API key stored in Keychain, set via Settings screen (per-device, not bundled)
- Prompt: structured, ingredient list in, JSON verdict out, ask for reasoning
- Volume is negligible at personal-use scale, no rate-limit concerns

## Persistence (SwiftData)

Entities:

- `ScanRecord`: timestamp, barcode (nullable), product name, ingredients text, verdict, source (off / ocr / manual), llm_called bool
- `ProductCache`: barcode, product name, brand, ingredients text, image URL, fetched_at
- `IngredientOverride`: ingredient name, status, note. User can mark something safe-for-me or trigger-for-me

Scan history view shows recent scans grouped by day, lets her tap in to see ingredient breakdown again.

## Permissions

Info.plist keys required:

- `NSCameraUsageDescription`: "Scan product barcodes and ingredient labels"
- `NSPhotoLibraryUsageDescription`: only if adding "import from photo" later

No location, contacts, tracking, or analytics. Personal app, stays personal.

## Project structure

```
LowFodmapScanner/
  App/
    LowFodmapScannerApp.swift
    AppContainer.swift              // dependency container
  Features/
    Scanner/
      ScannerView.swift
      ScannerViewModel.swift
      DataScannerRepresentable.swift
    Verdict/
      VerdictView.swift
      IngredientBreakdownView.swift
    History/
      HistoryView.swift
    Settings/
      SettingsView.swift
  Core/
    FodmapEngine/
      FodmapEngine.swift
      IngredientNormalizer.swift
      RulesetLoader.swift
    OpenFoodFacts/
      OpenFoodFactsClient.swift
      OFFProduct.swift
    LLM/
      AnthropicClient.swift
    Persistence/
      Models.swift                  // SwiftData @Model classes
      Persistence.swift
  Resources/
    fodmap_ingredients.json
  Tests/
    FodmapEngineTests.swift
    IngredientNormalizerTests.swift
    OpenFoodFactsClientTests.swift
```

## Milestones

Sized for evening sessions. Adjust to reality.

**M1: Skeleton scanner**
Wire DataScannerViewController, scan a barcode, log it to console. No UI polish, no verdict.

**M2: OFF integration**
Hit Open Food Facts on barcode scan, parse ingredients, show raw text on screen.

**M3: FODMAP engine + ruleset**
Build the matcher, seed the JSON ruleset, render verdict UI. First useful version.

**M4: OCR fallback**
When OFF misses, switch to text mode in DataScanner, capture ingredient panel, run through engine.

**M5: Persistence**
SwiftData models, scan history view, product cache.

**M6: TestFlight + grocery store test**
Paid Developer account, archive, upload, invite wife. Real-world test trip.

**M7: LLM fallback + ingredient overrides**
Anthropic client, "explain this" button on verdict screen, Settings for API key, override editor.

**M8: Polish**
Empty states, network errors, scan haptics, dark mode pass, app icon, launch screen.

## Open questions

Decisions needed before locking down ruleset behavior:

1. **Phase**: strict elimination or reintroduction? Affects whether dose-dependent items default to caution or avoid
2. **Personal triggers** beyond standard low-FODMAP? Some people react to extras
3. **Erythritol stance**: technically allowed in small doses for many. Default caution or safe?
4. **Garlic-infused oil exception**: include the nuance in matching logic or just flag all garlic mentions for safety?

## Future maybes (not v1)

- Apple Watch companion: red/green haptic when verdict lands, no need to look at phone in a crowded aisle
- Symptom log integration with the existing app (if it exports)
- Upstream fixes to Open Food Facts when entries are wrong or missing
- Recipe scanning: OCR a recipe card, surface issues, suggest swaps
- Live Activities for in-progress scans
- iCloud sync of overrides and history across devices

## References

- Open Food Facts API docs: https://wiki.openfoodfacts.org/API
- VisionKit DataScannerViewController: https://developer.apple.com/documentation/visionkit/datascannerviewcontroller
- Monash University FODMAP program (authoritative source, paid app): https://www.monashfodmap.com
- Anthropic API docs: https://docs.claude.com
