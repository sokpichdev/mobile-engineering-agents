---
platform: ios
---

# Skill: Battery (Energy) Optimization

## Overview

Battery drain comes from sustained CPU/GPU use, frequent networking (radio wake-ups),
location/sensor usage, and work that prevents the device from idling. The OS rewards
**batching, coalescing, and deferring** work. Use the Energy Log / `os_signpost` and
MetricKit to find drains, then reduce wake-ups, respect Low Power Mode, and offload deferrable
work to the system (`BGTaskScheduler`, discretionary `URLSession`).

## Use Cases

- Apps flagged for high background energy use.
- Location/realtime features draining battery.
- Chatty networking causing constant radio activity.

## Best Practices

- **Batch and coalesce** network requests; avoid frequent small polls (prefer push/WebSocket).
- **Defer non-urgent work** to `BGTaskScheduler` / discretionary background sessions.
- **Right-size location**: lowest accuracy that works, significant-location/region monitoring,
  stop updates when not needed.
- **Respect Low Power Mode** (`ProcessInfo.isLowPowerModeEnabled`): reduce refresh/animation.
- **Avoid wakeful timers/polling**; throttle background refresh.

## Anti-Patterns

- ❌ Polling an API every few seconds instead of using push/sockets.
- ❌ Continuous high-accuracy GPS when coarse location suffices.
- ❌ Keeping timers/connections alive in the background unnecessarily.
- ❌ Ignoring Low Power Mode.
- ❌ Heavy work on every scroll/keystroke without throttling/debouncing.

## Checklist

- [ ] Network requests batched/coalesced; polling minimized.
- [ ] Deferrable work uses `BGTaskScheduler`/discretionary sessions.
- [ ] Location accuracy right-sized; updates stopped when idle.
- [ ] Low Power Mode respected.
- [ ] No needless background timers/connections.

## Swift Examples

```swift
// Respect Low Power Mode and adapt behavior
if ProcessInfo.processInfo.isLowPowerModeEnabled {
    liveUpdates.setRefreshInterval(.seconds(30))   // back off when battery is constrained
} else {
    liveUpdates.setRefreshInterval(.seconds(5))
}
```

```swift
// Schedule deferrable background refresh instead of polling
import BackgroundTasks

func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 30) // ~30 min, system-coalesced
    try? BGTaskScheduler.shared.submit(request)
}

// Discretionary download lets the system pick an energy-efficient time
func makeDiscretionarySession() -> URLSession {
    let config = URLSessionConfiguration.background(withIdentifier: "com.app.bg")
    config.isDiscretionary = true
    config.sessionSendsLaunchEvents = true
    return URLSession(configuration: config, delegate: nil, delegateQueue: nil)
}
```

## Common Interview Questions

- What are the biggest sources of battery drain on iOS?
- Why is polling worse than push for battery?
- How does `BGTaskScheduler` help energy use?
- How do you reduce location energy cost?
- How should an app react to Low Power Mode?

## AI Implementation Notes

- Prefer push/WebSocket over polling; batch network work.
- Use `BGTaskScheduler`/discretionary sessions for deferrable work; check Low Power Mode.
- Right-size location accuracy and stop updates when idle.
- Related: [`startup_optimization.md`](startup_optimization.md),
  [`../../networking/ios/websocket.md`](../../networking/ios/websocket.md).
