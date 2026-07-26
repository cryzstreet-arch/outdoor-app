class User {
  final int id;
  final String email;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String? createdAt;
  final UserStats? estadisticas;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.estadisticas,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      createdAt: json['created_at'],
      estadisticas: json['estadisticas'] != null
          ? UserStats.fromJson(json['estadisticas'])
          : null,
    );
  }
}

class UserStats {
  final int totalCheckins;
  final double totalKm;
  final int totalFacil;
  final int totalMedio;
  final int totalDificil;
  final bool primeActivo;

  UserStats({
    required this.totalCheckins,
    required this.totalKm,
    required this.totalFacil,
    required this.totalMedio,
    required this.totalDificil,
    required this.primeActivo,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalCheckins: json['total_checkins'] ?? 0,
      totalKm: (json['total_km'] ?? 0).toDouble(),
      totalFacil: json['total_facil'] ?? 0,
      totalMedio: json['total_medio'] ?? 0,
      totalDificil: json['total_dificil'] ?? 0,
      primeActivo: json['prime_activo'] == 1,
    );
  }
}
