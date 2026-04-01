import '../../features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<({User user, String accessToken, String refreshToken})> login(
    String email,
    String password,
  );

  Future<({User user, String accessToken, String refreshToken})> signup(
    String email,
    String password,
    String? displayName,
  );

  Future<({String accessToken, String refreshToken})> refreshToken(
    String token,
  );

  Future<User> getMe(String accessToken);

  Future<User> updateMe(
    String accessToken, {
    String? displayName,
    String? avatarUrl,
  });

  Future<String> uploadImage(
    String accessToken,
    String filePath, {
    String folder,
  });

  Future<void> deleteAccount(String accessToken);
}
