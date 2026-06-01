import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/estado_app.dart';
import '../pantalla_principal.dart';

class PantallaCrearCuenta extends StatefulWidget {
  const PantallaCrearCuenta({super.key});

  @override
  State<PantallaCrearCuenta> createState() => _PantallaCrearCuentaState();
}

class _PantallaCrearCuentaState extends State<PantallaCrearCuenta> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController(text: '570');
  String _selectedType = 'Débito';

  final List<String> _accountTypes = [
    'Efectivo',
    'Débito',
    'Ahorros',
    'Crédito',
    'Inversión',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final balanceText = _balanceController.text.trim();
    final balance = double.tryParse(balanceText) ?? 0.0;

    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    estadoApp.completeOnboarding(name, _selectedType, balance);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PantallaPrincipal()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrimario = estadoApp.colorPrincipal;
    
    final colorFondo = esOscuro ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final colorTexto = esOscuro ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final colorSecundario = esOscuro ? const Color(0xFF64748B) : const Color(0xFF475569);
    final colorCard = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;
    final colorBuscador = esOscuro ? const Color(0xFF0E0E0E) : const Color(0xFFF1F5F9);

    final size = MediaQuery.of(context).size;
    final isNameEmpty = _nameController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Barra de progreso de iOS (100%)
              Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: size.width - 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorPrimario,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorCard,
                        border: Border.all(
                          color: esOscuro
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: colorTexto,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Crea tu primera cuenta',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: colorTexto,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Empieza con un saldo y tipo de cuenta.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorSecundario.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NOMBRE DE LA CUENTA
                      Text(
                        'NOMBRE DE LA CUENTA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: colorSecundario.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: colorCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: esOscuro
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: TextField(
                            controller: _nameController,
                            onChanged: (val) {
                              setState(() {});
                            },
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorTexto,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ej. Banco principal',
                              hintStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: colorSecundario.withValues(alpha: 0.4),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // TIPO DE CUENTA
                      Text(
                        'TIPO DE CUENTA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: colorSecundario.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _accountTypes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final type = _accountTypes[index];
                            final isSelected = _selectedType == type;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedType = type;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? colorPrimario : colorCard,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorPrimario
                                        : (esOscuro
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : const Color(0xFFE2E8F0)),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : colorTexto,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // SALDO INICIAL
                      Text(
                        'SALDO INICIAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: colorSecundario.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isNameEmpty
                                ? (esOscuro
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0))
                                : colorPrimario.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: colorBuscador,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${estadoApp.selectedCurrency}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: colorTexto,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _balanceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: colorTexto,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Puedes editar este valor más tarde desde la cuenta.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorSecundario.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      // Tarjeta Casi Listo Premium
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: esOscuro
                              ? const Color(0xFF064E3B).withValues(alpha: 0.2)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: esOscuro
                                ? const Color(0xFF059669).withValues(alpha: 0.2)
                                : const Color(0xFFA7F3D0),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorPrimario,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Casi listo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: colorTexto,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Podrás agregar más cuentas (tarjetas, ahorros, efectivo) en cualquier momento desde el menú.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                      color: colorSecundario.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Botón Finalizar Onboarding
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: isNameEmpty ? null : _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNameEmpty
                        ? (esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFE2E8F0))
                        : colorPrimario,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: esOscuro ? const Color(0xFF0E0E0E) : const Color(0xFFCBD5E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Empezar a usar AirMoney',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isNameEmpty
                          ? (esOscuro ? const Color(0xFF475569) : const Color(0xFF94A3B8))
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
