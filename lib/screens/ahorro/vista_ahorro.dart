import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/estado_app.dart';
import '../../widgets/interactive_scale.dart';
import '../../widgets/hex_color_picker.dart';

class VistaAhorro extends StatefulWidget {
  const VistaAhorro({super.key});

  @override
  State<VistaAhorro> createState() => _VistaAhorroState();
}

class _VistaAhorroState extends State<VistaAhorro> {
  // Lista de iconos para elegir en objetivos de ahorro
  final List<Map<String, dynamic>> _iconosDisponibles = [
    {'code': 'savings_rounded', 'icon': Icons.savings_rounded},
    {'code': 'flight_rounded', 'icon': Icons.flight_rounded},
    {'code': 'directions_car_rounded', 'icon': Icons.directions_car_rounded},
    {'code': 'home_rounded', 'icon': Icons.home_rounded},
    {'code': 'laptop_mac_rounded', 'icon': Icons.laptop_mac_rounded},
    {'code': 'videogame_asset_rounded', 'icon': Icons.videogame_asset_rounded},
    {'code': 'favorite_rounded', 'icon': Icons.favorite_rounded},
    {'code': 'local_mall_rounded', 'icon': Icons.local_mall_rounded},
    {'code': 'school_rounded', 'icon': Icons.school_rounded},
    {'code': 'fitness_center_rounded', 'icon': Icons.fitness_center_rounded},
  ];

  IconData _getIconFromCode(String code) {
    final match = _iconosDisponibles.firstWhere(
      (item) => item['code'] == code,
      orElse: () => _iconosDisponibles[0],
    );
    return match['icon'];
  }

  Color _getPrimaryColor(EstadoApp estadoApp, bool esOscuro) {
    if (estadoApp.colorPrincipal.toARGB32() == Colors.white.toARGB32()) {
      return esOscuro ? Colors.white : const Color(0xFF0F172A);
    }
    return estadoApp.colorPrincipal;
  }

