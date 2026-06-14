import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import '../../config/app_config.dart';
import '../../services/estado_app.dart';
import '../../widgets/interactive_scale.dart';
import '../../widgets/panel_transaccion.dart';


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
  final Set<String> _expandedSubcategoryIds = {};

  bool _mostrarReportes = false;
  String? _reporteSeleccionado;
  DateTime? _exportStartDate;
  DateTime? _exportEndDate;
  String _exportFormat = 'csv';

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
                            _expandedSubcategoryIds.clear();
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
                            _expandedSubcategoryIds.clear();
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
                        _expandedSubcategoryIds.clear();
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
                              _expandedSubcategoryIds.clear();
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
          grupo.childTransactions.putIfAbsent(cat.id, () => []).add(tx);
        } else {
          grupo.directAmount += tx.amount;
          grupo.directTransactions.add(tx);
        }
      }
    }

    final List<_GrupoCategoriaPadre> desglosePadres = grupos.values.toList();
    desglosePadres.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    for (var grupo in desglosePadres) {
      grupo.directTransactions.sort((a, b) => b.date.compareTo(a.date));
      grupo.childTransactions.forEach((childId, txs) {
        txs.sort((a, b) => b.date.compareTo(a.date));
      });
    }


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

    final colorFondoDock = esOscuro
        ? const Color(0xFF0A0A0A).withValues(alpha: 0.55)
        : const Color.fromARGB(255, 228, 228, 228).withValues(alpha: 0.75);

    final colorBordeDock = esOscuro
        ? const Color(0xFF1E1E1E)
        : Colors.black.withValues(alpha: 0.05);

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: 82 + MediaQuery.of(context).padding.top,
              bottom: 110,
            ),
            child: Column(
              children: [
                _buildDateFilterBar(esOscuro, colorTexto),
                const SizedBox(height: 12),
                _buildTypeSelector(esOscuro, colorTexto, estadoApp.colorPrincipal, totalGastos, totalIngresos, currency),
                const SizedBox(height: 16),
                
                if (txsPeriodo.isEmpty)
                  _buildNoDataWidget(colorTexto)
                else ...[
                  _buildDonutChartSection(esOscuro, colorTexto, totalPeriodo, seccionesDonut, currency, desglosePadres),
                  const SizedBox(height: 28),
                  _buildCategoryDistributionList(desglosePadres, totalPeriodo, esOscuro, colorTexto, currency, estadoApp.colorPrincipal, estadoApp),
                  const SizedBox(height: 24),
                  _buildInsightsPanel(esOscuro, colorTexto, promedioDiario, nombreMayorCategoria, montoMayorCategoria, colorMayorCategoria, currency),
                ]
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.fastOutSlowIn,
            height: _mostrarReportes
                ? MediaQuery.of(context).size.height
                : 44.0 + 28.0 + MediaQuery.of(context).padding.top + 2.0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 15,
                  sigmaY: 15,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: _mostrarReportes
                        ? (esOscuro ? const Color(0xFF000000).withValues(alpha: 0.92) : const Color(0xFFF8FAFC).withValues(alpha: 0.95))
                        : colorFondoDock,
                    border: Border(
                      bottom: BorderSide(
                        color: _mostrarReportes ? Colors.transparent : colorBordeDock,
                        width: 2.0,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 14 + MediaQuery.of(context).padding.top,
                          bottom: 14,
                        ),
                        child: SizedBox(
                          height: 44,
                          child: _buildEstadisticasHeader(esOscuro, colorTexto, estadoApp),
                        ),
                      ),
                      if (_mostrarReportes)
                        Expanded(
                          child: _buildPanelReportes(esOscuro, colorTexto, estadoApp, currency),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasHeader(bool esOscuro, Color colorTexto, EstadoApp estadoApp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _mostrarReportes ? 'Reportes Financieros' : 'Estadísticas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colorTexto,
            letterSpacing: -0.5,
          ),
        ),
        InteractiveScale(
          onTap: () {
            setState(() {
              _mostrarReportes = !_mostrarReportes;
              if (!_mostrarReportes) {
                _reporteSeleccionado = null;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _mostrarReportes
                  ? (esOscuro ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
                  : estadoApp.colorPrincipal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _mostrarReportes
                    ? (esOscuro ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1))
                    : estadoApp.colorPrincipal.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _mostrarReportes ? Icons.close_rounded : Icons.summarize_rounded,
                  color: _mostrarReportes ? colorTexto : estadoApp.colorPrincipal,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _mostrarReportes ? 'Cerrar' : 'Reportes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _mostrarReportes ? colorTexto : estadoApp.colorPrincipal,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPanelReportes(bool esOscuro, Color colorTexto, EstadoApp estadoApp, String currency) {
    if (_reporteSeleccionado != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                InteractiveScale(
                  onTap: () {
                    setState(() {
                      _reporteSeleccionado = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_rounded, color: colorTexto, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _obtenerTituloReporte(_reporteSeleccionado!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorTexto,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.transparent),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 8),
              child: Column(
                children: [
                  _buildDetalleReporte(_reporteSeleccionado!, esOscuro, colorTexto, estadoApp, currency),
                  if (_reporteSeleccionado != 'exportador_datos') ...[
                    const SizedBox(height: 30),
                    InteractiveScale(
                      onTap: () => _mostrarOpcionesExportacion(context, _reporteSeleccionado!, estadoApp, currency),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: estadoApp.colorPrincipal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: estadoApp.colorPrincipal.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download_rounded, color: estadoApp.colorPrincipal, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'EXPORTAR REPORTE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: estadoApp.colorPrincipal,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    final List<Map<String, dynamic>> reportesDisponibles = [
      {
        'id': 'flujo_caja',
        'titulo': 'Flujo de Caja',
        'descripcion': 'Ingresos vs. gastos del mes y ratio de ahorro neta.',
        'icono': Icons.swap_vert_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'comparativa_cuentas',
        'titulo': 'Comparativa de Cuentas',
        'descripcion': 'Resumen de entradas, salidas y saldos por cuenta.',
        'icono': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 'tendencia_6meses',
        'titulo': 'Tendencia de 6 Meses',
        'descripcion': 'Histórico mensual de ingresos vs. gastos.',
        'icono': Icons.timeline_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'id': 'gastos_hormiga',
        'titulo': 'Gastos Hormiga',
        'descripcion': 'Detección de pequeños consumos recurrentes.',
        'icono': Icons.bug_report_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 'presupuesto_vs_real',
        'titulo': 'Presupuestos vs. Real',
        'descripcion': 'Control de límites por categoría con alarmas.',
        'icono': Icons.adjust_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'id': 'fijos_vs_variables',
        'titulo': 'Gastos Fijos vs. Variables',
        'descripcion': 'Clasificación de costos programados vs. discrecionales.',
        'icono': Icons.pie_chart_outline_rounded,
        'color': const Color(0xFF06B6D4),
      },
      {
        'id': 'dias_semana',
        'titulo': 'Análisis por Días',
        'descripcion': 'Identificación de días pico de gasto (ej. fines de semana).',
        'icono': Icons.calendar_view_week_rounded,
        'color': const Color(0xFFEC4899),
      },
      {
        'id': 'exportador_datos',
        'titulo': 'Exportar Transacciones',
        'descripcion': 'Descarga o comparte transacciones filtradas en CSV/Texto.',
        'icono': Icons.share_rounded,
        'color': const Color(0xFF64748B),
      },
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 60, top: 8),
      itemCount: reportesDisponibles.length,
      itemBuilder: (context, index) {
        final rep = reportesDisponibles[index];
        final repColor = rep['color'] as Color;

        return InteractiveScale(
          onTap: () {
            setState(() {
              _reporteSeleccionado = rep['id'];
              if (_reporteSeleccionado == 'exportador_datos') {
                _exportStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
                _exportEndDate = DateTime.now();
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: esOscuro ? const Color(0xFF121212).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: esOscuro ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: esOscuro ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: repColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(rep['icono'] as IconData, color: repColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rep['titulo'] as String,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: colorTexto,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rep['descripcion'] as String,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colorTexto.withValues(alpha: 0.55),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorTexto.withValues(alpha: 0.25),
                  size: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _obtenerTituloReporte(String id) {
    switch (id) {
      case 'flujo_caja':
        return 'Flujo de Caja';
      case 'comparativa_cuentas':
        return 'Comparativa de Cuentas';
      case 'tendencia_6meses':
        return 'Tendencia de 6 Meses';
      case 'gastos_hormiga':
        return 'Gastos Hormiga';
      case 'presupuesto_vs_real':
        return 'Presupuesto vs. Real';
      case 'fijos_vs_variables':
        return 'Gastos Fijos vs. Variables';
      case 'dias_semana':
        return 'Análisis por Días';
      case 'exportador_datos':
        return 'Exportar Transacciones';
      default:
        return 'Detalle del Reporte';
    }
  }

  Widget _buildDetalleReporte(String id, bool esOscuro, Color colorTexto, EstadoApp estadoApp, String currency) {
    switch (id) {
      case 'flujo_caja':
        return _buildReporteFlujoCaja(esOscuro, colorTexto, estadoApp, currency);
      case 'comparativa_cuentas':
        return _buildReporteComparativaCuentas(esOscuro, colorTexto, estadoApp, currency);
      case 'tendencia_6meses':
        return _buildReporteTendencia6Meses(esOscuro, colorTexto, estadoApp, currency);
      case 'gastos_hormiga':
        return _buildReporteGastosHormiga(esOscuro, colorTexto, estadoApp, currency);
      case 'presupuesto_vs_real':
        return _buildReportePresupuestos(esOscuro, colorTexto, estadoApp, currency);
      case 'fijos_vs_variables':
        return _buildReporteFijosVariables(esOscuro, colorTexto, estadoApp, currency);
      case 'dias_semana':
        return _buildReporteDiasSemana(esOscuro, colorTexto, estadoApp, currency);
      case 'exportador_datos':
        return _buildReporteExportador(esOscuro, colorTexto, estadoApp, currency);
      default:
        return Center(child: Text('Reporte no implementado', style: TextStyle(color: colorTexto)));
    }
  }

  Widget _buildReporteFlujoCaja(bool esOscuro, Color colorTexto, EstadoApp estadoApp, String currency) {
    final txsGastos = estadoApp.transactions.where((tx) {
      return tx.pagada && tx.type == 'gasto' && tx.date.month == _selectedFilterMonth && tx.date.year == _selectedFilterYear;
    }).toList();
    final txsIngresos = estadoApp.transactions.where((tx) {
      return tx.pagada && tx.type == 'ingreso' && !tx.esRegistroApertura && tx.date.month == _selectedFilterMonth && tx.date.year == _selectedFilterYear;
    }).toList();

    double totalG = txsGastos.fold(0.0, (sum, tx) => sum + tx.amount);
    double totalI = txsIngresos.fold(0.0, (sum, tx) => sum + tx.amount);
    double neto = totalI - totalG;
    double ratioAhorro = totalI > 0 ? (neto / totalI) * 100 : 0.0;
    if (ratioAhorro < 0) ratioAhorro = 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis del mes ${_monthsNames[_selectedFilterMonth - 1]} $_selectedFilterYear',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorTexto.withValues(alpha: 0.5), letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),
        _buildInfoRowItem('Ingresos Totales', totalI, const Color(0xFF10B981), Icons.arrow_downward_rounded, currency, esOscuro, colorTexto),
        const SizedBox(height: 10),
        _buildInfoRowItem('Gastos Totales', totalG, const Color(0xFFEF4444), Icons.arrow_upward_rounded, currency, esOscuro, colorTexto),
        const SizedBox(height: 10),
        _buildInfoRowItem(neto >= 0 ? 'Ahorro Neto' : 'Déficit Neto', neto, neto >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444), neto >= 0 ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, currency, esOscuro, colorTexto),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: esOscuro ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tasa de Ahorro', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorTexto)),
                  Text('${ratioAhorro.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 12,
                  width: double.infinity,
                  color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (ratioAhorro / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF10B981)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                ratioAhorro >= 20.0
                    ? '¡Excelente! Estás por encima de la tasa recomendada del 20%. Tu ritmo te permite construir un colchón financiero sólido.'
                    : ratioAhorro > 0.0
                        ? 'Buen trabajo. Estás en verde, pero te sugerimos revisar si puedes optimizar gastos para acercarte a la meta del 20%.'
                        : 'Alerta de flujo de caja. Tus egresos consumieron el total de tus ingresos. Te sugerimos revisar tus gastos hormiga o recortar compras no esenciales.',
                style: TextStyle(fontSize: 11.5, color: colorTexto.withValues(alpha: 0.6), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowItem(String title, double amount, Color color, IconData icon, String currency, bool esOscuro, Color colorTexto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF121212).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esOscuro ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorTexto.withValues(alpha: 0.7)),
            ),
          ),
          Text(
            _formatCurrency(amount, currency),
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: colorTexto),
          ),
        ],
      ),
    );
  }

  Widget _buildReporteComparativaCuentas(bool esOscuro, Color colorTexto, EstadoApp estadoApp, String currency) {
    final accounts = estadoApp.accounts;
    final txs = estadoApp.transactions.where((t) => t.pagada).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flujo por cuenta bancaria y efectivo para el periodo activo',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorTexto.withValues(alpha: 0.5), letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),
        if (accounts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('No hay cuentas creadas aún.', style: TextStyle(color: colorTexto.withValues(alpha: 0.5))),
            ),
          ),
        ...accounts.map((acc) {
          final accTxs = txs.where((t) {
            final matchesMonth = t.date.month == _selectedFilterMonth;
            final matchesYear = t.date.year == _selectedFilterYear;
            final isCurrentAccount = t.accountId == acc.id || t.toAccountId == acc.id;
            return matchesMonth && matchesYear && isCurrentAccount;
          }).toList();

          double entradas = 0.0;
          double salidas = 0.0;

          for (var t in accTxs) {
            if (t.type == 'ingreso') {
              if (t.accountId == acc.id) {
                entradas += t.amount;
              }
            } else if (t.type == 'gasto') {
              if (t.accountId == acc.id) {
                salidas += t.amount;
              }
            } else if (t.type == 'transferencia') {
              if (t.toAccountId == acc.id) {
                entradas += t.amount;
              } else if (t.accountId == acc.id) {
                salidas += t.amount;
              }
            }
          }

          final flujoNeto = entradas - salidas;
          final colorFlujo = flujoNeto >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
          
          Color colorCuenta;
          try {
            colorCuenta = acc.customColorHex != null
                ? Color(int.parse(acc.customColorHex!.replaceFirst('#', '0xFF')))
                : estadoApp.colorPrincipal;
          } catch (_) {
            colorCuenta = estadoApp.colorPrincipal;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: esOscuro ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colorCuenta,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          acc.name,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: colorTexto),
                        ),
                      ],
                    ),
                    Text(
                      _formatCurrency(acc.balance, acc.currency ?? currency),
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: colorTexto),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ENTRADAS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorTexto.withValues(alpha: 0.4))),
                          const SizedBox(height: 2),
                          Text(_formatCurrency(entradas, acc.currency ?? currency), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SALIDAS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorTexto.withValues(alpha: 0.4))),
                          const SizedBox(height: 2),
                          Text(_formatCurrency(salidas, acc.currency ?? currency), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('FLUJO NETO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorTexto.withValues(alpha: 0.4))),
                          const SizedBox(height: 2),
                          Text(
                            (flujoNeto >= 0 ? '+' : '') + _formatCurrency(flujoNeto, acc.currency ?? currency),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorFlujo),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (entradas + salidas > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 5,
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (entradas * 100).toInt() + 1,
                            child: Container(color: const Color(0xFF10B981)),
                          ),
                          Expanded(
                            flex: (salidas * 100).toInt() + 1,
                            child: Container(color: const Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReporteTendencia6Meses(bool esOscuro, Color colorTexto, EstadoApp estadoApp, String currency) {
    List<DateTime> meses = [];
    DateTime base = DateTime(_selectedFilterYear, _selectedFilterMonth, 1);
    for (int i = 5; i >= 0; i--) {
      meses.add(DateTime(base.year, base.month - i, 1));
    }

    List<double> listIngresos = [];
    List<double> listGastos = [];
    double maxMonto = 1.0;

    for (var m in meses) {
      final mGastos = estadoApp.transactions.where((t) {
        return t.pagada && t.type == 'gasto' && t.date.month == m.month && t.date.year == m.year;
      }).fold(0.0, (sum, t) => sum + t.amount);
      
      final mIngresos = estadoApp.transactions.where((t) {
        return t.pagada && t.type == 'ingreso' && !t.esRegistroApertura && t.date.month == m.month && t.date.year == m.year;
      }).fold(0.0, (sum, t) => sum + t.amount);

      listIngresos.add(mIngresos);
      listGastos.add(mGastos);
      
      if (mIngresos > maxMonto) maxMonto = mIngresos;
      if (mGastos > maxMonto) maxMonto = mGastos;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendencia histórica de ingresos vs. gastos (últimos 6 meses)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorTexto.withValues(alpha: 0.5), letterSpacing: 0.5),
        ),
        const SizedBox(height: 20),
        ...List.generate(6, (idx) {
          final mes = meses[idx];
          final ing = listIngresos[idx];
          final gas = listGastos[idx];
          final mesString = _monthsNames[mes.month - 1] + ' ${mes.year.toString().substring(2)}';

          final widthFactorIng = ing / maxMonto;
          final widthFactorGas = gas / maxMonto;

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mesString,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colorTexto),
                    ),
                    Text(
                      'I: ${_formatCurrency(ing, currency)} | G: ${_formatCurrency(gas, currency)}',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: colorTexto.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 12,
                      child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 10),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: widthFactorIng.clamp(0.01, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 12,
                      child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 10),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: widthFactorGas.clamp(0.01, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReporteGastosHormiga(bool esOscuro, Color colorTexto, EstadoApp estadoApp, String currency) {
    final allTxs = estadoApp.transactions.where((t) {
      final matchesMonth = t.date.month == _selectedFilterMonth;
      final matchesYear = t.date.year == _selectedFilterYear;
      return t.pagada && t.type == 'gasto' && matchesMonth && matchesYear;
    }).toList();

    final Map<String, List<ModeloTransaccion>> agrupados = {};
    for (var tx in allTxs) {
      final key = tx.title.trim().toLowerCase();
      if (key.length > 2) {
        agrupados.putIfAbsent(key, () => []).add(tx);
      }
    }

    final threshold = estadoApp.selectedCurrency == 'USD' ? 15.0 : 60.0;
    final List<Map<String, dynamic>> hormigaList = [];

    agrupados.forEach((key, txs) {
      if (txs.length >= 2) {
        final avgAmount = txs.fold(0.0, (sum, tx) => sum + tx.amount) / txs.length;
        if (avgAmount <= threshold) {
          final totalM = txs.fold(0.0, (sum, tx) => sum + tx.amount);
          final tituloBonito = txs.first.title;
          hormigaList.add({
            'titulo': tituloBonito,
            'avg': avgAmount,
            'cantidad': txs.length,
            'total': totalM,
            'anual': totalM * 12,
          });
        }
      }
    });

    hormigaList.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    double totalHormigaMensual = hormigaList.fold(0.0, (sum, item) => sum + (item['total'] as double));
    double totalHormigaAnual = totalHormigaMensual * 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis de consumos frecuentes de bajo valor (Hormiga)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorTexto.withValues(alpha: 0.5), letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: esOscuro ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Fuga Silenciosa Detectada',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: esOscuro ? Colors.white : const Color(0xFF9A3412)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Los pequeños gastos que se repiten constantemente representan una salida importante de capital a mediano plazo.',
                style: TextStyle(fontSize: 12, color: colorTexto.withValues(alpha: 0.75), height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ESTE MES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorTexto.withValues(alpha: 0.5))),
                      const SizedBox(height: 2),
                      Text(_formatCurrency(totalHormigaMensual, currency), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorTexto)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('PROYECCIÓN ANUAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorTexto.withValues(alpha: 0.5))),
                      const SizedBox(height: 2),
                      Text(_formatCurrency(totalHormigaAnual, currency), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Desglose de Gastos Hormiga',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorTexto),
        ),
        const SizedBox(height: 10),
        if (hormigaList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                '¡Excelente! No se detectaron gastos hormiga repetitivos este mes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: colorTexto.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ...hormigaList.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF18181B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFF59E0B), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['titulo'] as String,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: colorTexto),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item['cantidad']} veces este mes (Prom. ${_formatCurrency(item['avg'] as double, currency)})',
                          style: TextStyle(fontSize: 10.5, color: colorTexto.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(item['total'] as double, currency),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorTexto),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Año: ${_formatCurrency(item['anual'] as double, currency)}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildReportePresupuestos(bool esOscuro, Color colorTexto, EstadoApp estadoApp, String currency) {
    final budgets = estadoApp.budgets;
    final txs = estadoApp.transactions.where((t) {
      final matchesMonth = t.date.month == _selectedFilterMonth;
      final matchesYear = t.date.year == _selectedFilterYear;
      return t.pagada && t.type == 'gasto' && matchesMonth && matchesYear;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Desviación presupuestaria mensual por categorías',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorTexto.withValues(alpha: 0.5), letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),
        if (budgets.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                'No has definido presupuestos de gastos mensuales.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorTexto.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ...budgets.map((bud) {
          double gastado = 0.0;
          if (bud.categoryName.toLowerCase() == 'global') {
            gastado = txs.fold(0.0, (sum, t) => sum + t.amount);
          } else {
            gastado = txs
                .where((t) => t.category.toLowerCase().trim() == bud.categoryName.toLowerCase().trim())
                .fold(0.0, (sum, t) => sum + t.amount);
          }

          final limit = bud.limitAmount;
          final pct = limit > 0 ? (gastado / limit) : 0.0;
          final restante = limit - gastado;
          
          Color colorEstado = const Color(0xFF10B981);
          if (pct >= 1.0) {
            colorEstado = const Color(0xFFEF4444);
          } else if (pct >= 0.75) {
            colorEstado = const Color(0xFFF59E0B);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: esOscuro ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bud.categoryName.toUpperCase(),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: colorTexto, letterSpacing: 0.5),
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorEstado),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    height: 8,
                    width: double.infinity,
                    color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(
                          color: colorEstado,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Límite: ${_formatCurrency(limit, currency)}',
                      style: TextStyle(fontSize: 11, color: colorTexto.withValues(alpha: 0.5)),
                    ),
                    Text(
                      restante >= 0 
                          ? 'Restan: ${_formatCurrency(restante, currency)}' 
                          : 'Excedido: ${_formatCurrency(-restante, currency)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: restante >= 0 ? colorTexto.withValues(alpha: 0.7) : const Color(0xFFEF4444)),
                    ),
                  ],
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReporteFijosVariables(bool esOscuro, Color colorTexto, EstadoApp estadoApp, String currency) {
    final txs = estadoApp.transactions.where((t) {
      final matchesMonth = t.date.month == _selectedFilterMonth;
      final matchesYear = t.date.year == _selectedFilterYear;
      return t.pagada && t.type == 'gasto' && matchesMonth && matchesYear;
    }).toList();

    double fijos = 0.0;
    double variables = 0.0;

    final fixedKeywords = ['alquiler', 'servicios', 'suscripcion', 'suscripción', 'educacion', 'educación', 'seguro', 'prestamo', 'préstamo', 'hipoteca', 'impuestos', 'colegio', 'luz', 'agua', 'internet', 'gas', 'telefono', 'teléfono'];

    for (var t in txs) {
      final cat = t.category.toLowerCase().trim();
      final hasFixedKeyword = fixedKeywords.any((keyword) => cat.contains(keyword));
      
      if (t.esProgramada || t.recurrencia != null || hasFixedKeyword) {
        fijos += t.amount;
      } else {
        variables += t.amount;
      }
    }

    final total = fijos + variables;
    final fijosPct = total > 0 ? (fijos / total) * 100 : 0.0;
    final variablesPct = total > 0 ? (variables / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución entre gastos obligatorios (fijos) y discrecionales (variables)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorTexto.withValues(alpha: 0.5), letterSpacing: 0.5),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: esOscuro ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gastos Fijos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorTexto)),
                  Text('${fijosPct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF06B6D4))),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gastos Variables', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorTexto)),
                  Text('${variablesPct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFEC4899))),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 12,
                  width: double.infinity,
                  color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (fijosPct * 10).toInt() + 1,
                        child: Container(color: const Color(0xFF06B6D4)),
                      ),
                      Expanded(
                        flex: (variablesPct * 10).toInt() + 1,
                        child: Container(color: const Color(0xFFEC4899)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildCostTypeCard('Fijos (Comprometidos)', fijos, 'Gastos necesarios para subsistir y mantener contratos. Son difíciles de recortar en el corto plazo.', const Color(0xFF06B6D4), currency, esOscuro, colorTexto),
        const SizedBox(height: 12),
        _buildCostTypeCard('Variables (Discrecionales)', variables, 'Consumos flexibles (ocio, alimentación fuera, ropa). Aquí es donde radica tu principal oportunidad de ahorro rápido.', const Color(0xFFEC4899), currency, esOscuro, colorTexto),
      ],
    );
  }

  Widget _buildCostTypeCard(String title, double amount, String desc, Color color, String currency, bool esOscuro, Color colorTexto) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF121212).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: colorTexto)),
                ],
              ),
              Text(_formatCurrency(amount, currency), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colorTexto)),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(fontSize: 11, color: colorTexto.withValues(alpha: 0.55), height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildReporteDiasSemana(bool esOscuro, Color colorTexto, EstadoApp estadoApp, String currency) {
    final txs = estadoApp.transactions.where((t) {
      final matchesMonth = t.date.month == _selectedFilterMonth;
      final matchesYear = t.date.year == _selectedFilterYear;
      return t.pagada && t.type == 'gasto' && matchesMonth && matchesYear;
    }).toList();

    List<double> montosPorDia = List.filled(7, 0.0);
    List<int> conteoPorDia = List.filled(7, 0);
    final nombresDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    for (var t in txs) {
      int idx = t.date.weekday - 1;
      if (idx >= 0 && idx < 7) {
        montosPorDia[idx] += t.amount;
        conteoPorDia[idx]++;
      }
    }

    double maxMonto = 1.0;
    int idxMax = 0;
    for (int i = 0; i < 7; i++) {
      if (montosPorDia[i] > maxMonto) {
        maxMonto = montosPorDia[i];
        idxMax = i;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis de concentración de gastos por día de la semana',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorTexto.withValues(alpha: 0.5), letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),
        if (txs.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withValues(alpha: esOscuro ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Color(0xFFEC4899), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pico de Consumo: los días ${nombresDias[idxMax]} registran la mayor salida de dinero con un total de ${_formatCurrency(montosPorDia[idxMax], currency)} (${conteoPorDia[idxMax]} transacciones).',
                    style: TextStyle(fontSize: 11.5, color: colorTexto.withValues(alpha: 0.8), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ...List.generate(7, (i) {
          final diaNom = nombresDias[i];
          final monto = montosPorDia[i];
          final count = conteoPorDia[i];
          final factor = maxMonto > 0 ? (monto / maxMonto) : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 75,
                  child: Text(diaNom, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colorTexto)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$count txs', 
                            style: TextStyle(fontSize: 10, color: colorTexto.withValues(alpha: 0.4), fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatCurrency(monto, currency), 
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: colorTexto),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 6,
                          width: double.infinity,
                          color: esOscuro ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: factor.clamp(0.005, 1.0),
                              child: Container(
                                color: i == idxMax ? const Color(0xFFEC4899) : estadoApp.colorPrincipal.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReporteExportador(bool esOscuro, Color colorTexto, EstadoApp estadoApp, String currency) {
    final startStr = _exportStartDate != null ? '${_exportStartDate!.day}/${_exportStartDate!.month}/${_exportStartDate!.year}' : 'Seleccionar';
    final endStr = _exportEndDate != null ? '${_exportEndDate!.day}/${_exportEndDate!.month}/${_exportEndDate!.year}' : 'Seleccionar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtra y exporta tu historial financiero para abrirlo en Excel o compartirlo.',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorTexto.withValues(alpha: 0.5), letterSpacing: 0.5),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: esOscuro ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildDateSelectorRow('Desde:', startStr, true, esOscuro, colorTexto, estadoApp),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Divider(height: 1, thickness: 0.5),
              ),
              _buildDateSelectorRow('Hasta:', endStr, false, esOscuro, colorTexto, estadoApp),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Formato de Salida', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorTexto.withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFormatSelectorButton('Excel / CSV', 'csv', esOscuro, colorTexto, estadoApp),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFormatSelectorButton('Texto TXT', 'texto', esOscuro, colorTexto, estadoApp),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFormatSelectorButton('JSON (.json)', 'json', esOscuro, colorTexto, estadoApp),
            ),
          ],
        ),
        const SizedBox(height: 30),
        InteractiveScale(
          onTap: () => _procesarExportacion(estadoApp, currency),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: estadoApp.colorPrincipal,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: estadoApp.colorPrincipal.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                )
              ]
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'COMPARTIR REPORTE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelectorRow(String label, String valueStr, bool esInicio, bool esOscuro, Color colorTexto, EstadoApp estadoApp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorTexto)),
        InteractiveScale(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: esInicio ? (_exportStartDate ?? DateTime.now()) : (_exportEndDate ?? DateTime.now()),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: estadoApp.colorPrincipal,
                      primary: estadoApp.colorPrincipal,
                      surface: esOscuro ? const Color(0xFF18181B) : Colors.white,
                      onSurface: colorTexto,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                if (esInicio) {
                  _exportStartDate = picked;
                } else {
                  _exportEndDate = picked;
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              valueStr,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: estadoApp.colorPrincipal),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatSelectorButton(String text, String format, bool esOscuro, Color colorTexto, EstadoApp estadoApp) {
    final isSelected = _exportFormat == format;
    return InteractiveScale(
      onTap: () {
        setState(() {
          _exportFormat = format;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? estadoApp.colorPrincipal.withValues(alpha: esOscuro ? 0.15 : 0.08)
              : (esOscuro ? const Color(0xFF18181B) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? estadoApp.colorPrincipal : (esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? estadoApp.colorPrincipal : colorTexto.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Future<void> _procesarExportacion(EstadoApp estadoApp, String currency) async {
    if (_exportStartDate == null || _exportEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona el rango de fechas.')),
      );
      return;
    }

    final txs = estadoApp.transactions.where((t) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      final start = DateTime(_exportStartDate!.year, _exportStartDate!.month, _exportStartDate!.day);
      final end = DateTime(_exportEndDate!.year, _exportEndDate!.month, _exportEndDate!.day);
      
      final inRange = (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
                      (date.isBefore(end) || date.isAtSameMomentAs(end));
      return t.pagada && inRange;
    }).toList();

    txs.sort((a, b) => a.date.compareTo(b.date));

    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay transacciones en el rango de fechas seleccionado.')),
      );
      return;
    }

    if (_exportFormat == 'csv') {
      final buffer = StringBuffer();
      buffer.writeln('Fecha,Tipo,Monto,Categoria,Titulo,Descripcion,Cuenta');
      for (var t in txs) {
        final dateStr = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
        final acc = estadoApp.accounts.firstWhere((a) => a.id == t.accountId, orElse: () => ModeloCuenta(id: '', name: 'Desconocida', type: '', balance: 0.0, gradientIndex: 0));
        
        final titleClean = t.title.replaceAll('"', '""').replaceAll(',', ' ');
        final descClean = t.description.replaceAll('"', '""').replaceAll(',', ' ');
        
        buffer.writeln('$dateStr,${t.type},${t.amount},${t.category},"$titleClean","$descClean","${acc.name}"');
      }

      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/reporte_transacciones_${DateTime.now().millisecondsSinceEpoch}.csv');
        await file.writeAsString(buffer.toString());

        if (!mounted) return;
        _mostrarOpcionesArchivoGenerado(file, 'csv', 'Transacciones desde ${AppConfig.appName}', estadoApp);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar archivo CSV: $e')),
        );
      }
    } else if (_exportFormat == 'json') {
      final List<Map<String, dynamic>> txsMap = txs.map((t) {
        final map = t.toMap();
        final acc = estadoApp.accounts.firstWhere((a) => a.id == t.accountId, orElse: () => ModeloCuenta(id: '', name: 'Desconocida', type: '', balance: 0.0, gradientIndex: 0));
        map['nombreCuenta'] = acc.name;
        return map;
      }).toList();

      final jsonContent = const JsonEncoder.withIndent('  ').convert(txsMap);

      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/exportacion_transacciones_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(jsonContent);

        if (!mounted) return;
        _mostrarOpcionesArchivoGenerado(file, 'json', 'Transacciones JSON', estadoApp);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar archivo JSON: $e')),
        );
      }
    } else {
      final buffer = StringBuffer();
      buffer.writeln('========================================');
      buffer.writeln('      REPORTE DE TRANSACCIONES          ');
      buffer.writeln('========================================');
      buffer.writeln('Desde: ${_exportStartDate!.day}/${_exportStartDate!.month}/${_exportStartDate!.year}');
      buffer.writeln('Hasta: ${_exportEndDate!.day}/${_exportEndDate!.month}/${_exportEndDate!.year}');
      buffer.writeln('Total transacciones: ${txs.length}');
      buffer.writeln('========================================\n');

      double totalI = 0;
      double totalG = 0;

      for (var t in txs) {
        final dateStr = '${t.date.day.toString().padLeft(2, '0')}/${t.date.month.toString().padLeft(2, '0')}/${t.date.year}';
        final sign = t.type == 'ingreso' ? '+' : '-';
        buffer.writeln('[$dateStr] ${t.category.toUpperCase()} | ${t.title}');
        buffer.writeln('      $sign ${_formatCurrency(t.amount, currency)}');
        if (t.description.isNotEmpty) {
          buffer.writeln('      Nota: ${t.description}');
        }
        buffer.writeln('----------------------------------------');

        if (t.type == 'ingreso') {
          if (!t.esRegistroApertura) totalI += t.amount;
        } else if (t.type == 'gasto') {
          totalG += t.amount;
        }
      }

      buffer.writeln('\n========================================');
      buffer.writeln('RESUMEN:');
      buffer.writeln('  Ingresos Netos: ${_formatCurrency(totalI, currency)}');
      buffer.writeln('  Gastos Netos  : ${_formatCurrency(totalG, currency)}');
      buffer.writeln('  Balance Neto  : ${_formatCurrency(totalI - totalG, currency)}');
      buffer.writeln('========================================');

      await Share.share(buffer.toString(), subject: 'Reporte de Gastos');
    }
  }

  void _mostrarOpcionesExportacion(BuildContext context, String id, EstadoApp estadoApp, String currency) {
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
                    'EXPORTAR REPORTE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorTexto.withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildExportOptionItem(
                        context: context,
                        label: 'Excel',
                        sub: '(.csv)',
                        icon: Icons.table_view_rounded,
                        color: const Color(0xFF10B981),
                        esOscuro: esOscuro,
                        colorTexto: colorTexto,
                        onTap: () {
                          Navigator.pop(context);
                          _ejecutarExportacionDeReporte(id, 'excel', estadoApp, currency);
                        },
                      ),
                      _buildExportOptionItem(
                        context: context,
                        label: 'Documento PDF',
                        sub: '(.pdf)',
                        icon: Icons.picture_as_pdf_rounded,
                        color: const Color(0xFFEF4444),
                        esOscuro: esOscuro,
                        colorTexto: colorTexto,
                        onTap: () {
                          Navigator.pop(context);
                          _ejecutarExportacionDeReporte(id, 'pdf', estadoApp, currency);
                        },
                      ),
                      _buildExportOptionItem(
                        context: context,
                        label: 'JSON',
                        sub: '(.json)',
                        icon: Icons.code_rounded,
                        color: const Color(0xFF3B82F6),
                        esOscuro: esOscuro,
                        colorTexto: colorTexto,
                        onTap: () {
                          Navigator.pop(context);
                          _ejecutarExportacionDeReporte(id, 'json', estadoApp, currency);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportOptionItem({
    required BuildContext context,
    required String label,
    required String sub,
    required IconData icon,
    required Color color,
    required bool esOscuro,
    required Color colorTexto,
    required VoidCallback onTap,
  }) {
    return InteractiveScale(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorTexto),
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: colorTexto.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarExportacionDeReporte(String id, String formato, EstadoApp estadoApp, String currency) async {
    String filename = 'reporte_${id}_${DateTime.now().millisecondsSinceEpoch}';
    String extension = '';
    String content = '';
    Uint8List? pdfBytes;
    final now = DateTime.now();
    final mesNombre = _monthsNames[_selectedFilterMonth - 1];

    if (formato == 'json') {
      extension = 'json';
      Map<String, dynamic> jsonData = {
        'reporte': id,
        'fecha_generacion': now.toIso8601String(),
        'periodo': '$mesNombre $_selectedFilterYear',
        'moneda': currency,
      };

      if (id == 'flujo_caja') {
        final txsGastos = estadoApp.transactions.where((tx) => tx.pagada && tx.type == 'gasto' && tx.date.month == _selectedFilterMonth && tx.date.year == _selectedFilterYear).toList();
        final txsIngresos = estadoApp.transactions.where((tx) => tx.pagada && tx.type == 'ingreso' && !tx.esRegistroApertura && tx.date.month == _selectedFilterMonth && tx.date.year == _selectedFilterYear).toList();
        double totalG = txsGastos.fold(0.0, (sum, tx) => sum + tx.amount);
        double totalI = txsIngresos.fold(0.0, (sum, tx) => sum + tx.amount);
        double neto = totalI - totalG;
        double ratio = totalI > 0 ? (neto / totalI) * 100 : 0.0;
        jsonData['datos'] = {
          'ingresos_totales': totalI,
          'gastos_totales': totalG,
          'ahorro_neto': neto,
          'tasa_ahorro_porcentaje': ratio,
        };
      } else if (id == 'comparativa_cuentas') {
        final accountsList = [];
        for (var acc in estadoApp.accounts) {
          final accTxs = estadoApp.transactions.where((t) => t.pagada && (t.accountId == acc.id || t.toAccountId == acc.id) && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
          double entradas = 0.0;
          double salidas = 0.0;
          for (var t in accTxs) {
            if (t.type == 'ingreso' && t.accountId == acc.id) entradas += t.amount;
            else if (t.type == 'gasto' && t.accountId == acc.id) salidas += t.amount;
            else if (t.type == 'transferencia') {
              if (t.toAccountId == acc.id) entradas += t.amount;
              else if (t.accountId == acc.id) salidas += t.amount;
            }
          }
          accountsList.add({
            'nombre_cuenta': acc.name,
            'saldo_actual': acc.balance,
            'entradas': entradas,
            'salidas': salidas,
            'flujo_neto': entradas - salidas,
          });
        }
        jsonData['datos'] = accountsList;
      } else if (id == 'tendencia_6meses') {
        List<DateTime> meses = [];
        DateTime base = DateTime(_selectedFilterYear, _selectedFilterMonth, 1);
        for (int i = 5; i >= 0; i--) {
          meses.add(DateTime(base.year, base.month - i, 1));
        }
        final trendsList = [];
        for (var m in meses) {
          double g = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == m.month && t.date.year == m.year).fold(0.0, (sum, t) => sum + t.amount);
          double ing = estadoApp.transactions.where((t) => t.pagada && t.type == 'ingreso' && !t.esRegistroApertura && t.date.month == m.month && t.date.year == m.year).fold(0.0, (sum, t) => sum + t.amount);
          trendsList.add({
            'mes': '${_monthsNames[m.month - 1]} ${m.year}',
            'ingresos': ing,
            'gastos': g,
            'balance': ing - g,
          });
        }
        jsonData['datos'] = trendsList;
      } else if (id == 'gastos_hormiga') {
        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        final Map<String, List<ModeloTransaccion>> agrupados = {};
        for (var tx in txs) {
          final key = tx.title.trim().toLowerCase();
          if (key.length > 2) agrupados.putIfAbsent(key, () => []).add(tx);
        }
        final threshold = estadoApp.selectedCurrency == 'USD' ? 15.0 : 60.0;
        final list = [];
        agrupados.forEach((key, txList) {
          if (txList.length >= 2) {
            final avg = txList.fold(0.0, (sum, tx) => sum + tx.amount) / txList.length;
            if (avg <= threshold) {
              final tot = txList.fold(0.0, (sum, tx) => sum + tx.amount);
              list.add({
                'concepto': txList.first.title,
                'cantidad': txList.length,
                'promedio': avg,
                'total_mensual': tot,
                'proyeccion_anual': tot * 12,
              });
            }
          }
        });
        jsonData['datos'] = list;
      } else if (id == 'presupuesto_vs_real') {
        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        final list = [];
        for (var bud in estadoApp.budgets) {
          double gastado = 0.0;
          if (bud.categoryName.toLowerCase() == 'global') {
            gastado = txs.fold(0.0, (sum, t) => sum + t.amount);
          } else {
            gastado = txs.where((t) => t.category.toLowerCase().trim() == bud.categoryName.toLowerCase().trim()).fold(0.0, (sum, t) => sum + t.amount);
          }
          list.add({
            'categoria': bud.categoryName,
            'limite': bud.limitAmount,
            'gastado': gastado,
            'porcentaje': bud.limitAmount > 0 ? (gastado / bud.limitAmount) * 100 : 0.0,
            'restante': bud.limitAmount - gastado,
          });
        }
        jsonData['datos'] = list;
      } else if (id == 'fijos_vs_variables') {
        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        double f = 0.0;
        double v = 0.0;
        final fixedKeywords = ['alquiler', 'servicios', 'suscripcion', 'suscripción', 'educacion', 'educación', 'seguro', 'prestamo', 'préstamo', 'hipoteca', 'impuestos', 'colegio', 'luz', 'agua', 'internet', 'gas', 'telefono', 'teléfono'];
        for (var t in txs) {
          final cat = t.category.toLowerCase().trim();
          final hasFixedKeyword = fixedKeywords.any((keyword) => cat.contains(keyword));
          if (t.esProgramada || t.recurrencia != null || hasFixedKeyword) f += t.amount;
          else v += t.amount;
        }
        double tot = f + v;
        jsonData['datos'] = {
          'gastos_fijos': f,
          'gastos_variables': v,
          'porcentaje_fijos': tot > 0 ? (f / tot) * 100 : 0,
          'porcentaje_variables': tot > 0 ? (v / tot) * 100 : 0,
        };
      } else if (id == 'dias_semana') {
        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        List<double> montos = List.filled(7, 0.0);
        List<int> conteos = List.filled(7, 0);
        final nombresDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
        for (var t in txs) {
          int idx = t.date.weekday - 1;
          if (idx >= 0 && idx < 7) {
            montos[idx] += t.amount;
            conteos[idx]++;
          }
        }
        final list = [];
        for (int i = 0; i < 7; i++) {
          list.add({
            'dia': nombresDias[i],
            'monto': montos[i],
            'cantidad_transacciones': conteos[i],
          });
        }
        jsonData['datos'] = list;
      }

      content = const JsonEncoder.withIndent('  ').convert(jsonData);
    } else if (formato == 'excel') {
      extension = 'csv';
      final buffer = StringBuffer();

      if (id == 'flujo_caja') {
        final txsGastos = estadoApp.transactions.where((tx) => tx.pagada && tx.type == 'gasto' && tx.date.month == _selectedFilterMonth && tx.date.year == _selectedFilterYear).toList();
        final txsIngresos = estadoApp.transactions.where((tx) => tx.pagada && tx.type == 'ingreso' && !tx.esRegistroApertura && tx.date.month == _selectedFilterMonth && tx.date.year == _selectedFilterYear).toList();
        double totalG = txsGastos.fold(0.0, (sum, tx) => sum + tx.amount);
        double totalI = txsIngresos.fold(0.0, (sum, tx) => sum + tx.amount);
        double neto = totalI - totalG;
        double ratio = totalI > 0 ? (neto / totalI) * 100 : 0.0;

        buffer.writeln('Reporte: Flujo de Caja');
        buffer.writeln('Periodo,$mesNombre $_selectedFilterYear');
        buffer.writeln('Moneda,$currency\n');
        buffer.writeln('Concepto,Monto');
        buffer.writeln('Ingresos Totales,$totalI');
        buffer.writeln('Gastos Totales,$totalG');
        buffer.writeln('Balance Neto,$neto');
        buffer.writeln('Tasa de Ahorro (%),${ratio.toStringAsFixed(2)}');
      } else if (id == 'comparativa_cuentas') {
        buffer.writeln('Reporte: Comparativa de Cuentas');
        buffer.writeln('Periodo,$mesNombre $_selectedFilterYear');
        buffer.writeln('Moneda,$currency\n');
        buffer.writeln('Cuenta,Saldo Actual,Entradas,Salidas,Flujo Neto');
        for (var acc in estadoApp.accounts) {
          final accTxs = estadoApp.transactions.where((t) => t.pagada && (t.accountId == acc.id || t.toAccountId == acc.id) && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
          double entradas = 0.0;
          double salidas = 0.0;
          for (var t in accTxs) {
            if (t.type == 'ingreso' && t.accountId == acc.id) entradas += t.amount;
            else if (t.type == 'gasto' && t.accountId == acc.id) salidas += t.amount;
            else if (t.type == 'transferencia') {
              if (t.toAccountId == acc.id) entradas += t.amount;
              else if (t.accountId == acc.id) salidas += t.amount;
            }
          }
          buffer.writeln('${acc.name},${acc.balance},$entradas,$salidas,${entradas - salidas}');
        }
      } else if (id == 'tendencia_6meses') {
        buffer.writeln('Reporte: Tendencia de 6 Meses');
        buffer.writeln('Periodo,$mesNombre $_selectedFilterYear');
        buffer.writeln('Moneda,$currency\n');
        buffer.writeln('Mes,Ingresos,Gastos,Balance');
        List<DateTime> meses = [];
        DateTime base = DateTime(_selectedFilterYear, _selectedFilterMonth, 1);
        for (int i = 5; i >= 0; i--) meses.add(DateTime(base.year, base.month - i, 1));
        for (var m in meses) {
          double g = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == m.month && t.date.year == m.year).fold(0.0, (sum, t) => sum + t.amount);
          double ing = estadoApp.transactions.where((t) => t.pagada && t.type == 'ingreso' && !t.esRegistroApertura && t.date.month == m.month && t.date.year == m.year).fold(0.0, (sum, t) => sum + t.amount);
          buffer.writeln('${_monthsNames[m.month - 1]} ${m.year},$ing,$g,${ing - g}');
        }
      } else if (id == 'gastos_hormiga') {
        buffer.writeln('Reporte: Análisis de Gastos Hormiga');
        buffer.writeln('Periodo,$mesNombre $_selectedFilterYear');
        buffer.writeln('Moneda,$currency\n');
        buffer.writeln('Concepto,Veces/Mes,Promedio,Total Mensual,Proyeccion Anual');
        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        final Map<String, List<ModeloTransaccion>> agrupados = {};
        for (var tx in txs) {
          final key = tx.title.trim().toLowerCase();
          if (key.length > 2) agrupados.putIfAbsent(key, () => []).add(tx);
        }
        final threshold = estadoApp.selectedCurrency == 'USD' ? 15.0 : 60.0;
        agrupados.forEach((key, txList) {
          if (txList.length >= 2) {
            final avg = txList.fold(0.0, (sum, tx) => sum + tx.amount) / txList.length;
            if (avg <= threshold) {
              final tot = txList.fold(0.0, (sum, tx) => sum + tx.amount);
              buffer.writeln('"${txList.first.title}",${txList.length},$avg,$tot,${tot * 12}');
            }
          }
        });
      } else if (id == 'presupuesto_vs_real') {
        buffer.writeln('Reporte: Presupuesto vs. Real');
        buffer.writeln('Periodo,$mesNombre $_selectedFilterYear');
        buffer.writeln('Moneda,$currency\n');
        buffer.writeln('Categoria,Limite,Gastado,Porcentaje Consumido,Restante');
        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        for (var bud in estadoApp.budgets) {
          double gastado = 0.0;
          if (bud.categoryName.toLowerCase() == 'global') {
            gastado = txs.fold(0.0, (sum, t) => sum + t.amount);
          } else {
            gastado = txs.where((t) => t.category.toLowerCase().trim() == bud.categoryName.toLowerCase().trim()).fold(0.0, (sum, t) => sum + t.amount);
          }
          final pct = bud.limitAmount > 0 ? (gastado / bud.limitAmount) * 100 : 0.0;
          buffer.writeln('${bud.categoryName},${bud.limitAmount},$gastado,${pct.toStringAsFixed(1)},${bud.limitAmount - gastado}');
        }
      } else if (id == 'fijos_vs_variables') {
        buffer.writeln('Reporte: Gastos Fijos vs. Variables');
        buffer.writeln('Periodo,$mesNombre $_selectedFilterYear');
        buffer.writeln('Moneda,$currency\n');
        buffer.writeln('Tipo de Gasto,Monto,Porcentaje');
        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        double f = 0.0;
        double v = 0.0;
        final fixedKeywords = ['alquiler', 'servicios', 'suscripcion', 'suscripción', 'educacion', 'educación', 'seguro', 'prestamo', 'préstamo', 'hipoteca', 'impuestos', 'colegio', 'luz', 'agua', 'internet', 'gas', 'telefono', 'teléfono'];
        for (var t in txs) {
          final cat = t.category.toLowerCase().trim();
          final hasFixedKeyword = fixedKeywords.any((keyword) => cat.contains(keyword));
          if (t.esProgramada || t.recurrencia != null || hasFixedKeyword) f += t.amount;
          else v += t.amount;
        }
        double tot = f + v;
        final fPct = tot > 0 ? (f / tot) * 100 : 0;
        final vPct = tot > 0 ? (v / tot) * 100 : 0;
        buffer.writeln('Fijos,$f,${fPct.toStringAsFixed(1)}');
        buffer.writeln('Variables,$v,${vPct.toStringAsFixed(1)}');
      } else if (id == 'dias_semana') {
        buffer.writeln('Reporte: Análisis por Días de la Semana');
        buffer.writeln('Periodo,$mesNombre $_selectedFilterYear');
        buffer.writeln('Moneda,$currency\n');
        buffer.writeln('Dia,Monto,Cantidad de Transacciones');
        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        List<double> montos = List.filled(7, 0.0);
        List<int> conteos = List.filled(7, 0);
        final nombresDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
        for (var t in txs) {
          int idx = t.date.weekday - 1;
          if (idx >= 0 && idx < 7) {
            montos[idx] += t.amount;
            conteos[idx]++;
          }
        }
        for (int i = 0; i < 7; i++) {
          buffer.writeln('${nombresDias[i]},${montos[i]},${conteos[i]}');
        }
      }

      content = buffer.toString();
    } else if (formato == 'pdf') {
      extension = 'pdf';
      final pdf = pw.Document();
      final color = estadoApp.colorPrincipal;
      final primaryPdfColor = PdfColor(color.red / 255.0, color.green / 255.0, color.blue / 255.0);
      final textPdfColor = const PdfColor(0.09, 0.14, 0.23);
      final bgLight = const PdfColor(0.96, 0.98, 1.0);
      final borderGrey = const PdfColor(0.88, 0.92, 0.96);

      final titleStyle = pw.TextStyle(
        fontSize: 20,
        fontWeight: pw.FontWeight.bold,
        color: primaryPdfColor,
      );
      final subtitleStyle = const pw.TextStyle(
        fontSize: 9,
        color: PdfColor(0.4, 0.45, 0.5),
      );
      final bodyStyle = pw.TextStyle(
        fontSize: 9,
        color: textPdfColor,
      );
      final boldBodyStyle = pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: textPdfColor,
      );

      pw.Widget buildPdfHeader(String title) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  AppConfig.appName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryPdfColor,
                  ),
                ),
                pw.Text(
                  '${now.day}/${now.month}/${now.year}',
                  style: subtitleStyle,
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              title,
              style: titleStyle,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Periodo: $mesNombre $_selectedFilterYear | Moneda: $currency',
              style: subtitleStyle,
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              height: 1.5,
              color: primaryPdfColor,
            ),
            pw.SizedBox(height: 20),
          ],
        );
      }

      pw.TableRow buildTableRow(String label, String value, {bool isHighlight = false}) {
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isHighlight ? bgLight : null,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                label,
                style: isHighlight ? boldBodyStyle : bodyStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                value,
                style: isHighlight ? boldBodyStyle : bodyStyle,
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        );
      }

      if (id == 'flujo_caja') {
        final txsGastos = estadoApp.transactions.where((tx) => tx.pagada && tx.type == 'gasto' && tx.date.month == _selectedFilterMonth && tx.date.year == _selectedFilterYear).toList();
        final txsIngresos = estadoApp.transactions.where((tx) => tx.pagada && tx.type == 'ingreso' && !tx.esRegistroApertura && tx.date.month == _selectedFilterMonth && tx.date.year == _selectedFilterYear).toList();
        double totalG = txsGastos.fold(0.0, (sum, tx) => sum + tx.amount);
        double totalI = txsIngresos.fold(0.0, (sum, tx) => sum + tx.amount);
        double neto = totalI - totalG;
        double ratio = totalI > 0 ? (neto / totalI) * 100 : 0.0;
        final diagnostico = ratio >= 20.0 
            ? 'Excelente nivel de ahorro mensual (meta recomendada: 20%).'
            : ratio > 0.0 
                ? 'Nivel de ahorro moderado. Se sugiere reducir gastos variables.'
                : 'Flujo deficitario. Se sugiere revisar con urgencia los gastos hormiga.';

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildPdfHeader('Balance de Flujo de Caja'),
                  pw.Text('RESUMEN DE FLUJOS:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryPdfColor)),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                    children: [
                      buildTableRow('Ingresos Totales', _formatCurrency(totalI, currency)),
                      buildTableRow('Gastos Totales', _formatCurrency(totalG, currency)),
                      buildTableRow('Balance Neto', _formatCurrency(neto, currency), isHighlight: true),
                      buildTableRow('Tasa de Ahorro', '${ratio.toStringAsFixed(1)}%', isHighlight: true),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: bgLight,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: borderGrey, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Diagnóstico de Salud Financiera:', style: boldBodyStyle),
                        pw.SizedBox(height: 6),
                        pw.Text(diagnostico, style: bodyStyle),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      } else if (id == 'comparativa_cuentas') {
        final tableRows = <pw.TableRow>[
          pw.TableRow(
            decoration: pw.BoxDecoration(color: primaryPdfColor),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Cuenta', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Saldo Actual', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Entradas (+)', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Salidas (-)', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Flujo Neto', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
            ],
          ),
        ];

        for (var acc in estadoApp.accounts) {
          final accTxs = estadoApp.transactions.where((t) => t.pagada && (t.accountId == acc.id || t.toAccountId == acc.id) && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
          double entradas = 0.0;
          double salidas = 0.0;
          for (var t in accTxs) {
            if (t.type == 'ingreso' && t.accountId == acc.id) entradas += t.amount;
            else if (t.type == 'gasto' && t.accountId == acc.id) salidas += t.amount;
            else if (t.type == 'transferencia') {
              if (t.toAccountId == acc.id) entradas += t.amount;
              else if (t.accountId == acc.id) salidas += t.amount;
            }
          }
          final cur = acc.currency ?? currency;
          tableRows.add(
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(acc.name, style: bodyStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(acc.balance, cur), style: bodyStyle, textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(entradas, cur), style: bodyStyle, textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(salidas, cur), style: bodyStyle, textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(entradas - salidas, cur), style: boldBodyStyle, textAlign: pw.TextAlign.right)),
              ],
            ),
          );
        }

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildPdfHeader('Comparativa de Cuentas'),
                  pw.Text('BALANCE GENERAL POR CUENTAS:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryPdfColor)),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                    children: tableRows,
                  ),
                ],
              );
            },
          ),
        );
      } else if (id == 'tendencia_6meses') {
        final tableRows = <pw.TableRow>[
          pw.TableRow(
            decoration: pw.BoxDecoration(color: primaryPdfColor),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Mes', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Ingresos (+)', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Gastos (-)', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Balance Neto', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
            ],
          ),
        ];

        List<DateTime> meses = [];
        DateTime base = DateTime(_selectedFilterYear, _selectedFilterMonth, 1);
        for (int i = 5; i >= 0; i--) meses.add(DateTime(base.year, base.month - i, 1));
        for (var m in meses) {
          double g = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == m.month && t.date.year == m.year).fold(0.0, (sum, t) => sum + t.amount);
          double ing = estadoApp.transactions.where((t) => t.pagada && t.type == 'ingreso' && !t.esRegistroApertura && t.date.month == m.month && t.date.year == m.year).fold(0.0, (sum, t) => sum + t.amount);
          tableRows.add(
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${_monthsNames[m.month - 1]} ${m.year}', style: bodyStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(ing, currency), style: bodyStyle, textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(g, currency), style: bodyStyle, textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(ing - g, currency), style: boldBodyStyle, textAlign: pw.TextAlign.right)),
              ],
            ),
          );
        }

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildPdfHeader('Tendencia de 6 Meses'),
                  pw.Text('HISTÓRICO MENSUAL DE TENDENCIA:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryPdfColor)),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                    children: tableRows,
                  ),
                ],
              );
            },
          ),
        );
      } else if (id == 'gastos_hormiga') {
        final tableRows = <pw.TableRow>[
          pw.TableRow(
            decoration: pw.BoxDecoration(color: primaryPdfColor),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Concepto', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Veces/Mes', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Promedio', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Mes', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Proyección Anual', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
            ],
          ),
        ];

        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        final Map<String, List<ModeloTransaccion>> agrupados = {};
        for (var tx in txs) {
          final key = tx.title.trim().toLowerCase();
          if (key.length > 2) agrupados.putIfAbsent(key, () => []).add(tx);
        }
        final threshold = estadoApp.selectedCurrency == 'USD' ? 15.0 : 60.0;
        int cont = 0;
        agrupados.forEach((key, txList) {
          if (txList.length >= 2) {
            final avg = txList.fold(0.0, (sum, tx) => sum + tx.amount) / txList.length;
            if (avg <= threshold) {
              cont++;
              final tot = txList.fold(0.0, (sum, tx) => sum + tx.amount);
              tableRows.add(
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(txList.first.title, style: bodyStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${txList.length}', style: bodyStyle, textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(avg, currency), style: bodyStyle, textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(tot, currency), style: bodyStyle, textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(tot * 12, currency), style: boldBodyStyle, textAlign: pw.TextAlign.right)),
                  ],
                ),
              );
            }
          }
        });

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildPdfHeader('Gastos Hormiga'),
                  pw.Text('DETECCIÓN DE FUGA SILENCIOSA:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryPdfColor)),
                  pw.SizedBox(height: 12),
                  if (cont > 0)
                    pw.Table(
                      border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                      children: tableRows,
                    )
                  else
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: bgLight,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: borderGrey, width: 0.5),
                      ),
                      child: pw.Text('No se detectaron fugas o gastos hormiga frecuentes en este mes.', style: bodyStyle),
                    ),
                ],
              );
            },
          ),
        );
      } else if (id == 'presupuesto_vs_real') {
        final tableRows = <pw.TableRow>[
          pw.TableRow(
            decoration: pw.BoxDecoration(color: primaryPdfColor),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Categoría', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Límite', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Gastado', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('% Cons.', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Restante/Alerta', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
            ],
          ),
        ];

        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        for (var bud in estadoApp.budgets) {
          double gastado = 0.0;
          if (bud.categoryName.toLowerCase() == 'global') {
            gastado = txs.fold(0.0, (sum, t) => sum + t.amount);
          } else {
            gastado = txs.where((t) => t.category.toLowerCase().trim() == bud.categoryName.toLowerCase().trim()).fold(0.0, (sum, t) => sum + t.amount);
          }
          final pct = bud.limitAmount > 0 ? (gastado / bud.limitAmount) * 100 : 0.0;
          final diff = bud.limitAmount - gastado;
          final statusText = diff >= 0 ? _formatCurrency(diff, currency) : 'Excedido por ${_formatCurrency(-diff, currency)}';
          final statusStyle = diff >= 0 ? bodyStyle : pw.TextStyle(fontSize: 9, color: const PdfColor(0.85, 0.18, 0.18), fontWeight: pw.FontWeight.bold);

          tableRows.add(
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(bud.categoryName.toUpperCase(), style: bodyStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(bud.limitAmount, currency), style: bodyStyle, textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(gastado, currency), style: bodyStyle, textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${pct.toStringAsFixed(1)}%', style: bodyStyle, textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(statusText, style: statusStyle, textAlign: pw.TextAlign.right)),
              ],
            ),
          );
        }

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildPdfHeader('Presupuesto vs. Real'),
                  pw.Text('CONTROL DE PRESUPUESTOS Y DESVIACIÓN:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryPdfColor)),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                    children: tableRows,
                  ),
                ],
              );
            },
          ),
        );
      } else if (id == 'fijos_vs_variables') {
        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        double f = 0.0;
        double v = 0.0;
        final fixedKeywords = ['alquiler', 'servicios', 'suscripcion', 'suscripción', 'educacion', 'educación', 'seguro', 'prestamo', 'préstamo', 'hipoteca', 'impuestos', 'colegio', 'luz', 'agua', 'internet', 'gas', 'telefono', 'teléfono'];
        for (var t in txs) {
          final cat = t.category.toLowerCase().trim();
          final hasFixedKeyword = fixedKeywords.any((keyword) => cat.contains(keyword));
          if (t.esProgramada || t.recurrencia != null || hasFixedKeyword) {
            f += t.amount;
          } else {
            v += t.amount;
          }
        }
        double tot = f + v;
        final fPct = tot > 0 ? (f / tot) * 100 : 0;
        final vPct = tot > 0 ? (v / tot) * 100 : 0;

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildPdfHeader('Gastos Fijos vs. Variables'),
                  pw.Text('CLASIFICACIÓN DE COSTOS FIJOS Y VARIABLES:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryPdfColor)),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: primaryPdfColor),
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Tipo de Gasto', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Monto', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Porcentaje', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Gastos Fijos', style: bodyStyle)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(f, currency), style: bodyStyle, textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${fPct.toStringAsFixed(1)}%', style: bodyStyle, textAlign: pw.TextAlign.right)),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Gastos Variables', style: bodyStyle)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(v, currency), style: bodyStyle, textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${vPct.toStringAsFixed(1)}%', style: bodyStyle, textAlign: pw.TextAlign.right)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: bgLight,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: borderGrey, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Consejo Financiero:', style: boldBodyStyle),
                        pw.SizedBox(height: 6),
                        pw.Text('Tus gastos variables corresponden a compras no indispensables. Reducir un 10% de este bloque aumentará de forma inmediata tus ahorros.', style: bodyStyle),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      } else if (id == 'dias_semana') {
        final tableRows = <pw.TableRow>[
          pw.TableRow(
            decoration: pw.BoxDecoration(color: primaryPdfColor),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Día', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Monto Acumulado', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Transacciones', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
            ],
          ),
        ];

        final txs = estadoApp.transactions.where((t) => t.pagada && t.type == 'gasto' && t.date.month == _selectedFilterMonth && t.date.year == _selectedFilterYear).toList();
        List<double> montos = List.filled(7, 0.0);
        List<int> conteos = List.filled(7, 0);
        final nombresDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
        for (var t in txs) {
          int idx = t.date.weekday - 1;
          if (idx >= 0 && idx < 7) {
            montos[idx] += t.amount;
            conteos[idx]++;
          }
        }
        for (int i = 0; i < 7; i++) {
          tableRows.add(
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(nombresDias[i], style: bodyStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(montos[i], currency), style: bodyStyle, textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${conteos[i]} transacciones', style: bodyStyle, textAlign: pw.TextAlign.right)),
              ],
            ),
          );
        }

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildPdfHeader('Análisis por Días'),
                  pw.Text('CONCENTRACIÓN DE GASTOS POR DÍA DE LA SEMANA:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryPdfColor)),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                    children: tableRows,
                  ),
                ],
              );
            },
          ),
        );
      }

      pdfBytes = await pdf.save();
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename.$extension');
      if (formato == 'pdf' && pdfBytes != null) {
        await file.writeAsBytes(pdfBytes);
      } else {
        await file.writeAsString(content);
      }

      if (!mounted) return;
      _mostrarOpcionesArchivoGenerado(file, formato, _obtenerTituloReporte(id), estadoApp);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar archivo: $e')),
      );
    }
  }

  void _mostrarOpcionesArchivoGenerado(File file, String formato, String tituloReporte, EstadoApp estadoApp) {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final esOscuro = estadoApp.esTemaOscuro;
        final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
        final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;
        final accentColor = estadoApp.colorPrincipal;

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: colorFondo.withValues(alpha: esOscuro ? 0.85 : 0.90),
                border: Border(
                  top: BorderSide(
                    color: esOscuro ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    width: 1.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorTexto.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Archivo Generado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: colorTexto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'El reporte se guardó correctamente. ¿Qué deseas hacer?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorTexto.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: InteractiveScale(
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);
                            try {
                              final result = await OpenFilex.open(file.path);
                              if (result.type != ResultType.done) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('No se pudo abrir el archivo: ${result.message}')),
                                );
                              }
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Error al abrir el archivo: $e')),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.visibility_rounded, color: accentColor, size: 24),
                                const SizedBox(height: 6),
                                Text(
                                  formato == 'pdf' ? 'Previsualizar PDF' : 'Abrir Archivo',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorTexto),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InteractiveScale(
                          onTap: () async {
                            Navigator.pop(context);
                            await Share.shareXFiles([XFile(file.path)], text: 'Exportación de $tituloReporte');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.share_rounded, color: Colors.white, size: 24),
                                SizedBox(height: 6),
                                Text(
                                  'Compartir',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
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
                _expandedSubcategoryIds.clear();
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
                _expandedSubcategoryIds.clear();
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
                          _expandedSubcategoryIds.clear();
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
                          _expandedSubcategoryIds.clear();
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
    EstadoApp estadoApp,
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
          const SizedBox(height: 8),
          ListView.separated(
            padding: EdgeInsets.zero,
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

              final hasSubcategories = childrenList.isNotEmpty;
              final hasDirectTransactions = group.directTransactions.isNotEmpty;
              final hasChildren = hasSubcategories || hasDirectTransactions;
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
                            child: hasSubcategories
                                ? ListView.separated(
                                    padding: EdgeInsets.zero,
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

                                      final isVirtualDirect = childCat.id == '${parentCat.id}_direct';
                                      final List<ModeloTransaccion> subCatTxs = isVirtualDirect
                                          ? group.directTransactions
                                          : (group.childTransactions[childCat.id] ?? []);

                                      return Column(
                                        children: [
                                          InteractiveScale(
                                            onTap: () {
                                              setState(() {
                                                if (_expandedSubcategoryIds.contains(childCat.id)) {
                                                  _expandedSubcategoryIds.remove(childCat.id);
                                                } else {
                                                  _expandedSubcategoryIds.add(childCat.id);
                                                }
                                              });
                                            },
                                            child: Container(
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
                                                              width: 34,
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
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    _expandedSubcategoryIds.contains(childCat.id)
                                                        ? Icons.keyboard_arrow_up_rounded
                                                        : Icons.keyboard_arrow_down_rounded,
                                                    color: colorTexto.withValues(alpha: 0.35),
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          AnimatedSize(
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.fastOutSlowIn,
                                            child: _expandedSubcategoryIds.contains(childCat.id)
                                                ? Container(
                                                    margin: const EdgeInsets.only(top: 6, left: 12, bottom: 4),
                                                    padding: const EdgeInsets.only(left: 10),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        left: BorderSide(
                                                          color: colorCategoria.withValues(alpha: 0.1),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: subCatTxs.map((tx) {
                                                        return _buildMiniTransactionRow(tx, esOscuro, colorTexto, currency, estadoApp);
                                                      }).toList(),
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ],
                                      );
                                    },
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: group.directTransactions.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                                    itemBuilder: (context, tIdx) {
                                      final tx = group.directTransactions[tIdx];
                                      return _buildMiniTransactionRow(tx, esOscuro, colorTexto, currency, estadoApp);
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

  Widget _buildMiniTransactionRow(ModeloTransaccion tx, bool esOscuro, Color colorTexto, String currency, EstadoApp estadoApp) {
    final isIncome = tx.type == 'ingreso';
    final isTransfer = tx.type == 'transferencia';
    final String dateStr = '${tx.date.day} ${_monthsNames[tx.date.month - 1].substring(0, 3)}';
    
    final acc = estadoApp.accounts.firstWhere(
      (a) => a.id == tx.accountId,
      orElse: () => ModeloCuenta(id: '', name: '...', balance: 0, gradientIndex: 0, type: 'Efectivo'),
    );

    final amountColor = isIncome
        ? const Color(0xFF10B981)
        : (isTransfer ? const Color(0xFF3B82F6) : const Color(0xFFEF4444));

    return InteractiveScale(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PanelTransaccion(transaccion: tx),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: esOscuro ? Colors.white.withValues(alpha: 0.01) : Colors.black.withValues(alpha: 0.005),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: esOscuro ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: colorTexto.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorTexto.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    acc.name,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                      color: colorTexto.withValues(alpha: 0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatCurrency(isIncome ? tx.amount : (isTransfer ? tx.amount : -tx.amount), currency),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: amountColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
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
  final List<ModeloTransaccion> directTransactions = [];
  final Map<String, List<ModeloTransaccion>> childTransactions = {};

  _GrupoCategoriaPadre(this.parent);
}
