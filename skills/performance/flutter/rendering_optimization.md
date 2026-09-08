---
platform: flutter
---

# Skill: Rendering Optimization

## Overview

A Flutter frame has a budget of ~16ms at 60Hz and ~8ms at 120Hz, split across two threads: the
**UI thread** (Dart: build, layout, paint recording) and the **raster thread** (GPU: turning the
recording into pixels). Jank is always one of those two overrunning, and the fix differs completely
between them — so **measure first**, in `--profile` mode on a real device. Debug-mode timings are
meaningless; the assertions and unoptimized code alone can triple frame times.

## Use Cases

- "The list stutters when I scroll."
- Dropped frames during a page transition or animation.
- Slow cold start.
- Memory growth or an out-of-memory crash on image-heavy screens.
- App size reduction before a release.

## Best Practices

**Diagnose before changing anything.**

- Run `flutter run --profile` on a physical device; use DevTools' Performance view. A tall bar on
  the UI thread means too much Dart work (rebuilds, layout); a tall bar on the raster thread means
  expensive painting (`saveLayer`, shaders, large images).
- Turn on "Track widget builds" in DevTools to see which widgets rebuild and how often. A widget
  rebuilding 60×/second that does not need to is the single most common cause.
- `debugPrintRebuildDirtyWidgets` and the Flutter Inspector's repaint-rainbow give the same signal
  in a pinch.

**Cut rebuilds (UI thread).**

- `const` constructors everywhere they apply — a `const` widget is skipped entirely on rebuild.
  Enable `prefer_const_constructors` in the analyzer so this is enforced, not remembered.
- Watch the narrowest slice: `ref.watch(cartProvider.select((c) => c.itemCount))` rebuilds on the
  count, not the whole cart.
- Scope a `Consumer` to the smallest subtree that actually depends on the provider, instead of
  making the whole screen a `ConsumerWidget`.
- Pass an unchanging subtree as the `child:` argument of `AnimatedBuilder`/`ValueListenableBuilder`
  so it is built once and reused every frame.
- Give list items stable keys so element identity survives reordering.

**Cut paint cost (raster thread).**

- `ListView.builder` (never a `Column` inside a `SingleChildScrollView` for long lists), with
  `itemExtent` or `prototypeItem` when rows are uniform — it lets Flutter skip per-item layout.
- `RepaintBoundary` around a subtree that animates independently, so its repaints don't dirty the
  rest of the screen. Do not sprinkle it everywhere; each boundary costs a layer.
- `Opacity`, `ClipRRect`, and `ShaderMask` over a large subtree trigger `saveLayer`, which is
  expensive. Prefer a color with alpha, a `borderRadius` on the decoration, or a pre-clipped asset.
- `IntrinsicHeight`/`IntrinsicWidth` can be O(n²) on nested layouts — avoid in list items.

**Images and memory.**

- **Decode at display size.** `cacheWidth`/`cacheHeight` (or `ResizeImage`) — decoding a 4000px
  photo into a 100px avatar is the most common memory bug in Flutter apps, and it is invisible
  until the OOM.
- `cached_network_image` for remote images; precache only what the first frame needs.

**Heavy work and startup.**

- Move CPU-bound work (large JSON parses, image processing, crypto) to an isolate with
  `Isolate.run` / `compute`. Anything over a few milliseconds on the UI thread is a dropped frame.
- Keep `main()` lean: do not block the first frame on network or database warm-up. Let providers
  resolve lazily and render a skeleton.
- `flutter build --analyze-size` to find what is actually in the bundle; ship
  `--obfuscate --split-debug-info` and upload the symbol files.

**Renderer note.** Flutter's renderer has moved from Skia to **Impeller**, whose rollout differs by
platform and version. Impeller precompiles shaders, which makes the older "SkSL shader warm-up"
advice obsolete where it is active. Check which renderer your target Flutter version uses on each
platform before applying shader-jank guidance.

## Anti-Patterns

- ❌ Optimizing from a debug-mode profile, or from a guess.
- ❌ A `Column` of hundreds of children inside a `SingleChildScrollView`.
- ❌ Full-resolution image decode for a thumbnail.
- ❌ `setState`/notifier updates that rebuild an entire screen for one changed field.
- ❌ JSON parsing or crypto on the UI isolate.
- ❌ `RepaintBoundary` scattered as a cargo-cult fix without a measurement.
- ❌ `Opacity` wrapping a large animated subtree.
- ❌ Blocking the first frame on network or DB initialization.

## Checklist

- [ ] Measured in `--profile` on a real device before and after.
- [ ] Attributed to the UI thread or the raster thread, and the fix matches.
- [ ] `const` constructors used; `prefer_const_constructors` enabled.
- [ ] Provider watches narrowed with `select`; `Consumer` scoped tightly.
- [ ] Long lists use `ListView.builder` with `itemExtent`/`prototypeItem` where uniform.
- [ ] Images decoded at display size.
- [ ] CPU-bound work runs in an isolate.
- [ ] Startup does not block the first frame on I/O.
- [ ] Release builds obfuscated with symbols uploaded.

## Dart Examples

```dart
// ❌ rebuilds the whole screen when any cart field changes
final cart = ref.watch(cartProvider);
return Text('${cart.itemCount}');

// ✅ rebuilds only when itemCount changes
final count = ref.watch(cartProvider.select((c) => c.itemCount));
return Text('$count');
```

```dart
// ✅ the expensive subtree is built once and reused each animation frame
AnimatedBuilder(
  animation: controller,
  // `child` is built once, outside the per-frame builder.
  child: const ExpensiveStaticHeader(),
  builder: (context, child) => Opacity(opacity: controller.value, child: child),
);
```

```dart
// ✅ uniform rows: itemExtent lets Flutter skip per-item layout during scroll
ListView.builder(
  itemExtent: 72,
  itemCount: articles.length,
  itemBuilder: (context, i) => RepaintBoundary(
    child: ArticleRow(key: ValueKey(articles[i].id), article: articles[i]),
  ),
);
```

```dart
// ❌ decodes at full resolution         ✅ decodes at display size
Image.network(url, width: 48)          // Image.network(url, width: 48, cacheWidth: 96)
```

```dart
// ✅ a large parse belongs off the UI isolate
final articles = await Isolate.run(() => parseArticles(rawJson));
```

## Common Interview Questions

- How do you tell UI-thread jank from raster-thread jank, and why does the distinction matter?
- Why must performance be measured in profile mode rather than debug?
- What does a `const` constructor actually save during a rebuild?
- What does `RepaintBoundary` cost, and when is it worth it?
- Why is `Opacity` over a large subtree expensive?
- What is the most common cause of image-related OOM in Flutter, and the fix?
- When should work move to an isolate?

## AI Implementation Notes

- Never propose an optimization without naming the measurement that justifies it.
- Default generated lists to `ListView.builder` with stable keys; add `itemExtent` when uniform.
- Always set `cacheWidth`/`cacheHeight` when generating image widgets with a known display size.
- Prefer `select` over watching a whole state object in generated widgets.
- Verify the renderer default (Impeller vs Skia) for the project's Flutter version before giving
  shader-warm-up advice.
- iOS counterparts: [`../ios/startup_optimization.md`](../ios/startup_optimization.md),
  [`../ios/memory_optimization.md`](../ios/memory_optimization.md).
- Related: [`../../../checklists/performance_review.md`](../../../checklists/performance_review.md),
  [`../../architecture/flutter/state_management.md`](../../architecture/flutter/state_management.md).
