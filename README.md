# FodScan

An iOS app for scanning grocery products and getting an instant verdict on whether they're safe for a low-FODMAP diet (SIBO context).

Scan a barcode or point the camera at an ingredient panel — FodScan checks against a bundled ingredient ruleset in under a second, with no account required and no data leaving your device.

## Features

- **Barcode scan** — looks up the product in Open Food Facts, parses the ingredient list, and runs it through the local FODMAP engine
- **Ingredient scan** — OCR mode for unlabeled products or anything OFF doesn't have
- **Local FODMAP engine** — bundled ruleset of 50+ ingredients with aliases, categories, and notes. Works fully offline
- **Four-level verdict** — Safe (green), Caution (yellow), Avoid (red), Unknown (gray)
- **Ingredient breakdown** — shows exactly which ingredients triggered the verdict and why
- **Scan history** — recent scans grouped by day
- **Apple Intelligence** — on-device explanation of verdicts on supported devices (iPhone 15 Pro and later)

## Requirements

- Xcode 16+
- iPhone running iOS 17 or later (iPhone 12 and newer; camera scanning does not work in Simulator)
- Apple Developer account (free tier works for personal device; paid required for TestFlight/App Store)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Setup

```bash
git clone https://github.com/studiocavan/fodscan-ios
cd fodscan-ios
xcodegen generate
open FodScan.xcodeproj
```

In Xcode, go to the **FodScan** target → **Signing & Capabilities** and set your development team. Build and run on a physical device.

## FODMAP ruleset

The bundled ruleset lives in `FodScan/Resources/fodmap_ingredients.json`. It covers the main FODMAP categories — fructans, GOS, lactose, excess fructose, and polyols — with common aliases for each ingredient.

Pull requests that improve the ruleset are welcome. When adding an entry:

- Use the most specific aliases possible (avoid short substrings like `"corn"` that match unintended ingredients)
- Cite the Monash University app or peer-reviewed source in the `notes` field
- Bump the `version` date at the top of the file

## Architecture

Three-tier resolution, fastest to slowest:

| Tier | Method | Target |
|------|--------|--------|
| 1 | Barcode → Open Food Facts (cached) | 200–500ms |
| 2 | On-device OCR (VisionKit) | 100–300ms |
| 3 | Local FODMAP engine (bundled JSON) | <50ms |

On supported devices, Apple Intelligence provides on-demand explanation of scan results entirely on-device.

Tech stack: Swift 5.10, SwiftUI, VisionKit, SwiftData, FoundationModels, URLSession. No third-party dependencies.

## Disclaimer

FodScan is a personal tool, not medical advice. The FODMAP ruleset is based on publicly available Monash University research but is not a substitute for guidance from a dietitian. Individual tolerances vary — use this as a starting point, not a final answer.

## License

MIT — see [LICENSE](LICENSE).
