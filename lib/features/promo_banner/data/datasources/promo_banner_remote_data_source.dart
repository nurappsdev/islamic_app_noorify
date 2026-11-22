import 'dart:async';

import 'package:dio/dio.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/core/storage/latest_json_cache.dart';
import 'package:tuhfatul_muslim/features/promo_banner/data/models/promo_banner_model.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/entities/promo_banner.dart';

/// Talks to the public promo-banner endpoints. Throws [ServerException] /
/// [NetworkException]; never returns error states.
abstract interface class PromoBannerRemoteDataSource {
  /// `GET /promo-banners/active`. No session needed — these are public.
  Future<List<PromoBanner>> getActiveBanners();

  /// `POST /promo-banners/{id}/click` with an empty body.
  Future<void> trackClick(String bannerId);
}

class PromoBannerRemoteDataSourceImpl implements PromoBannerRemoteDataSource {
  PromoBannerRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  /// The last good answer, replayed by [PromoBannerRepositoryImpl] so the
  /// Home screen can draw its banners before the network has answered.
  static final cache = LatestJsonCache('promo_banners_active');

  @override
  Future<List<PromoBanner>> getActiveBanners() async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        ApiConstants.promoBannersActiveEndPoint,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final body = response.data;
    final json = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300 || json['success'] == false) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }

    final data = json['data'];
    // An empty list is a valid answer ("no banners today"), so it is cached
    // too: that is how a deactivated carousel disappears on the next launch
    // instead of coming back from a stale cache.
    unawaited(cache.save({'data': data is List ? data : const []}));
    return PromoBannerModel.listFrom(data);
  }

  @override
  Future<void> trackClick(String bannerId) async {
    if (bannerId.trim().isEmpty) return;
    try {
      await _dio.post<dynamic>(
        ApiConstants.promoBannerClickEndPoint(bannerId),
        data: const <String, dynamic>{},
      );
    } on DioException catch (_) {
      // Counting a tap is never worth surfacing: the user has already left
      // for wherever the banner pointed.
    }
  }

  String? _extractError(Map<String, dynamic> json) {
    final message = json['message']?.toString();
    return message == null || message.isEmpty ? null : message;
  }

  Exception _mapDioException(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => NetworkException(
      'The request timed out. Please try again.',
    ),
    DioExceptionType.connectionError => NetworkException(),
    DioExceptionType.badCertificate => NetworkException(
      'Could not establish a secure connection.',
    ),
    DioExceptionType.cancel => NetworkException('The request was cancelled.'),
    DioExceptionType.badResponse || DioExceptionType.unknown => ServerException(
      _extractError(
            e.response?.data is Map<String, dynamic>
                ? e.response!.data as Map<String, dynamic>
                : const {},
          ) ??
          'Request failed (${e.response?.statusCode ?? 'network error'}).',
      statusCode: e.response?.statusCode,
    ),
  };
}
