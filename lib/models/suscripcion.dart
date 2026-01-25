class Suscripcion {
  final String id;
  final String clienteId;
  final String perfilId;
  final String plataformaId;
  final String tipoSuscripcion;
  final double precio;
  final DateTime fechaInicio;
  final DateTime fechaProximoPago;
  final DateTime fechaLimitePago;
  final String estado;
  final DateTime fechaCreacion;
  final String? notas;

  Suscripcion({
    required this.id,
    required this.clienteId,
    required this.perfilId,
    required this.plataformaId,
    required this.tipoSuscripcion,
    required this.precio,
    required this.fechaInicio,
    required this.fechaProximoPago,
    required this.fechaLimitePago,
    required this.estado,
    required this.fechaCreacion,
    this.notas,
  });

  factory Suscripcion.fromJson(Map<String, dynamic> json) {
    return Suscripcion(
      id: json['id'],
      clienteId: json['cliente_id'],
      perfilId: json['perfil_id'],
      plataformaId: json['plataforma_id'],
      tipoSuscripcion: json['tipo_suscripcion'] ?? 'perfil',
      precio: (json['precio']).toDouble(),
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaProximoPago: DateTime.parse(json['fecha_proximo_pago']),
      fechaLimitePago: DateTime.parse(json['fecha_limite_pago']),
      estado: json['estado'] ?? 'activa',
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'perfil_id': perfilId,
      'plataforma_id': plataformaId,
      'tipo_suscripcion': tipoSuscripcion,
      'precio': precio,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
      'fecha_proximo_pago': fechaProximoPago.toIso8601String().split('T')[0],
      'fecha_limite_pago': fechaLimitePago.toIso8601String().split('T')[0],
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'notas': notas,
    };
  }
}