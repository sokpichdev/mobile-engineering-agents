---
platform: ios
---

# Skill: Offline Sync

## Overview

Offline sync makes the **local store the source of truth** so the app works without a
network, then reconciles with the server when connectivity returns. It combines local
persistence, a **change/outbox queue** for pending mutations, **conflict resolution**, and
**optimistic UI updates** with rollback. This is one of the hardest mobile problems — design
the failure and conflict cases explicitly, not just the happy path.

## Use Cases

- Notes/tasks/messaging apps that must work offline.
- Field apps with intermittent connectivity.
- Any app where waiting on the network for every action is unacceptable UX.

## Best Practices

- **Local store is the source of truth**; the UI reads from it, not directly from the network.
- Queue mutations in an **outbox** with status (`pending/syncing/failed`) and retry with backoff.
- Use **optimistic updates** with a clear **rollback** path on server rejection.
- Define a **conflict strategy** explicitly: last-write-wins (with server timestamps),
  field-level merge, or CRDTs for collaborative data.
- Use **stable client-generated ids** (UUIDs) so offline-created items reconcile cleanly.
- Track a **sync cursor / updatedAt** to fetch only deltas.

## Anti-Patterns

- ❌ Treating the network as the source of truth and blocking the UI offline.
- ❌ No conflict strategy → silent data loss.
- ❌ Optimistic updates with no rollback on failure.
- ❌ Server-assigned ids only, breaking offline creation references.
- ❌ Full re-fetch every sync instead of deltas.

## Checklist

- [ ] Local store is the read source of truth.
- [ ] Outbox queue with status + backoff retry.
- [ ] Optimistic updates have a rollback path.
- [ ] Explicit, documented conflict-resolution strategy.
- [ ] Stable client ids; delta sync via cursor/updatedAt.

## Swift Examples

```swift
enum SyncStatus: String { case pending, syncing, synced, failed }

struct PendingMutation: Identifiable, Codable {
    let id: UUID                  // stable client id
    let type: MutationType
    let payload: Data
    var status: SyncStatus
    var attempts: Int
}

actor SyncEngine {
    private let outbox: OutboxStore
    private let api: SyncAPI

    func enqueue(_ mutation: PendingMutation) async { await outbox.add(mutation) }

    func sync() async {
        for var mutation in await outbox.pending() {
            mutation.status = .syncing; await outbox.update(mutation)
            do {
                try await api.apply(mutation)
                await outbox.remove(mutation.id)
            } catch let error as ConflictError {
                await resolve(error, for: mutation)        // explicit conflict handling
            } catch {
                mutation.status = .failed; mutation.attempts += 1
                await outbox.update(mutation)              // retried later with backoff
            }
        }
    }
}
```

## Common Interview Questions

- Why make the local store the source of truth?
- How do you handle conflicts (LWW vs merge vs CRDT)?
- Why use client-generated ids for offline creation?
- How do optimistic updates and rollback work?
- How do you sync only deltas?

## AI Implementation Notes

- Read from local store; queue writes in an outbox with retry/backoff.
- Always implement rollback for optimistic updates and a named conflict strategy.
- Use UUID client ids and a sync cursor for deltas.
- Related: [`caching.md`](caching.md), [`coredata.md`](coredata.md),
  [`../../../architecture/offline_first_architecture.md`](../../../architecture/offline_first_architecture.md).
