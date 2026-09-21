## 2026-09-20 - Flutter/GetX Video & Reader Controller Memory Leaks & Timers

**Learning:** Unmanaged `Timer.periodic`, `StreamSubscription` from player/device streams, and `ScrollController`/`ItemPositionsListener` listeners in Flutter/GetX controllers and StatefulWidgets persist in memory even after pages or controllers are closed, causing memory leaks and unexpected background callbacks.

**Action:**
1. Always store `StreamSubscription` references and cancel them in `onClose()` (for GetX controllers) or `dispose()` (for StatefulWidgets).
2. Use single-shot `Timer` instead of `Timer.periodic` for auto-hiding UI controls.
3. For quality switching or retries, bound periodic timers with `maxRetries` and store `Timer?` handles to cancel existing ones before starting new ones, as well as in `onClose()`.
4. Always save listener callbacks to named methods so `ScrollController.removeListener()` or `ItemPositionsListener.removeListener()` can be called in `dispose()` / `onClose()`.

## 2026-09-21 - Comic Chapter Metadata Caching, Seamless Webtoon Reading, and Android Immersive UI

**Learning:**
1. Image byte caching alone does not prevent loading delays in manga/comic readers when resolving image URLs requires QuickJS JavaScript evaluation and network calls for each chapter. Caching chapter image URL lists in Hive (ComicChapterStore) enables instant local rendering without network/JS runtime blocking.
2. In GetMaterialApp (Android), Fluent UI widgets throw assertions because FluentTheme is absent. Always branch platform controls using PlatformWidget or isAndroidLayout.
3. For Android sticky immersive mode (SystemUiMode.immersiveSticky), setting windowLayoutInDisplayCutoutMode = shortEdges in styles.xml ensures content fills notched/cutout screens without letterbox black bars.