  void _showAddOrEditGoalSheet({ModeloAhorro? goalToEdit}) {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;

    final nameController = TextEditingController(text: goalToEdit?.name ?? '');
    final targetController = TextEditingController(
      text: goalToEdit != null ? goalToEdit.targetAmount.toStringAsFixed(0) : '2000',
    );
    final currentController = TextEditingController(
      text: goalToEdit != null ? goalToEdit.currentAmount.toStringAsFixed(0) : '0',
    );

    String selectedColorHex = goalToEdit?.hexColor ?? '#10B981';
    String selectedIconCode = goalToEdit?.iconCode ?? 'savings_rounded';
    DateTime? selectedTargetDate = goalToEdit?.targetDate;

    // FASE 6 variables
    String linkOption = 'ninguno';
    if (goalToEdit == null) {
      linkOption = 'crear';
    } else if (goalToEdit.linkedAccountId != null) {
      linkOption = 'existente';
    }

    ModeloCuenta? selectedAccountToLink;
    if (goalToEdit?.linkedAccountId != null) {
      final linkedAccs = estadoApp.accounts.where((acc) => acc.id == goalToEdit!.linkedAccountId);
      if (linkedAccs.isNotEmpty) {
        selectedAccountToLink = linkedAccs.first;
      }
    } else {
      if (estadoApp.accounts.isNotEmpty) {
        selectedAccountToLink = estadoApp.accounts[0];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: colorFondo.withValues(alpha: esOscuro ? 0.85 : 0.90),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 20,
                    right: 20,
                    top: 16,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorTexto.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          goalToEdit == null ? 'Nuevo Objetivo de Ahorro' : 'Editar Objetivo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colorTexto,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Nombre
                        Text(
                          'NOMBRE DEL OBJETIVO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: colorTexto.withValues(alpha: 0.4),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          style: TextStyle(color: colorTexto, fontSize: 14, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'e.g. Vacaciones en la playa',
                            hintStyle: TextStyle(color: colorTexto.withValues(alpha: 0.25)),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF')))),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Montos
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'META FINAL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: colorTexto.withValues(alpha: 0.4),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: targetController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: colorTexto, fontSize: 14, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      prefixText: 'Bs ',
                                      prefixStyle: TextStyle(color: colorTexto.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF')))),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AHORRADO ACTUAL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: colorTexto.withValues(alpha: 0.4),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  linkOption == 'existente'
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          child: Text(
                                            'Bs ${selectedAccountToLink?.balance.toStringAsFixed(2) ?? "0.00"}',
                                            style: TextStyle(
                                              color: colorTexto,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFeatures: const [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                        )
                                      : TextField(
                                          controller: currentController,
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(color: colorTexto, fontSize: 14, fontWeight: FontWeight.bold),
                                          decoration: InputDecoration(
                                            prefixText: 'Bs ',
                                            prefixStyle: TextStyle(color: colorTexto.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF')))),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // FASE 6: Vinculación Contable
                        Text(
                          'VINCULAR A CUENTA DE AHORROS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: colorTexto.withValues(alpha: 0.4),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            // Opción 1: Crear cuenta (solo al crear objetivo nuevo)
                            if (goalToEdit == null) ...[
                              _buildLinkOptionCard(
                                title: 'Crear nueva cuenta de ahorro',
                                subtitle: 'Crea una cuenta real "Ahorro: [Nombre]" con este color',
                                icon: Icons.add_to_photos_rounded,
                                isSelected: linkOption == 'crear',
                                colorPrincipal: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))),
                                colorTexto: colorTexto,
                                onTap: () {
                                  setSheetState(() {
                                    linkOption = 'crear';
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Opción 2: Cuenta existente
                            _buildLinkOptionCard(
                              title: 'Vincular a cuenta existente',
                              subtitle: 'Asociar a una cuenta existente que ya tienes',
                              icon: Icons.link_rounded,
                              isSelected: linkOption == 'existente',
                              colorPrincipal: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))),
                              colorTexto: colorTexto,
                              onTap: () {
                                setSheetState(() {
                                  linkOption = 'existente';
                                  if (estadoApp.accounts.isNotEmpty) {
                                    selectedAccountToLink = estadoApp.accounts[0];
                                    currentController.text = selectedAccountToLink!.balance.toStringAsFixed(0);
                                  }
                                });
                              },
                            ),
                            if (linkOption == 'existente') ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: colorTexto.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colorTexto.withValues(alpha: 0.08)),
                                ),
                                child: DropdownButtonFormField<ModeloCuenta>(
                                  value: selectedAccountToLink,
                                  dropdownColor: colorFondo,
                                  decoration: const InputDecoration(border: InputBorder.none),
                                  style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold, fontSize: 13),
                                  hint: Text('Selecciona una cuenta', style: TextStyle(color: colorTexto.withValues(alpha: 0.5), fontSize: 12)),
                                  items: estadoApp.accounts.map((acc) {
                                    return DropdownMenuItem<ModeloCuenta>(
                                      value: acc,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(acc.name),
                                          Text(
                                            ' (Bs ${acc.balance.toStringAsFixed(2)})',
                                            style: TextStyle(
                                              color: colorTexto.withValues(alpha: 0.5),
                                              fontWeight: FontWeight.normal,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setSheetState(() {
                                      selectedAccountToLink = val;
                                      if (val != null) {
                                        currentController.text = val.balance.toStringAsFixed(0);
                                      }
                                    });
                                  },
                                ),
                              ),
                              if (estadoApp.accounts.isEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'No tienes ninguna cuenta creada. Crea una primero.',
                                        style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                            const SizedBox(height: 8),
                            // Opción 3: No vincular
                            _buildLinkOptionCard(
                              title: 'No vincular (Solo representativo)',
                              subtitle: 'Meta informativa, sin repercusión en saldo real',
                              icon: Icons.cloud_off_rounded,
                              isSelected: linkOption == 'ninguno',
                              colorPrincipal: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))),
                              colorTexto: colorTexto,
                              onTap: () {
                                setSheetState(() {
                                  linkOption = 'ninguno';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Fecha Objetivo (Opcional)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FECHA LÍMITE (OPCIONAL)',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: colorTexto.withValues(alpha: 0.4),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedTargetDate == null
                                      ? 'Sin fecha límite'
                                      : '${selectedTargetDate!.day}/${selectedTargetDate!.month}/${selectedTargetDate!.year}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: selectedTargetDate == null ? colorTexto.withValues(alpha: 0.5) : colorTexto,
                                  ),
                                ),
                              ],
                            ),
                            InteractiveScale(
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedTargetDate ?? now.add(const Duration(days: 30)),
                                  firstDate: now,
                                  lastDate: now.add(const Duration(days: 3650)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))),
                                          surface: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
                                          onPrimary: Colors.white,
                                          onSurface: colorTexto,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setSheetState(() {
                                    selectedTargetDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorTexto.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Seleccionar',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorTexto),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Selector de Icono
                        Text(
                          'SELECCIONAR ICONO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: colorTexto.withValues(alpha: 0.4),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _iconosDisponibles.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final item = _iconosDisponibles[idx];
                              final isSelected = selectedIconCode == item['code'];
                              final accentColor = Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF')));

                              return InteractiveScale(
                                onTap: () {
                                  setSheetState(() {
                                    selectedIconCode = item['code'];
                                  });
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected ? accentColor.withValues(alpha: 0.15) : colorTexto.withValues(alpha: 0.04),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? accentColor : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    item['icon'],
                                    color: isSelected ? accentColor : colorTexto.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // HSV Color Picker
                        HexColorPicker(
                          currentColorHex: selectedColorHex,
                          onColorChanged: (hex) {
                            setSheetState(() {
                              selectedColorHex = hex;
                            });
                          },
                          esOscuro: esOscuro,
                          colorPrincipal: estadoApp.colorPrincipal,
                        ),
                        const SizedBox(height: 32),

                        // Guardar/Crear
                        InteractiveScale(
                          onTap: () async {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor, ingresa un nombre para el objetivo.'),
                                  backgroundColor: Colors.orangeAccent,
                                ),
                              );
                              return;
                            }

                            final double targetVal = double.tryParse(targetController.text) ?? 2000.0;
                            final double currentVal = double.tryParse(currentController.text) ?? 0.0;

                            String? linkedId;
                            if (goalToEdit == null) {
                              if (linkOption == 'crear') {
                                // Crear cuenta de ahorros real
                                final newAcc = await estadoApp.addAccount(
                                  "Ahorro: ${nameController.text.trim()}",
                                  "Ahorros",
                                  currentVal,
                                  0,
                                  customColorHex: selectedColorHex,
                                );
                                linkedId = newAcc.id;
                              } else if (linkOption == 'existente') {
                                linkedId = selectedAccountToLink?.id;
                              }

                              final newGoal = ModeloAhorro(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: nameController.text.trim(),
                                targetAmount: targetVal,
                                currentAmount: currentVal,
                                startDate: DateTime.now(),
                                targetDate: selectedTargetDate,
                                hexColor: selectedColorHex,
                                iconCode: selectedIconCode,
                                linkedAccountId: linkedId,
                              );
                              estadoApp.addSavingGoal(newGoal);
                            } else {
                              if (linkOption == 'existente') {
                                linkedId = selectedAccountToLink?.id;
                              } else if (linkOption == 'ninguno') {
                                linkedId = null;
                              } else {
                                linkedId = goalToEdit.linkedAccountId;
                              }

                              final updatedGoal = ModeloAhorro(
                                id: goalToEdit.id,
                                name: nameController.text.trim(),
                                targetAmount: targetVal,
                                currentAmount: currentVal,
                                startDate: goalToEdit.startDate,
                                targetDate: selectedTargetDate,
                                hexColor: selectedColorHex,
                                iconCode: selectedIconCode,
                                linkedAccountId: linkedId,
                              );
                              estadoApp.updateSavingGoal(updatedGoal);
                            }

                            if (mounted) Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                goalToEdit == null ? 'Crear Objetivo' : 'Guardar Cambios',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddFundsSheet(ModeloAhorro goal) {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;

    final amountController = TextEditingController(text: '100');
    
    // Filtrar la lista de cuentas origen: excluimos la cuenta vinculada para no transferir a sí misma
    final cuentasOrigenValidas = estadoApp.accounts.where((acc) => acc.id != goal.linkedAccountId).toList();
    ModeloCuenta? cuentaSeleccionada = cuentasOrigenValidas.isNotEmpty ? cuentasOrigenValidas[0] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final double valorAportar = double.tryParse(amountController.text) ?? 0.0;
            final double saldoDisp = cuentaSeleccionada?.balance ?? 0.0;
            final bool sinSaldoSuficiente = valorAportar > saldoDisp;

            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: colorFondo.withValues(alpha: esOscuro ? 0.85 : 0.90),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 20,
                    right: 20,
                    top: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorTexto.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Aportar Fondos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: colorTexto,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.linkedAccountId != null
                            ? 'Registra un aporte. El dinero se transferirá a la cuenta de ahorros vinculada.'
                            : 'Registra un aporte para tu objetivo "${goal.name}".',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorTexto.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Monto a Aportar
                      Text(
                        'MONTO A APORTAR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: colorTexto.withValues(alpha: 0.4),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: TextStyle(color: colorTexto, fontSize: 16, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixText: 'Bs ',
                          prefixStyle: TextStyle(color: colorTexto.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(int.parse(goal.hexColor.replaceFirst('#', '0xFF')))),
                          ),
                        ),
                        onChanged: (val) {
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 20),

                      // Seleccionar Cuenta Origen
                      Text(
                        goal.linkedAccountId != null ? 'CUENTA DE ORIGEN (DÉBITO)' : 'DÉBITO DE CUENTA (SÓLO VIRTUAL)',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: colorTexto.withValues(alpha: 0.4),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      cuentasOrigenValidas.isEmpty
                          ? Text(
                              goal.linkedAccountId != null
                                  ? 'No tienes otras cuentas para transferir fondos. El aporte será un depósito directo.'
                                  : 'No tienes cuentas creadas. El aporte será meramente representativo.',
                              style: TextStyle(fontSize: 11, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: colorTexto.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorTexto.withValues(alpha: 0.08)),
                              ),
                              child: DropdownButtonFormField<ModeloCuenta>(
                                value: cuentaSeleccionada,
                                dropdownColor: colorFondo,
                                decoration: const InputDecoration(border: InputBorder.none),
                                style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold, fontSize: 13),
                                items: cuentasOrigenValidas.map((acc) {
                                  return DropdownMenuItem<ModeloCuenta>(
                                    value: acc,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(acc.name),
                                        Text(
                                          ' (Bs ${acc.balance.toStringAsFixed(2)})',
                                          style: TextStyle(
                                            color: colorTexto.withValues(alpha: 0.5),
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setSheetState(() {
                                    cuentaSeleccionada = val;
                                  });
                                },
                              ),
                            ),
                      if (cuentaSeleccionada != null && sinSaldoSuficiente) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Saldo insuficiente en la cuenta seleccionada.',
                              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),

                      // Botón Aportar
                      InteractiveScale(
                        onTap: () {
                          final double montoAportar = double.tryParse(amountController.text) ?? 0.0;
                          if (montoAportar <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor, ingresa un monto válido mayor a 0.'),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                            return;
                          }

                          if (goal.linkedAccountId != null) {
                            if (cuentaSeleccionada != null) {
                              if (sinSaldoSuficiente) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No tienes saldo suficiente en la cuenta seleccionada.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              // Registrar una TRANSFERENCIA real en la contabilidad
                              estadoApp.addTransaction(
                                title: 'Aporte: ${goal.name}',
                                description: 'Aporte transferido al objetivo',
                                amount: montoAportar,
                                category: 'Ahorro',
                                type: 'transferencia',
                                accountId: cuentaSeleccionada!.id,
                                toAccountId: goal.linkedAccountId!,
                              );
                            } else {
                              // Depósito directo a la cuenta de ahorros vinculada
                              estadoApp.addTransaction(
                                title: 'Aporte: ${goal.name}',
                                description: 'Aporte directo sin cuenta de origen',
                                amount: montoAportar,
                                category: 'Ahorro',
                                type: 'ingreso',
                                accountId: goal.linkedAccountId!,
                              );
                            }
                          }

                          // Actualizar la meta de ahorro en preferencias
                          estadoApp.addFundsToSavingGoal(goal.id, montoAportar);

                          Navigator.pop(context);
                          
                          // Mostrar mensaje de éxito premium
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('¡Aporte de Bs ${montoAportar.toStringAsFixed(2)} registrado con éxito!'),
                              backgroundColor: Color(int.parse(goal.hexColor.replaceFirst('#', '0xFF'))),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Color(int.parse(goal.hexColor.replaceFirst('#', '0xFF'))),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Confirmar Aporte',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(ModeloAhorro goal) {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorFondo = esOscuro ? const Color(0xFF0E0E0E) : Colors.white;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: colorFondo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            title: Text(
              '¿Eliminar Objetivo?',
              style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold),
            ),
            content: Text(
              '¿Estás seguro de que deseas eliminar el objetivo "${goal.name}"? Los fondos ahorrados no se reintegrarán a tus cuentas reales de forma automática.',
              style: TextStyle(color: colorTexto.withValues(alpha: 0.7), fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar', style: TextStyle(color: colorTexto.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  estadoApp.deleteSavingGoal(goal.id);
                  Navigator.pop(context);
                },
                child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorFondo = esOscuro ? const Color(0xFF000000) : const Color(0xFFF8FAFC);

    final double totalAhorrado = estadoApp.savingsGoals.fold(0.0, (sum, item) => sum + item.currentAmount);
    final double totalObjetivos = estadoApp.savingsGoals.fold(0.0, (sum, item) => sum + item.targetAmount);
    final double porcentajeAhorro = totalObjetivos > 0 ? (totalAhorrado / totalObjetivos) * 100 : 0.0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colorFondo,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objetivos de Ahorro',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: colorTexto,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Construye tu futuro paso a paso.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorTexto.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                InteractiveScale(
                  onTap: () => _showAddOrEditGoalSheet(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: estadoApp.colorPrincipal.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: _getPrimaryColor(estadoApp, esOscuro),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bento de Resumen Total de Ahorros
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: esOscuro ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: esOscuro ? 0.20 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FONDO DE AHORRO ACUMULADO',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: colorTexto.withValues(alpha: 0.45),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${porcentajeAhorro.toStringAsFixed(0)}% Completado',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bs ${totalAhorrado.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: colorTexto,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Meta combinada de Bs ${totalObjetivos.toStringAsFixed(0)} en ${estadoApp.savingsGoals.length} objetivos.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorTexto.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Linear progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        value: totalObjetivos > 0 ? (totalAhorrado / totalObjetivos) : 0.0,
                        backgroundColor: colorTexto.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(_getPrimaryColor(estadoApp, esOscuro)),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),
            const SizedBox(height: 24),

            Text(
              'MIS OBJETIVOS ACTIVOS',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: colorTexto.withValues(alpha: 0.45),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            // Empty State
            if (estadoApp.savingsGoals.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: esOscuro ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: estadoApp.colorPrincipal.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.savings_rounded, color: _getPrimaryColor(estadoApp, esOscuro), size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sin objetivos de ahorro',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorTexto),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Crea una meta de ahorro (por ejemplo: "Laptop nueva" o "Vacaciones") y realiza aportes directos desde tus cuentas para alcanzarla.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: colorTexto.withValues(alpha: 0.45), height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    InteractiveScale(
                      onTap: () => _showAddOrEditGoalSheet(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: estadoApp.colorPrincipal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Crear mi primer objetivo',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            ] else ...[
              // Grid de metas de ahorro Bento
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: estadoApp.savingsGoals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final goal = estadoApp.savingsGoals[index];
                  final accentColor = Color(int.parse(goal.hexColor.replaceFirst('#', '0xFF')));
                  final double pct = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
                  final double pctClamped = pct.clamp(0.0, 1.0);
                  
                  int? diasRestantes;
                  if (goal.targetDate != null) {
                    diasRestantes = goal.targetDate!.difference(DateTime.now()).inDays;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: esOscuro ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  _getIconFromCode(goal.iconCode),
                                  color: accentColor,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: colorTexto,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    diasRestantes == null
                                        ? 'Progreso continuo'
                                        : (diasRestantes <= 0 ? '¡Plazo cumplido!' : 'Faltan $diasRestantes días'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: diasRestantes != null && diasRestantes <= 0
                                          ? Colors.redAccent
                                          : colorTexto.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Menú de opciones (Tres puntos discretos)
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, color: colorTexto.withValues(alpha: 0.4), size: 18),
                              color: esOscuro ? const Color(0xFF0A0A0A) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              style: const ButtonStyle(
                                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                              ),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showAddOrEditGoalSheet(goalToEdit: goal);
                                } else if (val == 'delete') {
                                  _showDeleteConfirmation(goal);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, color: colorTexto.withValues(alpha: 0.6), size: 16),
                                      const SizedBox(width: 8),
                                      Text('Editar', style: TextStyle(color: colorTexto, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                      const SizedBox(width: 8),
                                      const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Balance / Monto
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AHORRADO',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: colorTexto.withValues(alpha: 0.35),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Bs ${goal.currentAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: colorTexto,
                                    letterSpacing: -0.3,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'OBJETIVO',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: colorTexto.withValues(alpha: 0.35),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Bs ${goal.targetAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colorTexto.withValues(alpha: 0.6),
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Progress Indicator
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  height: 6,
                                  child: LinearProgressIndicator(
                                    value: pctClamped,
                                    backgroundColor: colorTexto.withValues(alpha: 0.04),
                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(pct * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Botón Aportar Fondos rápido
                        InteractiveScale(
                          onTap: () => _showAddFundsSheet(goal),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_upward_rounded, color: accentColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Aportar Fondos',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
            ],
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color colorPrincipal,
    required Color colorTexto,
    required VoidCallback onTap,
  }) {
    return InteractiveScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorPrincipal.withValues(alpha: 0.08) : colorTexto.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorPrincipal : colorTexto.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorPrincipal : colorTexto.withValues(alpha: 0.5),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorTexto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: colorTexto.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: colorPrincipal,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
