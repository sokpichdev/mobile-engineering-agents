---
platform: flutter
---

# Skill: Local Persistence

## Overview

Pick the store by shape of data, not by habit. `shared_preferences` holds a handful of small,
non-sensitive key/values. **`drift`** is the default for anything relational or reactive — it
gives compile-checked queries, real migrations, and `watch()` streams that feed the UI directly.
`sqflite` is the lower-level option when you want raw SQL and no codegen. Secrets never go in any
of these unencrypted — see [`../../security/flutter/secure_storage.md`](../../security/flutter/secure_storage.md).

## Use Cases

- Offline-first caches backing an infinite feed or a detail screen.
- User preferences, feature flags, last-selected tab (`shared_preferences`).
- Sync outboxes and any table queried with relations or ordering (`drift`).
- Reactive UI: a `watch()` query as the single source of truth for a list.

## Best Practices

- **Choose deliberately:**
  - `shared_preferences` — small, flat, non-sensitive, no querying.
  - `drift` — relational data, migrations, reactive queries, type-safe DAOs. The default.
  - `sqflite` — raw SQL, no codegen, when you are porting existing SQL or want minimal deps.
  - Object databases (`objectbox`) — object-graph-heavy workloads; check maintenance status before
    adopting any of them, and prefer a store your team can support for the app's lifetime.
- **Every schema change ships a migration and a migration test.** `drift`'s `MigrationStrategy` plus
  a bumped `schemaVersion`; verify with generated schema snapshots. An un-migrated release is a
  crash-on-launch for every existing user.
- **Feed the UI from `watch()` queries**, not from a one-shot read plus manual invalidation. That
  gives one source of truth and removes the "list didn't refresh" class of bug.
- Run database work **off the UI isolate** for bulk writes and heavy queries.
- Index the columns you filter and sort on. A cache that scans is slower than the network it replaced.
- Keep persistence in the Data layer behind a repository. Domain never sees a row class.
- Set an explicit eviction/TTL policy for caches — unbounded caches become the app's disk footprint.

## Anti-Patterns

- ❌ Tokens, refresh tokens, or PII in `shared_preferences` or an unencrypted table.
- ❌ A JSON file used as an ad-hoc database.
- ❌ Schema changes with no migration ("just reinstall" is not a migration).
- ❌ Opening a new database connection per screen.
- ❌ Reading once in `initState` and hoping the list stays fresh.
- ❌ Row/DAO types leaking into Domain or Presentation.
- ❌ Bulk inserts on the UI isolate.

## Checklist

- [ ] Store chosen deliberately and justified; secrets are not in it.
- [ ] `schemaVersion` bumped and a `MigrationStrategy` written for every schema change.
- [ ] A migration test covers the upgrade path from the previous version.
- [ ] UI reads come from a reactive `watch()` query where a list can change.
- [ ] Filter/sort columns are indexed.
- [ ] Bulk work runs off the UI isolate.
- [ ] Row types are mapped to entities in Data; Domain is clean.
- [ ] Cache size/TTL policy is explicit.

## Dart Examples

```dart
// data/local/database.dart
class Articles extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get publishedAt => dateTime()();
  BoolColumn get isBookmarked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Articles])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // Every version step is explicit. Never "drop and recreate" on a user's device.
          if (from < 2) await m.addColumn(articles, articles.isBookmarked);
        },
      );

  // Reactive read: the UI updates whenever the table changes, from any writer.
  Stream<List<Article>> watchArticles() => (select(articles)
        ..orderBy([(a) => OrderingTerm.desc(a.publishedAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toEntity()).toList());
}
```

```dart
// presentation — one source of truth, no manual invalidation
final articlesProvider = StreamProvider.autoDispose<List<Article>>(
  (ref) => ref.watch(articleRepositoryProvider).watchArticles(),
);
```

```dart
// ❌ never                                     ✅ instead
await prefs.setString('refresh_token', token); // await secureStorage.write(
                                               //   key: 'refresh_token', value: token);
```

## Common Interview Questions

- How do you choose between `shared_preferences`, `drift`, and `sqflite`?
- What happens on a user's device if you change a schema without a migration?
- Why drive the UI from a `watch()` query rather than a one-shot read?
- Which data must never be stored in `shared_preferences`, and where does it go instead?
- How do you keep a large cache from becoming the app's disk-usage problem?

## AI Implementation Notes

- Default to `drift` for anything relational or reactive; `shared_preferences` only for small flat
  values that are not sensitive.
- Any generated schema change must come with a `MigrationStrategy` branch and a migration test —
  never emit a schema edit alone.
- Never generate token or PII writes into `shared_preferences` or a plain table.
- Expose reads as `Stream` from the repository so the UI has one source of truth.
- iOS counterparts: [`../ios/coredata.md`](../ios/coredata.md), [`../ios/sqlite.md`](../ios/sqlite.md).
- Related: [`offline_sync.md`](offline_sync.md),
  [`../../security/flutter/secure_storage.md`](../../security/flutter/secure_storage.md).
