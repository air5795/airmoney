import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/interactive_scale.dart';

class AjustesTipoCambio extends StatefulWidget {
  final VoidCallback onBack;

  const AjustesTipoCambio({
    super.key,
    required this.onBack,
  });

  @override
  State<AjustesTipoCambio> createState() => _AjustesTipoCambioState();
}

class _AjustesTipoCambioState extends State<AjustesTipoCambio> {
  final Map<String, TextEditingController> _controllers = {};
  
  final Map<String, String> _nombresMonedas = {
    'BOB': 'Boliviano boliviano',
    'MXN': 'Peso mexicano',
    'USD': 'Dolar estadounidense',
    'EUR': 'Euro',
    'GBP': 'Libra esterlina',
    'JPY': 'Yen japones',
    'CNY': 'Yuan chino',
    'KRW': 'Won surcoreano',
    'INR': 'Rupia india',
  };

  @override
  void initState() {
    super.initState();
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final monedaPrincipal = estadoApp.selectedCurrency;
    final todasMonedas = ['BOB', 'MXN', 'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'KRW', 'INR'];
    final monedasSecundarias = todasMonedas.where((m) => m != monedaPrincipal).toList();

    for (var m in monedasSecundarias) {
      final tasa = estadoApp.tiposCambio[m] ?? 1.0;
      _controllers[m] = TextEditingController(text: tasa.toStringAsFixed(4));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _guardarTiposCambio(EstadoApp estadoApp) async {
    bool algunError = false;
    final Map<String, double> nuevosTipos = {};

    _controllers.forEach((moneda, controller) {
      final valorTexto = controller.text.trim();
      final valor = double.tryParse(valorTexto);

      if (valor == null || valor <= 0) {
        algunError = true;
      } else {
        nuevosTipos[moneda] = valor;
      }
    });

    if (algunError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese valores numericos validos y mayores a cero en todas las monedas.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    for (var entry in nuevosTipos.entries) {
      await estadoApp.setTasaCambio(entry.key, entry.value);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tipos de cambio actualizados con exito.'),
        backgroundColor: Color(0xFF34C759),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorSecundario = esOscuro ? const Color(0xFF64748B) : const Color(0xFF475569);

    final String monedaPrincipal = estadoApp.selectedCurrency;
    final String simboloPrincipal = EstadoApp.getSymbolOfCurrency(monedaPrincipal);

    final todasMonedas = ['BOB', 'MXN', 'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'KRW', 'INR'];
    final monedasSecundarias = todasMonedas.where((m) => m != monedaPrincipal).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InteractiveScale(
              onTap: widget.onBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: colorPrincipal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ajustes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorPrincipal,
                    ),
                  ),
                ],
              ),
            ),
            InteractiveScale(
              onTap: () => _guardarTiposCambio(estadoApp),
              child: Text(
                'Guardar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorPrincipal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Tipos de Cambio',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colorTexto,
            letterSpacing: -0.8,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          'CONFIGURACION MULTI-DIVISA GLOBAL',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorTexto.withValues(alpha: 0.4),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 16),

        // Info Banner Bento
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: esOscuro
                    ? const Color(0xFF1E293B).withValues(alpha: 0.3)
                    : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorPrincipal,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tu moneda principal es $monedaPrincipal ($simboloPrincipal). A continuacion, define el valor referencial de cada divisa extranjera respecto a ella.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: colorSecundario,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 120.ms),
        const SizedBox(height: 20),

        // Lista de Monedas Secundarias
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: monedasSecundarias.length,
          itemBuilder: (context, index) {
            final moneda = monedasSecundarias[index];
            final nombreMoneda = _nombresMonedas[moneda] ?? moneda;
            final simboloMoneda = EstadoApp.getSymbolOfCurrency(moneda);
            final controller = _controllers[moneda];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: esOscuro
                          ? const Color(0xFF0A0A0A).withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: esOscuro
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.65),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorPrincipal.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                simboloMoneda,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorPrincipal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombreMoneda,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorTexto,
                                    ),
                                  ),
                                  Text(
                                    'Codigo de divisa: $moneda',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorSecundario.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: esOscuro
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.black.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: esOscuro
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '1 $moneda =',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorTexto,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: colorTexto,
                                      ),
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorPrincipal.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      monedaPrincipal,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: colorPrincipal,
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
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms, delay: (index * 50).ms).slideY(begin: 0.08, end: 0, duration: 350.ms),
            );
          },
        ),
        const SizedBox(height: 24),

        // Boton de Guardar

        const SizedBox(height: 100),
      ],
    );
  }
}
