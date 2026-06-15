import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/interactive_scale.dart';
import '../../../widgets/toast_ios.dart';

class AjustesVoz extends StatefulWidget {
  final VoidCallback onBack;

  const AjustesVoz({
    super.key,
    required this.onBack,
  });

  @override
  State<AjustesVoz> createState() => _AjustesVozState();
}

class _AjustesVozState extends State<AjustesVoz> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isObscure = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final estadoApp = Provider.of<EstadoApp>(context, listen: false);
      _apiKeyController.text = estadoApp.rawGeminiApiKey;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _abrirAiStudio() async {
    final Uri url = Uri.parse('https://aistudio.google.com/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ToastHelper.showError(context, 'No se pudo abrir el enlace');
      }
    }
  }

  Future<void> _pegarCopiar() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    if (data != null && data.text != null) {
      setState(() {
        _apiKeyController.text = data.text!;
      });
      ToastHelper.showSuccess(context, 'Clave pegada del portapapeles');
    } else {
      ToastHelper.showInfo(context, 'El portapapeles está vacío');
    }
  }

  Future<void> _probarConexion(EstadoApp estadoApp) async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ToastHelper.showError(context, 'Ingresa una clave API para probar');
      return;
    }

    setState(() {
      _isTesting = true;
    });

    final bool exito = await estadoApp.probarConexionGemini(key);

    setState(() {
      _isTesting = false;
    });

    if (mounted) {
      if (exito) {
        ToastHelper.showSuccess(context, '¡Conexión a Gemini exitosa!');
      } else {
        ToastHelper.showError(context, 'Error de conexión. Verifica la clave API.');
      }
    }
  }

  Future<void> _guardarClave(EstadoApp estadoApp) async {
    final key = _apiKeyController.text.trim();
    await estadoApp.setGeminiApiKey(key);
    if (mounted) {
      ToastHelper.showSuccess(
        context, 
        key.isEmpty 
            ? 'Configuración guardada (usando motor local)' 
            : 'Configuración de Gemini guardada correctamente'
      );
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

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
                    'Asistente de Voz',
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
              const Expanded(
                flex: 3,
                child: SizedBox(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Contenedor acrilico premium
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: esOscuro
                    ? const Color(0xFF0A0A0A).withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(24),
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
                  // Cabecera del asistente
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorPrincipal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.psychology_rounded,
                          color: colorPrincipal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motor de IA Gemini',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorTexto,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              estadoApp.rawGeminiApiKey.isEmpty
                                  ? 'Estado: Usando clave por defecto'
                                  : 'Estado: Clave personalizada activa',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colorPrincipal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Para disfrutar de un registro por voz 100% preciso con Inteligencia Artificial, ingresa tu clave API personal. Si la dejas vacía, la app usará la clave por defecto.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colorTexto.withValues(alpha: 0.7),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Botón para ir a Google AI Studio
                  GestureDetector(
                    onTap: _abrirAiStudio,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorPrincipal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorPrincipal.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 14, color: colorPrincipal),
                          const SizedBox(width: 8),
                          Text(
                            'Obtener API Key gratis en Google AI Studio',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: colorPrincipal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Campo de texto de API Key
                  Text(
                    'CLAVE DE API DE GEMINI',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorTexto.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  TextFormField(
                    controller: _apiKeyController,
                    obscureText: _isObscure,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorTexto,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Pega tu clave API aquí...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorTexto.withValues(alpha: 0.3),
                      ),
                      filled: true,
                      fillColor: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colorPrincipal, width: 1.0),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isObscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              size: 18,
                              color: colorTexto.withValues(alpha: 0.4),
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.content_paste_rounded,
                              size: 18,
                              color: colorPrincipal,
                            ),
                            onPressed: _pegarCopiar,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón de Probar Conexión
                  Row(
                    children: [
                      Expanded(
                        child: InteractiveScale(
                          onTap: _isTesting ? null : () => _probarConexion(estadoApp),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorTexto.withValues(alpha: 0.2),
                                width: 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: _isTesting
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorTexto,
                                    ),
                                  )
                                : Text(
                                    'Probar Conexión',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: colorTexto,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Botón de Guardar
                      Expanded(
                        child: InteractiveScale(
                          onTap: () => _guardarClave(estadoApp),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: colorPrincipal,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: colorPrincipal.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Guardar',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
        const SizedBox(height: 110),
      ],
    );
  }
}
