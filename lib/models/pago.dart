class Pago {
  final String id;
  final String suscripcionId;
  final String clienteId;
  final double monto;
  final DateTime fechaPago;
  final String metodoPago;
  final String? referencia;
  final String? notas;
  final String? registradoPor;

  Pago({
    required this.id,
    required this.suscripcionId,
    required this.clienteId,
    required this.monto,
    required this.fechaPago,
    required this.metodoPago,
    this.referencia,
    this.notas,
    this.registradoPor,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'],
      suscripcionId: json['suscripcion_id'],
      clienteId: json['cliente_id'],
      monto: (json['monto'] as num).toDouble(),
      fechaPago: DateTime.parse(json['fecha_pago']),
      metodoPago: json['metodo_pago'] ?? 'efectivo',
      referencia: json['referencia'],
      notas: json['notas'],
      registradoPor: json['registrado_por'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'suscripcion_id': suscripcionId,
      'cliente_id': clienteId,
      'monto': monto,
      'fecha_pago': fechaPago.toIso8601String(),
      'metodo_pago': metodoPago,
      'referencia': referencia,
      'notas': notas,
      'registrado_por': registradoPor,
    };

    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }
}
