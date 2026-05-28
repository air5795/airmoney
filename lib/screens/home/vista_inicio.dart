import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/estado_app.dart';
import '../../widgets/panel_transaccion.dart';

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

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'Ahorros';
    final balanceController = TextEditingController(text: '1000');

    showDialog(
      context: context,
      builder: (context) {
        final estadoApp = Provider.of<EstadoApp>(context, listen: false);
        final esOscuro = estadoApp.esTemaOscuro;
        final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
        final colorFondo = esOscuro ? const Color(0xFF12131C) : Colors.white;

        return AlertDialog(
          backgroundColor: colorFondo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Agregar nueva cuenta',
            style: TextStyle(fontWeight: FontWeight.bold, color: colorTexto, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: colorTexto, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Nombre de la cuenta',
                    labelStyle: TextStyle(fontSize: 13, color: colorTexto.withValues(alpha: 0.5)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: estadoApp.colorPrincipal),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: colorFondo,
                  style: TextStyle(color: colorTexto, fontSize: 14),
                  items: ['Efectivo', 'Débito', 'Ahorros', 'Crédito', 'Inversión']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type, style: TextStyle(color: colorTexto)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedType = val;
                  },
                  decoration: InputDecoration(
                    labelText: 'Tipo de cuenta',
                    labelStyle: TextStyle(fontSize: 13, color: colorTexto.withValues(alpha: 0.5)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: estadoApp.colorPrincipal),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: colorTexto, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Saldo Inicial',
                    labelStyle: TextStyle(fontSize: 13, color: colorTexto.withValues(alpha: 0.5)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: estadoApp.colorPrincipal),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: colorTexto.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
                if (name.isNotEmpty) {
                  final gradientIdx = estadoApp.accounts.length % _cardGradients.length;
                  estadoApp.addAccount(name, selectedType, balance, gradientIdx);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: estadoApp.colorPrincipal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Agregar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

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
          const SizedBox(height: 20),
          _buildBalanceCard(estadoApp),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CUENTAS ACTIVAS',
                style: textStyleSeccion,
              ),
              Text(
                'VER DETALLE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: estadoApp.colorPrincipal,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildAccountsGrid(context, estadoApp),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MOVIMIENTOS RECIENTES',
                style: textStyleSeccion,
              ),
              Text(
                'VER TODO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: estadoApp.colorPrincipal,
                  letterSpacing: 0.5,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: esOscuro
                ? const Color(0xFF0D0E15).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: esOscuro
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.70),
              width: 1.0,
            ),
          ),
          child: Column(
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
                'Bs ${estadoApp.totalBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: estadoApp.colorPrincipal,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: esOscuro
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFF0D0E15).withValues(alpha: 0.08),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildBalanceMiniChip(
                      label: 'TOTAL INGRESOS',
                      amount: '+Bs ${estadoApp.totalIncome.toStringAsFixed(2)}',
                      color: const Color(0xFF10B981),
                      esOscuro: esOscuro,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBalanceMiniChip(
                      label: 'TOTAL GASTOS',
                      amount: '-Bs ${estadoApp.totalExpenses.toStringAsFixed(2)}',
                      color: const Color(0xFFEF4444),
                      esOscuro: esOscuro,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    const maxGridItems = 4;
    final gridCount = activeAccounts.length + 1 > maxGridItems ? maxGridItems : activeAccounts.length + 1;
    final esOscuro = estadoApp.esTemaOscuro;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        if (index == activeAccounts.length) {
          return GestureDetector(
            onTap: () => _showAddAccountDialog(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: esOscuro
                        ? const Color(0xFF0D0E15).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(20),
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
                        size: 26,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'AGREGAR CUENTA',
                        style: TextStyle(
                          fontSize: 9.5,
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
        Color colorFin;
        
        if (acc.customColorHex != null && acc.customColorHex!.isNotEmpty) {
          colorInicio = _parseHexColor(acc.customColorHex, const Color(0xFFB3E5FC));
          colorFin = _parseHexColor(acc.customColorSecondaryHex ?? acc.customColorHex, const Color(0xFFE2E8F0));
        } else {
          final grad = _cardGradients[acc.gradientIndex % _cardGradients.length];
          colorInicio = grad.first;
          colorFin = grad.last;
        }

        final bgColors = [
          colorInicio.withValues(alpha: 0.95),
          colorFin.withValues(alpha: 0.95),
        ];

        final cardContentColor = (acc.useDarkText ?? false) ? const Color(0xFF0F172A) : Colors.white;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          fontSize: 8.0,
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
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardContentColor.withValues(alpha: 0.35),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(-5, 0),
                          child: Container(
                            width: 14,
                            height: 14,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: cardContentColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bs ${acc.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: cardContentColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(EstadoApp estadoApp) {
    final txs = estadoApp.transactions;
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

    return ClipRRect(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txs.length > 5 ? 5 : txs.length,
            separatorBuilder: (_, __) => Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: esOscuro
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFF0D0E15).withValues(alpha: 0.05),
            ),
            itemBuilder: (context, index) {
              final tx = txs[index];
              final isIncome = tx.type == 'ingreso';
              final isTransfer = tx.type == 'transferencia';

              final accName = estadoApp.accounts.firstWhere(
                (a) => a.id == tx.accountId,
                orElse: () => ModeloCuenta(id: '', name: 'N/A', type: '', balance: 0.0, gradientIndex: 0),
              ).name;

              IconData transIcon = Icons.arrow_downward_rounded;
              Color transIconColor = const Color(0xFFEF4444);
              if (isIncome) {
                transIcon = Icons.arrow_upward_rounded;
                transIconColor = const Color(0xFF10B981);
              } else if (isTransfer) {
                transIcon = Icons.swap_horiz_rounded;
                transIconColor = const Color(0xFF3B82F6);
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
                                  ? '+Bs ${tx.amount.toStringAsFixed(2)}'
                                  : isTransfer
                                      ? 'Bs ${tx.amount.toStringAsFixed(2)}'
                                      : '-Bs ${tx.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isIncome
                                    ? const Color(0xFF10B981)
                                    : isTransfer
                                        ? const Color(0xFF3B82F6)
                                        : const Color(0xFFEF4444),
                                letterSpacing: -0.2,
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
        ),
      ),
    );
  }
}
