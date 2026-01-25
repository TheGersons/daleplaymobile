class Perfil {
  final String id;
  final String cuentaId;
  final String nombrePerfil;
  final String pin;
  final String estado;
  final DateTime fechaCreacion;

  Perfil({
    required this.id,
    required this.cuentaId,
    required this.nombrePerfil,
    required this.pin,
    required this.estado,
    required this.fechaCreacion,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id'],
      cuentaId: json['cuenta_id'],
      nombrePerfil: json['nombre_perfil'],
      pin: json['pin'] ?? '',
      estado: json['estado'] ?? 'disponible',
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cuenta_id': cuentaId,
      'nombre_perfil': nombrePerfil,
      'pin': pin,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }
}