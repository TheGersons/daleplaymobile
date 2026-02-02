class Configuracion {
  final String id;
  final String clave;
  final String valor;
  final String? descripcion;
  final String tipoDato; // string, integer, boolean, decimal, json
  final String categoria; // general, notificaciones, pagos, etc
  final DateTime fechaModificacion;

  Configuracion({
    required this.id,
    required this.clave,
    required this.valor,
    this.descripcion,
    required this.tipoDato,
    required this.categoria,
    required this.fechaModificacion,
  });

  factory Configuracion.fromJson(Map<String, dynamic> json) {
    return Configuracion(
      id: json['id'],
      clave: json['clave'],
      valor: json['valor'],
      descripcion: json['descripcion'],
      tipoDato: json['tipo_dato'] ?? 'string',
      categoria: json['categoria'] ?? 'general',
      fechaModificacion: DateTime.parse(json['fecha_modificacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clave': clave,
      'valor': valor,
      'descripcion': descripcion,
      'tipo_dato': tipoDato,
      'categoria': categoria,
      'fecha_modificacion': fechaModificacion.toIso8601String(),
    };
  }

  // Helpers para obtener el valor según el tipo
  bool get valorBoolean => valor.toLowerCase() == 'true';
  int get valorInt => int.tryParse(valor) ?? 0;
  double get valorDecimal => double.tryParse(valor) ?? 0.0;
}