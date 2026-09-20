import 'dart:typed_data';

import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.4:8000';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> cloneVoice({
    required String name,
    required String audioPath,
    required bool consent,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'consent': consent.toString(),
      'file': await MultipartFile.fromFile(
        audioPath,
        filename: audioPath.split(RegExp(r'[\\/]')).last,
      ),
    });

    try {
      final response = await _dio.post(
        '/api/voice/clone',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      return Map<String, dynamic>.from(
        response.data as Map,
      );
    } on DioException catch (e) {
      String message = 'Voice cloning request failed.';

      if (e.type == DioExceptionType.receiveTimeout) {
        message =
            'Voice cloning is taking longer than expected. '
            'Please wait and try again.';
      } else if (e.response?.data != null) {
        final data = e.response!.data;

        if (data is Map &&
            data['detail'] != null) {
          message = data['detail'].toString();
        } else {
          message = data.toString();
        }
      } else if (e.message != null) {
        message = e.message!;
      }

      throw Exception(message);
    }
  }

  Future<Uint8List> generateSpeech({
    required String voiceId,
    required String text,
    String? languageCode,
  }) async {
    final formData = FormData.fromMap({
      'voice_id': voiceId,
      'text': text,
      if (languageCode != null)
        'language_code': languageCode,
    });

    try {
      final response = await _dio.post<List<int>>(
        '/api/tts',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.bytes,
          receiveTimeout:
              const Duration(minutes: 5),
          sendTimeout:
              const Duration(minutes: 5),
        ),
      );

      return Uint8List.fromList(
        response.data ?? <int>[],
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw Exception(
          e.response!.data.toString(),
        );
      }

      throw Exception(
        e.message ?? 'Speech generation failed.',
      );
    }
  }
}
