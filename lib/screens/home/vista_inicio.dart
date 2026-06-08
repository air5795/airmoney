import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/estado_app.dart';
import '../../services/servicio_autenticacion.dart';
import '../../widgets/panel_transaccion.dart';
import '../../widgets/interactive_scale.dart';
import '../ajustes/pantalla_ajustes.dart';
import '../ajustes/subvistas/detalle_cuenta.dart';
import '../../helpers/formato_fecha.dart';

class VistaInicio extends StatelessWidget {
  const VistaInicio({super.key});



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

  static final List<SolidCardColors> _predefinedSchemes = [
    const SolidCardColors(Color(0xFFC8E6C9), Color(0xFF0F5132)), // Verde Esmeralda
    const SolidCardColors(Color(0xFFE1F5FE), Color(0xFF01579B)), // Azul Vibrante
    const SolidCardColors(Color(0xFFFFCDD2), Color(0xFF842029)), // Rosa/Rojo Neon
    const SolidCardColors(Color(0xFFFFE0B2), Color(0xFFE65100)), // Naranja/Amarillo
    const SolidCardColors(Color(0xFFE1BEE7), Color(0xFF4A148C)), // Purpura Profundo
    const SolidCardColors(Color(0xFFE0F2F1), Color(0xFF004D40)), // Menta Fresca
    const SolidCardColors(Color(0xFFFFCCBC), Color(0xFFBF360C)), // Atardecer de Ibiza
    const SolidCardColors(Color(0xFFF8BBD0), Color(0xFF880E4F)), // Violeta Ciberpunk
    const SolidCardColors(Color(0xFFE8EAF6), Color(0xFF1A237E)), // Cielo Nocturno
    const SolidCardColors(Color(0xFFE0F7FA), Color(0xFF006064)), // Bosque Mistico
    const SolidCardColors(Color(0xFFFFE0B2), Color(0xFFDD2C00)), // Fuego Fenix
    const SolidCardColors(Color(0xFFF3E5F5), Color(0xFF6A1B9A)), // Rosa Orquidea
    const SolidCardColors(Color(0xFFECEFF1), Color(0xFF37474F)), // Azul Glaciar
    const SolidCardColors(Color(0xFFF1F8E9), Color(0xFF33691E)), // Neon Alien
  ];

  SolidCardColors _getAccountColors(ModeloCuenta acc, bool esOscuro) {
    Color bg;
    Color text;
    if (acc.customColorHex != null && acc.customColorHex!.isNotEmpty) {
      bg = _parseHexColor(acc.customColorHex, const Color(0xFFC8E6C9));
      text = _parseHexColor(acc.customColorSecondaryHex, _getDarkShade(bg));
    } else {
      final index = acc.gradientIndex % _predefinedSchemes.length;
      bg = _predefinedSchemes[index].background;
      text = _predefinedSchemes[index].text;
    }

    if (esOscuro) {
      final hsl = HSLColor.fromColor(bg);
      bg = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    }
    return SolidCardColors(bg, text);
  }

