import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/estado_app.dart';

class VistaEstadisticas extends StatefulWidget {
  const VistaEstadisticas({super.key});

  @override
  State<VistaEstadisticas> createState() => _VistaEstadisticasState();
}

class _VistaEstadisticasState extends State<VistaEstadisticas> {
  int _selectedFilterMonth = DateTime.now().month;
  int _selectedFilterYear = DateTime.now().year;
  String? _selectedAccountFilter;
  String _selectedType = 'gasto'; // 'gasto' o 'ingreso'

  static const List<String> _monthsNames = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
  ];

  static final Map<String, IconData> _galleryIcons = {
    'restaurant': Icons.restaurant_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'directions_car': Icons.directions_car_rounded,
    'work': Icons.work_rounded,
    'electrical_services': Icons.electrical_services_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'category': Icons.category_rounded,
    'movie': Icons.movie_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'home': Icons.home_rounded,
    'flight': Icons.flight_rounded,
    'pets': Icons.pets_rounded,
    'school': Icons.school_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'savings': Icons.savings_rounded,
    'phone_android': Icons.phone_android_rounded,
    'celebration': Icons.celebration_rounded,
    'water_drop': Icons.water_drop_rounded,
    'router': Icons.router_rounded,
    'tv': Icons.tv_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'build': Icons.build_rounded,
    'payments': Icons.payments_rounded,
    'laptop': Icons.laptop_chromebook_rounded,
    'trending_up': Icons.trending_up_rounded,
    'directions_bus': Icons.directions_bus_rounded,
  };

  String _formatCurrency(double amount, String currency) {
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInteger = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    final formattedAmount = '$formattedInteger,$decimalPart';
    
    return '$currency $formattedAmount';
  }

  void _showMonthSelector() {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final esOscuro = estadoApp.esTemaOscuro;
        final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
        final colorFondo = esOscuro ? const Color(0xFF0D0E15) : Colors.white;

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: colorFondo.withValues(alpha: esOscuro ? 0.85 : 0.90),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: esOscuro ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.65),
                    width: 1.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorTexto.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SELECCIONAR MES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorTexto.withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, idx) {
                      final isSelected = _selectedFilterMonth == (idx + 1);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilterMonth = idx + 1;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? estadoApp.colorPrincipal.withValues(alpha: esOscuro ? 0.20 : 0.12)
                                : (esOscuro ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected 
                                  ? estadoApp.colorPrincipal 
                                  : (esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _monthsNames[idx],
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? estadoApp.colorPrincipal : colorTexto,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showYearSelector() {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final esOscuro = estadoApp.esTemaOscuro;
        final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
        final colorFondo = esOscuro ? const Color(0xFF0D0E15) : Colors.white;
        final currentYear = DateTime.now().year;
        final years = List.generate(10, (idx) => currentYear - 5 + idx);

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: colorFondo.withValues(alpha: esOscuro ? 0.85 : 0.90),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: esOscuro ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.65),
                    width: 1.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorTexto.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SELECCIONAR AÑO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorTexto.withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: years.length,
                    itemBuilder: (context, idx) {
                      final y = years[idx];
                      final isSelected = _selectedFilterYear == y;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilterYear = y;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? estadoApp.colorPrincipal.withValues(alpha: esOscuro ? 0.20 : 0.12)
                                : (esOscuro ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected 
                                  ? estadoApp.colorPrincipal 
                                  : (esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            y.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? estadoApp.colorPrincipal : colorTexto,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAccountFilterSelector() {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final esOscuro = estadoApp.esTemaOscuro;
        final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
        final colorFondo = esOscuro ? const Color(0xFF0D0E15) : Colors.white;

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: colorFondo.withValues(alpha: esOscuro ? 0.85 : 0.90),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: esOscuro ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.65),
                    width: 1.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorTexto.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'FILTRAR POR CUENTA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorTexto.withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedAccountFilter == null 
                            ? estadoApp.colorPrincipal.withValues(alpha: 0.15)
                            : (esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedAccountFilter == null 
                              ? estadoApp.colorPrincipal 
                              : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: _selectedAccountFilter == null ? estadoApp.colorPrincipal : colorTexto.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Todas las cuentas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorTexto,
                      ),
                    ),
                    trailing: _selectedAccountFilter == null
                        ? Icon(Icons.check_circle_rounded, color: estadoApp.colorPrincipal, size: 20)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedAccountFilter = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: estadoApp.accounts.length,
                      itemBuilder: (context, idx) {
                        final acc = estadoApp.accounts[idx];
                        final isSelected = _selectedAccountFilter == acc.id;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? estadoApp.colorPrincipal.withValues(alpha: 0.15)
                                  : (esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? estadoApp.colorPrincipal : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: isSelected ? estadoApp.colorPrincipal : colorTexto.withValues(alpha: 0.6),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            acc.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorTexto,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: estadoApp.colorPrincipal, size: 20)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedAccountFilter = acc.id;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final currency = estadoApp.selectedCurrency == 'BOB' ? 'Bs' : estadoApp.selectedCurrency;

    // 1. Filtrar las transacciones del periodo y cuenta seleccionados para el tipo actual
    List<ModeloTransaccion> txsPeriodo = estadoApp.transactions.where((tx) {
      final matchesMonth = tx.date.month == _selectedFilterMonth;
      final matchesYear = tx.date.year == _selectedFilterYear;
      final matchesType = tx.type == _selectedType;
      bool matchesAccount = true;
      if (_selectedAccountFilter != null) {
        matchesAccount = tx.accountId == _selectedAccountFilter || tx.toAccountId == _selectedAccountFilter;
      }
      return matchesMonth && matchesYear && matchesType && matchesAccount;
    }).toList();

    // 2. Calcular el total acumulado en el periodo
    double totalPeriodo = txsPeriodo.fold(0.0, (sum, tx) => sum + tx.amount);

    // 3. Obtener transacciones del mes anterior para calcular tendencia
    int mesAnterior = _selectedFilterMonth - 1;
    int anioAnterior = _selectedFilterYear;
    if (mesAnterior < 1) {
      mesAnterior = 12;
      anioAnterior--;
    }

    List<ModeloTransaccion> txsMesAnterior = estadoApp.transactions.where((tx) {
      final matchesMonth = tx.date.month == mesAnterior;
      final matchesYear = tx.date.year == anioAnterior;
      final matchesType = tx.type == _selectedType;
      bool matchesAccount = true;
      if (_selectedAccountFilter != null) {
        matchesAccount = tx.accountId == _selectedAccountFilter || tx.toAccountId == _selectedAccountFilter;
      }
      return matchesMonth && matchesYear && matchesType && matchesAccount;
    }).toList();

    double totalMesAnterior = txsMesAnterior.fold(0.0, (sum, tx) => sum + tx.amount);

    // 4. Calcular variacion porcentual
    double variacionPorcentaje = 0.0;
    bool tieneVariacionValida = totalMesAnterior > 0;
    if (tieneVariacionValida) {
      variacionPorcentaje = ((totalPeriodo - totalMesAnterior) / totalMesAnterior) * 100;
    }

    // 5. Agrupar transacciones por categoria
    Map<String, double> agrupadoCategorias = {};
    for (var tx in txsPeriodo) {
      final catKey = tx.category.toLowerCase().trim();
      agrupadoCategorias[catKey] = (agrupadoCategorias[catKey] ?? 0.0) + tx.amount;
    }

    // 6. Obtener informacion detallada de categorias con porcentajes, ordenada de mayor a menor
    List<Map<String, dynamic>> desgloseCategorias = [];
    agrupadoCategorias.forEach((catName, monto) {
      // Buscar la categoria oficial en estadoApp para obtener su color e icono
      final catOficial = estadoApp.categories.firstWhere(
        (c) => c.name.toLowerCase().trim() == catName,
        orElse: () => ModeloCategoria(
          id: '',
          name: catName,
          iconCode: 'category',
          hexColor: _selectedType == 'ingreso' ? '#10B981' : '#64748B',
        ),
      );

      final porcentaje = totalPeriodo > 0 ? (monto / totalPeriodo) : 0.0;
      desgloseCategorias.add({
        'categoria': catOficial,
        'monto': monto,
        'porcentaje': porcentaje,
      });
    });

    // Ordenar de mayor a menor
    desgloseCategorias.sort((a, b) => b['monto'].compareTo(a['monto']));

    // 7. Preparar las secciones del anillo para el pintor
    List<SeccionGrafico> seccionesDonut = [];
    for (var item in desgloseCategorias) {
      final cat = item['categoria'] as ModeloCategoria;
      final porcentaje = item['porcentaje'] as double;
      Color colorSec;
      try {
        colorSec = Color(int.parse(cat.hexColor.replaceFirst('#', '0xFF')));
      } catch (_) {
        colorSec = estadoApp.colorPrincipal;
      }
      seccionesDonut.add(SeccionGrafico(porcentaje: porcentaje, color: colorSec));
    }

    // 8. Calcular insights avanzados
    // Promedio Diario
    double promedioDiario = 0.0;
    final ahora = DateTime.now();
    int diasDivisor = 30;
    if (_selectedFilterMonth == ahora.month && _selectedFilterYear == ahora.year) {
      diasDivisor = ahora.day;
    } else {
      diasDivisor = _obtenerDiasDelMes(_selectedFilterMonth, _selectedFilterYear);
    }
    promedioDiario = totalPeriodo / (diasDivisor > 0 ? diasDivisor : 1);

    // Categoria de mayor gasto / ingreso
    String nombreMayorCategoria = 'Ninguna';
    double montoMayorCategoria = 0.0;
    Color colorMayorCategoria = estadoApp.colorPrincipal;
    if (desgloseCategorias.isNotEmpty) {
      final cat = desgloseCategorias.first['categoria'] as ModeloCategoria;
      nombreMayorCategoria = cat.name.toUpperCase();
      montoMayorCategoria = desgloseCategorias.first['monto'] as double;
      try {
        colorMayorCategoria = Color(int.parse(cat.hexColor.replaceFirst('#', '0xFF')));
      } catch (_) {
        colorMayorCategoria = estadoApp.colorPrincipal;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildEstadisticasHeader(esOscuro, colorTexto),
          const SizedBox(height: 6),
          _buildDateFilterBar(esOscuro, colorTexto),
          const SizedBox(height: 12),
          _buildTypeSelector(esOscuro, colorTexto, estadoApp.colorPrincipal),
          const SizedBox(height: 16),
          
          if (txsPeriodo.isEmpty)
            _buildNoDataWidget(colorTexto)
          else ...[
            _buildSummaryTrendCard(esOscuro, colorTexto, totalPeriodo, variacionPorcentaje, tieneVariacionValida, currency, estadoApp.colorPrincipal),
            const SizedBox(height: 24),
            _buildDonutChartSection(esOscuro, colorTexto, totalPeriodo, seccionesDonut, currency),
            const SizedBox(height: 28),
            _buildCategoryDistributionList(desgloseCategorias, esOscuro, colorTexto, currency, estadoApp.colorPrincipal),
            const SizedBox(height: 24),
            _buildInsightsPanel(esOscuro, colorTexto, promedioDiario, nombreMayorCategoria, montoMayorCategoria, colorMayorCategoria, currency),
            const SizedBox(height: 120),
          ]
        ],
      ),
    );
  }

  Widget _buildEstadisticasHeader(bool esOscuro, Color colorTexto) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 4),
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colorTexto,
              letterSpacing: -0.5,
            ),
          ),
          Icon(
            Icons.pie_chart_rounded,
            color: colorTexto.withValues(alpha: 0.3),
            size: 20,
          )
        ],
      ),
    );
  }

  Widget _buildDateFilterBar(bool esOscuro, Color colorTexto) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final activeColor = estadoApp.colorPrincipal;
    final String mesTexto = _monthsNames[_selectedFilterMonth - 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorTexto.withValues(alpha: 0.5), size: 14),
            onPressed: () {
              setState(() {
                _selectedFilterMonth--;
                if (_selectedFilterMonth < 1) {
                  _selectedFilterMonth = 12;
                  _selectedFilterYear--;
                }
              });
            },
          ),
          GestureDetector(
            onTap: _showMonthSelector,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: esOscuro 
                        ? Colors.white.withValues(alpha: 0.05) 
                        : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: esOscuro 
                          ? Colors.white.withValues(alpha: 0.08) 
                          : Colors.white.withValues(alpha: 0.6),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    mesTexto,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: activeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _showYearSelector,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: esOscuro 
                        ? Colors.white.withValues(alpha: 0.05) 
                        : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: esOscuro 
                          ? Colors.white.withValues(alpha: 0.08) 
                          : Colors.white.withValues(alpha: 0.6),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    _selectedFilterYear.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorTexto.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: _selectedAccountFilter != null ? activeColor : colorTexto.withValues(alpha: 0.5),
              size: 20,
            ),
            onPressed: _showAccountFilterSelector,
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios_rounded, color: colorTexto.withValues(alpha: 0.5), size: 14),
            onPressed: () {
              setState(() {
                _selectedFilterMonth++;
                if (_selectedFilterMonth > 12) {
                  _selectedFilterMonth = 1;
                  _selectedFilterYear++;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool esOscuro, Color colorTexto, Color colorPrincipal) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: esOscuro 
            ? Colors.white.withValues(alpha: 0.03) 
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esOscuro 
              ? Colors.white.withValues(alpha: 0.06) 
              : Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'gasto';
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedType == 'gasto'
                      ? colorPrincipal.withValues(alpha: esOscuro ? 0.20 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedType == 'gasto'
                        ? colorPrincipal
                        : Colors.transparent,
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'GASTOS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: _selectedType == 'gasto' ? colorPrincipal : colorTexto.withValues(alpha: 0.5),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'ingreso';
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedType == 'ingreso'
                      ? const Color(0xFF10B981).withValues(alpha: esOscuro ? 0.20 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedType == 'ingreso'
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'INGRESOS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: _selectedType == 'ingreso' ? const Color(0xFF10B981) : colorTexto.withValues(alpha: 0.5),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTrendCard(
    bool esOscuro,
    Color colorTexto,
    double total,
    double variacion,
    bool tieneVariacionValida,
    String currency,
    Color colorPrincipal,
  ) {
    // Resolver colores de tendencia. Si es gasto, bajar es verde (bueno), subir es rojo (malo). Si es ingreso, subir es verde.
    final bool esGasto = _selectedType == 'gasto';
    final bool esTendenciaPositiva = esGasto ? (variacion <= 0) : (variacion >= 0);
    final Color colorTendencia = esTendenciaPositiva ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    
    String labelVariacion = '';
    if (tieneVariacionValida) {
      final absVar = variacion.abs().toStringAsFixed(1);
      if (esTendenciaPositiva) {
        labelVariacion = esGasto 
            ? 'Gastaste un $absVar% menos que el mes pasado'
            : 'Ingresaste un $absVar% más que el mes pasado';
      } else {
        labelVariacion = esGasto
            ? 'Gastaste un $absVar% más que el mes pasado'
            : 'Ingresaste un $absVar% menos que el mes pasado';
      }
    } else {
      labelVariacion = 'Sin datos comparativos del mes pasado';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esOscuro
            ? const Color(0xFF111625)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: esOscuro
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? 0.20 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedType == 'gasto' ? 'TOTAL DE GASTOS' : 'TOTAL DE INGRESOS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: colorTexto.withValues(alpha: 0.5),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(total, currency),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _selectedType == 'gasto' ? colorPrincipal : const Color(0xFF10B981),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: esOscuro
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFF0D0E15).withValues(alpha: 0.06),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                tieneVariacionValida 
                    ? (esTendenciaPositiva ? Icons.trending_down_rounded : Icons.trending_up_rounded)
                    : Icons.info_outline_rounded,
                color: tieneVariacionValida ? colorTendencia : colorTexto.withValues(alpha: 0.4),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  labelVariacion,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: tieneVariacionValida ? colorTendencia : colorTexto.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChartSection(
    bool esOscuro,
    Color colorTexto,
    double total,
    List<SeccionGrafico> secciones,
    String currency,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutBack,
      builder: (context, animFactor, child) {
        return SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(170, 170),
                painter: PintorAnilloEstadisticas(
                  secciones: secciones,
                  factorAnimacion: animFactor,
                  strokeWidth: 16.0,
                ),
              ),
              // Circulo interno para alojar los importes con efecto de cristal
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: esOscuro
                      ? const Color(0xFF020617).withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.45),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: esOscuro ? 0.08 : 0.02),
                      blurRadius: 10,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedType == 'gasto' ? 'GASTADO' : 'INGRESADO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: colorTexto.withValues(alpha: 0.4),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatCurrency(total, currency),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: colorTexto,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '100%',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: colorTexto.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryDistributionList(
    List<Map<String, dynamic>> desglose,
    bool esOscuro,
    Color colorTexto,
    String currency,
    Color colorPrincipal,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISTRIBUCIÓN POR CATEGORÍA',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: colorTexto.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: desglose.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final item = desglose[idx];
              final cat = item['categoria'] as ModeloCategoria;
              final monto = item['monto'] as double;
              final porcentaje = item['porcentaje'] as double;
              final porcentajeTexto = (porcentaje * 100).toStringAsFixed(1);

              IconData iconData = _galleryIcons[cat.iconCode] ?? Icons.category_rounded;
              Color colorCategoria;
              try {
                colorCategoria = Color(int.parse(cat.hexColor.replaceFirst('#', '0xFF')));
              } catch (_) {
                colorCategoria = colorPrincipal;
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: esOscuro 
                      ? Colors.white.withValues(alpha: 0.02) 
                      : Colors.black.withValues(alpha: 0.015),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: esOscuro 
                        ? Colors.white.withValues(alpha: 0.05) 
                        : Colors.black.withValues(alpha: 0.04),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorCategoria.withValues(alpha: esOscuro ? 0.20 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: colorCategoria,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                cat.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: colorTexto,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                _formatCurrency(monto, currency),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: colorTexto,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    height: 5.5,
                                    color: esOscuro 
                                        ? Colors.white.withValues(alpha: 0.04) 
                                        : Colors.black.withValues(alpha: 0.04),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: porcentaje,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colorCategoria,
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorCategoria.withValues(alpha: 0.3),
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 34,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$porcentajeTexto%',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: colorTexto.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms, delay: (idx * 50).ms).slideX(begin: 0.05, end: 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsPanel(
    bool esOscuro,
    Color colorTexto,
    double promedio,
    String mayorCat,
    double mayorCatMonto,
    Color colorMayorCat,
    String currency,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REVELACIONES CLAVE',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: colorTexto.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  height: 104,
                  decoration: BoxDecoration(
                    color: esOscuro
                        ? const Color(0xFF111625)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: esOscuro
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: esOscuro ? 0.15 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedType == 'gasto' ? 'PROMEDIO DIARIO' : 'PROMEDIO RECIBIDO',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: colorTexto.withValues(alpha: 0.45),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatCurrency(promedio, currency),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: colorTexto,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Calculado en este periodo',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: colorTexto.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  height: 104,
                  decoration: BoxDecoration(
                    color: esOscuro
                        ? const Color(0xFF111625)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: esOscuro
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: esOscuro ? 0.15 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedType == 'gasto' ? 'MAYOR CONSUMO' : 'MAYOR INGRESO',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: colorTexto.withValues(alpha: 0.45),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              mayorCat,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: colorMayorCat,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Monto: ${_formatCurrency(mayorCatMonto, currency)}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: colorTexto.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget(Color colorTexto) {
    return Container(
      height: 380,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 48,
            color: colorTexto.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),
          Text(
            'SIN REGISTROS EN ESTE PERIODO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colorTexto.withValues(alpha: 0.35),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Prueba cambiando de mes o cuenta',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: colorTexto.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }

  int _obtenerDiasDelMes(int mes, int anio) {
    switch (mes) {
      case 1: // Enero
      case 3: // Marzo
      case 5: // Mayo
      case 7: // Julio
      case 8: // Agosto
      case 10: // Octubre
      case 12: // Diciembre
        return 31;
      case 4: // Abril
      case 6: // Junio
      case 9: // Septiembre
      case 11: // Noviembre
        return 30;
      case 2: // Febrero
        final esBisiesto = (anio % 4 == 0 && anio % 100 != 0) || (anio % 400 == 0);
        return esBisiesto ? 29 : 28;
      default:
        return 30;
    }
  }
}

class SeccionGrafico {
  final double porcentaje;
  final Color color;

  SeccionGrafico({required this.porcentaje, required this.color});
}

class PintorAnilloEstadisticas extends CustomPainter {
  final List<SeccionGrafico> secciones;
  final double factorAnimacion;
  final double strokeWidth;

  PintorAnilloEstadisticas({
    required this.secciones,
    required this.factorAnimacion,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Si no hay secciones, pintar un circulo gris base con diseño de cristal
    if (secciones.isEmpty) {
      final paintGris = Paint()
        ..color = Colors.grey.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, paintGris);
      return;
    }

    double anguloInicio = -pi / 2; // Iniciar en el extremo superior vertical (12 en punto)

    for (var i = 0; i < secciones.length; i++) {
      final seccion = secciones[i];
      final anguloBarrido = seccion.porcentaje * 2 * pi * factorAnimacion;

      final paintSeccion = Paint()
        ..color = seccion.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt; // Alineacion contigua limpia

      canvas.drawArc(rect, anguloInicio, anguloBarrido, false, paintSeccion);
      
      // Incrementar el angulo de inicio para la siguiente seccion basándonos en la proporcion completa
      anguloInicio += seccion.porcentaje * 2 * pi;
    }
  }

  @override
  bool shouldRepaint(covariant PintorAnilloEstadisticas oldDelegate) {
    return oldDelegate.factorAnimacion != factorAnimacion ||
           oldDelegate.secciones != secciones ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
