# Workflow: Optimize Performance

Measure → find the bottleneck → fix → verify. Never optimize on intuition.

## Objective

Resolve a performance problem (slow launch, janky scrolling, memory growth, battery drain)
with a measured before/after improvement and no correctness regressions.

## Inputs

- Symptom + context (which screen/flow, device, OS, reproduction steps).
- A target/budget if one exists (e.g. launch < 400ms, 60fps scroll).

## Outputs

- Root-cause analysis, the fix, and before/after measurements.

## Step-by-Step Process

1. **Reproduce + measure baseline** ([Performance Expert](../agents/performance_expert.md)) —
   pick the right Instrument (Time Profiler, Allocations/Leaks, Animation Hitches, Energy) and
   capture numbers.
2. **Identify the dominant bottleneck** — fix the biggest cost first.
3. **Apply the targeted fix** — e.g. move work off main thread, break a retain cycle, bound a
   cache, downsample images, defer launch work (see [`skills/performance/`](../skills/performance/)).
4. **Re-measure** under the same conditions; compare to baseline.
5. **Guard against regression** — add a budget/metric (MetricKit, a perf test) where feasible.
6. **Review** — ensure no correctness/security trade-off was made silently.

## Validation Steps

- Before/after measurements show a real improvement on the target metric.
- No new correctness failures; tests still pass.
- The change targets the measured bottleneck, not a guess.

## Failure Scenarios

- **No measurable improvement** → wrong bottleneck; re-profile.
- **Improvement with a regression** → revert; find a non-destructive approach.
- **Can't reproduce the slowness** → match device/OS/data scale of the report.

## AI Agent Instructions

- Always attach a baseline measurement before changing anything.
- Fix the dominant cost first; avoid micro-optimizations that don't move the metric.
- Keep UI work on the main thread and heavy work off it; never trade correctness/security for
  speed without explicit sign-off.
- Re-measure and report before/after numbers.

## Acceptance Criteria

- [ ] Baseline measured with the appropriate Instrument.
- [ ] Dominant bottleneck identified and addressed.
- [ ] Before/after numbers show improvement.
- [ ] No correctness/security regression; tests pass.
- [ ] Regression guard added where feasible.
