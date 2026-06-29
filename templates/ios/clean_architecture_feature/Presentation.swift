//  Presentation.swift
//  Clean Architecture Feature template — Presentation layer (MVVM).
//  Thin view + single state enum + @Observable @MainActor ViewModel.

import SwiftUI
import Observation

// MARK: - Generic view state

public enum ViewState<T: Equatable>: Equatable {
    case idle
    case loading
    case loaded(T)
    case failed(String)
}

// MARK: - ViewModel

@MainActor
@Observable
public final class ArticlesViewModel {
    public private(set) var state: ViewState<[Article]> = .idle
    private let fetch: FetchArticlesUseCase

    public init(fetch: FetchArticlesUseCase) {
        self.fetch = fetch
    }

    public func load(refresh: Bool = false) async {
        state = .loading
        do {
            let articles = try await fetch.execute(refresh: refresh)
            state = .loaded(articles)
        } catch {
            state = .failed("Couldn't load articles. Pull to retry.")
        }
    }
}

// MARK: - View

public struct ArticlesView: View {
    @State private var viewModel: ArticlesViewModel

    public init(viewModel: ArticlesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView().accessibilityLabel("Loading articles")
            case .loaded(let articles) where articles.isEmpty:
                ContentUnavailableView("No articles", systemImage: "newspaper")
            case .loaded(let articles):
                List(articles) { article in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.title).font(.headline)
                        Text(article.author).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                .refreshable { await viewModel.load(refresh: true) }
            case .failed(let message):
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") { Task { await viewModel.load(refresh: true) } }
                }
            }
        }
        .navigationTitle("Articles")
        .task { await viewModel.load() }
    }
}
