# Skill: Startup (Launch) Optimization

## Overview

Launch time is a first-impression metric Apple tracks (and surfaces in MetricKit/Xcode
Organizer). It splits into **pre-main** (dynamic linking, static initializers) and
**post-main** (your `didFinishLaunching`/first-frame work). The goal is a fast **time to
first usable frame**: defer everything non-essential, do no blocking I/O or network on the
launch path, and measure with the App Launch Instrument. Target well under ~400ms to first
frame where possible.

## Use Cases

- Slow cold launches hurting retention and App Store metrics.
- Heavy SDK initialization bloating startup.
- "White screen" before first content appears.

## Best Practices

- **Defer non-critical work** off the launch path (`Task` after first frame, lazy init).
- **No synchronous network/disk** in `didFinishLaunching` or first view `init`.
- **Lazy-initialize SDKs/analytics**; initialize only what the first screen needs.
- Reduce **pre-main** cost: fewer dynamic frameworks, avoid heavy `+load`/static initializers.
- **Measure** with the App Launch Instrument and MetricKit; set a launch budget.

## Anti-Patterns

- ❌ Initializing every SDK eagerly at launch.
- ❌ Synchronous network/database calls before first frame.
- ❌ Heavy work in the root view's `init`/`onAppear`.
- ❌ Many dynamic frameworks inflating pre-main linking.
- ❌ Optimizing launch without measuring it.

## Checklist

- [ ] No synchronous network/disk on the launch path.
- [ ] Non-critical work deferred past first frame.
- [ ] SDKs lazily initialized; only first-screen deps loaded eagerly.
- [ ] Pre-main cost considered (frameworks, static init).
- [ ] Launch measured with a budget.

## Swift Examples

```swift
@main
struct BankingApp: App {
    init() {
        // Keep launch lean: only what the first frame needs.
        CrashReporter.startMinimal()
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    // Deferred, non-blocking startup work after first frame.
                    await AppBootstrap.shared.warmCaches()
                    Analytics.shared.initializeLazily()
                    await RemoteConfig.shared.refresh()
                }
        }
    }
}

enum AppBootstrap {
    static let shared = AppBootstrap()
    func warmCaches() async { /* prefetch off the critical path */ }
}
```

## Common Interview Questions

- What are pre-main vs post-main launch phases?
- How do you measure launch time?
- Why avoid eager SDK initialization at launch?
- How do dynamic frameworks affect launch?
- What is "time to first frame" and why does it matter?

## AI Implementation Notes

- Move startup work into a deferred `.task`/background after first frame; never block launch.
- Lazily initialize SDKs and analytics.
- Recommend measuring with the App Launch Instrument and setting a budget.
- Related: [`memory_optimization.md`](memory_optimization.md),
  [`battery_optimization.md`](battery_optimization.md).
