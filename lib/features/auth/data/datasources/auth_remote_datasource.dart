import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Remote datasource interface for auth
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<String> refreshToken(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<UserModel> getMe();
  Future<UserModel> updateMe({String? firstName, String? lastName, String? phoneNumber});
  Future<void> changePassword({required String currentPassword, required String newPassword});
  Future<UserModel> uploadAvatar({required Uint8List bytes, required String filename});
}

/// Real API implementation of AuthRemoteDataSource.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      final me = await dioClient.get(
        ApiEndpoints.usersMe,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      return UserModel.fromJson({
        ...me.data as Map<String, dynamic>,
        'access_token': accessToken,
        'refresh_token': refreshToken,
      });
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      return data['access_token'] as String;
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await dioClient.post(
        ApiEndpoints.logout,
        data: {'refresh_token': refreshToken},
      );
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await dioClient.get(ApiEndpoints.usersMe);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<UserModel> updateMe({String? firstName, String? lastName, String? phoneNumber}) async {
    try {
      final response = await dioClient.patch(
        ApiEndpoints.usersMe,
        data: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await dioClient.post(
        ApiEndpoints.usersMePassword,
        data: {'current_password': currentPassword, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<UserModel> uploadAvatar({required Uint8List bytes, required String filename}) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.usersMeAvatar,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: filename),
        }),
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  Exception _normalize(DioException e) {
    final normalized = e.error;
    if (normalized is Exception) return normalized;
    return ServerException(
      message: e.message ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
