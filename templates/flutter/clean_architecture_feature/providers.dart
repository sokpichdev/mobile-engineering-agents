// Composition root — the DI graph. Providers are typed as the DOMAIN interface,
// which is what makes every edge overridable in a test.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data.dart';
import 'domain.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final articleRemoteDataSourceProvider = Provider<ArticleRemoteDataSource>(
  (ref) => ArticleRemoteDataSource(ref.watch(dioProvider)),
);

/// Typed as `ArticleRepository`, not `ArticleRepositoryImpl` — that is the seam.
final articleRepositoryProvider = Provider<ArticleRepository>(
  (ref) => ArticleRepositoryImpl(ref.watch(articleRemoteDataSourceProvider)),
);

final getArticlesProvider = Provider<GetArticles>(
  (ref) => GetArticles(ref.watch(articleRepositoryProvider)),
);

final getArticleProvider = Provider<GetArticle>(
  (ref) => GetArticle(ref.watch(articleRepositoryProvider)),
);
