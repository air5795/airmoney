import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../services/estado_app.dart';
import 'pantalla_moneda.dart';

class PantallaIdioma extends StatefulWidget {
  const PantallaIdioma({super.key});

  @override
  State<PantallaIdioma> createState() => _PantallaIdiomaState();
}

class _PantallaIdiomaState extends State<PantallaIdioma> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _languages = [
    {'code': 'ES', 'name': 'Español', 'native': 'Español', 'id': 'es'},
    {'code': 'EN', 'name': 'English', 'native': 'Inglés', 'id': 'en'},
    {'code': 'PT', 'name': 'Português', 'native': 'Português', 'id': 'pt'},
    {'code': 'PT', 'name': 'Português (BR)', 'native': 'Português (Brasil)', 'id': 'pt_br'},
    {'code': 'FR', 'name': 'Français', 'native': 'Francés', 'id': 'fr'},
    {'code': 'DE', 'name': 'Deutsch', 'native': 'Alemán', 'id': 'de'},
    {'code': 'IT', 'name': 'Italiano', 'native': 'Italiano', 'id': 'it'},
    {'code': 'NL', 'name': 'Nederlands', 'native': 'Holandés', 'id': 'nl'},
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

    final filteredLanguages = _languages.where((lang) {
      final name = lang['name']!.toLowerCase();
      final native = lang['native']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || native.contains(query);
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
              
              // Barra de progreso institucional (33%)
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
                      width: size.width * 0.3,
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
              
              Text(
                'Elige tu idioma',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: colorTexto,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Personaliza ${AppConfig.appName} en tu idioma.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorSecundario.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buscador de Idioma elegante
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
                          hintText: 'Buscar idioma...',
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
              
              // Lista de Idiomas Bento Style
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredLanguages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lang = filteredLanguages[index];
                    final isSelected = estadoApp.selectedLanguage == lang['id'];

                    return GestureDetector(
                      onTap: () => estadoApp.setLanguage(lang['id']!),
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
                                  lang['code']!,
                                  style: TextStyle(
                                    fontSize: 12,
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
                                    lang['name']!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: colorTexto,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lang['native']!,
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
                      MaterialPageRoute(builder: (_) => const PantallaMoneda()),
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
