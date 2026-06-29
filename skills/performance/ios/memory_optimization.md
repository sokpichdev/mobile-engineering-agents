---
platform: ios
---

# Skill: Memory Optimization

## Overview

Memory problems on iOS show up as **leaks** (objects never freed, usually retain cycles),
**abandoned memory** (reachable but unused), and **spikes** (loading too much at once) that
trigger OS termination. Fix them with **measurement first** — Instruments (Allocations,
Leaks) and the memory graph debugger — then break retain cycles, bound caches, and
right-size data/image loading. Don't guess.

## Use Cases

- App terminated by the OS for excessive memory.
- Memory that grows on a screen and never comes back.
- Image-heavy lists consuming hundreds of MB.

## Best Practices

- **Break retain cycles**: use `[weak self]` in escaping closures that outlive their owner;
  `weak`/`unowned` for delegates and parent references.
- **Bound caches** (`NSCache` count/cost limits) and respond to memory warnings.
- **Downsample images** to display size; don't decode full-resolution into small views.
- **Load lazily / page** large datasets instead of all at once.
- **Profile with Instruments**; use the memory graph debugger to find cycles.

## Anti-Patterns

- ❌ Strongly capturing `self` in long-lived closures (Timers, Combine sinks, async tasks).
- ❌ Unbounded caches/arrays growing without eviction.
- ❌ Decoding full-resolution images into thumbnails.
- ❌ Holding large objects after they're needed.
- ❌ "Fixing" memory by intuition without profiling.

## Checklist

- [ ] No retain cycles (verified via memory graph).
- [ ] Escaping closures capture `self` weakly where appropriate.
- [ ] Caches bounded; memory warnings handled.
- [ ] Images downsampled to display size.
- [ ] Large data paged/lazy-loaded; change backed by a measurement.

## Swift Examples

```swift
// Break a retain cycle in an escaping closure
final class FeedLoader {
    private var task: Task<Void, Never>?
    func start() {
        task = Task { [weak self] in            // weak self prevents the cycle
            guard let self else { return }
            await self.load()
        }
    }
    deinit { task?.cancel() }
}
```

```swift
// Downsample an image to the display size instead of decoding full resolution
func downsample(_ url: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
    let options = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else { return nil }
    let maxDimension = max(pointSize.width, pointSize.height) * scale
    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimension
    ] as CFDictionary
    guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else { return nil }
    return UIImage(cgImage: cg)
}
```

## Common Interview Questions

- What causes retain cycles and how do you find them?
- `weak` vs `unowned` — when to use each?
- How do you reduce memory for image-heavy screens?
- What does `NSCache` give you over a dictionary?
- How do you profile memory in Instruments?

## AI Implementation Notes

- Use `[weak self]` in escaping/long-lived closures; cancel tasks/observers in `deinit`.
- Always downsample images to display size; bound caches.
- Recommend profiling before/after any memory change.
- Related: [`startup_optimization.md`](startup_optimization.md),
  [`../../storage/ios/caching.md`](../../storage/ios/caching.md),
  [`../../../checklists/performance_review.md`](../../../checklists/performance_review.md).
