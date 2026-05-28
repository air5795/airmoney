import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/estado_app.dart';
import '../../widgets/panel_transaccion.dart';

class VistaMovimientos extends StatefulWidget {
  const VistaMovimientos({super.key});

  @override
  State<VistaMovimientos> createState() => _VistaMovimientosState();
}

class _VistaMovimientosState extends State<VistaMovimientos> {
  int _selectedFilterMonth = DateTime.now().month;
  int _selectedFilterYear = DateTime.now().year;
  String? _selectedAccountFilter;
  bool _hideBalances = false;
  String _movimientosSortOrder = 'date_desc';

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

  String _formatCurrency(double amount, String currency, {bool showSign = false}) {
    if (_hideBalances) {
      return '$currency***';
    }
    
    final sign = showSign && amount > 0 ? '+' : '';
    final absAmount = amount.abs();
    
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInteger = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    
    final formattedAmount = '$formattedInteger,$decimalPart';
    
    if (amount < 0) {
      return '-$currency$formattedAmount';
    } else {
      return '$sign$currency$formattedAmount';
    }
  }

  String _getDayNameFull(int weekday) {
    switch (weekday) {
      case 1: return 'LUNES';
      case 2: return 'MARTES';
      case 3: return 'MIÉRCOLES';
      case 4: return 'JUEVES';
      case 5: return 'VIERNES';
      case 6: return 'SÁBADO';
      case 7: return 'DOMINGO';
      default: return '';
    }
  }

