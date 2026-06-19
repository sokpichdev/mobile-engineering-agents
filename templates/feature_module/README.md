# Template: Feature Module

A self-contained, layered feature packaged as a Swift Package. Copy this structure for a new
feature. See [`architecture/feature_module_architecture.md`](../../architecture/feature_module_architecture.md).

## Folder Structure

```text
{{Feature}}Feature/
├── Package.swift
├── Sources/{{Feature}}Feature/
│   ├── {{Feature}}Feature.swift        // public entry: factory + root view
│   ├── Domain/
│   │   ├── {{Entity}}.swift
│   │   ├── {{Feature}}Repository.swift // protocol
│   │   └── Fetch{{Entity}}UseCase.swift
│   ├── Data/
│   │   ├── {{Entity}}DTO.swift
│   │   ├── {{Entity}}Mapper.swift
│   │   └── Remote{{Feature}}Repository.swift
│   └── Presentation/
│       ├── {{Feature}}ViewModel.swift
│       ├── {{Feature}}View.swift
│       └── Subviews/
└── Tests/{{Feature}}FeatureTests/
    ├── Fetch{{Entity}}UseCaseTests.swift
    ├── {{Feature}}ViewModelTests.swift
    └── {{Entity}}MapperTests.swift
```

## Naming Conventions

- Module: `{{Feature}}Feature` (e.g. `AccountsFeature`).
- One public entry type exposing a factory; everything else `internal`.
- Files named after their primary type.

## Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "{{Feature}}Feature",
    platforms: [.iOS(.v16)],
    products: [.library(name: "{{Feature}}Feature", targets: ["{{Feature}}Feature"])],
    dependencies: [
        .package(path: "../CoreNetworking"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(name: "{{Feature}}Feature", dependencies: ["CoreNetworking", "DesignSystem"]),
        .testTarget(name: "{{Feature}}FeatureTests", dependencies: ["{{Feature}}Feature"])
    ]
)
```

## Public Entry (DI seam)

```swift
import SwiftUI
import CoreNetworking

public enum {{Feature}}Feature {
    public static func makeRootView(client: APIClient) -> some View {
        let repository = Remote{{Feature}}Repository(client: client)
        let useCase = Fetch{{Entity}}UseCase(repository: repository)
        return {{Feature}}View(viewModel: {{Feature}}ViewModel(fetch: useCase))
    }
}
```

## Conventions Embedded Here

- **DI:** dependencies passed into the factory; no singletons inside the module.
- **Error handling:** repository throws typed errors; ViewModel maps to a state enum.
- **Testing:** Domain + Presentation unit-tested; Data mapping tested with fixtures.

See the layer-specific templates: [clean_architecture_feature](../clean_architecture_feature/),
[repository_layer](../repository_layer/), [swiftui_screen](../swiftui_screen/),
[unit_test_template](../unit_test_template/).
