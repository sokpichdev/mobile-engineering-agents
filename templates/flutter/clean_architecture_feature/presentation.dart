// Presentation layer — notifier + widget. Talks to use cases only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain.dart';
import 'providers.dart';

/// Presentation logic only. No BuildContext, no Navigator, no HTTP.
class ArticlesNotifier extends AsyncNotifier<List<Article>> {
  @override
  Future<List<Article>> build() => ref.watch(getArticlesProvider)();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    // guard() routes the error into state rather than letting it escape.
    state = await AsyncValue.guard(() => ref.read(getArticlesProvider)());
  }
}

final articlesProvider =
    AsyncNotifierProvider<ArticlesNotifier, List<Article>>(ArticlesNotifier.new);

class ArticlesScreen extends ConsumerWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articlesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Articles')),
      body: switch (articles) {
        // Empty is its own state, not a branch hidden inside `loaded`.
        AsyncData(:final value) when value.isEmpty =>
          const _EmptyView(key: Key('articles.empty')),
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () => ref.read(articlesProvider.notifier).refresh(),
            child: ListView.builder(
              key: const Key('articles.content'),
              itemExtent: 72,
              itemCount: value.length,
              itemBuilder: (context, i) => _ArticleRow(
                key: ValueKey(value[i].id),
                article: value[i],
              ),
            ),
          ),
        AsyncError(:final error) => _ErrorView(
            key: const Key('articles.error'),
            message: _messageFor(error),
            onRetry: () => ref.read(articlesProvider.notifier).refresh(),
          ),
        _ => const Center(
            key: Key('articles.loading'),
            child: CircularProgressIndicator(),
          ),
      },
    );
  }

  /// Typed failures make user-facing copy a mapping, not string matching.
  String _messageFor(Object error) => switch (error) {
        NetworkFailure() => 'You appear to be offline. Pull to retry.',
        UnauthorizedFailure() => 'Your session expired. Please sign in again.',
        _ => 'Something went wrong. Pull to retry.',
      };
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article, super.key});

  final Article article;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(article.title, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('No articles yet.'));
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('articles.retry'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}
