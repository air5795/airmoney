import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/estado_app.dart';
import 'vista_ajustes.dart';

class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key});

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorFondo = esOscuro ? const Color(0xFF000000) : const Color(0xFFF0F2F5);
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    final showAppBar = estadoApp.selectedSettingsSubView == 0;

    return PopScope(
      canPop: estadoApp.selectedSettingsSubView == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        estadoApp.selectedSettingsSubView = 0;
      },
      child: Scaffold(
        backgroundColor: colorFondo,
        appBar: showAppBar
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorTexto, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Ajustes',
                  style: TextStyle(
                    color: colorTexto,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: true,
              )
            : null,
        body: const SafeArea(
          child: VistaAjustes(),
        ),
      ),
    );
  }
}
