---
name: project-code-review-notes
description: Minor code smells and known rough edges in FodScan iOS, not bugs but worth cleaning up before wider release
metadata:
  type: project
---

Identified during review on 2026-05-13. None are bugs; all are acceptable for personal/two-user use.

1. **`pendingSuggestions: [Any]` force-cast** — `SettingsView.swift:168`. `pendingSuggestions` is typed `[Any]` because `@State` can't hold an `@available(iOS 26, *)` type. The `as! [RulesetSuggestion]` in the sheet closure is safe in practice (only ever assigned that type), but fragile. Fix: wrap in a version-erased container type if this needs to be more robust.

2. **`analysisError` alert anti-pattern** — `SettingsView.swift:54`. Uses `.constant(analysisError != nil)` as the `isPresented` binding instead of a dedicated `@State var showingAnalysisError: Bool`. Works because the OK button nils the error, but the system can never dismiss it independently. Fix: introduce a `showingAnalysisError: Bool` state var.

3. **`OnDeviceLLMClient` creates new sessions per call** — `OnDeviceLLMClient.swift`. `explainSession` and `researchSession` are instance properties; every `OnDeviceLLMClient()` call creates fresh sessions. For single-turn inference this is fine. If Apple Intelligence ever benefits from persistent conversation context, move to a shared singleton or cache the client instance in the ViewModel.

4. **`VerdictFeedback` note has no minimum length** — `VerdictView.swift:172`. Submit requires non-empty but a single character passes. Low signal noise in the research export. Fix: require e.g. 10+ characters or a word count before enabling submit.

**Why:** noted for future cleanup pass before TestFlight or wider release.
**How to apply:** surface these if the user asks about polish, cleanup, or pre-release hardening.
