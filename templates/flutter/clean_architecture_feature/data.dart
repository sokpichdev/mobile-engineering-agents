// Data layer — DTOs, mappers, data sources, and the repository implementation.
// This is the only layer that knows `dio` (or any transport) exists.

import 'package:dio/dio.dart';

import 'domain.dart';

/// DTO: mirrors the wire format, including its snake_case keys.
class ArticleDto {
  const ArticleDto({
    required this.id,
    required this.title,
    required this.publishedAt,
  });

  factory ArticleDto.fromJson(Map<String, dynamic> json) => ArticleDto(
        id: json['id'] as String,
        title: json['title'] as String,
        publishedAt: json['published_at'] as String,
      );

  final String id;
  final String title;
  final String publishedAt;

  /// Mapping lives here — a DTO never crosses into Domain.
  Article toEntity() => Article(
        id: id,
        title: title,
        publishedAt: DateTime.parse(publishedAt),
      );
}

class ArticleRemoteDataSource {
  const ArticleRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ArticleDto>> getArticles({required int page}) async {
    final response = await _dio.get<List<dynamic>>(
      '/articles',
      queryParameters: {'page': page},
    );
    return (response.data ?? const [])
        .map((json) => ArticleDto.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ArticleDto> getArticle(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/articles/$id');
    return ArticleDto.fromJson(response.data!);
  }
}

class ArticleRepositoryImpl implements ArticleRepository {
  const ArticleRepositoryImpl(this._remote);

  final ArticleRemoteDataSource _remote;

  @override
  Future<List<Article>> fetchArticles({required int page}) async {
    try {
      final dtos = await _remote.getArticles(page: page);
      return dtos.map((dto) => dto.toEntity()).toList(growable: false);
    } on DioException catch (e) {
      throw _mapFailure(e);
    }
  }

  @override
  Future<Article> fetchArticle(String id) async {
    try {
      return (await _remote.getArticle(id)).toEntity();
    } on DioException catch (e) {
      throw _mapFailure(e);
    }
  }

  /// Every transport error becomes a Domain failure. Nothing above this line
  /// should ever have to know what `DioExceptionType` is.
  Failure _mapFailure(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.connectionError =>
          const NetworkFailure(),
        DioExceptionType.badResponse => switch (e.response?.statusCode) {
            401 => const UnauthorizedFailure(),
            404 => const NotFoundFailure(),
            _ => UnknownFailure(e),
          },
        _ => UnknownFailure(e),
      };
}
