/// Instagram 연결 상태.
class InstagramAuth {
  const InstagramAuth({
    this.isConnected = false,
    this.accessToken,
    this.userId,
    this.username,
    this.isLoading = false,
    this.error,
  });

  final bool isConnected;
  final String? accessToken;
  final String? userId;
  final String? username;
  final bool isLoading;
  final String? error;

  InstagramAuth copyWith({
    bool? isConnected,
    String? accessToken,
    String? userId,
    String? username,
    bool? isLoading,
    String? error,
  }) {
    return InstagramAuth(
      isConnected: isConnected ?? this.isConnected,
      accessToken: accessToken ?? this.accessToken,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
