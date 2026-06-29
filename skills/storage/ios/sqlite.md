---
platform: ios
---

# Skill: SQLite

## Overview

SQLite is a fast, embedded relational database. On iOS you can use it directly (C API) but
in practice you use a Swift wrapper — **GRDB** (recommended for control + safety) or
SQLite.swift. Choose SQLite over Core Data when you want explicit SQL, predictable
performance, full-text search, or a simpler mental model without the object-graph machinery.
As always, keep it in the **Data layer** behind a repository and map rows to domain entities.

## Use Cases

- High-volume local data with explicit query control.
- Full-text search, complex joins, analytics-style queries.
- Teams that prefer SQL over Core Data's object graph.

## Best Practices

- Use a **maintained wrapper (GRDB)** with `Codable` record types and migrations.
- Run a **migrator** (`DatabaseMigrator`) for schema evolution; never mutate schema ad-hoc.
- Use **transactions** for multi-statement writes; **WAL mode** for concurrent reads.
- **Parameterize all queries** (never string-interpolate values → SQL injection).
- Index columns used in `WHERE`/`ORDER BY`; map rows to domain structs at the boundary.

## Anti-Patterns

- ❌ Hand-writing the raw C API across the codebase.
- ❌ String-concatenating user input into SQL.
- ❌ Schema changes with no migration → corruption/crashes on upgrade.
- ❌ Missing indexes causing slow queries.
- ❌ Doing large writes on the main thread without a transaction.

## Checklist

- [ ] Maintained wrapper + typed records.
- [ ] Migrations defined via a migrator.
- [ ] Queries parameterized; no string interpolation of values.
- [ ] Transactions for multi-write operations; WAL enabled.
- [ ] Appropriate indexes; rows mapped to domain entities.

## Swift Examples

```swift
import GRDB

struct ArticleRecord: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var title: String
    var createdAt: Date
    static let databaseTableName = "article"
}

enum Database {
    static func makeQueue(path: String) throws -> DatabaseQueue {
        var config = Configuration()
        config.prepareDatabase { db in try db.execute(sql: "PRAGMA journal_mode = WAL") }
        let queue = try DatabaseQueue(path: path, configuration: config)
        try migrator.migrate(queue)
        return queue
    }

    static var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("createArticle") { db in
            try db.create(table: "article") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("createdAt", .datetime).notNull().indexed()
            }
        }
        return m
    }
}

// Parameterized read mapped to a domain entity
func recentArticles(_ queue: DatabaseQueue, limit: Int) throws -> [Article] {
    try queue.read { db in
        try ArticleRecord
            .order(Column("createdAt").desc)
            .limit(limit)
            .fetchAll(db)
            .map { Article(id: $0.id, title: $0.title) }
    }
}
```

## Common Interview Questions

- SQLite vs Core Data — when to choose each?
- What is WAL mode and why enable it?
- How do you prevent SQL injection?
- How do you evolve the schema safely?
- How do indexes affect read/write performance?

## AI Implementation Notes

- Prefer GRDB with typed records and a `DatabaseMigrator`; enable WAL.
- Always parameterize queries; map records to domain structs in the repository.
- Wrap multi-write operations in transactions.
- Related: [`coredata.md`](coredata.md), [`offline_sync.md`](offline_sync.md).
