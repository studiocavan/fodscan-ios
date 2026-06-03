---
name: project-production-checklist
description: App Store production readiness checklist for FodScan iOS — items to complete before submission
metadata:
  type: project
---

Track these in order before App Store submission. First two are hard blockers.

**Why:** App Store Connect requires a hosted privacy policy URL (not a GitHub blob) and a dedicated support email. Everything else can be done in parallel.

## Blockers (do first)
- [ ] Enable GitHub Pages on the repo for a clean privacy policy URL (`studiocavan.github.io/fodscan-ios`)
- [ ] Create a dedicated support email (not personal Gmail) and add to `PRIVACY.md`

## Technical
- [ ] Add `NSCameraUsageDescription` to Info.plist — "Used to scan product barcodes and photograph ingredient lists"
- [ ] Archive and upload build to App Store Connect via Xcode

## Assets
- [ ] Design and export app icon at 1024×1024px
- [ ] Take App Store screenshots for 6.9" and 6.5" iPhone sizes (can use Simulator)

## App Store Connect setup
- [ ] Enroll in Apple Developer Program ($99/yr) if not already
- [ ] Create app record in App Store Connect (bundle ID, name, category: Health & Fitness)
- [ ] Write App Store description — no medical claims, reference Monash University, note iOS 26 required for Apple Intelligence features
- [ ] Fill in App Privacy nutrition labels (data not collected, camera local-only, network = OFF barcode lookups only)

## Testing
- [ ] Run TestFlight external beta — fix any crashes before submission

## Final
- [ ] Submit for App Store Review