  void _showSortMenu() {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final activeColor = estadoApp.colorPrincipal;

    showMenu<String>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: RelativeRect.fromLTRB(size.width - 180, 80, 16, 0),
      items: [
        PopupMenuItem(
          value: 'date_desc',
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 18, color: _movimientosSortOrder == 'date_desc' ? activeColor : Colors.grey),
              const SizedBox(width: 8),
              const Text('Recientes primero', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'date_asc',
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: _movimientosSortOrder == 'date_asc' ? activeColor : Colors.grey),
              const SizedBox(width: 8),
              const Text('Antiguos primero', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'amount_desc',
          child: Row(
            children: [
              Icon(Icons.trending_down_rounded, size: 18, color: _movimientosSortOrder == 'amount_desc' ? activeColor : Colors.grey),
              const SizedBox(width: 8),
              const Text('Mayor importe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'amount_asc',
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: _movimientosSortOrder == 'amount_asc' ? activeColor : Colors.grey),
              const SizedBox(width: 8),
              const Text('Menor importe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (val != null) {
        setState(() {
          _movimientosSortOrder = val;
        });
      }
    });
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

    double saldoActualGeneral = 0;
    if (_selectedAccountFilter != null) {
      final acc = estadoApp.accounts.firstWhere(
        (a) => a.id == _selectedAccountFilter,
        orElse: () => ModeloCuenta(id: '', name: '', balance: 0.0, gradientIndex: 0, type: 'Efectivo'),
      );
      saldoActualGeneral = acc.balance;
    } else {
      saldoActualGeneral = estadoApp.accounts.fold(0.0, (sum, acc) => sum + acc.balance);
    }

    List<ModeloTransaccion> todasLasTxs = List.from(estadoApp.transactions);
    todasLasTxs.sort((a, b) => b.date.compareTo(a.date));

    Map<String, double> saldoHistoricoTxs = {};
    double runningBalance = saldoActualGeneral;

    for (var tx in todasLasTxs) {
      saldoHistoricoTxs[tx.id] = runningBalance;
      
      if (_selectedAccountFilter == null) {
        if (tx.type == 'ingreso') {
          runningBalance -= tx.amount;
        } else if (tx.type == 'gasto') {
          runningBalance += tx.amount;
        }
      } else {
        if (tx.accountId == _selectedAccountFilter) {
          runningBalance += tx.amount;
        } else if (tx.toAccountId == _selectedAccountFilter) {
          runningBalance -= tx.amount;
        }
      }
    }

    List<ModeloTransaccion> txsFiltradas = estadoApp.transactions.where((tx) {
      final matchesMonth = tx.date.month == _selectedFilterMonth;
      final matchesYear = tx.date.year == _selectedFilterYear;
      bool matchesAccount = true;
      if (_selectedAccountFilter != null) {
        matchesAccount = tx.accountId == _selectedAccountFilter || tx.toAccountId == _selectedAccountFilter;
      }
      return matchesMonth && matchesYear && matchesAccount;
    }).toList();

    if (_movimientosSortOrder == 'date_desc') {
      txsFiltradas.sort((a, b) => b.date.compareTo(a.date));
    } else if (_movimientosSortOrder == 'date_asc') {
      txsFiltradas.sort((a, b) => a.date.compareTo(b.date));
    } else if (_movimientosSortOrder == 'amount_desc') {
      txsFiltradas.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_movimientosSortOrder == 'amount_asc') {
      txsFiltradas.sort((a, b) => a.amount.compareTo(b.amount));
    }

    Map<String, List<ModeloTransaccion>> agrupadoPorDia = {};
    for (var tx in txsFiltradas) {
      final claveDia = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
      if (!agrupadoPorDia.containsKey(claveDia)) {
        agrupadoPorDia[claveDia] = [];
      }
      agrupadoPorDia[claveDia]!.add(tx);
    }

    List<String> clavesDiasOrdenadas = agrupadoPorDia.keys.toList();
    clavesDiasOrdenadas.sort((a, b) {
      final partsA = a.split('-').map(int.parse).toList();
      final partsB = b.split('-').map(int.parse).toList();
      final dateA = DateTime(partsA[0], partsA[1], partsA[2]);
      final dateB = DateTime(partsB[0], partsB[1], partsB[2]);
      return dateB.compareTo(dateA);
    });

    return Column(
      children: [
        _buildMovimientosHeader(esOscuro, colorTexto),
        const SizedBox(height: 6),
        _buildDateFilterBar(esOscuro, colorTexto),
        const SizedBox(height: 14),
        Expanded(
          child: txsFiltradas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: colorTexto.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'NO HAY REGISTROS EN ESTE PERIODO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorTexto.withValues(alpha: 0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 110),
                  itemCount: clavesDiasOrdenadas.length,
                  itemBuilder: (context, index) {
                    final claveDia = clavesDiasOrdenadas[index];
                    final transaccionesDia = agrupadoPorDia[claveDia]!;
                    final parts = claveDia.split('-').map(int.parse).toList();
                    final fechaDia = DateTime(parts[0], parts[1], parts[2]);

                    double netoDia = transaccionesDia.fold(0.0, (sum, tx) {
                      if (_selectedAccountFilter == null) {
                        if (tx.type == 'ingreso') return sum + tx.amount;
                        if (tx.type == 'gasto') return sum - tx.amount;
                      } else {
                        if (tx.accountId == _selectedAccountFilter) return sum - tx.amount;
                        if (tx.toAccountId == _selectedAccountFilter) return sum + tx.amount;
                      }
                      return sum;
                    });

                    transaccionesDia.sort((a, b) => b.date.compareTo(a.date));
                    final saldoAcumuladoDia = saldoHistoricoTxs[transaccionesDia.first.id] ?? 0.0;

                    return _buildDayCard(
                      fechaDia: fechaDia,
                      netoDia: netoDia,
                      saldoAcumuladoDia: saldoAcumuladoDia,
                      transacciones: transaccionesDia,
                      currency: currency,
                      estadoApp: estadoApp,
                      esOscuro: esOscuro,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMovimientosHeader(bool esOscuro, Color colorTexto) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 12, top: 8, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Libro Mayor',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colorTexto,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _hideBalances ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: colorTexto.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _hideBalances = !_hideBalances;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.sort_rounded, color: colorTexto.withValues(alpha: 0.6), size: 20),
                onPressed: _showSortMenu,
              ),
            ],
          ),
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

  Widget _buildDayCard({
    required DateTime fechaDia,
    required double netoDia,
    required double saldoAcumuladoDia,
    required List<ModeloTransaccion> transacciones,
    required String currency,
    required EstadoApp estadoApp,
    required bool esOscuro,
  }) {
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final String nombreDia = _getDayNameFull(fechaDia.weekday);
    final String mesAnio = '${_monthsNames[fechaDia.month - 1]} ${fechaDia.year}';
    final isNetoDiaPositivo = netoDia >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: esOscuro
                  ? const Color(0xFF0D0E15).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: esOscuro
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.65),
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: esOscuro 
                        ? Colors.white.withValues(alpha: 0.02) 
                        : const Color(0xFFF1F5F9).withValues(alpha: 0.4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: esOscuro 
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            fechaDia.day.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: colorTexto,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreDia,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: colorTexto,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              mesAnio,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: colorTexto.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(netoDia, currency, showSign: true),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isNetoDiaPositivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SALDO: ${_formatCurrency(saldoAcumuladoDia, currency)}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: colorTexto.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFF0D0E15).withValues(alpha: 0.05),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transacciones.length,
                  separatorBuilder: (_, __) => Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.03)
                        : const Color(0xFF0D0E15).withValues(alpha: 0.03),
                  ),
                  itemBuilder: (context, idx) {
                    final tx = transacciones[idx];
                    final isIncome = tx.type == 'ingreso';
                    final isTransfer = tx.type == 'transferencia';

                    String labelDetalle = '';
                    if (isTransfer) {
                      final accOrigen = estadoApp.accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => ModeloCuenta(id: '', name: 'Desconocido', balance: 0, gradientIndex: 0, type: 'Efectivo'));
                      final accDestino = estadoApp.accounts.firstWhere((a) => a.id == tx.toAccountId, orElse: () => ModeloCuenta(id: '', name: 'Desconocido', balance: 0, gradientIndex: 0, type: 'Efectivo'));
                      labelDetalle = 'TRF: ${accOrigen.name.toUpperCase()} > ${accDestino.name.toUpperCase()}';
                    } else {
                      final acc = estadoApp.accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => ModeloCuenta(id: '', name: '', balance: 0, gradientIndex: 0, type: 'Efectivo'));
                      labelDetalle = '${tx.category.toUpperCase()} • ${acc.name.toUpperCase()}';
                    }

                    IconData transIcon = Icons.arrow_downward_rounded;
                    Color transIconColor = const Color(0xFFEF4444);
                    
                    if (isTransfer) {
                      transIcon = Icons.swap_horiz_rounded;
                      transIconColor = const Color(0xFF3B82F6);
                    } else {
                      // Buscar el icono real y color de la categoria de la transaccion
                      final defaultColorHex = isIncome ? '#10B981' : '#EF4444';
                      final cat = estadoApp.categories.firstWhere(
                        (c) => c.name.toLowerCase() == tx.category.toLowerCase(),
                        orElse: () => ModeloCategoria(id: '', name: tx.category, iconCode: 'category', hexColor: defaultColorHex),
                      );
                      transIcon = _galleryIcons[cat.iconCode] ?? Icons.category_rounded;
                      // Resolver color hex a objeto Color
                      try {
                        transIconColor = Color(int.parse(cat.hexColor.replaceFirst('#', '0xFF')));
                      } catch (e) {
                        transIconColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                      }
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => PanelTransaccion(transaccion: tx),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: transIconColor.withValues(alpha: esOscuro ? 0.15 : 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  transIcon,
                                  color: transIconColor,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: colorTexto,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    labelDetalle,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: colorTexto.withValues(alpha: 0.45),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatCurrency(isIncome ? tx.amount : (isTransfer ? tx.amount : -tx.amount), currency, showSign: isIncome),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isIncome
                                      ? const Color(0xFF10B981)
                                      : (isTransfer ? const Color(0xFF3B82F6) : const Color(0xFFEF4444)),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
