import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/estado_app.dart';
import '../../widgets/interactive_scale.dart';

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
  int? _selectedSliceIndex;
  final Set<String> _expandedParentCategoryIds = {};

  static const List<String> _monthsNames = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
  ];

  static final Map<String, IconData> _galleryIcons = EstadoApp.galleryIcons;

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
        final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;

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
                      return InteractiveScale(
                        onTap: () {
                          setState(() {
                            _selectedFilterMonth = idx + 1;
                            _selectedSliceIndex = null;
                            _expandedParentCategoryIds.clear();
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
        final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;
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
                      return InteractiveScale(
                        onTap: () {
                          setState(() {
                            _selectedFilterYear = y;
                            _selectedSliceIndex = null;
                            _expandedParentCategoryIds.clear();
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
        final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;

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
                  InteractiveScale(
                    onTap: () {
                      setState(() {
                        _selectedAccountFilter = null;
                        _selectedSliceIndex = null;
                        _expandedParentCategoryIds.clear();
                      });
                      Navigator.pop(context);
                    },
                    child: ListTile(
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
                    ),
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

                        return InteractiveScale(
                          onTap: () {
                            setState(() {
                              _selectedAccountFilter = acc.id;
                              _selectedSliceIndex = null;
                              _expandedParentCategoryIds.clear();
                            });
                            Navigator.pop(context);
                          },
                          child: ListTile(
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
                          ),
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

    // 1. Filtrar las transacciones del periodo y cuenta seleccionados para gastos
    List<ModeloTransaccion> txsGastos = estadoApp.transactions.where((tx) {
      if (!tx.pagada) return false;
      final matchesMonth = tx.date.month == _selectedFilterMonth;
      final matchesYear = tx.date.year == _selectedFilterYear;
      final matchesType = tx.type == 'gasto';
      bool matchesAccount = true;
      if (_selectedAccountFilter != null) {
        matchesAccount = tx.accountId == _selectedAccountFilter || tx.toAccountId == _selectedAccountFilter;
      }
      return matchesMonth && matchesYear && matchesType && matchesAccount;
    }).toList();
    double totalGastos = txsGastos.fold(0.0, (sum, tx) => sum + tx.amount);

    // 2. Filtrar las transacciones del periodo y cuenta seleccionados para ingresos
    List<ModeloTransaccion> txsIngresos = estadoApp.transactions.where((tx) {
      if (!tx.pagada) return false;
      final matchesMonth = tx.date.month == _selectedFilterMonth;
      final matchesYear = tx.date.year == _selectedFilterYear;
      final matchesType = tx.type == 'ingreso';
      if (tx.esRegistroApertura) return false;
      bool matchesAccount = true;
      if (_selectedAccountFilter != null) {
        matchesAccount = tx.accountId == _selectedAccountFilter || tx.toAccountId == _selectedAccountFilter;
      }
      return matchesMonth && matchesYear && matchesType && matchesAccount;
    }).toList();
    double totalIngresos = txsIngresos.fold(0.0, (sum, tx) => sum + tx.amount);

    // 3. Seleccionar según el filtro activo
    List<ModeloTransaccion> txsPeriodo = _selectedType == 'gasto' ? txsGastos : txsIngresos;
    double totalPeriodo = _selectedType == 'gasto' ? totalGastos : totalIngresos;
    // 5. Agrupar transacciones por categoría principal (padre) y subcategorías (hijos)
    final Map<String, ModeloCategoria> categoriesMap = {
      for (var c in estadoApp.categories) c.id: c
    };
    final Map<String, ModeloCategoria> categoriesByName = {
      for (var c in estadoApp.categories) c.name.toLowerCase().trim(): c
    };

    final Map<String, _GrupoCategoriaPadre> grupos = {};

    for (var tx in txsPeriodo) {
      final catName = tx.category.toLowerCase().trim();
      final cat = categoriesByName[catName];

      if (cat == null) {
        final fallbackId = 'fallback_$catName';
        final fallbackParent = ModeloCategoria(
          id: fallbackId,
          name: tx.category,
          parentId: null,
          iconCode: 'category',
          hexColor: _selectedType == 'ingreso' ? '#10B981' : '#64748B',
        );
        grupos.putIfAbsent(fallbackId, () => _GrupoCategoriaPadre(fallbackParent));
        grupos[fallbackId]!.totalAmount += tx.amount;
        grupos[fallbackId]!.directAmount += tx.amount;
      } else {
        ModeloCategoria padre;
        bool esSubcategoria = cat.parentId != null;
        if (esSubcategoria) {
          final parentCat = categoriesMap[cat.parentId];
          if (parentCat != null) {
            padre = parentCat;
          } else {
            padre = cat;
            esSubcategoria = false;
          }
        } else {
          padre = cat;
        }

        grupos.putIfAbsent(padre.id, () => _GrupoCategoriaPadre(padre));
        final grupo = grupos[padre.id]!;
        grupo.totalAmount += tx.amount;

        if (esSubcategoria) {
          grupo.childAmounts[cat.id] = (grupo.childAmounts[cat.id] ?? 0.0) + tx.amount;
          grupo.childCategories[cat.id] = cat;
        } else {
          grupo.directAmount += tx.amount;
        }
      }
    }

    final List<_GrupoCategoriaPadre> desglosePadres = grupos.values.toList();
    desglosePadres.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    // 6. Preparar las secciones del anillo para el pintor
    List<SeccionGrafico> seccionesDonut = [];
    for (var grupo in desglosePadres) {
      final cat = grupo.parent;
      final porcentaje = totalPeriodo > 0 ? (grupo.totalAmount / totalPeriodo) : 0.0;
      Color colorSec;
      try {
        colorSec = Color(int.parse(cat.hexColor.replaceFirst('#', '0xFF')));
      } catch (_) {
        colorSec = estadoApp.colorPrincipal;
      }
      seccionesDonut.add(SeccionGrafico(
        id: cat.id,
        nombre: cat.name,
        monto: grupo.totalAmount,
        porcentaje: porcentaje,
        color: colorSec,
      ));
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

    // Categoria de mayor gasto / ingreso (basada en el padre de mayor consumo)
    String nombreMayorCategoria = 'Ninguna';
    double montoMayorCategoria = 0.0;
    Color colorMayorCategoria = estadoApp.colorPrincipal;
    if (desglosePadres.isNotEmpty) {
      final group = desglosePadres.first;
      final cat = group.parent;
      nombreMayorCategoria = cat.name.toUpperCase();
      montoMayorCategoria = group.totalAmount;
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
          _buildTypeSelector(esOscuro, colorTexto, estadoApp.colorPrincipal, totalGastos, totalIngresos, currency),
          const SizedBox(height: 16),
          
          if (txsPeriodo.isEmpty)
            _buildNoDataWidget(colorTexto)
          else ...[
            _buildDonutChartSection(esOscuro, colorTexto, totalPeriodo, seccionesDonut, currency, desglosePadres),
            const SizedBox(height: 28),
            _buildCategoryDistributionList(desglosePadres, totalPeriodo, esOscuro, colorTexto, currency, estadoApp.colorPrincipal),
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
          InteractiveScale(
            onTap: () {
              setState(() {
                _selectedFilterMonth--;
                if (_selectedFilterMonth < 1) {
                  _selectedFilterMonth = 12;
                  _selectedFilterYear--;
                }
                _selectedSliceIndex = null;
                _expandedParentCategoryIds.clear();
              });
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF0E0E0E) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: colorTexto.withValues(alpha: 0.6), size: 12),
            ),
          ),
          InteractiveScale(
            onTap: _showMonthSelector,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: esOscuro 
                      ? const Color(0xFF0E0E0E) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: esOscuro 
                        ? Colors.white.withValues(alpha: 0.08) 
                        : const Color(0xFFE2E8F0),
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
          InteractiveScale(
            onTap: _showYearSelector,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: esOscuro 
                      ? const Color(0xFF0E0E0E) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: esOscuro 
                        ? Colors.white.withValues(alpha: 0.08) 
                        : const Color(0xFFE2E8F0),
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
          InteractiveScale(
            onTap: _showAccountFilterSelector,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF0E0E0E) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: _selectedAccountFilter != null ? Border.all(color: activeColor, width: 1.0) : null,
              ),
              child: Icon(
                Icons.filter_alt_outlined,
                color: _selectedAccountFilter != null ? activeColor : colorTexto.withValues(alpha: 0.6),
                size: 16,
              ),
            ),
          ),
          InteractiveScale(
            onTap: () {
              setState(() {
                _selectedFilterMonth++;
                if (_selectedFilterMonth > 12) {
                  _selectedFilterMonth = 1;
                  _selectedFilterYear++;
                }
                _selectedSliceIndex = null;
                _expandedParentCategoryIds.clear();
              });
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF0E0E0E) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: colorTexto.withValues(alpha: 0.6), size: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool esOscuro, Color colorTexto, Color colorPrincipal, double totalGastos, double totalIngresos, String currency) {
    final colorFondoSelector = esOscuro
        ? const Color(0xFF0E0E0E)
        : const Color(0xFFF1F5F9);
    final activeColor = _selectedType == 'gasto' 
        ? const Color(0xFFEF4444) 
        : const Color(0xFF10B981);

    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorFondoSelector,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: esOscuro ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Micro-deslizador animado con color adaptativo
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                left: (_selectedType == 'gasto' ? 0 : 1) * width,
                top: 0,
                bottom: 0,
                width: width,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  decoration: BoxDecoration(
                    color: esOscuro ? activeColor.withValues(alpha: 0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: esOscuro
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                    border: Border.all(
                      color: esOscuro 
                          ? activeColor.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
              
              // Textos de las pestañas
              Row(
                children: [
                  Expanded(
                    child: InteractiveScale(
                      onTap: () {
                        setState(() {
                          _selectedType = 'gasto';
                          _selectedSliceIndex = null;
                          _expandedParentCategoryIds.clear();
                        });
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'GASTOS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: _selectedType == 'gasto' ? FontWeight.w900 : FontWeight.bold,
                                color: _selectedType == 'gasto' 
                                    ? const Color(0xFFEF4444)
                                    : colorTexto.withValues(alpha: 0.5),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatCurrency(totalGastos, currency),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: _selectedType == 'gasto' ? FontWeight.bold : FontWeight.w600,
                                color: _selectedType == 'gasto' 
                                    ? const Color(0xFFEF4444)
                                    : colorTexto.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InteractiveScale(
                      onTap: () {
                        setState(() {
                          _selectedType = 'ingreso';
                          _selectedSliceIndex = null;
                          _expandedParentCategoryIds.clear();
                        });
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'INGRESOS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: _selectedType == 'ingreso' ? FontWeight.w900 : FontWeight.bold,
                                color: _selectedType == 'ingreso' 
                                    ? const Color(0xFF10B981)
                                    : colorTexto.withValues(alpha: 0.5),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatCurrency(totalIngresos, currency),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: _selectedType == 'ingreso' ? FontWeight.bold : FontWeight.w600,
                                color: _selectedType == 'ingreso' 
                                    ? const Color(0xFF10B981)
                                    : colorTexto.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDonutChartSection(
    bool esOscuro,
    Color colorTexto,
    double total,
    List<SeccionGrafico> secciones,
    String currency,
    List<_GrupoCategoriaPadre> listParents,
  ) {
    // Determinar contenido del centro dinámicamente
    String centerLabel;
    String centerAmountText;
    String centerPercentageText;
    Color centerColor = colorTexto;

    if (_selectedSliceIndex != null && _selectedSliceIndex! < secciones.length) {
      final selectedSection = secciones[_selectedSliceIndex!];
      centerLabel = selectedSection.nombre.toUpperCase();
      centerAmountText = _formatCurrency(selectedSection.monto, currency);
      centerPercentageText = '${(selectedSection.porcentaje * 100).toStringAsFixed(1)}%';
      centerColor = selectedSection.color;
    } else {
      centerLabel = _selectedType == 'gasto' ? 'GASTADO' : 'INGRESADO';
      centerAmountText = _formatCurrency(total, currency);
      centerPercentageText = '100%';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: esOscuro ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
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
        children: [
          Text(
            'VISUALIZACIÓN DE FLUJO',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: colorTexto.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutBack,
              builder: (context, animFactor, child) {
                return SizedBox(
                  width: 170,
                  height: 170,
                  child: GestureDetector(
                    onTapUp: (details) {
                      if (secciones.isEmpty) return;

                      final double x = details.localPosition.dx;
                      final double y = details.localPosition.dy;
                      final double centerX = 170 / 2;
                      final double centerY = 170 / 2;
                      final double dx = x - centerX;
                      final double dy = y - centerY;
                      final double distance = sqrt(dx * dx + dy * dy);

                      // Corona circular: el radio medio es 77, el grosor es 16.
                      // Ampliamos el rango de toque de 45 a 95 para mejor usabilidad táctil.
                      if (distance >= 45 && distance <= 95) {
                        double angle = atan2(dy, dx);
                        // Convertir a un rango de [0, 2*pi] con inicio en el extremo superior vertical (-pi/2)
                        double normalizedAngle = angle + pi / 2;
                        if (normalizedAngle < 0) {
                          normalizedAngle += 2 * pi;
                        }

                        double currentAngle = 0.0;
                        int tappedIndex = -1;
                        for (int i = 0; i < secciones.length; i++) {
                          double sweep = secciones[i].porcentaje * 2 * pi;
                          if (normalizedAngle >= currentAngle && normalizedAngle < currentAngle + sweep) {
                            tappedIndex = i;
                            break;
                          }
                          currentAngle += sweep;
                        }

                        // Fallback por imprecisiones decimales cerca de 2*pi
                        if (tappedIndex == -1 && normalizedAngle >= 2 * pi - 0.15) {
                          tappedIndex = secciones.length - 1;
                        }

                        if (tappedIndex != -1) {
                          setState(() {
                            if (_selectedSliceIndex == tappedIndex) {
                              _selectedSliceIndex = null;
                            } else {
                              _selectedSliceIndex = tappedIndex;
                              
                              // Expandir automáticamente el padre seleccionado
                              final selectedParentGroup = listParents[tappedIndex];
                              final hasChildren = selectedParentGroup.childAmounts.isNotEmpty;
                              if (hasChildren) {
                                _expandedParentCategoryIds.add(selectedParentGroup.parent.id);
                              }
                            }
                          });
                        }
                      } else if (distance < 45) {
                        // Pulsar en el centro limpia la selección
                        setState(() {
                          _selectedSliceIndex = null;
                        });
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(170, 170),
                          painter: PintorAnilloEstadisticas(
                            secciones: secciones,
                            factorAnimacion: animFactor,
                            strokeWidth: 16.0,
                            selectedIndex: _selectedSliceIndex,
                          ),
                        ),
                        // Círculo interno para alojar los importes con efecto de cristal
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: esOscuro
                                ? const Color(0xFF000000).withValues(alpha: 0.35)
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
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  centerLabel,
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: _selectedSliceIndex != null ? centerColor : colorTexto.withValues(alpha: 0.4),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  centerAmountText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: _selectedSliceIndex != null ? centerColor : colorTexto,
                                    letterSpacing: -0.5,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                centerPercentageText,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedSliceIndex != null ? centerColor.withValues(alpha: 0.8) : colorTexto.withValues(alpha: 0.45),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistributionList(
    List<_GrupoCategoriaPadre> desglosePadres,
    double totalPeriodo,
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
            itemCount: desglosePadres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final group = desglosePadres[idx];
              final parentCat = group.parent;
              final parentMonto = group.totalAmount;
              final parentPorcentaje = totalPeriodo > 0 ? (parentMonto / totalPeriodo) : 0.0;
              final parentPorcentajeTexto = (parentPorcentaje * 100).toStringAsFixed(1);

              final isSelectedInChart = _selectedSliceIndex != null &&
                  _selectedSliceIndex! < desglosePadres.length &&
                  desglosePadres[_selectedSliceIndex!].parent.id == parentCat.id;

              List<Map<String, dynamic>> childrenList = [];
              group.childAmounts.forEach((childId, amount) {
                final childCat = group.childCategories[childId]!;
                childrenList.add({
                  'categoria': childCat,
                  'monto': amount,
                  'porcentaje': totalPeriodo > 0 ? (amount / totalPeriodo) : 0.0,
                });
              });

              if (group.directAmount > 0 && group.childAmounts.isNotEmpty) {
                childrenList.add({
                  'categoria': ModeloCategoria(
                    id: '${parentCat.id}_direct',
                    name: 'General / Otros',
                    parentId: parentCat.id,
                    iconCode: parentCat.iconCode,
                    hexColor: parentCat.hexColor,
                  ),
                  'monto': group.directAmount,
                  'porcentaje': totalPeriodo > 0 ? (group.directAmount / totalPeriodo) : 0.0,
                });
              }

              childrenList.sort((a, b) => b['monto'].compareTo(a['monto']));

              final hasChildren = childrenList.isNotEmpty;
              final isExpanded = _expandedParentCategoryIds.contains(parentCat.id);

              IconData parentIcon = _galleryIcons[parentCat.iconCode] ?? Icons.category_rounded;
              Color colorCategoria;
              try {
                colorCategoria = Color(int.parse(parentCat.hexColor.replaceFirst('#', '0xFF')));
              } catch (_) {
                colorCategoria = colorPrincipal;
              }

              return Column(
                children: [
                  InteractiveScale(
                    onTap: () {
                      setState(() {
                        if (_selectedSliceIndex == idx) {
                          _selectedSliceIndex = null;
                        } else {
                          _selectedSliceIndex = idx;
                        }

                        if (hasChildren) {
                          if (isExpanded) {
                            _expandedParentCategoryIds.remove(parentCat.id);
                          } else {
                            _expandedParentCategoryIds.add(parentCat.id);
                          }
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelectedInChart
                            ? colorCategoria.withValues(alpha: esOscuro ? 0.08 : 0.04)
                            : (esOscuro
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.black.withValues(alpha: 0.015)),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelectedInChart
                              ? colorCategoria.withValues(alpha: 0.5)
                              : (esOscuro
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04)),
                          width: isSelectedInChart ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorCategoria.withValues(alpha: esOscuro ? 0.20 : 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              parentIcon,
                              color: colorCategoria,
                              size: 16,
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
                                      parentCat.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: colorTexto,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(parentMonto, currency),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: colorTexto,
                                        letterSpacing: -0.2,
                                        fontFeatures: const [FontFeature.tabularFigures()],
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
                                          height: 6,
                                          color: esOscuro
                                              ? Colors.white.withValues(alpha: 0.04)
                                              : Colors.black.withValues(alpha: 0.04),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: parentPorcentaje,
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
                                        '$parentPorcentajeTexto%',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: colorTexto.withValues(alpha: 0.55),
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (hasChildren) ...[
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: isExpanded ? 0.5 : 0.0,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: colorTexto.withValues(alpha: 0.4),
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.fastOutSlowIn,
                    child: isExpanded
                        ? Container(
                            margin: const EdgeInsets.only(top: 8, left: 16),
                            padding: const EdgeInsets.only(left: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: colorCategoria.withValues(alpha: 0.15),
                                  width: 2.0,
                                ),
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: childrenList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, cIdx) {
                                final childItem = childrenList[cIdx];
                                final childCat = childItem['categoria'] as ModeloCategoria;
                                final childMonto = childItem['monto'] as double;
                                final childPorcentaje = childItem['porcentaje'] as double;
                                final childPorcentajeTexto = (childPorcentaje * 100).toStringAsFixed(1);

                                IconData childIcon = _galleryIcons[childCat.iconCode] ?? Icons.circle_outlined;

                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: esOscuro
                                        ? Colors.white.withValues(alpha: 0.01)
                                        : Colors.black.withValues(alpha: 0.005),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: colorCategoria.withValues(alpha: esOscuro ? 0.12 : 0.06),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          childIcon,
                                          color: colorCategoria.withValues(alpha: 0.8),
                                          size: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  childCat.name,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: colorTexto.withValues(alpha: 0.8),
                                                  ),
                                                ),
                                                Text(
                                                  _formatCurrency(childMonto, currency),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: colorTexto.withValues(alpha: 0.9),
                                                    fontFeatures: const [FontFeature.tabularFigures()],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(2),
                                                    child: Container(
                                                      height: 4,
                                                      color: esOscuro
                                                          ? Colors.white.withValues(alpha: 0.02)
                                                          : Colors.black.withValues(alpha: 0.02),
                                                      child: FractionallySizedBox(
                                                        alignment: Alignment.centerLeft,
                                                        widthFactor: childPorcentaje,
                                                        child: Container(
                                                          color: colorCategoria.withValues(alpha: 0.7),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  width: 30,
                                                  alignment: Alignment.centerRight,
                                                  child: Text(
                                                    '$childPorcentajeTexto%',
                                                    style: TextStyle(
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: colorTexto.withValues(alpha: 0.45),
                                                      fontFeatures: const [FontFeature.tabularFigures()],
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
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms, delay: (idx * 40).ms).slideY(begin: 0.05, end: 0);
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
                        ? const Color(0xFF0E0E0E)
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
                                fontFeatures: const [FontFeature.tabularFigures()],
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
                        ? const Color(0xFF0E0E0E)
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
                              fontFeatures: const [FontFeature.tabularFigures()],
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
  final String id;
  final String nombre;
  final double monto;
  final double porcentaje;
  final Color color;

  SeccionGrafico({
    required this.id,
    required this.nombre,
    required this.monto,
    required this.porcentaje,
    required this.color,
  });
}

class PintorAnilloEstadisticas extends CustomPainter {
  final List<SeccionGrafico> secciones;
  final double factorAnimacion;
  final double strokeWidth;
  final int? selectedIndex;

  PintorAnilloEstadisticas({
    required this.secciones,
    required this.factorAnimacion,
    required this.strokeWidth,
    this.selectedIndex,
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
    final double totalSweep = 2 * pi * factorAnimacion;

    for (var i = 0; i < secciones.length; i++) {
      final seccion = secciones[i];
      final double anguloBarridoCompleto = seccion.porcentaje * totalSweep;

      // Dejar un pequeño espacio entre las rebanadas si hay más de una sección
      double gap = 0.0;
      if (secciones.length > 1 && factorAnimacion > 0.8) {
        gap = 0.03; // En radianes (~1.7 grados)
      }

      final double anguloBarrido = max(0.0, anguloBarridoCompleto - gap);
      
      final isSelected = selectedIndex != null && selectedIndex == i;

      final paintSeccion = Paint()
        ..color = isSelected
            ? seccion.color
            : (selectedIndex == null ? seccion.color : seccion.color.withValues(alpha: 0.25))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 4.0 : strokeWidth
        ..strokeCap = StrokeCap.butt;

      if (isSelected) {
        // Calcular el ángulo medio de esta sección para desplazarla en esa dirección radial
        final anguloMedio = anguloInicio + anguloBarridoCompleto / 2;
        final desplazamiento = Offset(cos(anguloMedio) * 3, sin(anguloMedio) * 3);
        final rectDesplazado = Rect.fromCircle(center: center + desplazamiento, radius: radius);
        canvas.drawArc(rectDesplazado, anguloInicio, anguloBarrido, false, paintSeccion);
      } else {
        canvas.drawArc(rect, anguloInicio, anguloBarrido, false, paintSeccion);
      }

      // Incrementar el angulo de inicio para la siguiente seccion basándonos en la proporcion completa
      anguloInicio += seccion.porcentaje * 2 * pi;
    }
  }

  @override
  bool shouldRepaint(covariant PintorAnilloEstadisticas oldDelegate) {
    return oldDelegate.factorAnimacion != factorAnimacion ||
           oldDelegate.secciones != secciones ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.selectedIndex != selectedIndex;
  }
}

class _GrupoCategoriaPadre {
  final ModeloCategoria parent;
  double totalAmount = 0.0;
  double directAmount = 0.0;
  final Map<String, double> childAmounts = {};
  final Map<String, ModeloCategoria> childCategories = {};

  _GrupoCategoriaPadre(this.parent);
}
