import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/interactive_scale.dart';
import '../../../widgets/panel_transaccion.dart';

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

  LinearGradient _buildAccountGradient(ModeloCuenta acc, List<List<Color>> cardGradients, {double alpha = 0.95}) {
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
      final grad = cardGradients[acc.gradientIndex % cardGradients.length];
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

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorFondo = esOscuro ? const Color(0xFF000000) : const Color(0xFFF0F2F5);
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    // Obtener y filtrar movimientos de la cuenta (origen o destino)
    final accountTxs = estadoApp.transactions
        .where((tx) => (tx.accountId == account.id || tx.toAccountId == account.id) && !tx.esRegistroApertura)
        .toList();

    // Buscar la cuenta fresca del estado para reflejar balances actualizados en tiempo real
    final activeAcc = estadoApp.accounts.firstWhere(
      (acc) => acc.id == account.id,
      orElse: () => account,
    );
    final cardContentColor = (activeAcc.useDarkText ?? false) ? const Color(0xFF0F172A) : Colors.white;

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
                        ? Colors.white.withValues(alpha: 0.08) 
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
                          gradient: _buildAccountGradient(activeAcc, _cardGradients, alpha: 1.0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: cardContentColor.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 4,
                              left: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.8),
                                decoration: BoxDecoration(
                                  color: cardContentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: cardContentColor.withValues(alpha: 0.30),
                                    width: 0.4,
                                  ),
                                ),
                                child: Text(
                                  activeAcc.type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 3.5,
                                    fontWeight: FontWeight.w900,
                                    color: cardContentColor,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 5,
                              child: Row(
                                children: [
                                  Container(
                                    width: 5.5,
                                    height: 5.5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cardContentColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(-2, 0),
                                    child: Container(
                                      width: 5.5,
                                      height: 5.5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: cardContentColor.withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 3,
                              left: 5,
                              right: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    activeAcc.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 4.5,
                                      fontWeight: FontWeight.w900,
                                      color: cardContentColor,
                                      letterSpacing: -0.15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 0.5),
                                  Text(
                                    '${EstadoApp.getSymbolOfCurrency(activeAcc.currency ?? estadoApp.selectedCurrency)} ${activeAcc.balance.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 5,
                                      fontWeight: FontWeight.w900,
                                      color: cardContentColor,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
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
                              Text(
                                '${EstadoApp.getSymbolOfCurrency(activeAcc.currency ?? estadoApp.selectedCurrency)} ${activeAcc.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: colorTexto,
                                  letterSpacing: -0.3,
                                  fontFeatures: const [FontFeature.tabularFigures()],
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
                                      isIncomingTransfer
                                          ? 'TRANSFERENCIA ENTRANTE'
                                          : isOutgoingTransfer
                                              ? 'TRANSFERENCIA SALIENTE'
                                              : tx.type.toUpperCase(),
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
