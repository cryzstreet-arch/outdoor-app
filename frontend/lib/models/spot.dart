class Spot {
  final int id;
  final int userId;
  final String nombre;
  final String descripcion;
  final double lat;
  final double lng;
  final String categoria;
  final String dificultad;
  final String? imagenUrl;
  final double hideRadius;
  final double revealRadius;
  final double detailRadius;
  final double gpsRadius;
  final double? startLat;
  final double? startLng;
  final String? createdAt;
  final String? username;
  final String? avatarUrl;
  final int totalLikes;
  final int totalComentarios;
  final int totalCheckins;
  final double? distancia;

  Spot({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.descripcion,
    required this.lat,
    required this.lng,
    required this.categoria,
    required this.dificultad,
    this.imagenUrl,
    required this.hideRadius,
    required this.revealRadius,
    required this.detailRadius,
    required this.gpsRadius,
    this.startLat,
    this.startLng,
    this.createdAt,
    this.username,
    this.avatarUrl,
    required this.totalLikes,
    required this.totalComentarios,
    required this.totalCheckins,
    this.distancia,
  });

  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'],
      userId: json['user_id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      categoria: json['categoria'] ?? 'otro',
      dificultad: json['dificultad'] ?? 'facil',
      imagenUrl: json['imagen_url'],
      hideRadius: (json['hide_radius'] ?? 3000).toDouble(),
      revealRadius: (json['reveal_radius'] ?? 1000).toDouble(),
      detailRadius: (json['detail_radius'] ?? 300).toDouble(),
      gpsRadius: (json['gps_radius'] ?? 50).toDouble(),
      startLat: json['start_lat']?.toDouble(),
      startLng: json['start_lng']?.toDouble(),
      createdAt: json['created_at'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      totalLikes: json['total_likes'] ?? 0,
      totalComentarios: json['total_comentarios'] ?? 0,
      totalCheckins: json['total_checkins'] ?? 0,
      distancia: json['distancia']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 'user_id': userId, 'nombre': nombre,
      'descripcion': descripcion, 'lat': lat, 'lng': lng,
      'categoria': categoria, 'dificultad': dificultad,
      'imagen_url': imagenUrl, 'hide_radius': hideRadius,
      'reveal_radius': revealRadius, 'detail_radius': detailRadius,
      'gps_radius': gpsRadius, 'start_lat': startLat, 'start_lng': startLng,
      'created_at': createdAt, 'username': username, 'avatar_url': avatarUrl,
      'total_likes': totalLikes, 'total_comentarios': totalComentarios,
      'total_checkins': totalCheckins, 'distancia': distancia,
    };
  }
}
