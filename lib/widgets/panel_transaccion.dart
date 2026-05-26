import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/estado_app.dart';

class PanelTransaccion extends StatefulWidget {
  const PanelTransaccion({super.key});

  @override
  State<PanelTransaccion> createState() => _PanelTransaccionState();
}

class _PanelTransaccionState extends State<PanelTransaccion> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String _selectedCategory = 'Comida';
  DateTime _selectedDate = DateTime.now();
  String? _simulatedPhotoPath;

  final List<String> _categories = [
    'Comida',
    'Salario',
    'Transporte',
    'Servicios',
    'Entretenimiento',
    'Educación',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Actualiza el formulario al cambiar de pestaña
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final estadoApp = Provider.of<EstadoApp>(context, listen: false);
      if (estadoApp.accounts.isNotEmpty) {
        setState(() {
          _selectedAccountId = estadoApp.accounts.first.id;
          if (estadoApp.accounts.length > 1) {
            _selectedToAccountId = estadoApp.accounts[1].id;
          } else {
            _selectedToAccountId = estadoApp.accounts.first.id;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final comment = _commentController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El importe debe ser mayor a 0.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedAccountId == null) return;

    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    String type = 'gasto';
    if (_tabController.index == 1) {
      type = 'ingreso';
    } else if (_tabController.index == 2) {
      type = 'transferencia';
      if (_selectedAccountId == _selectedToAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cuenta de destino debe ser diferente a la de origen.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    estadoApp.addTransaction(
      title: title,
      description: comment,
      amount: amount,
      category: _tabController.index == 2 ? 'Transferencia' : _selectedCategory,
      type: type,
      accountId: _selectedAccountId!,
      toAccountId: type == 'transferencia' ? _selectedToAccountId : null,
      photoPath: _simulatedPhotoPath,
    );

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Movimiento registrado con exito'),
        backgroundColor: const Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final size = MediaQuery.of(context).size;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: size.height * 0.85,
          color: Colors.white.withOpacity(0.92),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Linea superior indicadora de BottomSheet
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Registrar movimiento',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Pestañas (Tabs)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF0F172A).withOpacity(0.55),
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: 'Gasto'),
                      Tab(text: 'Ingreso'),
                      Tab(text: 'Transferencia'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Campos del Formulario
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITULO DEL MOVIMIENTO
                        _buildLabel('TITULO'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: _buildInputDecoration('Ej. Almuerzo familiar'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un titulo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        // IMPORTE
                        _buildLabel('IMPORTE'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A).withOpacity(0.2),
                            ),
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              margin: const EdgeInsets.only(right: 12, left: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Bs ${estadoApp.selectedCurrency}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un importe';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // LOGICA DE CUENTAS (SEGUN TAB SELECCIONADO)
                        if (_tabController.index == 2) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('ORIGEN'),
                                    const SizedBox(height: 8),
                                    _buildAccountDropdown(
                                      value: _selectedAccountId,
                                      accounts: estadoApp.accounts,
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedAccountId = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('DESTINO'),
                                    const SizedBox(height: 8),
                                    _buildAccountDropdown(
                                      value: _selectedToAccountId,
                                      accounts: estadoApp.accounts,
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedToAccountId = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildLabel(_tabController.index == 0 ? 'CUENTA ORIGEN' : 'CUENTA DESTINO'),
                          const SizedBox(height: 8),
                          _buildAccountDropdown(
                            value: _selectedAccountId,
                            accounts: estadoApp.accounts,
                            onChanged: (val) {
                              setState(() {
                                _selectedAccountId = val;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 18),

                        // CATEGORIA (SOLO PARA INGRESO Y GASTO)
                        if (_tabController.index != 2) ...[
                          _buildLabel('CATEGORIA'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                                items: _categories.map((cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat,
                                    child: Text(cat),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedCategory = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // FECHA
                        _buildLabel('FECHA'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: const Color(0xFF0F172A).withOpacity(0.5),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // COMENTARIO
                        _buildLabel('COMENTARIO'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _commentController,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: _buildInputDecoration('Ej. Pago de la cena de cumple...'),
                        ),
                        const SizedBox(height: 18),

                        // AGREGAR FOTO
                        _buildLabel('FOTO ADJUNTA'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _simulatedPhotoPath = 'photo_simulated_path.jpg';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Foto simulada adjuntada correctamente'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            height: 70,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _simulatedPhotoPath != null
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _simulatedPhotoPath != null
                                        ? Icons.check_circle_rounded
                                        : Icons.camera_alt_rounded,
                                    color: _simulatedPhotoPath != null
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFF0F172A).withOpacity(0.4),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _simulatedPhotoPath != null
                                        ? 'Foto cargada con éxito'
                                        : 'Agregar foto',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _simulatedPhotoPath != null
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFF0F172A).withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
                // BOTON REGISTRAR
                Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: _submitTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Registrar movimiento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: const Color(0xFF0F172A).withOpacity(0.5),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0F172A).withOpacity(0.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String? value,
    required List<ModeloCuenta> accounts,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
          dropdownColor: Colors.white,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          items: accounts.map((acc) {
            return DropdownMenuItem<String>(
              value: acc.id,
              child: Text('${acc.name} (${acc.type}) - Bs ${acc.balance.toStringAsFixed(2)}'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
