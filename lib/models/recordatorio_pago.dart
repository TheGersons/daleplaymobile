class RecordatorioPago {
  final String id;
  final String suscripcionId;
  final DateTime fechaRecordatorio;
  final bool enviado;
  final DateTime? fechaEnvio;
  final String? notas;
  final DateTime createdAt;

  RecordatorioPago({
    required this.id,
    required this.suscripcionId,
    required this.fechaRecordatorio,
    required this.enviado,
    this.fechaEnvio,
    this.notas,
    required this.createdAt,
  });

  factory RecordatorioPago.fromJson(Map<String, dynamic> json) {
    return RecordatorioPago(
      id: json['id'] as String,
      suscripcionId: json['suscripcion_id'] as String,
      fechaRecordatorio: DateTime.parse(json['fecha_recordatorio'] as String),
      enviado: json['enviado'] as bool? ?? false,
      fechaEnvio: json['fecha_envio'] != null
          ? DateTime.parse(json['fecha_envio'] as String)
          : null,
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'suscripcion_id': suscripcionId,
      'fecha_recordatorio': fechaRecordatorio.toIso8601String().split('T')[0],
      'enviado': enviado,
      'fecha_envio': fechaEnvio?.toIso8601String(),
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
    };
  }

  RecordatorioPago copyWith({
    String? id,
    String? suscripcionId,
    DateTime? fechaRecordatorio,
    bool? enviado,
    DateTime? fechaEnvio,
    String? notas,
    DateTime? createdAt,
  }) {
    return RecordatorioPago(
      id: id ?? this.id,
      suscripcionId: suscripcionId ?? this.suscripcionId,
      fechaRecordatorio: fechaRecordatorio ?? this.fechaRecordatorio,
      enviado: enviado ?? this.enviado,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}