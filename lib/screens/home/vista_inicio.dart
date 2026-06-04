import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/estado_app.dart';
import '../../services/servicio_autenticacion.dart';
import '../../widgets/panel_transaccion.dart';
import '../../widgets/interactive_scale.dart';
import '../ajustes/pantalla_ajustes.dart';
import '../ajustes/subvistas/detalle_cuenta.dart';

class VistaInicio extends StatelessWidget {
  const VistaInicio({super.key});

  static final List<List<Color>> _cardGradients = [
    [const Color(0xFF00E676), const Color(0xFF00B0FF)], // Verde Esmeralda
    [const Color(0xFF2979FF), const Color(0xFF00E5FF)], // Azul Vibrante
    [const Color(0xFFFF1744), const Color(0xFFD500F9)], // Rosa/Rojo Neon
    [const Color(0xFFF57C00), const Color(0xFFFFD54F)], // Naranja/Amarillo
    [const Color(0xFF651FFF), const Color(0xFF00E5FF)], // Purpura Profundo / Azul Electrico
    [const Color(0xFF00BFA5), const Color(0xFF64FFDA)], // Menta Fresca / Turquesa Liquido
    [const Color(0xFFFF4081), const Color(0xFFFFD54F)], // Atardecer de Ibiza (Coral / Oro)
    [const Color(0xFFD500F9), const Color(0xFFFF4081)], // Violeta Ciberpunk / Magenta
    [const Color(0xFF1A237E), const Color(0xFF536DFE)], // Cielo Nocturno (Azul Marino / Indigo)
    [const Color(0xFF00E5FF), const Color(0xFFAEEA00)], // Bosque Mistico (Cian / Verde Lima)
    [const Color(0xFFFF3D00), const Color(0xFFFFC400)], // Fuego Fenix (Rojo Feroz / Naranja)
    [const Color(0xFFEC407A), const Color(0xFFAB47BC)], // Rosa Orquidea / Lavanda
    [const Color(0xFF80DEEA), const Color(0xFFB0BEC5)], // Azul Glaciar / Plata
    [const Color(0xFF76FF03), const Color(0xFF00E5FF)], // Neon Alien (Verde Lima / Turquesa)
  ];

