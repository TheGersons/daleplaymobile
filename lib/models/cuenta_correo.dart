class CuentaCorreo {
  final String id;
  final String plataformaId;
  final String email;
  final String password;
  final String estado;
  final DateTime fechaCreacion;
  final String? notas;

  CuentaCorreo({
    required this.id,
    required this.plataformaId,
    required this.email,
    required this.password,
    required this.estado,
    required this.fechaCreacion,
    this.notas,
  });

  factory CuentaCorreo.fromJson(Map<String, dynamic> json) {
    return CuentaCorreo(
      id: json['id'],
      plataformaId: json['plataforma_id'],
      email: json['email'],
      password: json['password'],
      estado: json['estado'] ?? 'activa',
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plataforma_id': plataformaId,
      'email': email,
      'password': password,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'notas': notas,
    };
  }
}