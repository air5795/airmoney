import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/hex_color_picker.dart';
import '../../../widgets/interactive_scale.dart';
import 'detalle_cuenta.dart';

class AjustesCuentas extends StatefulWidget {
  final VoidCallback onBack;

  const AjustesCuentas({
    super.key,
    required this.onBack,
  });

  @override
  State<AjustesCuentas> createState() => _AjustesCuentasState();
}

class _AjustesCuentasState extends State<AjustesCuentas> {
  bool _isCreatingOrEditingAccount = false;
  ModeloCuenta? _selectedAccountToEdit;

  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountBalanceController = TextEditingController();

  String _selectedAccountType = 'Ahorros';
  String _selectedAccountCurrency = 'BOB';
  int _selectedAccountGradientIdx = 0;
  String _selectedAccountColorHex = '#B3E5FC';
  String _selectedAccountSecondaryColorHex = '#E2E8F0';

  bool _useCustomColorForAccount = false;
  bool _selectedAccountUseDarkText = false;
  bool _selectedAccountContabilizable = true;

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


  static final List<String> _strongColorsStart = [
    '#E53935', // Rojo Intenso
    '#D81B60', // Rosa Fucsia
    '#8E24AA', // Purpura Vibrante
    '#5E35B1', // Violeta Electrico
    '#1E88E5', // Azul Cobalto
    '#00B0FF', // Azul Electrico
    '#00ACC1', // Cian Brillante
    '#00897B', // Menta Intensa
    '#43A047', // Verde Esmeralda
    '#7CB342', // Verde Lima Brillante
    '#FDD835', // Amarillo Oro
    '#FB8C00', // Naranja Atardecer
    '#F4511E', // Rojo Coral
    '#00E5FF', // Cian Verdoso
    '#76FF03', // Verde Alien
    '#FF4081', // Rosa Neon
    '#D500F9', // Purpura Neon
    '#1A237E', // Azul Marino Intenso
    '#EC407A', // Magenta Ciberpunk
    '#1DE9B6', // Turquesa Mistico
  ];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final estadoApp = Provider.of<EstadoApp>(context, listen: false);
      if (estadoApp.accountToEditDirectly != null) {
        final acc = estadoApp.accountToEditDirectly!;
        estadoApp.accountToEditDirectly = null; // reset
        _iniciarEdicion(acc);
      }
    });
  }

  void _iniciarEdicion(ModeloCuenta acc) {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    _accountNameController.text = acc.name;
    _accountBalanceController.text = acc.balance.toStringAsFixed(2);

    setState(() {
      _selectedAccountToEdit = acc;
      _isCreatingOrEditingAccount = true;
      
      final typeUpper = acc.type.toUpperCase();
      if (typeUpper.contains('AHORRO')) {
        _selectedAccountType = 'Ahorros';
      } else if (typeUpper.contains('DEBITO') || typeUpper.contains('DÉBITO')) {
        _selectedAccountType = 'Débito';
      } else if (typeUpper.contains('CREDITO') || typeUpper.contains('CRÉDITO')) {
        _selectedAccountType = 'Crédito';
      } else if (typeUpper.contains('EFECTIVO')) {
        _selectedAccountType = 'Efectivo';
      } else if (typeUpper.contains('INVERSION') || typeUpper.contains('INVERSIÓN')) {
        _selectedAccountType = 'Inversión';
      } else {
        _selectedAccountType = 'Ahorros';
      }
      
      _selectedAccountCurrency = acc.currency ?? estadoApp.selectedCurrency;
      _selectedAccountGradientIdx = acc.gradientIndex;
      _selectedAccountColorHex = acc.customColorHex ?? '#B3E5FC';
      _selectedAccountSecondaryColorHex = acc.customColorSecondaryHex ?? '#E2E8F0';
      _useCustomColorForAccount = acc.customColorHex != null;
      _selectedAccountUseDarkText = acc.useDarkText ?? false;
      _selectedAccountContabilizable = acc.contabilizable ?? true;
    });
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountBalanceController.dispose();
    super.dispose();
  }

  void _guardarCuenta(EstadoApp estadoApp) {
    final name = _accountNameController.text.trim();
    final balance = double.tryParse(_accountBalanceController.text.trim()) ?? 0.0;
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese un nombre para la cuenta.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedAccountToEdit != null) {
      estadoApp.editAccount(
        _selectedAccountToEdit!.id,
        name,
        _selectedAccountType,
        balance,
        _selectedAccountGradientIdx,
        customColorHex: _useCustomColorForAccount ? _selectedAccountColorHex : null,
        customColorSecondaryHex: _useCustomColorForAccount ? _selectedAccountSecondaryColorHex : null,
        customColorThirdHex: null,
        stop1: null,
        stop2: null,
        stop3: null,
        useDarkText: _selectedAccountUseDarkText,
        currency: _selectedAccountCurrency,
        contabilizable: _selectedAccountContabilizable,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta actualizada con éxito.'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
    } else {
      estadoApp.addAccount(
        name,
        _selectedAccountType,
        balance,
        _selectedAccountGradientIdx,
        customColorHex: _useCustomColorForAccount ? _selectedAccountColorHex : null,
        customColorSecondaryHex: _useCustomColorForAccount ? _selectedAccountSecondaryColorHex : null,
        customColorThirdHex: null,
        stop1: null,
        stop2: null,
        stop3: null,
        useDarkText: _selectedAccountUseDarkText,
        currency: _selectedAccountCurrency,
        contabilizable: _selectedAccountContabilizable,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada con éxito.'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
    }

    setState(() {
      _isCreatingOrEditingAccount = false;
      _selectedAccountToEdit = null;
      _selectedAccountUseDarkText = false;
      _selectedAccountContabilizable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InteractiveScale(
              onTap: () {
                if (_isCreatingOrEditingAccount) {
                  setState(() {
                    _isCreatingOrEditingAccount = false;
                    _selectedAccountToEdit = null;
                  });
                } else {
                  widget.onBack();
                }
              },
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
                    _isCreatingOrEditingAccount ? 'Cuentas' : 'Ajustes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorPrincipal,
                    ),
                  ),
                ],
              ),
            ),
            if (_isCreatingOrEditingAccount)
              InteractiveScale(
                onTap: () => _guardarCuenta(estadoApp),
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
          _isCreatingOrEditingAccount
              ? (_selectedAccountToEdit == null ? 'Nueva Cuenta' : 'Editar Cuenta')
              : 'Mis Cuentas',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: esOscuro ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.8,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          _isCreatingOrEditingAccount ? 'CONFIGURAR DATOS DE LA TARJETA' : 'GESTIONAR CUENTAS DE AIRMONEY',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 24),
        _isCreatingOrEditingAccount
            ? _buildAccountFormView(estadoApp)
            : _buildAccountsListView(estadoApp),
        const SizedBox(height: 110),
      ],
    );
  }

  Widget _buildAccountsListView(EstadoApp estadoApp) {
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final accounts = estadoApp.accounts;

    return Column(
      children: [
        InteractiveScale(
          onTap: () {
            setState(() {
              _isCreatingOrEditingAccount = true;
              _selectedAccountToEdit = null;
              _accountNameController.clear();
              _accountBalanceController.text = '0.00';
              _selectedAccountType = 'Ahorros';
              _selectedAccountCurrency = estadoApp.selectedCurrency;
              _selectedAccountGradientIdx = 0;
              _selectedAccountColorHex = '#B3E5FC';
              _selectedAccountSecondaryColorHex = '#E2E8F0';

              _useCustomColorForAccount = false;
              _selectedAccountUseDarkText = false;
              _selectedAccountContabilizable = true;
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: esOscuro
                        ? const Color(0xFF1E1E1E)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_card_rounded,
                      color: colorPrincipal,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Crear Nueva Cuenta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorPrincipal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: accounts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final acc = accounts[index];
            final colors = _getAccountColors(acc, esOscuro);
            final miniBgColor = colors.background;
            final miniTextColor = colors.text;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: esOscuro 
                    ? const Color(0xFF0E0E0E).withValues(alpha: 0.55) 
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: esOscuro 
                      ? const Color(0xFF1E1E1E) 
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: esOscuro
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFCBD5E1).withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: miniBgColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  topRight: Radius.circular(7),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        acc.type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 3.5,
                                          fontWeight: FontWeight.w900,
                                          color: miniTextColor.withValues(alpha: 0.75),
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                      // Switch decorativo miniatura
                                      Container(
                                        width: 10,
                                        height: 5,
                                        padding: const EdgeInsets.all(0.5),
                                        decoration: BoxDecoration(
                                          color: miniTextColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(2.5),
                                        ),
                                        child: Align(
                                          alignment: (acc.contabilizable ?? true)
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: miniTextColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      // Chip miniatura
                                      Container(
                                        width: 7,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: miniTextColor,
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          acc.name.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 4.5,
                                            fontWeight: FontWeight.w900,
                                            color: miniTextColor,
                                            letterSpacing: -0.1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 11,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _getBottomBgColor(miniBgColor),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(7),
                                bottomRight: Radius.circular(7),
                              ),
                            ),
                            child: Text(
                              '${EstadoApp.getSymbolOfCurrency(acc.currency ?? estadoApp.selectedCurrency)} ${acc.balance.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 5,
                                fontWeight: FontWeight.w900,
                                color: miniTextColor,
                                letterSpacing: -0.2,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                          acc.name.toUpperCase(),
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
                                acc.type.toUpperCase(),
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
                            Flexible(
                              child: Text(
                                '${EstadoApp.getSymbolOfCurrency(acc.currency ?? estadoApp.selectedCurrency)} ${acc.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: colorTexto,
                                  letterSpacing: -0.3,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opciones',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFCBD5E1),
                        width: 1.0,
                      ),
                    ),
                    color: esOscuro ? const Color(0xFF0A0A0A) : Colors.white,
                    elevation: 6,
                    onSelected: (value) async {
                      if (value == 'ver') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VistaDetalleCuenta(account: acc),
                          ),
                        );
                        if (result == 'editar' && context.mounted) {
                          _iniciarEdicion(acc);
                        }
                      } else if (value == 'editar') {
                        _iniciarEdicion(acc);
                      } else if (value == 'eliminar') {
                        final messenger = ScaffoldMessenger.of(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: esOscuro ? const Color(0xFF0A0A0A) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFCBD5E1),
                                width: 1.0,
                              ),
                            ),
                            title: Text(
                              'Eliminar Cuenta',
                              style: TextStyle(
                                color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              '¿Está seguro de que desea eliminar la cuenta "${acc.name}"? Esta acción eliminará todos sus movimientos y no se puede deshacer.',
                              style: TextStyle(
                                color: esOscuro ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF0F172A).withValues(alpha: 0.7),
                              ),
                            ),
                            actions: [
                              InteractiveScale(
                                onTap: () => Navigator.pop(context, false),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: esOscuro ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF0F172A).withValues(alpha: 0.6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              InteractiveScale(
                                onTap: () => Navigator.pop(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final success = await estadoApp.deleteAccount(acc.id);
                          if (!mounted) return;
                          if (!success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('No es posible eliminar la última cuenta activa.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Cuenta eliminada correctamente.'),
                                backgroundColor: Color(0xFF34C759),
                              ),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'ver',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_rounded, color: colorTexto.withValues(alpha: 0.8), size: 18),
                            const SizedBox(width: 12),
                            Text('Ver detalle', style: TextStyle(color: colorTexto, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, color: colorTexto.withValues(alpha: 0.8), size: 18),
                            const SizedBox(width: 12),
                            Text('Editar cuenta', style: TextStyle(color: colorTexto, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<String>(
                        value: 'eliminar',
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            SizedBox(width: 12),
                            Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: esOscuro ? const Color(0xFF1E1E1E) : Colors.black.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: colorTexto.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            );
        },
      ),
    ],
  );
}

  void _mostrarSelectorColorManual(BuildContext context, EstadoApp estadoApp, {required String titulo, required String colorHexActual, required ValueChanged<String> onColorChanged}) {
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: esOscuro ? 0.5 : 0.35),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double screenHeight = MediaQuery.of(context).size.height;
            final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
            
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: screenHeight * 0.70,
                decoration: BoxDecoration(
                  color: esOscuro 
                      ? const Color(0xFF0A0A0A).withValues(alpha: 0.88)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: esOscuro 
                        ? const Color(0xFF1E1E1E)
                        : Colors.white.withValues(alpha: 0.80),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: esOscuro ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: colorTexto,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: colorTexto.withValues(alpha: 0.6)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: HexColorPicker(
                          currentColorHex: colorHexActual,
                          onColorChanged: (hex) {
                            onColorChanged(hex);
                            setDialogState(() {
                              colorHexActual = hex;
                            });
                          },
                          esOscuro: esOscuro,
                          colorPrincipal: colorPrincipal,
                          customColors: _strongColorsStart,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static final List<SolidCardColors> _predefinedSchemes = [
    const SolidCardColors(Color(0xFFC8E6C9), Color(0xFF0F5132)), // Verde Esmeralda
    const SolidCardColors(Color(0xFFE1F5FE), Color(0xFF01579B)), // Azul Vibrante
    const SolidCardColors(Color(0xFFFFCDD2), Color(0xFF842029)), // Rosa/Rojo Neon
    const SolidCardColors(Color(0xFFFFE0B2), Color(0xFFE65100)), // Naranja/Amarillo
    const SolidCardColors(Color(0xFFE1BEE7), Color(0xFF4A148C)), // Purpura Profundo
    const SolidCardColors(Color(0xFFE0F2F1), Color(0xFF004D40)), // Menta Fresca
    const SolidCardColors(Color(0xFFFFCCBC), Color(0xFFBF360C)), // Atardecer de Ibiza
    const SolidCardColors(Color(0xFFF8BBD0), Color(0xFF880E4F)), // Violeta Ciberpunk
    const SolidCardColors(Color(0xFFE8EAF6), Color(0xFF1A237E)), // Cielo Nocturno
    const SolidCardColors(Color(0xFFE0F7FA), Color(0xFF006064)), // Bosque Mistico
    const SolidCardColors(Color(0xFFFFE0B2), Color(0xFFDD2C00)), // Fuego Fenix
    const SolidCardColors(Color(0xFFF3E5F5), Color(0xFF6A1B9A)), // Rosa Orquidea
    const SolidCardColors(Color(0xFFECEFF1), Color(0xFF37474F)), // Azul Glaciar
    const SolidCardColors(Color(0xFFF1F8E9), Color(0xFF33691E)), // Neon Alien
  ];

  static final List<Color> _basePaletteColors = [
    // Verdes y Menta (6)
    const Color(0xFF10B981), // Verde Esmeralda
    const Color(0xFF059669), // Verde Oscuro
    const Color(0xFF22C55E), // Verde/Esmeralda Brillante
    const Color(0xFF16A34A), // Verde Bosque
    const Color(0xFF14B8A6), // Menta/Teal
    const Color(0xFF0D9488), // Menta Oscura
    
    // Azules y Celestes (6)
    const Color(0xFF0284C7), // Azul Cielo
    const Color(0xFF0369A1), // Azul Océano
    const Color(0xFF3B82F6), // Azul Estándar
    const Color(0xFF2563EB), // Azul Real
    const Color(0xFF06B6D4), // Cian/Turquesa
    const Color(0xFF0891B2), // Turquesa Oscuro
    
    // Púrpuras, Violetas e Índigos (6)
    const Color(0xFF8B5CF6), // Violeta/Púrpura
    const Color(0xFF7C3AED), // Violeta Oscuro
    const Color(0xFF6366F1), // Índigo
    const Color(0xFF4F46E5), // Índigo Profundo
    const Color(0xFFA855F7), // Amatista
    const Color(0xFF86198F), // Púrpura Imperial
    
    // Rosas y Rojos (6)
    const Color(0xFFEC4899), // Rosa Vibrante
    const Color(0xFFD946EF), // Fucsia
    const Color(0xFFEF4444), // Rojo
    const Color(0xFFDC2626), // Rojo Crimson
    const Color(0xFFF43F5E), // Rosa Fuerte
    const Color(0xFFE11D48), // Rubí
    
    // Amarillos, Naranjas y Cafés (6)
    const Color(0xFFF59E0B), // Amarillo Oro
    const Color(0xFFD97706), // Ámbar
    const Color(0xFFEAB308), // Amarillo Limón
    const Color(0xFFF97316), // Naranja/Coral
    const Color(0xFFEA580C), // Naranja Quemado
    const Color(0xFF854D0E), // Café Bronce
  ];

  Color _getSuggestedLightShade(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(0.90).withSaturation(hsl.saturation.clamp(0.4, 0.75)).toColor();
  }

  Color _getSuggestedDarkShade(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(0.18).withSaturation(hsl.saturation.clamp(0.6, 0.9)).toColor();
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  SolidCardColors _getAccountColors(ModeloCuenta acc, bool esOscuro) {
    Color bg;
    Color text;
    if (acc.customColorHex != null && acc.customColorHex!.isNotEmpty) {
      bg = _parseHexColor(acc.customColorHex, const Color(0xFFC8E6C9));
      text = _parseHexColor(acc.customColorSecondaryHex, _getDarkShade(bg));
    } else {
      final index = acc.gradientIndex % _predefinedSchemes.length;
      bg = _predefinedSchemes[index].background;
      text = _predefinedSchemes[index].text;
    }

    if (esOscuro) {
      final hsl = HSLColor.fromColor(bg);
      bg = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    }
    return SolidCardColors(bg, text);
  }

  Color _getBottomBgColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();
  }

  Color _getDarkShade(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - 0.5).clamp(0.12, 0.35))
        .withSaturation((hsl.saturation + 0.2).clamp(0.6, 0.95))
        .toColor();
  }

  Widget _buildAccountFormView(EstadoApp estadoApp) {
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    
    final String liveName = _accountNameController.text.isEmpty ? 'Nombre de Cuenta' : _accountNameController.text;
    final double liveBalance = double.tryParse(_accountBalanceController.text) ?? 0.0;
    
    Color liveBgColor;
    Color liveTextColor;

    if (_useCustomColorForAccount) {
      liveBgColor = _parseHexColor(_selectedAccountColorHex, const Color(0xFFC8E6C9));
      liveTextColor = _parseHexColor(_selectedAccountSecondaryColorHex, const Color(0xFF0F5132));
    } else {
      final scheme = _predefinedSchemes[_selectedAccountGradientIdx % _predefinedSchemes.length];
      liveBgColor = scheme.background;
      liveTextColor = scheme.text;
    }

    if (esOscuro) {
      final hsl = HSLColor.fromColor(liveBgColor);
      liveBgColor = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'PREVISUALIZACION EN VIVO',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 165,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: esOscuro
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFCBD5E1).withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sección Superior
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: liveBgColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 5, bottom: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedAccountType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      color: liveTextColor.withValues(alpha: 0.75),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  // Switch decorativo
                                  Container(
                                    width: 24,
                                    height: 12,
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                      color: liveTextColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Align(
                                      alignment: _selectedAccountContabilizable
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: liveTextColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Chip de tarjeta de crédito
                                  Container(
                                    width: 16,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: liveTextColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 3,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 0.5,
                                            color: liveBgColor.withValues(alpha: 0.8),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 3,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 0.5,
                                            color: liveBgColor.withValues(alpha: 0.8),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          bottom: 0,
                                          left: 8,
                                          child: Container(
                                            width: 0.5,
                                            color: liveBgColor.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      liveName.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: liveTextColor,
                                        letterSpacing: -0.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Sección Inferior (Ligeramente más oscuro)
                      Container(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          color: _getBottomBgColor(liveBgColor),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          '${EstadoApp.getSymbolOfCurrency(_selectedAccountCurrency)} ${liveBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: liveTextColor,
                            letterSpacing: -0.3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'NOMBRE DE LA CUENTA',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _accountNameController,
          onChanged: (val) {
            setState(() {});
          },
          style: TextStyle(
            color: esOscuro ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Ej. Banco Mercantil Santa Cruz',
            hintStyle: TextStyle(
              color: esOscuro ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF0F172A).withValues(alpha: 0.3),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorPrincipal,
                width: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TIPO DE CUENTA',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: ['Efectivo', 'Débito', 'Ahorros', 'Crédito', 'Inversión'].contains(_selectedAccountType)
                        ? _selectedAccountType
                        : 'Ahorros',
                    dropdownColor: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
                    style: TextStyle(
                      color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    items: ['Efectivo', 'Débito', 'Ahorros', 'Crédito', 'Inversión']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedAccountType = val;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorPrincipal,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SALDO INICIAL',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _accountBalanceController,
                    onChanged: (val) {
                      setState(() {});
                    },
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      filled: true,
                      fillColor: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorPrincipal,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'MONEDA DE LA CUENTA',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: ['BOB', 'MXN', 'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'KRW', 'INR'].contains(_selectedAccountCurrency)
              ? _selectedAccountCurrency
              : 'BOB',
          dropdownColor: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
          style: TextStyle(
            color: esOscuro ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          items: const [
            DropdownMenuItem(value: 'BOB', child: Text('Boliviano (BOB)')),
            DropdownMenuItem(value: 'USD', child: Text('Dólar estadounidense (USD)')),
            DropdownMenuItem(value: 'MXN', child: Text('Peso mexicano (MXN)')),
            DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR)')),
            DropdownMenuItem(value: 'GBP', child: Text('Libra esterlina (GBP)')),
            DropdownMenuItem(value: 'JPY', child: Text('Yen japonés (JPY)')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedAccountCurrency = val;
              });
            }
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorPrincipal,
                width: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PERSONALIZAR COLORES DE LA TARJETA',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
              ),
            ),
            Switch.adaptive(
              value: _useCustomColorForAccount,
              activeThumbColor: colorPrincipal,
              onChanged: (val) {
                setState(() {
                  _useCustomColorForAccount = val;
                  if (val) {
                    // Inicializar con sugerencia a partir del color principal de la app
                    final suggestedBg = _getSuggestedLightShade(colorPrincipal);
                    final suggestedText = _getSuggestedDarkShade(colorPrincipal);
                    _selectedAccountColorHex = _colorToHex(suggestedBg);
                    _selectedAccountSecondaryColorHex = _colorToHex(suggestedText);
                    _selectedAccountUseDarkText = true;
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INCLUIR EN EL BALANCE TOTAL',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'El saldo de esta cuenta sumará al total global',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: esOscuro ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF0F172A).withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
            Switch.adaptive(
              value: _selectedAccountContabilizable,
              activeThumbColor: colorPrincipal,
              onChanged: (val) {
                setState(() {
                  _selectedAccountContabilizable = val;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_useCustomColorForAccount) ...[
          Text(
            'PALETA DE COLORES (SELECCIONAR COLOR PRINCIPAL)',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _basePaletteColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final baseColor = _basePaletteColors[index];
                return InteractiveScale(
                  onTap: () {
                    final sugBg = _getSuggestedLightShade(baseColor);
                    final sugText = _getSuggestedDarkShade(baseColor);
                    setState(() {
                      _selectedAccountColorHex = _colorToHex(sugBg);
                      _selectedAccountSecondaryColorHex = _colorToHex(sugText);
                      _selectedAccountUseDarkText = true;
                    });
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: baseColor.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PERSONALIZACIÓN MANUAL DE COLORES',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InteractiveScale(
                  onTap: () {
                    _mostrarSelectorColorManual(
                      context,
                      estadoApp,
                      titulo: 'Color de Fondo Superior',
                      colorHexActual: _selectedAccountColorHex,
                      onColorChanged: (hex) {
                        setState(() {
                          _selectedAccountColorHex = hex;
                        });
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: esOscuro ? const Color(0xFF1E1E1E) : Colors.black.withValues(alpha: 0.05),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _parseHexColor(_selectedAccountColorHex, Colors.white),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: esOscuro ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
                              width: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fondo Superior',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: esOscuro ? Colors.white70 : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedAccountColorHex.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InteractiveScale(
                  onTap: () {
                    _mostrarSelectorColorManual(
                      context,
                      estadoApp,
                      titulo: 'Color del Texto / Detalles',
                      colorHexActual: _selectedAccountSecondaryColorHex,
                      onColorChanged: (hex) {
                        setState(() {
                          _selectedAccountSecondaryColorHex = hex;
                        });
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: esOscuro ? const Color(0xFF1E1E1E) : Colors.black.withValues(alpha: 0.05),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _parseHexColor(_selectedAccountSecondaryColorHex, Colors.black),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: esOscuro ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
                              width: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Texto / Detalles',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: esOscuro ? Colors.white70 : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedAccountSecondaryColorHex.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ] else ...[
          Text(
            'COLOR PREDEFINIDO DE LA TARJETA',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _predefinedSchemes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final scheme = _predefinedSchemes[index];
                final isSelected = _selectedAccountGradientIdx == index;

                return InteractiveScale(
                  onTap: () {
                    setState(() {
                      _selectedAccountGradientIdx = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: scheme.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? (esOscuro ? Colors.white : const Color(0xFF0F172A))
                            : (esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFCBD5E1)),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: scheme.text,
                              size: 24,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class SolidCardColors {
  final Color background;
  final Color text;
  const SolidCardColors(this.background, this.text);
}

