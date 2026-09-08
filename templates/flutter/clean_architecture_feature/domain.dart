// Domain layer — pure Dart. No `package:flutter`, no `dio`, no `drift`.
// Split into one-type-per-file when you copy this into a real module.

/// Entity: immutable, framework-free.
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.publishedAt,
    this.isBookmarked = false,
  });

  final String id;
  final String title;
  final DateTime publishedAt;
  final bool isBookmarked;

  Article copyWith({bool? isBookmarked}) => Article(
        id: id,
        title: title,
        publishedAt: publishedAt,
        isBookmarked: isBookmarked ?? this.isBookmarked,
      );
}

/// Typed failures. Data translates transport/storage errors into these so no
/// `DioException` or `SqliteException` ever reaches Presentation.
sealed class Failure implements Exception {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

final class UnknownFailure extends Failure {
  const UnknownFailure(this.cause);
  final Object cause;
}

/// The contract Domain owns. Data implements it; Domain never sees a DTO.
abstract interface class ArticleRepository {
  Future<List<Article>> fetchArticles({required int page});

  Future<Article> fetchArticle(String id);
}

/// Use case: a callable class, so the call site reads like a function.
class GetArticles {
  const GetArticles(this._repository);

  final ArticleRepository _repository;

  Future<List<Article>> call({int page = 1}) => _repository.fetchArticles(page: page);
}

class GetArticle {
  const GetArticle(this._repository);

  final ArticleRepository _repository;

  Future<Article> call(String id) => _repository.fetchArticle(id);
}
