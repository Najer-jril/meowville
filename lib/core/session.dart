/// Tokens returned by POST /auth/v1/token.
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    required this.email,
  });

  factory Session.fromAuthJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return Session(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (json['expires_at'] as int) * 1000,
      ),
      userId: user['id'] as String,
      email: user['email'] as String,
    );
  }

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresAt: DateTime.parse(json['expires_at'] as String),
    userId: json['user_id'] as String,
    email: json['email'] as String,
  );

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;
  final String email;

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 1)));

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toIso8601String(),
    'user_id': userId,
    'email': email,
  };
}
