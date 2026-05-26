import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/estado_app.dart';
import '../services/servicio_autenticacion.dart';
import '../widgets/panel_transaccion.dart';
import 'pantalla_login.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedDockIndex = 0;
  final ServicioAutenticacion _servicioAuth = ServicioAutenticacion();

  // Gradientes predefinidos para las tarjetas de credito del Grid 2x2
  final List<List<Color>> _cardGradients = [
    [const Color(0xFF00E676), const Color(0xFF00B0FF)], // Verde Esmeralda
    [const Color(0xFF2979FF), const Color(0xFF00E5FF)], // Azul Vibrante
    [const Color(0xFFFF1744), const Color(0xFFD500F9)], // Rosa/Rojo Neón
    [const Color(0xFFF57C00), const Color(0xFFFFD54F)], // Naranja/Amarillo
  ];

  Future<void> _handleLogout() async {
    try {
      await _servicioAuth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PantallaLogin()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cerrar sesion')),
      );
    }
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PanelTransaccion(),
    );
  }

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    String selectedType = 'Ahorros';
    final balanceController = TextEditingController(text: '1000');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Agregar nueva cuenta',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la cuenta',
                    hintText: 'Ej. Banco BCP',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['Efectivo', 'Débito', 'Ahorros', 'Crédito', 'Inversión']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedType = val;
                  },
                  decoration: const InputDecoration(labelText: 'Tipo de cuenta'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Saldo Inicial'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF0F172A))),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
                if (name.isNotEmpty) {
                  final estadoApp = Provider.of<EstadoApp>(context, listen: false);
                  final gradientIdx = estadoApp.accounts.length % _cardGradients.length;
                  estadoApp.addAccount(name, selectedType, balance, gradientIdx);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
              child: const Text('Agregar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final size = MediaQuery.of(context).size;
    final esOscuro = estadoApp.esTemaOscuro;
    final colorFondo = esOscuro ? const Color(0xFF020617) : const Color(0xFFFAF8F5);

    return Scaffold(
      backgroundColor: colorFondo,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: colorFondo,
        child: Stack(
          children: [
            // Fondo con textura de papel de cuaderno rayado sutil y difuso
            Positioned.fill(
              child: CustomPaint(
                painter: PintorPapelCuaderno(esTemaOscuro: esOscuro),
              ),
            ),
            // Destello verde superior izquierdo
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.25,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (esOscuro ? const Color(0xFF00E676).withOpacity(0.18) : const Color(0xFFC5FAD5).withOpacity(0.55)),
                      colorFondo.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Contenido Principal con Scroll General
            SafeArea(
              child: _selectedDockIndex == 3
                  ? _buildSettingsView(estadoApp)
                  : _buildHomeView(estadoApp, size),
            ),
            // Dock de Navegacion Flotante Inferior
            _buildFloatingDock(size),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView(EstadoApp estadoApp, Size size) {
    final user = _servicioAuth.currentUser;
    final esOscuro = estadoApp.esTemaOscuro;
    final textStylePrincipal = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w900,
      color: esOscuro ? Colors.white : const Color(0xFF0F172A),
      letterSpacing: -0.5,
    );
    final textStyleSecundario = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: esOscuro ? Colors.white.withOpacity(0.5) : const Color(0xFF0F172A).withOpacity(0.4),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Cabecera Premium
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola,',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: esOscuro ? Colors.white.withOpacity(0.5) : const Color(0xFF0F172A).withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        user?.displayName.split(' ').first ?? 'Bienvenido',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '👋',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Boton Cerrar Sesion Discreto
                  GestureDetector(
                    onTap: _handleLogout,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: esOscuro ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white,
                        border: Border.all(
                          color: esOscuro ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E293B).withOpacity(0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Campana de Notificaciones
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: esOscuro ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white,
                      border: Border.all(
                        color: esOscuro ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E293B).withOpacity(0.02),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                          size: 22,
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.1, end: 0, duration: 500.ms),
          const SizedBox(height: 24),
          // Tarjeta Principal (Saldo Total)
          _buildBalanceCard(estadoApp),
          const SizedBox(height: 28),
          // Fila Cuentas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis cuentas',
                style: textStylePrincipal,
              ),
              Text(
                'Ver todas >',
                style: textStyleSecundario,
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms),
          const SizedBox(height: 16),
          // Grid 2x2 de Tarjetas de Credito
          _buildAccountsGrid(estadoApp),
          const SizedBox(height: 28),
          // Actividad Reciente
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actividad reciente',
                style: textStylePrincipal,
              ),
              Text(
                'Ver todo >',
                style: textStyleSecundario,
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 400.ms),
          const SizedBox(height: 12),
          // Lista de transacciones
          _buildTransactionList(estadoApp),
          // Espacio abajo
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _buildSettingsView(EstadoApp estadoApp) {
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;

    final List<Color> selectorColores = [
      const Color(0xFFFF2D55),
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFF5856D6),
      const Color(0xFFFFCC00),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Configuraciones',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: esOscuro ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.8,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            'APARIENCIA Y TEMA',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: esOscuro ? Colors.white.withOpacity(0.4) : const Color(0xFF0F172A).withOpacity(0.4),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: esOscuro ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.65),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
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
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: colorPrincipal.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.dark_mode_rounded,
                                color: colorPrincipal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modo Oscuro',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Alternar tema de la aplicación',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: esOscuro ? Colors.white.withOpacity(0.4) : const Color(0xFF0F172A).withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: esOscuro,
                          activeColor: colorPrincipal,
                          onChanged: (val) {
                            estadoApp.toggleTema(val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      color: esOscuro ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                      height: 1,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colorPrincipal.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.color_lens_rounded,
                            color: colorPrincipal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Color Principal',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Personalizar acentos y dock',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: esOscuro ? Colors.white.withOpacity(0.4) : const Color(0xFF0F172A).withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: selectorColores.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final colorSel = selectorColores[index];
                          final isSelectedColor = colorPrincipal.value == colorSel.value;

                          return GestureDetector(
                            onTap: () {
                              estadoApp.setColorPrincipal(colorSel);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colorSel,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelectedColor
                                      ? (esOscuro ? Colors.white : const Color(0xFF0F172A))
                                      : Colors.transparent,
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  if (isSelectedColor)
                                    BoxShadow(
                                      color: colorSel.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              child: isSelectedColor
                                  ? const Center(
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    )
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
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).scale(duration: 500.ms, delay: 200.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(EstadoApp estadoApp) {
    final esOscuro = estadoApp.esTemaOscuro;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: esOscuro ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.65),
              width: 1.0,
            ),
            gradient: LinearGradient(
              colors: esOscuro
                  ? [
                      const Color(0xFF1E293B).withOpacity(0.55),
                      const Color(0xFF00E676).withOpacity(0.06),
                    ]
                  : [
                      Colors.white.withOpacity(0.6),
                      const Color(0xFFC5FAD5).withOpacity(0.25),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SALDO TOTAL',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: esOscuro ? Colors.white.withOpacity(0.4) : const Color(0xFF0F172A).withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bs ${estadoApp.totalBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildBalanceMiniChip(
                    label: 'INGRESOS',
                    amount: '+${estadoApp.totalIncome.toStringAsFixed(2)}',
                    icon: Icons.keyboard_arrow_up_rounded,
                    color: const Color(0xFF34C759),
                    esOscuro: esOscuro,
                  ),
                  const SizedBox(width: 24),
                  _buildBalanceMiniChip(
                    label: 'GASTOS',
                    amount: '-${estadoApp.totalExpenses.toStringAsFixed(2)}',
                    icon: Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFFFF3B30),
                    esOscuro: esOscuro,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 100.ms)
        .scale(duration: 600.ms, delay: 100.ms, curve: Curves.easeOutBack);
  }

  Widget _buildBalanceMiniChip({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
    required bool esOscuro,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(esOscuro ? 0.12 : 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: esOscuro ? Colors.white.withOpacity(0.4) : const Color(0xFF0F172A).withOpacity(0.4),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              amount,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountsGrid(EstadoApp estadoApp) {
    final activeAccounts = estadoApp.accounts;
    const maxGridItems = 4;
    final gridCount = activeAccounts.length + 1 > maxGridItems ? maxGridItems : activeAccounts.length + 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        if (index == activeAccounts.length) {
          // Tarjeta Vacia Punteada (Agregar Cuenta) de la Captura
          return GestureDetector(
            onTap: _showAddAccountDialog,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Agregar cuenta',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A).withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final acc = activeAccounts[index];
        final gradient = _cardGradients[acc.gradientIndex % _cardGradients.length];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 6),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      acc.type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white.withOpacity(0.75),
                    size: 16,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acc.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bs ${acc.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 300.ms)
        .scale(duration: 600.ms, delay: 300.ms, curve: Curves.easeOutBack);
  }

  Widget _buildTransactionList(EstadoApp estadoApp) {
    final txs = estadoApp.transactions;
    final esOscuro = estadoApp.esTemaOscuro;

    if (txs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No hay movimientos registrados hoy.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: esOscuro ? Colors.white.withOpacity(0.25) : const Color(0xFF0F172A).withOpacity(0.25),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ).animate().fadeIn(duration: 500.ms);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: txs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = txs[index];
        final isIncome = tx.type == 'ingreso';
        final isTransfer = tx.type == 'transferencia';

        Color categoryColor = const Color(0xFFF57C00);
        IconData categoryIcon = Icons.bubble_chart_rounded;

        if (tx.category == 'Comida') {
          categoryColor = const Color(0xFFF57C00);
          categoryIcon = Icons.restaurant_rounded;
        } else if (tx.category == 'Salario') {
          categoryColor = const Color(0xFF00E676);
          categoryIcon = Icons.work_rounded;
        } else if (tx.category == 'Transporte') {
          categoryColor = const Color(0xFF2979FF);
          categoryIcon = Icons.directions_car_rounded;
        } else if (tx.category == 'Servicios') {
          categoryColor = const Color(0xFF7C4DFF);
          categoryIcon = Icons.electrical_services_rounded;
        } else if (tx.category == 'Entretenimiento') {
          categoryColor = const Color(0xFFE040FB);
          categoryIcon = Icons.videogame_asset_rounded;
        } else if (isTransfer) {
          categoryColor = const Color(0xFF00E5FF);
          categoryIcon = Icons.swap_horiz_rounded;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: esOscuro ? const Color(0xFF1E293B).withOpacity(0.85) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: esOscuro ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(categoryIcon, color: categoryColor, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tx.category} • ${tx.date.day}/${tx.date.month}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: esOscuro ? Colors.white.withOpacity(0.5) : const Color(0xFF0F172A).withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isIncome
                    ? '+Bs ${tx.amount.toStringAsFixed(2)}'
                    : isTransfer
                        ? 'Bs ${tx.amount.toStringAsFixed(2)}'
                        : '-Bs ${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isIncome
                      ? const Color(0xFF00E676)
                      : isTransfer
                          ? const Color(0xFF00B0FF)
                          : (esOscuro ? Colors.white70 : const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 500.ms);
  }

  Widget _buildFloatingDock(Size size) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 74,
                  decoration: BoxDecoration(
                    color: esOscuro ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: esOscuro ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.65),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDockItem(0, Icons.home_filled, 'Inicio', estadoApp),
                      _buildDockItem(1, Icons.grid_view_rounded, 'Movimientos', estadoApp),
                      _buildDockItem(2, Icons.bar_chart_rounded, 'Estadísticas', estadoApp),
                      _buildDockItem(3, Icons.settings_rounded, 'Ajustes', estadoApp),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showAddTransactionSheet,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: esOscuro ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: esOscuro ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.9),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorPrincipal.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: colorPrincipal,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem(int index, IconData icon, String label, EstadoApp estadoApp) {
    final isSelected = _selectedDockIndex == index;
    final activeColor = estadoApp.colorPrincipal;
    final inactiveColor = estadoApp.esTemaOscuro ? Colors.white.withOpacity(0.45) : const Color(0xFF0F172A).withOpacity(0.45);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDockIndex = index;
        });
        if (index == 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seccion de Estadisticas en construccion')),
          );
        } else if (index == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seccion de Movimientos en construccion')),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(
                  color: activeColor.withOpacity(0.2),
                  width: 0.8,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PintorPapelCuaderno extends CustomPainter {
  final bool esTemaOscuro;
  const PintorPapelCuaderno({required this.esTemaOscuro});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLinea = Paint()
      ..color = esTemaOscuro
          ? Colors.white.withOpacity(0.04)
          : const Color(0xFF0F172A).withOpacity(0.035)
      ..strokeWidth = 1.0;

    final paintMargen = Paint()
      ..color = esTemaOscuro
          ? const Color(0xFFFF2D55).withOpacity(0.08)
          : const Color(0xFFFF2D55).withOpacity(0.05)
      ..strokeWidth = 1.2;

    canvas.drawLine(
      const Offset(35, 0),
      Offset(35, size.height),
      paintMargen,
    );

    double y = 50;
    while (y < size.height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paintLinea,
      );
      y += 28;
    }
  }

  @override
  bool shouldRepaint(covariant PintorPapelCuaderno oldDelegate) =>
      oldDelegate.esTemaOscuro != esTemaOscuro;
}