  Color _getDarkShade(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - 0.5).clamp(0.12, 0.35))
        .withSaturation((hsl.saturation + 0.2).clamp(0.6, 0.95))
        .toColor();
  }

  Color _getBottomBgColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();
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

    final colorFondoDock = esOscuro
        ? const Color(0xFF0A0A0A).withValues(alpha: 0.55)
        : const Color.fromARGB(255, 228, 228, 228).withValues(alpha: 0.75);

    final colorBordeDock = esOscuro
        ? const Color(0xFF1E1E1E)
        : Colors.black.withValues(alpha: 0.05);

    return Stack(
      children: [
        // 1. Área de Contenido Desplazable (Ocupa todo el espacio, pero con top padding para el header)
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 82 + MediaQuery.of(context).padding.top,
              bottom: 110,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(estadoApp),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CUENTAS ACTIVAS', style: textStyleSeccion),
                    InteractiveScale(
                      onTap: () {
                        estadoApp.selectedSettingsSubView = 2;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PantallaAjustes(),
                          ),
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
                    Text('MOVIMIENTOS RECIENTES', style: textStyleSeccion),
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
          ),
        ),

        // 2. Barra Superior Edge-to-Edge Glaseada (Fijada al tope sobre el Stack)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ), // Match dock's exact blur sigma
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 14 + MediaQuery.of(context).padding.top,
                  bottom: 14,
                ),
                decoration: BoxDecoration(
                  color: colorFondoDock,
                  border: Border(
                    bottom: BorderSide(
                      color: colorBordeDock,
                      width: 2.0, // Match dock's exact border width
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Imagen del usuario en contenedor premium Liquid Glass
                          InteractiveScale(
                            onTap: () {
                              estadoApp.selectedSettingsSubView = 0;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PantallaAjustes(),
                                ),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: estadoApp.colorPrincipal.withValues(
                                    alpha: 0.2,
                                  ),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: estadoApp.colorPrincipal.withValues(
                                      alpha: esOscuro ? 0.15 : 0.05,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child:
                                    authUser?.photoUrl != null &&
                                        authUser!.photoUrl!.isNotEmpty
                                    ? Image.network(
                                        authUser.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return CircleAvatar(
                                                backgroundColor: colorTexto
                                                    .withValues(alpha: 0.06),
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  size: 20,
                                                  color: colorTexto.withValues(
                                                    alpha: 0.6,
                                                  ),
                                                ),
                                              );
                                            },
                                      )
                                    : CircleAvatar(
                                        backgroundColor: colorTexto.withValues(
                                          alpha: 0.06,
                                        ),
                                        child: Icon(
                                          Icons.person_rounded,
                                          size: 20,
                                          color: colorTexto.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    text: 'Hola, ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: colorTexto,
                                      letterSpacing: -0.5,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: nombreUsuario,
                                        style: TextStyle(
                                          color: estadoApp.colorPrincipal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Aquí tienes el resumen de tus finanzas.',
                                  style: TextStyle(
                                    fontSize: 11,
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
                          MaterialPageRoute(
                            builder: (_) => const PantallaAjustes(),
                          ),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorTexto.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorTexto.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.settings_rounded,
                            size: 20,
                            color: colorTexto.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatearMonto(double monto, {bool forzarDecimales = false}) {
    final bool esEntero = (monto % 1 == 0) && !forzarDecimales;
    final String formatBase = monto.toStringAsFixed(esEntero ? 0 : 2);

    final parts = formatBase.split('.');
    String entero = parts[0];
    final String decimal = parts.length > 1 ? parts[1] : '';

    final regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');
    entero = entero.replaceAllMapped(regExp, (Match m) => '.');

    if (decimal.isNotEmpty) {
      return '$entero,$decimal';
    }
    return entero;
  }

  Widget _buildBalanceCard(EstadoApp estadoApp) {
    final esOscuro = estadoApp.esTemaOscuro;

    // Calcular ingresos y gastos del mes actual de forma reactiva
    final ahora = DateTime.now();
    double ingresosMes = 0.0;
    double gastosMes = 0.0;
    for (var tx in estadoApp.transactions) {
      if (!tx.pagada) continue;
      if (tx.date.month == ahora.month && tx.date.year == ahora.year) {
        if (tx.type == 'ingreso' && !tx.esRegistroApertura) {
          ingresosMes += tx.amount;
        } else if (tx.type == 'gasto') {
          gastosMes += tx.amount;
        }
      }
    }

    const meses = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    final nombreMes = meses[ahora.month - 1];

    // Cuentas de Ahorros y Excluidas
    final tieneAhorros = estadoApp.accounts.any((acc) => acc.type == 'Ahorros');
    final tieneExcluidas = estadoApp.accounts.any(
      (acc) => acc.contabilizable == false,
    );

    double totalAhorros = 0.0;
    double totalExcluido = 0.0;

    if (tieneAhorros) {
      for (var acc in estadoApp.accounts) {
        if (acc.type == 'Ahorros') {
          final accCurrency = acc.currency ?? estadoApp.selectedCurrency;
          totalAhorros += estadoApp.convertirMoneda(
            acc.balance,
            accCurrency,
            estadoApp.selectedCurrency,
          );
        }
      }
    }

    if (tieneExcluidas) {
      for (var acc in estadoApp.accounts) {
        if (acc.contabilizable == false) {
          final accCurrency = acc.currency ?? estadoApp.selectedCurrency;
          totalExcluido += estadoApp.convertirMoneda(
            acc.balance,
            accCurrency,
            estadoApp.selectedCurrency,
          );
        }
      }
    }

    final List<String> parts = [];
    if (tieneAhorros) {
      parts.add(
        'Ahorros: ${estadoApp.currencySymbol} ${_formatearMonto(totalAhorros)}',
      );
    }
    if (tieneExcluidas) {
      parts.add(
        'No incluidos: ${estadoApp.currencySymbol} ${_formatearMonto(totalExcluido)}',
      );
    }
    final subText = parts.join('  •  ');

    final colorGreen = esOscuro
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    final colorRed = esOscuro
        ? const Color(0xFFF87171)
        : const Color(0xFFB91C1C);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: esOscuro
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
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
          // TOP SECTION (Padded, scaled down spacing and fonts)
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BALANCE TOTAL',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.5)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${estadoApp.currencySymbol} ${_formatearMonto(estadoApp.totalBalance, forzarDecimales: true)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: esOscuro
                        ? Colors.white
                        : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (tieneAhorros || tieneExcluidas) ...[
                  const SizedBox(height: 8),
                  Text(
                    subText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: esOscuro
                          ? Colors.white.withValues(alpha: 0.5)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // HORIZONTAL DIVIDER
          Container(
            height: 1,
            color: esOscuro
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFCBD5E1).withValues(alpha: 0.4),
          ),
          // BOTTOM SECTION (Touches boundaries, compact vertical pads)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // INGRESOS
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: esOscuro
                          ? const Color(0xFF064E3B).withValues(alpha: 0.15)
                          : const Color(0xFFF0FDF4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              color: colorGreen,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'INGRESOS DE $nombreMes',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: colorGreen,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${estadoApp.currencySymbol} ${_formatearMonto(ingresosMes, forzarDecimales: true)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colorGreen,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // VERTICAL DIVIDER
                Container(
                  width: 1,
                  color: esOscuro
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFCBD5E1).withValues(alpha: 0.4),
                ),
                // GASTOS
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: esOscuro
                          ? const Color(0xFF7F1D1D).withValues(alpha: 0.15)
                          : const Color(0xFFFEF2F2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              color: colorRed,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'GASTOS DE $nombreMes',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: colorRed,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '-${estadoApp.currencySymbol} ${_formatearMonto(gastosMes, forzarDecimales: true)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colorRed,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsGrid(BuildContext context, EstadoApp estadoApp) {
    final activeAccounts = estadoApp.accounts;
    const maxGridItems = 6;
    final gridCount = activeAccounts.length + 1 > maxGridItems
        ? maxGridItems
        : activeAccounts.length + 1;
    final esOscuro = estadoApp.esTemaOscuro;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: gridCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.15,
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
                          ? const Color(0xFF1E1E1E)
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
                        size: 18,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AGREGAR CUENTA',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: estadoApp.colorPrincipal,
                          letterSpacing: 0.3,
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
        final colors = _getAccountColors(acc, esOscuro);
        final topBgColor = colors.background;
        final topTextColor = colors.text;

        return InteractiveScale(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VistaDetalleCuenta(account: acc),
              ),
            );
            if (result == 'editar' && context.mounted) {
              estadoApp.accountToEditDirectly = acc;
              estadoApp.selectedSettingsSubView = 2;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaAjustes()),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: esOscuro
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFCBD5E1).withValues(alpha: 0.4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: esOscuro ? 0.2 : 0.04,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sección Superior de Color Sólido
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: topBgColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 5, bottom: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              acc.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                color: topTextColor.withValues(alpha: 0.75),
                                letterSpacing: 0.3,
                              ),
                            ),
                            // Indicador Switch Decorativo
                            Container(
                              width: 24,
                              height: 12,
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: topTextColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Align(
                                alignment: (acc.contabilizable ?? true)
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: topTextColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Chip de tarjeta de crédito
                            Container(
                              width: 16,
                              height: 12,
                              decoration: BoxDecoration(
                                color: topTextColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 3,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 0.5,
                                      color: topBgColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 3,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 0.5,
                                      color: topBgColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    left: 8,
                                    child: Container(
                                      width: 0.5,
                                      color: topBgColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                acc.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: topTextColor,
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Sección Inferior con Saldo (Ligeramente más oscuro para resaltar)
                Container(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: _getBottomBgColor(topBgColor),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Text(
                    '${EstadoApp.getSymbolOfCurrency(acc.currency ?? estadoApp.selectedCurrency)} ${_formatearMonto(acc.balance, forzarDecimales: true)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: topTextColor,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(EstadoApp estadoApp) {
    final txs = estadoApp.transactions
        .where((tx) => !tx.esRegistroApertura && tx.pagada)
        .toList();
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
        color: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: esOscuro
              ? const Color(0xFF1E1E1E)
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
        padding: EdgeInsets.zero,
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
            orElse: () => ModeloCuenta(
              id: '',
              name: 'N/A',
              type: '',
              balance: 0.0,
              gradientIndex: 0,
            ),
          );
          final accName = acc.name;
          final txSymbol = EstadoApp.getSymbolOfCurrency(
            acc.currency ?? estadoApp.selectedCurrency,
          );

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
                      color: transIconColor.withValues(
                        alpha: esOscuro ? 0.15 : 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(transIcon, color: transIconColor, size: 18),
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
                          '${accName.toUpperCase()} • ${formatearFechaHora(tx.date, estadoApp.selectedLanguage)}',
                          style: TextStyle(
                            fontSize: 9,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isTransfer
                                ? (esOscuro
                                          ? const Color(0xFF00B0FF)
                                          : const Color(0xFF0284C7))
                                      .withValues(alpha: 0.08)
                                : (esOscuro
                                          ? Colors.white
                                          : const Color(0xFF4B5563))
                                      .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: isTransfer
                                  ? (esOscuro
                                        ? const Color(0xFF00B0FF)
                                        : const Color(0xFF0284C7))
                                  : (esOscuro
                                        ? Colors.white70
                                        : const Color(0xFF4B5563)),
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
}

class SolidCardColors {
  final Color background;
  final Color text;
  const SolidCardColors(this.background, this.text);
}

