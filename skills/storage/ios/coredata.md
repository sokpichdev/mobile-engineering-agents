---
platform: ios
---

# Skill: Core Data

## Overview

Core Data is Apple's object-graph persistence framework. It excels at modeling related
entities, querying with `NSFetchRequest`/`NSPredicate`, and (via `NSPersistentContainer`)
managing a SQLite store. The critical discipline is **context threading**: the view context
is main-queue only; do writes/imports on background contexts and merge changes. Keep Core
Data in the **Data layer** behind a repository so the Domain/UI never see `NSManagedObject`.

## Use Cases

- Complex related local data (offline caches, user content, drafts).
- Apps needing powerful querying, faulting, and relationship management.
- Local source of truth for offline-first apps.

## Best Practices

- Use **`NSPersistentContainer`**; do writes on `performBackgroundTask`/a background context.
- Treat the **`viewContext` as read-only on the main queue**; set `automaticallyMergesChangesFromParent`.
- **Never pass `NSManagedObject` out of the Data layer** — map to domain structs.
- Always access a managed object **on its own context's queue** (`perform`).
- Use **batch operations** (`NSBatchInsertRequest`/`NSBatchDeleteRequest`) for large imports.
- Add a **lightweight migration** plan as the model evolves.

## Anti-Patterns

- ❌ Using `NSManagedObject` subclasses as your app-wide model in the UI.
- ❌ Accessing a managed object across threads (crashes/corruption).
- ❌ Doing large imports on the view context (UI hangs).
- ❌ Ignoring migrations → store fails to open after a model change.
- ❌ Massive single context with no background work.

## Checklist

- [ ] Writes/imports on a background context; view context main-queue read-mostly.
- [ ] Changes merge into the view context automatically.
- [ ] Managed objects mapped to domain structs at the Data boundary.
- [ ] Managed objects only touched on their context's queue.
- [ ] Migration strategy defined.

## Swift Examples

```swift
final class CoreDataStack {
    let container: NSPersistentContainer
    init(modelName: String) {
        container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { _, error in
            if let error { fatalError("Store load failed: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

final class CoreDataArticleStore {
    private let stack: CoreDataStack
    init(stack: CoreDataStack) { self.stack = stack }

    func save(_ articles: [Article]) async throws {
        try await stack.container.performBackgroundTask { context in   // background write
            for article in articles {
                let mo = ArticleMO(context: context)
                mo.id = article.id; mo.title = article.title
            }
            try context.save()
        }
    }

    func all() async throws -> [Article] {
        let context = stack.container.viewContext
        return try await context.perform {                              // on context queue
            let request = ArticleMO.fetchRequest()
            return try context.fetch(request).map {                     // map MO -> domain
                Article(id: $0.id ?? "", title: $0.title ?? "")
            }
        }
    }
}
```

## Common Interview Questions

- How does Core Data handle concurrency / contexts?
- Why not expose `NSManagedObject` to the UI?
- What is faulting?
- How do lightweight migrations work?
- When would you choose Core Data vs SwiftData vs SQLite/GRDB?

## AI Implementation Notes

- Always write on background contexts; map managed objects to domain structs at the boundary.
- Wrap Core Data in a repository; never leak `NSManagedObject` outward.
- Generate a stack with merge policy + auto-merge configured.
- Related: [`sqlite.md`](sqlite.md), [`caching.md`](caching.md),
  [`../../architecture/ios/repository_pattern.md`](../../architecture/ios/repository_pattern.md).
