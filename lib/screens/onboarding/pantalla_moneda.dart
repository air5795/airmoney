import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/estado_app.dart';
import 'pantalla_crear_cuenta.dart';

class PantallaMoneda extends StatefulWidget {
  const PantallaMoneda({super.key});

  @override
  State<PantallaMoneda> createState() => _PantallaMonedaState();
}

class _PantallaMonedaState extends State<PantallaMoneda> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _currencies = [
    {'symbol': 'Bs', 'name': 'Boliviano boliviano', 'code': 'BOB'},
    {'symbol': '\$', 'name': 'Peso mexicano', 'code': 'MXN'},
    {'symbol': '\$', 'name': 'Dólar estadounidense', 'code': 'USD'},
    {'symbol': '€', 'name': 'Euro', 'code': 'EUR'},
    {'symbol': '£', 'name': 'Libra esterlina', 'code': 'GBP'},
    {'symbol': '¥', 'name': 'Yen japonés', 'code': 'JPY'},
    {'symbol': '¥', 'name': 'Yuan chino', 'code': 'CNY'},
    {'symbol': '₩', 'name': 'Won surcoreano', 'code': 'KRW'},
    {'symbol': '₹', 'name': 'Rupia india', 'code': 'INR'},
  ];

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

    final filteredCurrencies = _currencies.where((cur) {
      final name = cur['name']!.toLowerCase();
      final code = cur['code']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Barra de progreso de iOS (66%)
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
                      width: size.width * 0.6,
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
                    'Selecciona tu moneda',
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
                  'Esta será la moneda principal de tu app.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorSecundario.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buscador de Moneda
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: colorBuscador,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: colorSecundario.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorTexto,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar moneda o código...',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: colorSecundario.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Lista de Monedas Bento Style
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredCurrencies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cur = filteredCurrencies[index];
                    final isSelected = estadoApp.selectedCurrency == cur['code'];

                    return GestureDetector(
                      onTap: () => estadoApp.setCurrency(cur['code']!),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? colorPrimario
                                : (esOscuro
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isSelected
                                    ? (esOscuro ? 0.20 : 0.04)
                                    : (esOscuro ? 0.05 : 0.01),
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: esOscuro
                                    ? const Color(0xFF0E0E0E)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  cur['symbol']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: colorTexto,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cur['name']!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: colorTexto,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cur['code']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorSecundario.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? colorPrimario
                                      : colorSecundario.withValues(alpha: 0.35),
                                  width: isSelected ? 6.5 : 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(
                                        Icons.check,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // Botón Continuar Premium
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PantallaCrearCuenta()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                    ],
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
