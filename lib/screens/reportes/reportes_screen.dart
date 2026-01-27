import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/suscripcion.dart';
import '../../models/plataforma.dart';
import '../../models/cuenta_correo.dart';
import '../../models/perfil.dart';
import '../../models/cliente.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  late TabController _tabController;
  bool _isLoading = true;

  // Datos Crudos
  List<Suscripcion> _suscripciones = [];
  List<Plataforma> _plataformas = [];
  List<CuentaCorreo> _cuentas = [];
  List<Perfil> _perfiles = [];
  List<Cliente> _clientes = [];

  // Métricas Calculadas
  double _ingresosMensuales = 0;
  double _costosOperativos = 0;
  double _utilidadNeta = 0;
  int _clientesActivos = 0;
  
  // Datos para Gráficos
  Map<String, double> _ingresosPorPlataforma = {};
  int _perfilesTotales = 0;
  int _perfilesOcupados = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabaseService.obtenerSuscripciones(),
        _supabaseService.obtenerPlataformas(),
        _supabaseService.obtenerCuentas(),
        _supabaseService.obtenerPerfiles(),
        _supabaseService.obtenerClientes(),
      ]);

      if (mounted) {
        setState(() {
          _suscripciones = results[0] as List<Suscripcion>;
          _plataformas = results[1] as List<Plataforma>;
          _cuentas = results[2] as List<CuentaCorreo>;
          _perfiles = results[3] as List<Perfil>;
          _clientes = results[4] as List<Cliente>;
          _calcularMetricas();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calcularMetricas() {
    // 1. Ingresos (Solo activas)
    _ingresosMensuales = _suscripciones
        .where((s) => s.estado == 'activa')
        .fold(0, (sum, item) => sum + item.precio);

    // 2. Costos Operativos (Cuentas Activas * Precio Base)
    _costosOperativos = 0;
    for (var cuenta in _cuentas) {
      if (cuenta.estado == 'activa') {
        final plataforma = _plataformas.firstWhere(
          (p) => p.id == cuenta.plataformaId,
          orElse: () => Plataforma(id: '', nombre: '', icono: '', precioBase: 0, maxPerfiles: 0, color: '#000000', estado: '', fechaCreacion: DateTime.now()),
        );
        _costosOperativos += plataforma.precioBase;
      }
    }

    _utilidadNeta = _ingresosMensuales - _costosOperativos;

    // 3. Clientes Activos
    final clientesConSuscripcionActiva = _suscripciones
        .where((s) => s.estado == 'activa')
        .map((s) => s.clienteId)
        .toSet();
    _clientesActivos = clientesConSuscripcionActiva.length;

    // 4. Ingresos por Plataforma (Para el gráfico)
    _ingresosPorPlataforma = {};
    for (var p in _plataformas) {
      double total = _suscripciones
          .where((s) => s.plataformaId == p.id && s.estado == 'activa')
          .fold(0, (sum, s) => sum + s.precio);
      if (total > 0) {
        _ingresosPorPlataforma[p.nombre] = total;
      }
    }

    // 5. Inventario
    _perfilesTotales = _perfiles.length;
    _perfilesOcupados = _perfiles.where((p) => p.estado == 'ocupado').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes & Finanzas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.analytics_outlined)),
            Tab(text: 'Deudas', icon: Icon(Icons.money_off_csred_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(),
                _buildDeudasTab(),
              ],
            ),
    );
  }

  // ==================== TAB 1: GENERAL ====================

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tarjetas Financieras (KPIs)
          _buildFinancialCards(),
          const SizedBox(height: 24),

          // 2. Gráfico de Ingresos por Plataforma (Barras con valores visibles)
          Text('Ingresos por Plataforma', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildBarChart(),
          
          const SizedBox(height: 24),
          
          // 3. Ocupación y Rentabilidad (Cards originales)
          Row(
            children: [
              Expanded(child: _buildOccupancyCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildProfitMarginCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCards() {
    final currencyFormat = NumberFormat.currency(symbol: 'L ', decimalDigits: 2);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Ingresos Mensuales',
                value: currencyFormat.format(_ingresosMensuales),
                icon: Icons.attach_money,
                color: Colors.green,
                subtitle: 'Suscripciones activas',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Utilidad Neta',
                value: currencyFormat.format(_utilidadNeta),
                icon: Icons.trending_up,
                color: Colors.blue,
                subtitle: 'Ganancia real',
                isHighlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Costos Operativos',
                value: currencyFormat.format(_costosOperativos),
                icon: Icons.money_off,
                color: Colors.redAccent,
                subtitle: 'Cuentas activas',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Clientes Activos',
                value: _clientesActivos.toString(),
                icon: Icons.people,
                color: Colors.orange,
                subtitle: 'Recurrentes',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    if (_ingresosPorPlataforma.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("Sin datos suficientes")));
    }

    // Ordenar de mayor a menor ingreso
    var sortedEntries = _ingresosPorPlataforma.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Tomar top 5
    if (sortedEntries.length > 5) sortedEntries = sortedEntries.sublist(0, 5);

    // Calcular máximo Y con margen para que quepa el texto arriba
    double maxY = sortedEntries.first.value * 1.3; 

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xff232d37), // Fondo oscuro
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: false), // Desactivar touch para no interferir
              titlesData: FlTitlesData(
                show: true,
                // VALORES ARRIBA DE LAS BARRAS
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= sortedEntries.length) return const SizedBox.shrink();
                      final amount = sortedEntries[index].value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          NumberFormat.compactCurrency(symbol: 'L').format(amount),
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 11, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // NOMBRES ABAJO
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= sortedEntries.length) return const SizedBox.shrink();
                      String name = sortedEntries[value.toInt()].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          name.length > 8 ? '${name.substring(0, 7)}..' : name,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.05),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: sortedEntries.asMap().entries.map((e) {
                final index = e.key;
                final value = e.value.value;
                final plat = _plataformas.firstWhere((p) => p.nombre == e.value.key, orElse: () => _plataformas.first);
                final color = _parseColor(plat.color);

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: color,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: Colors.white.withOpacity(0.02),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOccupancyCard() {
    double porcentaje = _perfilesTotales == 0 ? 0 : (_perfilesOcupados / _perfilesTotales);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Ocupación', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              width: 100,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: _perfilesOcupados.toDouble(),
                          color: Colors.blue,
                          radius: 12,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: (_perfilesTotales - _perfilesOcupados).toDouble(),
                          color: Colors.grey[200],
                          radius: 12,
                          showTitle: false,
                        ),
                      ],
                      centerSpaceRadius: 38,
                      sectionsSpace: 0,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(porcentaje * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_perfilesOcupados de $_perfilesTotales',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitMarginCard() {
    double margen = _ingresosMensuales == 0 ? 0 : (_utilidadNeta / _ingresosMensuales);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Rentabilidad', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Icon(
              margen > 0.3 ? Icons.trending_up : Icons.sentiment_neutral,
              size: 48,
              color: margen > 0.3 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              '${(margen * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 26, 
                fontWeight: FontWeight.bold,
                color: margen > 0.3 ? Colors.green[700] : Colors.orange[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Margen',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 2: DEUDAS ====================

  Widget _buildDeudasTab() {
    final vencidas = _suscripciones.where((s) => s.estado == 'vencida').toList();

    if (vencidas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text("¡Todo al día! No hay cobros pendientes.", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    double totalDeuda = vencidas.fold(0, (sum, s) => sum + s.precio);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.red[50],
          child: Column(
            children: [
              Text(
                'Dinero Pendiente de Cobro',
                style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold),
              ),
              Text(
                NumberFormat.currency(symbol: 'L ').format(totalDeuda),
                style: TextStyle(color: Colors.red[700], fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vencidas.length,
            itemBuilder: (context, index) {
              final sub = vencidas[index];
              final cliente = _clientes.firstWhere((c) => c.id == sub.clienteId, orElse: () => Cliente(id: '', nombreCompleto: 'Desconocido', telefono: '', estado: '', notas: '', fechaRegistro: DateTime.now()));
              final plataforma = _plataformas.firstWhere((p) => p.id == sub.plataformaId, orElse: () => Plataforma(id: '', nombre: '?', icono: '', precioBase: 0, maxPerfiles: 0, color: '#000000', estado: '', fechaCreacion: DateTime.now()));
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: const Icon(Icons.priority_high, color: Colors.red),
                  ),
                  title: Text(cliente.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${plataforma.nombre} • Venció: ${DateFormat('dd/MM/yyyy').format(sub.fechaLimitePago)}'),
                  trailing: Text(
                    NumberFormat.currency(symbol: 'L ', decimalDigits: 0).format(sub.precio),
                    style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red[800]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helpers
  Color _parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isHighlight;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isHighlight ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isHighlight ? Colors.white : color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isHighlight ? Colors.white.withOpacity(0.9) : Colors.grey[600],
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isHighlight ? Colors.white.withOpacity(0.7) : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}