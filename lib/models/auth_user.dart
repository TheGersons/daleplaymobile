class AuthUser {
  final String id;
  final String email;
  final String passwordHash;
  final String nombreCompleto;
  final String rol;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaUltimoAcceso;

  AuthUser({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.nombreCompleto,
    required this.rol,
    required this.estado,
    required this.fechaCreacion,
    this.fechaUltimoAcceso,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      email: json['email'],
      passwordHash: json['password_hash'],
      nombreCompleto: json['nombre_completo'],
      rol: json['rol'],
      estado: json['estado'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaUltimoAcceso: json['fecha_ultimo_acceso'] != null
          ? DateTime.parse(json['fecha_ultimo_acceso'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'nombre_completo': nombreCompleto,
      'rol': rol,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_ultimo_acceso': fechaUltimoAcceso?.toIso8601String(),
    };
  }

  bool get isAdmin => rol == 'admin';
  bool get isVendedor => rol == 'vendedor';
}