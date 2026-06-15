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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _estaCargandoApi = false;
  bool _respetarCambiosManuales = true;

  @override
  void initState() {
    super.initState();
    _cargarTasasEnControladores();
  }

  void _cargarTasasEnControladores() {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final monedaPrincipal = estadoApp.selectedCurrency;
    final todasMonedas = EstadoApp.todosCodigosMoneda;
    final monedasSecundarias = todasMonedas.where((m) => m != monedaPrincipal).toList();

    for (var m in monedasSecundarias) {
      final tasa = estadoApp.tiposCambio[m] ?? 1.0;
      if (_controllers.containsKey(m)) {
        _controllers[m]!.text = tasa.toStringAsFixed(4);
      } else {
        _controllers[m] = TextEditingController(text: tasa.toStringAsFixed(4));
      }
    }
  }

  String _formatearUltimaActualizacion(int millis) {
    if (millis == 0) return 'Nunca';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final hora = dt.hour.toString().padLeft(2, '0');
    final minuto = dt.minute.toString().padLeft(2, '0');
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final anio = dt.year;
    return '$dia/$mes/$anio $hora:$minuto';
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _guardarTiposCambio(EstadoApp estadoApp) async {
    bool algunError = false;
    String mensajeError = '';
    final Map<String, double> nuevosTipos = {};

    for (var m in _controllers.keys) {
      final controller = _controllers[m]!;
      final valorTexto = controller.text.trim().replaceAll(',', '.');
      final valor = double.tryParse(valorTexto);
      final valorActual = estadoApp.tiposCambio[m] ?? 1.0;

      // Comprobar si realmente ha cambiado
      final textoActual = valorActual.toStringAsFixed(4);
      final textoFormateadoController = valor != null ? valor.toStringAsFixed(4) : '';

      if (valorTexto == textoActual || textoFormateadoController == textoActual) {
        continue; // No cambió, no validamos ni guardamos esto
      }

      // Si cambió, sí validamos
      if (valor == null || valor <= 0) {
        algunError = true;
        mensajeError = 'Por favor, ingrese un valor numérico mayor a 0 para ${EstadoApp.getNameOfCurrency(m)} ($m).';
        break;
      } else {
        nuevosTipos[m] = valor;
      }
    }

    if (algunError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (nuevosTipos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cambios para guardar.'),
          backgroundColor: Colors.blueGrey,
        ),
      );
      return;
    }

    for (var entry in nuevosTipos.entries) {
      final moneda = entry.key;
      final nuevoValor = entry.value;
      await estadoApp.marcarMonedaComoPersonalizada(moneda);
      await estadoApp.setTasaCambio(moneda, nuevoValor);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tipos de cambio actualizados con éxito.'),
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
    final String banderaPrincipal = EstadoApp.getFlagOfCurrency(monedaPrincipal);

    final todasMonedas = EstadoApp.todosCodigosMoneda;
    final monedasSecundariasCompleto = todasMonedas.where((m) => m != monedaPrincipal).toList();
    final monedasSecundariasFiltradas = monedasSecundariasCompleto.where((m) {
      final nombre = EstadoApp.getNameOfCurrency(m).toLowerCase();
      final codigo = m.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nombre.contains(query) || codigo.contains(query);
    }).toList();

    final monedasSecundarias = _searchQuery.isEmpty
        ? monedasSecundariasFiltradas.take(10).toList()
        : monedasSecundariasFiltradas;

    final Color colorTitulo = esOscuro
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.1), colorPrincipal)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.15), colorPrincipal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InteractiveScale(
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
                            fontWeight: FontWeight.w700,
                            color: colorPrincipal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                    'Tipos de Cambio',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colorTitulo,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InteractiveScale(
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
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

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
                      'Tu moneda principal es $banderaPrincipal $monedaPrincipal ($simboloPrincipal). A continuacion, define el valor referencial de cada divisa extranjera respecto a ella.',
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
        // Buscador de Monedas Secundarias
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: esOscuro ? const Color(0xFF0E0E0E) : const Color(0xFFF1F5F9),
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
                    hintText: 'Buscar divisa...',
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
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: Icon(
                    Icons.clear_rounded,
                    color: colorSecundario.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
        const SizedBox(height: 20),

        // Card de Sincronización Automática
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: esOscuro
                    ? const Color(0xFF1E293B).withValues(alpha: 0.15)
                    : const Color(0xFFF1F5F9).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_sync_rounded,
                        color: colorPrincipal,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Actualización Automática',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorTexto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Si el valor de cambio real de Google o el mercado es diferente al mostrado abajo, puedes presionar el botón para sincronizar todas las divisas al instante desde internet o editarlas manualmente.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: colorSecundario.withValues(alpha: 0.8),
                    ),
                  ),
                  Divider(
                    height: 24,
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Respetar cambios manuales',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorTexto,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'No actualizar las divisas que has editado personalmente.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colorSecundario.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _respetarCambiosManuales,
                        activeColor: colorPrincipal,
                        onChanged: (val) {
                          setState(() {
                            _respetarCambiosManuales = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Última sinc.: ${_formatearUltimaActualizacion(estadoApp.lastLocalUpdateMillis)}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: colorSecundario.withValues(alpha: 0.6),
                        ),
                      ),
                      _estaCargandoApi
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(colorPrincipal),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () async {
                                  setState(() {
                                    _estaCargandoApi = true;
                                  });
                                  final messenger = ScaffoldMessenger.of(context);
                                  final exito = await estadoApp.actualizarTasasDesdeInternet(
                                    respetarPersonalizadas: _respetarCambiosManuales,
                                  );
                                  if (mounted) {
                                    setState(() {
                                      _estaCargandoApi = false;
                                    });
                                    if (exito) {
                                      _cargarTasasEnControladores();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Tipos de cambio actualizados con éxito desde internet.'),
                                          backgroundColor: Color(0xFF34C759),
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Error al conectar con el servidor. Verifica tu conexión.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                              icon: const Icon(Icons.sync_rounded, size: 16),
                              label: const Text(
                                'Actualizar Divisas',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrincipal,
                                foregroundColor: esOscuro ? Colors.black : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 180.ms),
        const SizedBox(height: 20),

        // Lista de Monedas Secundarias
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: monedasSecundarias.length,
          itemBuilder: (context, index) {
            final moneda = monedasSecundarias[index];
            final nombreMoneda = EstadoApp.getNameOfCurrency(moneda);
            final simboloMoneda = EstadoApp.getSymbolOfCurrency(moneda);
            final banderaMoneda = EstadoApp.getFlagOfCurrency(moneda);
            final controller = _controllers[moneda];
            final esPersonalizada = estadoApp.monedasPersonalizadas.contains(moneda);

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
                                banderaMoneda,
                                style: const TextStyle(
                                  fontSize: 18,
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
                                    'Código de divisa: $moneda ($simboloMoneda)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorSecundario.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (esPersonalizada) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      size: 10,
                                      color: Colors.amber,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Editado',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  setState(() {
                                    _estaCargandoApi = true;
                                  });
                                  await estadoApp.removerMonedaPersonalizada(moneda);
                                  final exito = await estadoApp.actualizarTasasDesdeInternet(
                                    respetarPersonalizadas: true,
                                  );
                                  if (mounted) {
                                    setState(() {
                                      _estaCargandoApi = false;
                                    });
                                    _cargarTasasEnControladores();
                                    if (exito) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Divisa $moneda restaurada al valor del servidor.'),
                                          backgroundColor: const Color(0xFF34C759),
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Divisa $moneda marcada para actualizar en la próxima sincronización.'),
                                          backgroundColor: Colors.blueGrey,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.settings_backup_restore_rounded,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ],
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