  Color _parseHexColor(String? hexStr, Color defaultColor) {
    if (hexStr == null || hexStr.isEmpty) return defaultColor;
    try {
      final cleanHex = hexStr.trim().replaceAll('#', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('0xFF$cleanHex'));
      } else if (cleanHex.length == 8) {
        return Color(int.parse('0x$cleanHex'));
      }
    } catch (_) {}
    return defaultColor;
  }

  LinearGradient _buildAccountGradient(ModeloCuenta acc, {double alpha = 0.95}) {
    if (acc.customColorHex != null && acc.customColorHex!.isNotEmpty) {
      final c1 = _parseHexColor(acc.customColorHex, const Color(0xFFB3E5FC));
      final c2 = _parseHexColor(acc.customColorSecondaryHex ?? acc.customColorHex!, const Color(0xFFE2E8F0));
      
      if (acc.customColorThirdHex != null && acc.customColorThirdHex!.isNotEmpty) {
        final c3 = _parseHexColor(acc.customColorThirdHex, Colors.white);
        final s1 = acc.stop1 ?? 0.0;
        final s2 = acc.stop2 ?? 0.5;
        final s3 = acc.stop3 ?? 1.0;
        return LinearGradient(
          colors: [
            c1.withValues(alpha: alpha),
            c3.withValues(alpha: alpha),
            c2.withValues(alpha: alpha),
          ],
          stops: [s1, s2, s3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else {
        return LinearGradient(
          colors: [
            c1.withValues(alpha: alpha),
            c2.withValues(alpha: alpha),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    } else {
      final grad = _cardGradients[acc.gradientIndex % _cardGradients.length];
      return LinearGradient(
        colors: [
          grad.first.withValues(alpha: alpha),
          grad.last.withValues(alpha: alpha),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    
    final authUser = ServicioAutenticacion().currentUser;
    final nombreUsuarioCompleto = authUser?.displayName ?? 'Invitado';
    final nombreUsuario = nombreUsuarioCompleto.trim().split(' ').first;

    final textStyleSeccion = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: colorTexto.withValues(alpha: 0.6),
      letterSpacing: 0.5,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Contenedor premium Liquid Glass para el logo adaptativo
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'assets/images/512-trans.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $nombreUsuario',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: colorTexto,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Aquí tienes el resumen de tus finanzas.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorTexto.withValues(alpha: 0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InteractiveScale(
                onTap: () {
                  estadoApp.selectedSettingsSubView = 0;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PantallaAjustes()),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: colorTexto.withValues(alpha: 0.06),
                  backgroundImage: authUser?.photoUrl != null && authUser!.photoUrl!.isNotEmpty
                      ? NetworkImage(authUser.photoUrl!)
                      : null,
                  child: authUser?.photoUrl == null || authUser!.photoUrl!.isEmpty
                      ? Icon(Icons.person_rounded, size: 18, color: colorTexto.withValues(alpha: 0.6))
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildBalanceCard(estadoApp),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CUENTAS ACTIVAS',
                style: textStyleSeccion,
              ),
              InteractiveScale(
                onTap: () {
                  estadoApp.selectedSettingsSubView = 2;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PantallaAjustes()),
                  );
                },
                child: Text(
                  'VER DETALLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: estadoApp.colorPrincipal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildAccountsGrid(context, estadoApp),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MOVIMIENTOS RECIENTES',
                style: textStyleSeccion,
              ),
              InteractiveScale(
                onTap: () {
                  estadoApp.selectedDockIndex = 1;
                },
                child: Text(
                  'VER TODO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: estadoApp.colorPrincipal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTransactionList(estadoApp),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(EstadoApp estadoApp) {
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    // Calcular ingresos y gastos del mes actual de forma reactiva
    final ahora = DateTime.now();
    double ingresosMes = 0.0;
    double gastosMes = 0.0;
    for (var tx in estadoApp.transactions) {
      if (tx.date.month == ahora.month && tx.date.year == ahora.year) {
        if (tx.type == 'ingreso' && !tx.esRegistroApertura) {
          ingresosMes += tx.amount;
        } else if (tx.type == 'gasto') {
          gastosMes += tx.amount;
        }
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: esOscuro
                ? const Color(0xFF0A0A0A).withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: esOscuro
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1.0,
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BALANCE GENERAL DE CUENTAS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: colorTexto.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                   Text(
                    '${estadoApp.currencySymbol} ${estadoApp.totalBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              _buildMiniMonthlyChart(ingresosMes, gastosMes, esOscuro),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: esOscuro
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFF0A0A0A).withValues(alpha: 0.08),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceMiniChip(
                  label: 'TOTAL INGRESOS',
                  amount: '+${estadoApp.currencySymbol} ${estadoApp.totalIncome.toStringAsFixed(2)}',
                  color: const Color(0xFF10B981),
                  esOscuro: esOscuro,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBalanceMiniChip(
                  label: 'TOTAL GASTOS',
                  amount: '-${estadoApp.currencySymbol} ${estadoApp.totalExpenses.toStringAsFixed(2)}',
                  color: const Color(0xFFEF4444),
                  esOscuro: esOscuro,
                ),
              ),
            ],
          ),
        ],
      ),
    )));
  }

  Widget _buildBalanceMiniChip({
    required String label,
    required String amount,
    required Color color,
    required bool esOscuro,
  }) {
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    return Row(
      children: [
        Container(
          width: 3.5,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: colorTexto.withValues(alpha: 0.5),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsGrid(BuildContext context, EstadoApp estadoApp) {
    final activeAccounts = estadoApp.accounts;
    const maxGridItems = 6;
    final gridCount = activeAccounts.length + 1 > maxGridItems ? maxGridItems : activeAccounts.length + 1;
    final esOscuro = estadoApp.esTemaOscuro;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        if (index == activeAccounts.length) {
          return InteractiveScale(
            onTap: () {
              estadoApp.selectedSettingsSubView = 2;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaAjustes()),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: esOscuro
                        ? const Color(0xFF0A0A0A).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: esOscuro
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.40),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: estadoApp.colorPrincipal,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AGREGAR CUENTA',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: estadoApp.colorPrincipal,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final acc = activeAccounts[index];
        
        Color colorInicio;
        if (acc.customColorHex != null && acc.customColorHex!.isNotEmpty) {
          colorInicio = _parseHexColor(acc.customColorHex, const Color(0xFFB3E5FC));
        } else {
          final grad = _cardGradients[acc.gradientIndex % _cardGradients.length];
          colorInicio = grad.first;
        }

        final cardContentColor = (acc.useDarkText ?? false) ? const Color(0xFF0F172A) : Colors.white;

        return InteractiveScale(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VistaDetalleCuenta(account: acc),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: _buildAccountGradient(acc, alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.40),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorInicio.withValues(alpha: esOscuro ? 0.25 : 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tipo de cuenta en capsula acrilica
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: cardContentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: cardContentColor.withValues(alpha: 0.30),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          acc.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: cardContentColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      // Circulos acrilicos decorativos (MasterCard style) unificados con Ajustes
                      Row(
                        children: [
                          Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cardContentColor.withValues(alpha: 0.35),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-4, 0),
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardContentColor.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acc.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: cardContentColor,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${EstadoApp.getSymbolOfCurrency(acc.currency ?? estadoApp.selectedCurrency)} ${acc.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: cardContentColor,
                          letterSpacing: -0.3,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(EstadoApp estadoApp) {
    final txs = estadoApp.transactions.where((tx) => !tx.esRegistroApertura).toList();
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    if (txs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No hay movimientos registrados hoy.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorTexto.withValues(alpha: 0.4),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: esOscuro
            ? const Color(0xFF0E0E0E)
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: txs.length > 5 ? 5 : txs.length,
        separatorBuilder: (_, __) => Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: esOscuro
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
        ),
        itemBuilder: (context, index) {
          final tx = txs[index];
          final isIncome = tx.type == 'ingreso';
          final isTransfer = tx.type == 'transferencia';

          final acc = estadoApp.accounts.firstWhere(
            (a) => a.id == tx.accountId,
            orElse: () => ModeloCuenta(id: '', name: 'N/A', type: '', balance: 0.0, gradientIndex: 0),
          );
          final accName = acc.name;
          final txSymbol = EstadoApp.getSymbolOfCurrency(acc.currency ?? estadoApp.selectedCurrency);

          IconData transIcon = Icons.arrow_downward_rounded;
          Color transIconColor = const Color(0xFFEF4444);
          if (isIncome) {
            transIcon = Icons.arrow_upward_rounded;
            transIconColor = const Color(0xFF10B981);
          } else if (isTransfer) {
            transIcon = Icons.swap_horiz_rounded;
            transIconColor = const Color(0xFF3B82F6);
          }

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: transIconColor.withValues(alpha: esOscuro ? 0.15 : 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        transIcon,
                        color: transIconColor,
                        size: 18,
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
                          accName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: colorTexto.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isIncome
                              ? '+$txSymbol ${tx.amount.toStringAsFixed(2)}'
                              : isTransfer
                                  ? '$txSymbol ${tx.amount.toStringAsFixed(2)}'
                                  : '-$txSymbol ${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isIncome
                                ? const Color(0xFF10B981)
                                : isTransfer
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFEF4444),
                            letterSpacing: -0.2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isTransfer
                                ? (esOscuro ? const Color(0xFF00B0FF) : const Color(0xFF0284C7)).withValues(alpha: 0.08)
                                : (esOscuro ? Colors.white : const Color(0xFF4B5563)).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: isTransfer
                                  ? (esOscuro ? const Color(0xFF00B0FF) : const Color(0xFF0284C7))
                                  : (esOscuro ? Colors.white70 : const Color(0xFF4B5563)),
                            ),
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
    );
  }

  Widget _buildMiniMonthlyChart(double ingresos, double gastos, bool esOscuro) {
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final maxMonto = ingresos > gastos ? ingresos : gastos;
    
    // Altura maxima de las barras es 44px, minima 4px
    final double alturaIngresos = maxMonto > 0 ? (ingresos / maxMonto) * 44.0 : 4.0;
    final double alturaGastos = maxMonto > 0 ? (gastos / maxMonto) * 44.0 : 4.0;
    
    // Asegurar que la barra tenga al menos 4px si tiene monto mayor a 0
    final double hIng = ingresos > 0 && alturaIngresos < 4.0 ? 4.0 : alturaIngresos;
    final double hGas = gastos > 0 && alturaGastos < 4.0 ? 4.0 : alturaGastos;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: esOscuro
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esOscuro
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Barra de ingresos (Verde)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 10,
                    height: hIng,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF10B981)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Barra de gastos (Rojo)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 10,
                    height: hGas,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF87171), Color(0xFFEF4444)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ESTE MES',
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: colorTexto.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
