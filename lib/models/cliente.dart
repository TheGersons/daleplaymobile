class Cliente {
  final String id;
  final String nombreCompleto;
  final String telefono;
  final String estado;
  final DateTime fechaRegistro;
  final String? notas;

  Cliente({
    required this.id,
    required this.nombreCompleto,
    required this.telefono,
    required this.estado,
    required this.fechaRegistro,
    this.notas,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nombreCompleto: json['nombre_completo'],
      telefono: json['telefono'],
      estado: json['estado'] ?? 'activo',
      fechaRegistro: DateTime.parse(json['fecha_registro']),
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'telefono': telefono,
      'estado': estado,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'notas': notas,
    };
  }
}