import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/interactive_scale.dart';
import '../../../widgets/panel_transaccion.dart';
import '../../../helpers/formato_fecha.dart';

class VistaDetalleCuenta extends StatelessWidget {
  final ModeloCuenta account;

  const VistaDetalleCuenta({
    super.key,
    required this.account,
  });

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

  Color _getBottomBgColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();
  }

  Color _getDarkShade(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - 0.5).clamp(0.12, 0.35))
        .withSaturation((hsl.saturation + 0.2).clamp(0.6, 0.95))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorFondo = esOscuro ? const Color(0xFF000000) : const Color(0xFFF0F2F5);
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    // Obtener y filtrar movimientos de la cuenta (origen o destino)
    final accountTxs = estadoApp.transactions
        .where((tx) => tx.pagada && (tx.accountId == account.id || tx.toAccountId == account.id) && !tx.esRegistroApertura)
        .toList();

    // Buscar la cuenta fresca del estado para reflejar balances actualizados en tiempo real
    final activeAcc = estadoApp.accounts.firstWhere(
      (acc) => acc.id == account.id,
      orElse: () => account,
    );

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorTexto, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalle de Cuenta',
          style: TextStyle(
            color: colorTexto,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: colorTexto, size: 20),
            onPressed: () => Navigator.pop(context, 'editar'),
            tooltip: 'Editar Cuenta',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bento Card exact size as in list
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: esOscuro 
                      ? const Color(0xFF0E0E0E).withValues(alpha: 0.55) 
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: esOscuro 
                        ? const Color(0xFF1E1E1E) 
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: esOscuro ? 0.15 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 52,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: esOscuro
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFCBD5E1).withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getAccountColors(activeAcc, esOscuro).background,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(7),
                                    topRight: Radius.circular(7),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          activeAcc.type.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 3.5,
                                            fontWeight: FontWeight.w900,
                                            color: _getAccountColors(activeAcc, esOscuro).text.withValues(alpha: 0.75),
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        // Switch decorativo miniatura
                                        Container(
                                          width: 10,
                                          height: 5,
                                          padding: const EdgeInsets.all(0.5),
                                          decoration: BoxDecoration(
                                            color: _getAccountColors(activeAcc, esOscuro).text.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(2.5),
                                          ),
                                          child: Align(
                                            alignment: (activeAcc.contabilizable ?? true)
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            child: Container(
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: _getAccountColors(activeAcc, esOscuro).text,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        // Chip miniatura
                                        Container(
                                          width: 7,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: _getAccountColors(activeAcc, esOscuro).text,
                                            borderRadius: BorderRadius.circular(1),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            activeAcc.name.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 4.5,
                                              fontWeight: FontWeight.w900,
                                              color: _getAccountColors(activeAcc, esOscuro).text,
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
                            Container(
                              height: 11,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _getBottomBgColor(_getAccountColors(activeAcc, esOscuro).background),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(7),
                                  bottomRight: Radius.circular(7),
                                ),
                              ),
                              child: Text(
                                '${EstadoApp.getSymbolOfCurrency(activeAcc.currency ?? estadoApp.selectedCurrency)} ${activeAcc.balance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 5,
                                  fontWeight: FontWeight.w900,
                                  color: _getAccountColors(activeAcc, esOscuro).text,
                                  letterSpacing: -0.2,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeAcc.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: colorTexto,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorPrincipal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: colorPrincipal.withValues(alpha: 0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  activeAcc.type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                    color: colorPrincipal,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorTexto.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  '${EstadoApp.getSymbolOfCurrency(activeAcc.currency ?? estadoApp.selectedCurrency)} ${activeAcc.balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: colorTexto,
                                    letterSpacing: -0.3,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05, end: 0, duration: 350.ms),
              const SizedBox(height: 28),
              
              Text(
                'MOVIMIENTOS DE LA CUENTA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: colorTexto.withValues(alpha: 0.45),
                ),
              ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
              const SizedBox(height: 12),
              
              // Listado de transacciones
              if (accountTxs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 40,
                          color: colorTexto.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay movimientos para esta cuenta.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: colorTexto.withValues(alpha: 0.45),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 150.ms)
              else
                Container(
                  decoration: BoxDecoration(
                    color: esOscuro
                        ? const Color(0xFF0E0E0E)
                        : Colors.white,
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
                    itemCount: accountTxs.length,
                    separatorBuilder: (_, __) => Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: esOscuro
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                    ),
                    itemBuilder: (context, index) {
                      final tx = accountTxs[index];
                      
                      final bool isIncomingTransfer = tx.type == 'transferencia' && tx.toAccountId == activeAcc.id;
                      final bool isOutgoingTransfer = tx.type == 'transferencia' && tx.accountId == activeAcc.id;
                      final bool isIncome = tx.type == 'ingreso' || isIncomingTransfer;
                      final bool isTransfer = tx.type == 'transferencia';

                      final txSymbol = EstadoApp.getSymbolOfCurrency(activeAcc.currency ?? estadoApp.selectedCurrency);

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
                                      '${isIncomingTransfer ? 'TRANSFERENCIA ENTRANTE' : isOutgoingTransfer ? 'TRANSFERENCIA SALIENTE' : tx.type.toUpperCase()} • ${formatearFechaHora(tx.date, estadoApp.selectedLanguage)}',
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
                                          : isOutgoingTransfer
                                              ? '-$txSymbol ${tx.amount.toStringAsFixed(2)}'
                                              : '-$txSymbol ${tx.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: isIncome
                                            ? const Color(0xFF10B981)
                                            : isOutgoingTransfer
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
                ).animate().fadeIn(duration: 350.ms, delay: 150.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class SolidCardColors {
  final Color background;
  final Color text;
  const SolidCardColors(this.background, this.text);
}

