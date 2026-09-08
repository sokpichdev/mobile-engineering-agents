// Tests — deterministic, no real network. Override the repository seam and let
// the real notifier and use case logic run.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data.dart';
import 'domain.dart';
import 'presentation.dart';
import 'providers.dart';

/// A hand-written fake beats a mock for a repository you own.
class FakeArticleRepository implements ArticleRepository {
  FakeArticleRepository({this.articles = const [], this.failure});

  List<Article> articles;
  Failure? failure;

  @override
  Future<List<Article>> fetchArticles({required int page}) async {
    if (failure != null) throw failure!;
    return articles;
  }

  @override
  Future<Article> fetchArticle(String id) async {
    if (failure != null) throw failure!;
    return articles.firstWhere((a) => a.id == id);
  }
}

final testArticle = Article(
  id: '1',
  title: 'Clean Architecture in Flutter',
  publishedAt: DateTime.utc(2026, 1, 1),
);

ProviderContainer makeContainer(ArticleRepository repository) {
  final container = ProviderContainer(
    overrides: [articleRepositoryProvider.overrideWithValue(repository)],
  );
  // Without this, providers leak across tests and state bleeds between them.
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('mapper', () {
    test('toEntity parses the wire format', () {
      const dto = ArticleDto(id: '1', title: 'T', publishedAt: '2026-01-01T00:00:00Z');

      final entity = dto.toEntity();

      expect(entity.id, '1');
      expect(entity.publishedAt, DateTime.utc(2026));
    });
  });

  group('GetArticles', () {
    test('returns the repository result', () async {
      final sut = GetArticles(FakeArticleRepository(articles: [testArticle]));

      expect(await sut(), [testArticle]);
    });

    test('propagates a typed failure', () async {
      final sut = GetArticles(FakeArticleRepository(failure: const NetworkFailure()));

      await expectLater(sut(), throwsA(isA<NetworkFailure>()));
    });
  });

  group('ArticlesNotifier', () {
    test('build emits the loaded articles', () async {
      final container = makeContainer(FakeArticleRepository(articles: [testArticle]));

      expect(await container.read(articlesProvider.future), [testArticle]);
    });

    test('a repository failure becomes an error state', () async {
      final container = makeContainer(FakeArticleRepository(failure: const NetworkFailure()));

      await expectLater(container.read(articlesProvider.future), throwsA(isA<NetworkFailure>()));
      expect(container.read(articlesProvider), isA<AsyncError<List<Article>>>());
    });
  });

  group('ArticlesScreen', () {
    Future<void> pumpScreen(WidgetTester tester, ArticleRepository repository) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [articleRepositoryProvider.overrideWithValue(repository)],
            child: const MaterialApp(home: ArticlesScreen()),
          ),
        );

    testWidgets('renders the empty state', (tester) async {
      await pumpScreen(tester, FakeArticleRepository());
      await tester.pump();

      expect(find.byKey(const Key('articles.empty')), findsOneWidget);
    });

    testWidgets('renders the loaded state', (tester) async {
      await pumpScreen(tester, FakeArticleRepository(articles: [testArticle]));
      await tester.pump();

      expect(find.text(testArticle.title), findsOneWidget);
    });

    testWidgets('renders an error with a working retry', (tester) async {
      final repository = FakeArticleRepository(failure: const NetworkFailure());
      await pumpScreen(tester, repository);
      await tester.pump();

      expect(find.byKey(const Key('articles.error')), findsOneWidget);

      repository
        ..failure = null
        ..articles = [testArticle];
      await tester.tap(find.byKey(const Key('articles.retry')));
      await tester.pump();
      await tester.pump();

      expect(find.text(testArticle.title), findsOneWidget);
    });
  });
}
