import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/hex_color_picker.dart';
import '../../../widgets/interactive_scale.dart';

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

  static final List<String> _strongColorsEnd = [
    '#311B92', // Purpura Oscuro
    '#0D47A1', // Azul Profundo
    '#006064', // Cian Oscuro
    '#1B5E20', // Verde Oscuro
    '#E65100', // Naranja Oscuro
    '#B71C1C', // Rojo Oscuro
    '#880E4F', // Magenta Oscuro
    '#CFD8DC', // Plata Metalico
    '#00E5FF', // Cian Electrico
    '#A7FFEB', // Turquesa Claro
    '#FFE082', // Oro Claro
    '#F8BBD0', // Rosa Suave
    '#C8E6C9', // Verde Menta Suave
    '#B3E5FC', // Azul Glaciar
    '#D1C4E9', // Purpura Pastel
    '#FFCCBC', // Naranja Coral Suave
    '#0097A7', // Cian Profundo
    '#00796B', // Verde Azulado
    '#3E2723', // Marron Chocolate
    '#263238', // Gris Carbon
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountBalanceController.dispose();
    super.dispose();
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
                        ? Colors.white.withValues(alpha: 0.08)
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
            
            Color colorInicio;
            Color colorFin;
            if (acc.customColorHex != null && acc.customColorHex!.isNotEmpty) {
              colorInicio = _parseHexColor(acc.customColorHex, const Color(0xFFB3E5FC));
              final secondaryHex = acc.customColorSecondaryHex ?? acc.customColorHex!;
              colorFin = _parseHexColor(secondaryHex, const Color(0xFFE2E8F0));
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
                padding: const EdgeInsets.all(16),
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
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                  child: Row(
                    children: [
                       ClipRRect(
                         borderRadius: BorderRadius.circular(10),
                         child: Container(
                           width: 48,
                           height: 34,
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: [colorInicio, colorFin],
                               begin: Alignment.topLeft,
                               end: Alignment.bottomRight,
                             ),
                             borderRadius: BorderRadius.circular(10),
                             border: Border.all(
                               color: Colors.white.withValues(alpha: 0.35),
                               width: 1.0,
                             ),
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
                                 color: cardContentColor,
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
                                       fontSize: 7.5,
                                       fontWeight: FontWeight.w900,
                                       color: cardContentColor,
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
                                       color: cardContentColor.withValues(alpha: 0.5),
                                     ),
                                   ),
                                 ),
                                 Text(
                                   '${EstadoApp.getSymbolOfCurrency(acc.currency ?? estadoApp.selectedCurrency)} ${acc.balance.toStringAsFixed(2)}',
                                   style: TextStyle(
                                     fontSize: 12.5,
                                     fontWeight: FontWeight.w900,
                                     color: cardContentColor,
                                     letterSpacing: -0.3,
                                     fontFeatures: const [FontFeature.tabularFigures()],
                                   ),
                                 ),
                               ],
                             ),
                           ],
                         ),
                       ),
                      Row(
                        children: [
                          InteractiveScale(
                            onTap: () {
                              // Asignar texto a los controladores fuera de setState para prevenir conflictos de listeners recurrentes
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
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cardContentColor.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cardContentColor.withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: cardContentColor,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                      InteractiveScale(
                        onTap: () async {
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
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cardContentColor.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cardContentColor.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: cardContentColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}

  void _mostrarDisenadorDegradado(BuildContext context, EstadoApp estadoApp, {int inicialTab = 0}) {
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    int currentTab = inicialTab;
    
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
            
            final String liveName = _accountNameController.text.isEmpty ? 'Nombre de Cuenta' : _accountNameController.text;
            final double liveBalance = double.tryParse(_accountBalanceController.text) ?? 0.0;
            
            final colorInicio = _parseHexColor(_selectedAccountColorHex, const Color(0xFFB3E5FC));
            final colorFin = _parseHexColor(_selectedAccountSecondaryColorHex, const Color(0xFFE2E8F0));
            final bgColors = [
              colorInicio.withValues(alpha: 0.95),
              colorFin.withValues(alpha: 0.95),
            ];
            final cardContentColor = _selectedAccountUseDarkText ? const Color(0xFF0F172A) : Colors.white;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: screenHeight * 0.88,
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
                        ? Colors.white.withValues(alpha: 0.10)
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diseñador de Degradados',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: colorTexto,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'PERSONALIZA LA APARIENCIA DE TU TARJETA',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: colorTexto.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorTexto.withValues(alpha: 0.6),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 260,
                          height: 150,
                          padding: const EdgeInsets.all(18),
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
                                      _selectedAccountType.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: cardContentColor,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: cardContentColor.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: const Offset(-6, 0),
                                        child: Container(
                                          width: 16,
                                          height: 16,
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
                                    liveName.toUpperCase(),
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
                                    'Bs ${liveBalance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: cardContentColor,
                                      letterSpacing: -0.3,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: esOscuro 
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: esOscuro ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: InteractiveScale(
                              onTap: () {
                                setDialogState(() {
                                  currentTab = 0;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  color: currentTab == 0
                                      ? colorPrincipal
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: currentTab == 0
                                      ? [
                                          BoxShadow(
                                            color: colorPrincipal.withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Color de Inicio',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: currentTab == 0
                                        ? Colors.white
                                        : colorTexto.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InteractiveScale(
                              onTap: () {
                                setDialogState(() {
                                  currentTab = 1;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  color: currentTab == 1
                                      ? colorPrincipal
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: currentTab == 1
                                      ? [
                                          BoxShadow(
                                            color: colorPrincipal.withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Color de Fin',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: currentTab == 1
                                        ? Colors.white
                                        : colorTexto.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: KeyedSubtree(
                                key: ValueKey<int>(currentTab),
                                child: HexColorPicker(
                                  currentColorHex: currentTab == 0 
                                      ? _selectedAccountColorHex 
                                      : _selectedAccountSecondaryColorHex,
                                  onColorChanged: (hex) {
                                    setDialogState(() {
                                      if (currentTab == 0) {
                                        _selectedAccountColorHex = hex;
                                      } else {
                                        _selectedAccountSecondaryColorHex = hex;
                                      }
                                    });
                                    setState(() {
                                      if (currentTab == 0) {
                                        _selectedAccountColorHex = hex;
                                      } else {
                                        _selectedAccountSecondaryColorHex = hex;
                                      }
                                    });
                                  },
                                  esOscuro: esOscuro,
                                  colorPrincipal: colorPrincipal,
                                  customColors: currentTab == 0 
                                      ? _strongColorsStart 
                                      : _strongColorsEnd,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24, top: 12),
                      child: InteractiveScale(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: colorPrincipal,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: colorPrincipal.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Guardar Degradado',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAccountFormView(EstadoApp estadoApp) {
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    
    final String liveName = _accountNameController.text.isEmpty ? 'Nombre de Cuenta' : _accountNameController.text;
    final double liveBalance = double.tryParse(_accountBalanceController.text) ?? 0.0;
    
    List<Color> bgColors;
    Color colorInicio;
    if (_useCustomColorForAccount) {
      colorInicio = _parseHexColor(_selectedAccountColorHex, const Color(0xFFB3E5FC));
      final colorFin = _parseHexColor(_selectedAccountSecondaryColorHex, const Color(0xFFE2E8F0));
      bgColors = [
        colorInicio.withValues(alpha: 0.95),
        colorFin.withValues(alpha: 0.95),
      ];
    } else {
      final grad = _cardGradients[_selectedAccountGradientIdx % _cardGradients.length];
      colorInicio = grad[0];
      bgColors = [
        colorInicio.withValues(alpha: 0.95),
        grad[1].withValues(alpha: 0.95),
      ];
    }
    final cardContentColor = _selectedAccountUseDarkText ? const Color(0xFF0F172A) : Colors.white;

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
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 260,
                  height: 150,
                  padding: const EdgeInsets.all(18),
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
                                _selectedAccountType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: cardContentColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cardContentColor.withValues(alpha: 0.35),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(-6, 0),
                                  child: Container(
                                    width: 16,
                                    height: 16,
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
                              liveName.toUpperCase(),
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
                              '${EstadoApp.getSymbolOfCurrency(_selectedAccountCurrency)} ${liveBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: cardContentColor,
                                letterSpacing: -0.3,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
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
              'DISEÑAR DEGRADADO PERSONALIZADO',
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
              'USAR TEXTO OSCURO (ALTO CONTRASTE)',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
              ),
            ),
            Switch.adaptive(
              value: _selectedAccountUseDarkText,
              activeThumbColor: colorPrincipal,
              onChanged: (val) {
                setState(() {
                  _selectedAccountUseDarkText = val;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_useCustomColorForAccount) ...[
          Text(
            'DISEÑO DEL DEGRADADO',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: esOscuro
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: esOscuro
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      InteractiveScale(
                        onTap: () => _mostrarDisenadorDegradado(context, estadoApp, inicialTab: 0),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _parseHexColor(_selectedAccountColorHex, const Color(0xFFB3E5FC)),
                                border: Border.all(
                                  color: esOscuro ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.15),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _parseHexColor(_selectedAccountColorHex, const Color(0xFFB3E5FC)).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.colorize_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedAccountColorHex.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: esOscuro ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF0F172A).withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: LinearGradient(
                                    colors: [
                                      _parseHexColor(_selectedAccountColorHex, const Color(0xFFB3E5FC)),
                                      _parseHexColor(_selectedAccountSecondaryColorHex, const Color(0xFFE2E8F0)),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: esOscuro ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Degradado Activo',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: esOscuro ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF0F172A).withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InteractiveScale(
                        onTap: () => _mostrarDisenadorDegradado(context, estadoApp, inicialTab: 1),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _parseHexColor(_selectedAccountSecondaryColorHex, const Color(0xFFE2E8F0)),
                                border: Border.all(
                                  color: esOscuro ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.15),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _parseHexColor(_selectedAccountSecondaryColorHex, const Color(0xFFE2E8F0)).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.colorize_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedAccountSecondaryColorHex.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: esOscuro ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF0F172A).withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InteractiveScale(
                    onTap: () => _mostrarDisenadorDegradado(context, estadoApp, inicialTab: 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colorPrincipal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorPrincipal.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.palette_rounded,
                            color: colorPrincipal,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Personalizar Colores',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorPrincipal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          Text(
            'GRADIENTE PREDEFINIDO DE LA TARJETA',
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
              itemCount: _cardGradients.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final grad = _cardGradients[index];
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
                      gradient: LinearGradient(
                        colors: grad,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? (esOscuro ? Colors.white : const Color(0xFF0F172A))
                             : (esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFCBD5E1)),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(
              child: InteractiveScale(
                onTap: () {
                  setState(() {
                    _isCreatingOrEditingAccount = false;
                    _selectedAccountToEdit = null;
                    _selectedAccountUseDarkText = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: esOscuro ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFCBD5E1),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: esOscuro ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF0F172A).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: InteractiveScale(
                onTap: () {
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
                      useDarkText: _selectedAccountUseDarkText,
                      currency: _selectedAccountCurrency,
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
                      useDarkText: _selectedAccountUseDarkText,
                      currency: _selectedAccountCurrency,
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
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: colorPrincipal,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Text(
                      'Guardar Cuenta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
