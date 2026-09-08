---
platform: flutter
---

# Skill: Offline Sync

## Overview

Offline-first means the local database is the app's source of truth: the UI always reads from it,
the network only writes into it, and user mutations go into an **outbox** that a sync worker drains
when connectivity returns. The app then works identically on a plane and on wifi, and the "loading
spinner over an empty screen" state largely disappears.

## Use Cases

- Field, logistics, and healthcare apps used in poor connectivity.
- Any app where a user action must not be lost when the request fails.
- Feeds and detail screens that should render instantly from cache.
- Multi-device apps needing a defined conflict-resolution story.

## Best Practices

- **Read path:** UI ← `watch()` query ← local DB. Network refresh writes to the DB; it never
  writes to the UI. One source of truth, one code path for cached and fresh data.
- **Write path:** apply the change locally *and* enqueue an outbox row in the same transaction, so
  the optimistic update and the pending mutation can never disagree.
- Outbox row: `id, entity, entityId, operation, payload, attempts, status, createdAt, lastError`.
  Drain it in order, serialized (`synchronized` or a single-flight lock) so retries can't interleave.
- **Idempotency keys** on every mutation. A retried request that the server already applied must be
  a no-op, not a duplicate order.
- Surface sync state per row — pending / syncing / failed — rather than one global spinner. Users
  need to know which of their changes is not yet safe.
- **Conflict strategy, in order of preference:** server-authoritative (server wins, client re-reads)
  → last-write-wins on a *server* timestamp → per-field merge → CRDT only for genuinely
  collaborative editing. Pick one, write it down, and test it.
- `connectivity_plus` tells you an interface exists, **not that the internet works** (captive
  portals). Probe with a cheap request before declaring the app online.
- Use `workmanager` for OS-scheduled background drains; don't rely on the app being foregrounded.
- Cap `attempts` and move a permanently failing row to a `failed` state that the user can see and
  retry, instead of retrying forever.

## Anti-Patterns

- ❌ Writing network results straight into UI state, bypassing the DB.
- ❌ An optimistic update with no outbox row — the change is lost on kill.
- ❌ Retrying mutations without an idempotency key.
- ❌ Treating `connectivity_plus` "connected" as "the API is reachable".
- ❌ Last-write-wins on the *client* clock (device clocks are wrong and user-settable).
- ❌ A single global "syncing" spinner that hides which rows are actually pending.
- ❌ Unbounded retry of a request the server will never accept (a 422 is not transient).

## Checklist

- [ ] UI reads exclusively from the local store via a reactive query.
- [ ] Local write and outbox enqueue happen in one transaction.
- [ ] Every mutation carries an idempotency key.
- [ ] The drain loop is serialized and ordered.
- [ ] Retries use backoff, a capped attempt count, and a terminal `failed` state.
- [ ] Non-transient failures (4xx other than 408/429) do not retry.
- [ ] Conflict strategy is documented and covered by a test.
- [ ] Per-row sync status is visible in the UI.
- [ ] Connectivity is verified by a probe, not just an interface check.

## Dart Examples

```dart
// data/sync/outbox.dart
enum OutboxStatus { pending, syncing, failed }

class OutboxEntries extends Table {
  TextColumn get id => text()();                       // also the idempotency key
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get status => textEnum<OutboxStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// data/repositories/article_repository_impl.dart
@override
Future<void> bookmark(String articleId) => _db.transaction(() async {
      // Optimistic local write and the pending mutation land together, or neither lands.
      await _db.setBookmarked(articleId, true);
      await _db.enqueue(
        OutboxEntry(
          id: _uuid.v4(), // idempotency key — the server dedupes on it
          entity: 'article',
          entityId: articleId,
          operation: 'bookmark',
          payload: jsonEncode({'bookmarked': true}),
          status: OutboxStatus.pending,
          createdAt: _clock.now(),
        ),
      );
    });
```

```dart
// data/sync/sync_worker.dart
class SyncWorker {
  SyncWorker(this._db, this._api, this._lock);

  final AppDatabase _db;
  final ApiClient _api;
  final Lock _lock;

  static const _maxAttempts = 5;

  Future<void> drain() => _lock.synchronized(() async {
        for (final entry in await _db.pendingOutbox()) {
          try {
            await _api.apply(entry, idempotencyKey: entry.id);
            await _db.deleteOutbox(entry.id);
          } on DioException catch (e) {
            final status = e.response?.statusCode;
            final permanent = status != null && status >= 400 && status < 500 &&
                status != 408 && status != 429;
            if (permanent || entry.attempts + 1 >= _maxAttempts) {
              // Terminal: surface it to the user rather than retrying forever.
              await _db.markFailed(entry.id, '$e');
            } else {
              await _db.bumpAttempts(entry.id);
            }
            break; // preserve ordering; retry from here on the next drain
          }
        }
      });
}
```

## Common Interview Questions

- Why must the local write and the outbox enqueue share a transaction?
- What does an idempotency key protect against, exactly?
- Why is last-write-wins on the client clock unsafe?
- How do you distinguish a transient failure from a permanent one, and why does it matter?
- Why isn't `connectivity_plus` reporting "connected" enough to start syncing?
- How do you show the user which of their changes are not yet saved?

## AI Implementation Notes

- Never generate an optimistic update without the matching outbox row in the same transaction.
- Always attach an idempotency key to a queued mutation.
- Classify errors before retrying; a 422 must go straight to `failed`.
- Expose per-row sync status in generated UI, not a single global spinner.
- iOS counterpart: [`../ios/offline_sync.md`](../ios/offline_sync.md).
- Related: [`local_persistence.md`](local_persistence.md),
  [`../../../architecture/offline_first_architecture.md`](../../../architecture/offline_first_architecture.md).
