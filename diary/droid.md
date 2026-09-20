## 2026-09-20 - Flutter/GetX Video & Reader Controller Memory Leaks & Timers

**Learning:** Unmanaged `Timer.periodic`, `StreamSubscription` from player/device streams, and `ScrollController`/`ItemPositionsListener` listeners in Flutter/GetX controllers and StatefulWidgets persist in memory even after pages or controllers are closed, causing memory leaks and unexpected background callbacks.

**Action:**
1. Always store `StreamSubscription` references and cancel them in `onClose()` (for GetX controllers) or `dispose()` (for StatefulWidgets).
2. Use single-shot `Timer` instead of `Timer.periodic` for auto-hiding UI controls.
3. For quality switching or retries, bound periodic timers with `maxRetries` and store `Timer?` handles to cancel existing ones before starting new ones, as well as in `onClose()`.
4. Always save listener callbacks to named methods so `ScrollController.removeListener()` or `ItemPositionsListener.removeListener()` can be called in `dispose()` / `onClose()`.
