# Checklist: Performance Review

Owned by the [Performance Expert](../agents/performance_expert.md). Every change should be
backed by a measurement, not intuition. See [`skills/performance/`](../skills/performance/).

## Measurement (Critical)

- [ ] Change backed by a before/after measurement (Instruments / MetricKit).
- [ ] The dominant bottleneck was identified before optimizing.

## Main Thread & Concurrency

- [ ] No heavy work (JSON decode, image decode, crypto, disk) on the main thread.
- [ ] UI updates hop back to `@MainActor`.
- [ ] No synchronous network/disk on the launch path or in view `init`.

## Memory

- [ ] No retain cycles (verified via memory graph); escaping closures use `[weak self]` where needed.
- [ ] Caches bounded (count/cost limits) and respond to memory warnings.
- [ ] Images downsampled to display size; large datasets paged/lazy-loaded.

## Rendering / Lists

- [ ] Lists use stable identifiers; lazy containers for large collections.
- [ ] No layout thrash / excessive body recomputation; expensive work memoized.

## Launch

- [ ] Non-critical startup work deferred past first frame; SDKs lazily initialized.

## Battery

- [ ] Network requests batched; polling minimized (push/WebSocket preferred).
- [ ] Location accuracy right-sized; Low Power Mode respected.

## Regression Guard

- [ ] A budget/metric or perf test added where feasible.
- [ ] No correctness/security regression introduced for speed.
