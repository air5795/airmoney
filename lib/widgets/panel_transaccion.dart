import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/estado_app.dart';
import '../helpers/asistente_voz_helper.dart';
import 'toast_ios.dart';
import 'interactive_scale.dart';

class PanelTransaccion extends StatefulWidget {
  final ModeloTransaccion? transaccion;
  final bool iniciarConVoz;

  const PanelTransaccion({
    super.key,
    this.transaccion,
    this.iniciarConVoz = false,
  });

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

  // Variables del Asistente de Voz
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  // Galería de iconos que coincide con la de Ajustes para pintar el dropdown
  static final Map<String, IconData> _galleryIcons = {
    'restaurant': Icons.restaurant_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'directions_car': Icons.directions_car_rounded,
    'work': Icons.work_rounded,
    'electrical_services': Icons.electrical_services_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'category': Icons.category_rounded,
    'movie': Icons.movie_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'home': Icons.home_rounded,
    'flight': Icons.flight_rounded,
    'pets': Icons.pets_rounded,
    'school': Icons.school_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'savings': Icons.savings_rounded,
    'phone_android': Icons.phone_android_rounded,
    'celebration': Icons.celebration_rounded,
    'water_drop': Icons.water_drop_rounded,
    'router': Icons.router_rounded,
    'tv': Icons.tv_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'build': Icons.build_rounded,
    'payments': Icons.payments_rounded,
    'laptop': Icons.laptop_chromebook_rounded,
    'trending_up': Icons.trending_up_rounded,
    'directions_bus': Icons.directions_bus_rounded,
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    int initialIndex = 0;
    if (widget.transaccion != null) {
      if (widget.transaccion!.type == 'ingreso') {
        initialIndex = 1;
      } else if (widget.transaccion!.type == 'transferencia') {
        initialIndex = 2;
      }
    }
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      setState(() {
        // Actualiza el color dinámico y controles al cambiar de tipo
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final estadoApp = Provider.of<EstadoApp>(context, listen: false);
      
      if (widget.transaccion != null) {
        final tx = widget.transaccion!;
        setState(() {
          _titleController.text = tx.title;
          _amountController.text = tx.amount.toStringAsFixed(2);
          _commentController.text = tx.description;
          _selectedAccountId = tx.accountId;
          _selectedToAccountId = tx.toAccountId;
          _selectedCategory = tx.category;
          _selectedDate = tx.date;
          _simulatedPhotoPath = tx.photoPath;
        });
      } else {
        if (estadoApp.accounts.isNotEmpty) {
          setState(() {
            _selectedAccountId = estadoApp.accounts.first.id;
            if (estadoApp.accounts.length > 1) {
              _selectedToAccountId = estadoApp.accounts[1].id;
            } else {
              _selectedToAccountId = estadoApp.accounts.first.id;
            }
            if (estadoApp.categories.isNotEmpty) {
              _selectedCategory = estadoApp.categories.first.name;
            }
          });
        }
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

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) => debugPrint('Error de voz: $val'),
        onStatus: (val) {
          debugPrint('Estado de voz: $val');
          if (val == 'done' || val == 'notListening') {
            if (_isListening) {
              setState(() {
                _isListening = false;
              });
              _procesarVozResult(_lastWords);
            }
          }
        },
      );
      setState(() {});
      if (widget.iniciarConVoz && _speechEnabled) {
        _startListening();
      }
    } catch (e) {
      debugPrint('Error inicializando voz: $e');
    }
  }

  void _startListening() async {
    _lastWords = '';
    setState(() {
      _isListening = true;
    });
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
        if (result.finalResult == true) {
          _procesarVozResult(_lastWords);
        }
      },
      listenOptions: SpeechListenOptions(localeId: 'es_ES'),
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    _procesarVozResult(_lastWords);
  }

  void _procesarVozResult(String frase) {
    if (frase.trim().isEmpty) {
      setState(() {
        _isListening = false;
      });
      return;
    }

    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final res = AsistenteVozHelper.procesarFrase(frase, estadoApp.accounts, estadoApp.categories);

    setState(() {
      if (res.titulo != null) _titleController.text = res.titulo!;
      if (res.importe != null) _amountController.text = res.importe!.toStringAsFixed(2);
      if (res.tipo != null) {
        if (res.tipo == 'ingreso') {
          _tabController.index = 1;
        } else if (res.tipo == 'transferencia') {
          _tabController.index = 2;
        } else {
          _tabController.index = 0;
        }
      }
      if (res.accountId != null) _selectedAccountId = res.accountId;
      if (res.toAccountId != null) _selectedToAccountId = res.toAccountId;
      if (res.categoria != null && res.tipo != 'transferencia') {
        _selectedCategory = res.categoria!;
      }
      _isListening = false;
    });

    ToastHelper.showInfo(context, 'Asistente: Rellenado "$frase"');
  }

  // Obtener el color dinámico basado en el tipo de transacción seleccionado
  Color _getTipoColor() {
    switch (_tabController.index) {
      case 0:
        return const Color(0xFFEF4444); // Gasto -> Rojo
      case 1:
        return const Color(0xFF10B981); // Ingreso -> Verde
      case 2:
        return const Color(0xFF3B82F6); // Transferencia -> Azul
      default:
        return const Color(0xFFEF4444);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final Color colorTipo = _getTipoColor();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorTipo,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF0F172A),
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
      ToastHelper.showError(context, 'El importe debe ser mayor a 0.');
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
        ToastHelper.showError(context, 'La cuenta de destino debe ser diferente a la de origen.');
        return;
      }
    }

    final String successMessage;
    if (widget.transaccion != null) {
      estadoApp.updateTransaction(
        id: widget.transaccion!.id,
        title: title,
        description: comment,
        amount: amount,
        category: _tabController.index == 2 ? 'Transferencia' : _selectedCategory,
        type: type,
        accountId: _selectedAccountId!,
        toAccountId: type == 'transferencia' ? _selectedToAccountId : null,
        photoPath: _simulatedPhotoPath,
        date: _selectedDate,
      );
      successMessage = 'Movimiento actualizado con éxito';
    } else {
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
      successMessage = 'Movimiento registrado con éxito';
    }

    Navigator.pop(context);
    
    ToastHelper.showSuccess(context, successMessage);
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final size = MediaQuery.of(context).size;
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorTipo = _getTipoColor();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: size.height * 0.9,
          decoration: BoxDecoration(
            color: esOscuro
                ? const Color(0xFF0A0A0A).withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.80),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: esOscuro
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.70),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: _formKey,
            child: Stack(
              children: [
                Column(
                  children: [
                const SizedBox(height: 8),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorTexto.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.transaccion != null ? 'Editar movimiento' : 'Registrar movimiento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colorTexto,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (widget.transaccion == null && _speechEnabled)
                      GestureDetector(
                        onTap: _startListening,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorTipo.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorTipo.withValues(alpha: 0.25),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            Icons.mic_none_rounded,
                            color: colorTipo,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Pestanas dinamicas en capsula Liquid Glass
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      width: 1.0,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: colorTipo,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorTipo.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: colorTexto.withValues(alpha: 0.5),
                    labelStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(text: 'Gasto'),
                      Tab(text: 'Ingreso'),
                      Tab(text: 'Transferencia'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('TÍTULO', esOscuro),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorTexto,
                          ),
                          decoration: _buildInputDecoration('Ej. Almuerzo familiar', esOscuro, colorTipo),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un título';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel('IMPORTE', esOscuro),
                        const SizedBox(height: 8),
                        
                        // Input de Importe interactivo
                        GestureDetector(
                          onTap: () => _showCalculatorBottomSheet(esOscuro, colorTexto, colorTipo),
                          child: AbsBottomKeyboard(
                            child: TextFormField(
                              controller: _amountController,
                              enabled: false, // Bloquear el teclado normal
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorTexto,
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colorTexto.withValues(alpha: 0.25),
                                ),
                                prefixIcon: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  margin: const EdgeInsets.only(right: 12, left: 4),
                                  decoration: BoxDecoration(
                                    color: colorTipo.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorTipo.withValues(alpha: 0.2),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    'Bs ${estadoApp.selectedCurrency}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: colorTipo,
                                    ),
                                  ),
                                ),
                                suffixIcon: Icon(
                                  Icons.calculate_rounded,
                                  color: colorTipo,
                                  size: 24,
                                ),
                                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                filled: true,
                                fillColor: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty || double.tryParse(value) == 0.0) {
                                  return 'Por favor ingresa un importe válido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Selector de cuentas redondeado
                        if (_tabController.index == 2) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('ORIGEN', esOscuro),
                                    const SizedBox(height: 8),
                                    _buildAccountSelectorCard(
                                      accountId: _selectedAccountId,
                                      accounts: estadoApp.accounts,
                                      onSelected: (val) {
                                        setState(() {
                                          _selectedAccountId = val;
                                        });
                                      },
                                      esOscuro: esOscuro,
                                      colorTexto: colorTexto,
                                      colorTipo: colorTipo,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('DESTINO', esOscuro),
                                    const SizedBox(height: 8),
                                    _buildAccountSelectorCard(
                                      accountId: _selectedToAccountId,
                                      accounts: estadoApp.accounts,
                                      onSelected: (val) {
                                        setState(() {
                                          _selectedToAccountId = val;
                                        });
                                      },
                                      esOscuro: esOscuro,
                                      colorTexto: colorTexto,
                                      colorTipo: colorTipo,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildLabel(_tabController.index == 0 ? 'CUENTA ORIGEN' : 'CUENTA DESTINO', esOscuro),
                          const SizedBox(height: 8),
                          _buildAccountSelectorCard(
                            accountId: _selectedAccountId,
                            accounts: estadoApp.accounts,
                            onSelected: (val) {
                              setState(() {
                                _selectedAccountId = val;
                              });
                            },
                            esOscuro: esOscuro,
                            colorTexto: colorTexto,
                            colorTipo: colorTipo,
                          ),
                        ],
                        const SizedBox(height: 20),
                        
                        // Selector de categorias redondeado
                        if (_tabController.index != 2) ...[
                          _buildLabel('CATEGORÍA', esOscuro),
                          const SizedBox(height: 8),
                          _buildCategorySelectorCard(
                            selectedCategoryName: _selectedCategory,
                            categories: estadoApp.categories,
                            onSelected: (val) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            },
                            esOscuro: esOscuro,
                            colorTexto: colorTexto,
                            colorTipo: colorTipo,
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        _buildLabel('FECHA', esOscuro),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colorTexto,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: colorTipo,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel('COMENTARIO', esOscuro),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _commentController,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorTexto,
                          ),
                          decoration: _buildInputDecoration('Ej. Pago de la cena de cumple...', esOscuro, colorTipo),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel('FOTO ADJUNTA', esOscuro),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _simulatedPhotoPath = 'photo_simulated_path.jpg';
                            });
                            ToastHelper.showInfo(context, 'Foto simulada adjuntada correctamente');
                          },
                          child: Container(
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _simulatedPhotoPath != null
                                    ? const Color(0xFF10B981)
                                    : (esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                                width: 1.0,
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
                                        ? const Color(0xFF10B981)
                                        : colorTexto.withValues(alpha: 0.4),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _simulatedPhotoPath != null
                                        ? 'Foto cargada con éxito'
                                        : 'Agregar foto',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _simulatedPhotoPath != null
                                          ? const Color(0xFF10B981)
                                          : colorTexto.withValues(alpha: 0.5),
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
                
                // Boton de registrar en capsula premium
                Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InteractiveScale(
                    onTap: _submitTransaction,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorTipo,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: colorTipo.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.transaccion != null ? 'Guardar cambios' : 'Registrar movimiento',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.transaccion != null)
                  Container(
                    width: double.infinity,
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InteractiveScale(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text('Eliminar Movimiento', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: const Text('Confirmas que deseas eliminar este movimiento de forma permanente? El saldo de la cuenta se restaurara.'),
                              actions: [
                                TextButton(
                                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  onPressed: () => Navigator.pop(dialogContext),
                                ),
                                TextButton(
                                  child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    estadoApp.deleteTransaction(widget.transaccion!.id);
                                    Navigator.pop(context);
                                    
                                    ToastHelper.showSuccess(context, 'Movimiento eliminado con éxito');
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: esOscuro ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Eliminar movimiento',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
                if (_isListening)
                  Positioned.fill(
                    child: _buildListeningOverlay(colorTexto, colorTipo),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool esOscuro) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: esOscuro ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF0F172A).withValues(alpha: 0.45),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, bool esOscuro, Color colorTipo) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: esOscuro ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF0F172A).withValues(alpha: 0.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorTipo, width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
    );
  }

  // --- Selector de Cuentas Premium ---
  Widget _buildAccountSelectorCard({
    required String? accountId,
    required List<ModeloCuenta> accounts,
    required ValueChanged<String?> onSelected,
    required bool esOscuro,
    required Color colorTexto,
    required Color colorTipo,
  }) {
    final activeAccount = accounts.firstWhere((a) => a.id == accountId, orElse: () => ModeloCuenta(id: '', name: 'No seleccionada', balance: 0.0, gradientIndex: 0, type: ''));
    final isSelected = activeAccount.id.isNotEmpty;

    return InteractiveScale(
      onTap: () => _showAccountSelectorBottomSheet(accounts, accountId, onSelected, esOscuro, colorTexto, colorTipo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorTipo.withValues(alpha: 0.5) : (esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? colorTipo.withValues(alpha: 0.08) : (esOscuro ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorTipo.withValues(alpha: 0.2) : Colors.transparent,
                  width: 1.0,
                ),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: isSelected ? colorTipo : colorTexto.withValues(alpha: 0.5),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeAccount.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: colorTexto,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 1),
                    Text(
                      '${activeAccount.type} • Bs ${activeAccount.balance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorTexto.withValues(alpha: 0.45),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorTexto.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountSelectorBottomSheet(
    List<ModeloCuenta> accounts,
    String? selectedId,
    ValueChanged<String?> onSelected,
    bool esOscuro,
    Color colorTexto,
    Color colorTipo,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: colorFondo.withValues(alpha: esOscuro ? 0.85 : 0.90),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: esOscuro ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.65),
                    width: 1.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorTexto.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seleccionar Cuenta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorTexto,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: colorTexto.withValues(alpha: 0.5)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final acc = accounts[idx];
                        final isAct = acc.id == selectedId;

                        return GestureDetector(
                          onTap: () {
                            onSelected(acc.id);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isAct 
                                  ? colorTipo.withValues(alpha: 0.08)
                                  : (esOscuro ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isAct ? colorTipo : (esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: colorTipo.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorTipo.withValues(alpha: 0.2),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_rounded,
                                    color: colorTipo,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: colorTexto,
                                        ),
                                      ),
                                      Text(
                                        acc.type,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: colorTexto.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Bs ${acc.balance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                if (isAct) ...[
                                  const SizedBox(width: 10),
                                  Icon(Icons.check_circle_rounded, color: colorTipo, size: 20),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Selector de Categorías Premium ---
  Widget _buildCategorySelectorCard({
    required String selectedCategoryName,
    required List<ModeloCategoria> categories,
    required ValueChanged<String> onSelected,
    required bool esOscuro,
    required Color colorTexto,
    required Color colorTipo,
  }) {
    final activeCat = categories.firstWhere(
      (cat) => cat.name.toLowerCase() == selectedCategoryName.toLowerCase(),
      orElse: () => ModeloCategoria(id: '', name: selectedCategoryName, iconCode: 'bubble_chart', hexColor: '#FFCC80'),
    );
    final catColor = Color(int.parse(activeCat.hexColor.replaceFirst('#', '0xFF')));

    return InteractiveScale(
      onTap: () => _showCategorySelectorBottomSheet(categories, selectedCategoryName, onSelected, esOscuro, colorTexto, colorTipo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: catColor.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  _galleryIcons[activeCat.iconCode] ?? Icons.bubble_chart_rounded,
                  color: catColor,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeCat.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: colorTexto,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    activeCat.parentId == null ? 'Categoría Principal' : 'Subcategoría',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorTexto.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorTexto.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategorySelectorBottomSheet(
    List<ModeloCategoria> categories,
    String currentCategoryName,
    ValueChanged<String> onSelected,
    bool esOscuro,
    Color colorTexto,
    Color colorTipo,
  ) {
    final parentCategories = categories.where((cat) => cat.parentId == null).toList();
    final subcategoriesMap = <String, List<ModeloCategoria>>{};
    for (var cat in categories) {
      if (cat.parentId != null) {
        subcategoriesMap.putIfAbsent(cat.parentId!, () => []).add(cat);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;
        final Set<String> expandedParentIds = {}; // Cerrados por defecto

        return StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: colorFondo.withValues(alpha: esOscuro ? 0.85 : 0.90),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: esOscuro ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.65),
                        width: 1.0,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorTexto.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seleccionar Categoría',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: colorTexto.withValues(alpha: 0.5)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: parentCategories.length,
                          itemBuilder: (context, idx) {
                            final parent = parentCategories[idx];
                            final children = subcategoriesMap[parent.id] ?? [];
                            final hasChildren = children.isNotEmpty;
                            final isExpanded = expandedParentIds.contains(parent.id);
                            final isParentActive = parent.name.toLowerCase() == currentCategoryName.toLowerCase();
                            final parentColor = Color(int.parse(parent.hexColor.replaceFirst('#', '0xFF')));

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isParentActive
                                        ? parentColor.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            onSelected(parent.name);
                                            Navigator.pop(context);
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 34,
                                                  height: 34,
                                                  decoration: BoxDecoration(
                                                    color: parentColor.withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: parentColor.withValues(alpha: 0.25),
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      _galleryIcons[parent.iconCode] ?? Icons.bubble_chart_rounded,
                                                      color: parentColor,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    parent.name,
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: colorTexto,
                                                    ),
                                                  ),
                                                ),
                                                if (isParentActive)
                                                  Icon(Icons.check_circle_rounded, color: parentColor, size: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (hasChildren)
                                        GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              if (expandedParentIds.contains(parent.id)) {
                                                expandedParentIds.remove(parent.id);
                                              } else {
                                                expandedParentIds.add(parent.id);
                                              }
                                            });
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            child: Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_up_rounded
                                                  : Icons.keyboard_arrow_down_rounded,
                                              color: colorTexto.withValues(alpha: 0.5),
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (hasChildren && isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 28, bottom: 8),
                                    child: Column(
                                      children: children.map((child) {
                                        final isChildActive = child.name.toLowerCase() == currentCategoryName.toLowerCase();
                                        final childColor = Color(int.parse(child.hexColor.replaceFirst('#', '0xFF')));

                                        return GestureDetector(
                                          onTap: () {
                                            onSelected(child.name);
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 2),
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: isChildActive
                                                  ? childColor.withValues(alpha: 0.08)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: childColor.withValues(alpha: 0.08),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: childColor.withValues(alpha: 0.20),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      _galleryIcons[child.iconCode] ?? Icons.bubble_chart_rounded,
                                                      color: childColor,
                                                      size: 13,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    child.name,
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w500,
                                                      color: colorTexto.withValues(alpha: 0.85),
                                                    ),
                                                  ),
                                                ),
                                                if (isChildActive)
                                                  Icon(Icons.check_circle_rounded, color: childColor, size: 18),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            );
                          },
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

  // --- Calculadora Táctil Premium ---
  void _showCalculatorBottomSheet(bool esOscuro, Color colorTexto, Color colorTipo) {
    String currentExpr = _amountController.text.trim();
    if (currentExpr == '0.00' || currentExpr == '0') currentExpr = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void calcPress(String val) {
              setModalState(() {
                if (val == 'C') {
                  currentExpr = '';
                } else if (val == 'DEL') {
                  if (currentExpr.isNotEmpty) {
                    currentExpr = currentExpr.substring(0, currentExpr.length - 1);
                  }
                } else if (val == '=') {
                  try {
                    currentExpr = _evaluateExpression(currentExpr);
                  } catch (e) {
                    currentExpr = 'Error';
                  }
                } else if (val == 'LISTO') {
                  try {
                    final evaluated = _evaluateExpression(currentExpr);
                    final parsed = double.tryParse(evaluated) ?? 0.0;
                    _amountController.text = parsed.toStringAsFixed(2);
                  } catch (e) {
                    _amountController.text = '0.00';
                  }
                  Navigator.pop(context);
                } else {
                  if (currentExpr.isNotEmpty && 
                      ['+', '-', '*', '/'].contains(val) && 
                      ['+', '-', '*', '/'].contains(currentExpr.substring(currentExpr.length - 1))) {
                    currentExpr = currentExpr.substring(0, currentExpr.length - 1) + val;
                  } else {
                    currentExpr += val;
                  }
                }
              });
            }

            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorFondo.withValues(alpha: esOscuro ? 0.85 : 0.90),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: esOscuro ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.65),
                        width: 1.0,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorTexto.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ingresar Importe',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorTexto.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Pantalla de la calculadora redondeada
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: esOscuro ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Text(
                            currentExpr.isEmpty ? '0.00' : currentExpr,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Teclado 4x5 de la calculadora en burbujas ovaladas
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.3,
                        children: [
                          _buildCalcButton('C', Colors.redAccent, calcPress, esOscuro),
                          _buildCalcButton('DEL', Colors.orangeAccent, calcPress, esOscuro),
                          _buildCalcButton('%', colorTipo, calcPress, esOscuro),
                          _buildCalcButton('/', colorTipo, calcPress, esOscuro),
                          
                          _buildCalcButton('7', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('8', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('9', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('*', colorTipo, calcPress, esOscuro),
                          
                          _buildCalcButton('4', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('5', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('6', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('-', colorTipo, calcPress, esOscuro),
                          
                          _buildCalcButton('1', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('2', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('3', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('+', colorTipo, calcPress, esOscuro),
                          
                          _buildCalcButton('0', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('.', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('=', Colors.blueAccent, calcPress, esOscuro),
                          _buildCalcButton('LISTO', const Color(0xFF10B981), calcPress, esOscuro, isBig: true),
                        ],
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
 
  Widget _buildCalcButton(
    String label,
    Color color,
    ValueChanged<String> onPress,
    bool esOscuro, {
    bool isNum = false,
    bool isBig = false,
  }) {
    final Color buttonColor = isNum
        ? (esOscuro ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9))
        : color.withValues(alpha: 0.08);
    final Color fontColor = color;

    return InteractiveScale(
      onTap: () => onPress(label),
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: label == 'LISTO' ? 12 : 18,
            fontWeight: FontWeight.bold,
            color: fontColor,
          ),
        ),
      ),
    );
  }

  // Utilidad simple para evaluar expresiones matematicas basicas (+, -, *, /, %)
  String _evaluateExpression(String expr) {
    if (expr.isEmpty) return '0';
    
    // Remplazar % por /100 de forma manual
    String cleanExpr = expr.replaceAll('%', '/100');
    
    // Evaluador de tokens basico de suma, resta, multiplicacion y division
    try {
      // Dart no tiene un evaluador nativo, asi que podemos hacer un parser muy robusto paso a paso
      // Primero multiplicaciones y divisiones, luego sumas y restas
      final double result = _parseExprSum(cleanExpr);
      if (result.isInfinite || result.isNaN) return '0.00';
      return result.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), ''); // Quitar ceros redundantes
    } catch (e) {
      return 'Error';
    }
  }

  double _parseExprSum(String expr) {
    final parts = expr.split('+');
    double sum = 0;
    for (var part in parts) {
      if (part.contains('-')) {
        final subparts = part.split('-');
        double diff = _parseExprMul(subparts[0]);
        for (int i = 1; i < subparts.length; i++) {
          diff -= _parseExprMul(subparts[i]);
        }
        sum += diff;
      } else {
        sum += _parseExprMul(part);
      }
    }
    return sum;
  }

  double _parseExprMul(String expr) {
    final parts = expr.split('*');
    double prod = 1;
    for (var part in parts) {
      if (part.contains('/')) {
        final subparts = part.split('/');
        double div = double.tryParse(subparts[0]) ?? 0;
        for (int i = 1; i < subparts.length; i++) {
          final val = double.tryParse(subparts[i]) ?? 1.0;
          div /= val == 0 ? 1.0 : val;
        }
        prod *= div;
      } else {
        prod *= double.tryParse(part) ?? 0.0;
      }
    }
    return prod;
  }

  Widget _buildListeningOverlay(Color colorTexto, Color colorTipo) {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final esOscuro = estadoApp.esTemaOscuro;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: (esOscuro ? Colors.black : Colors.white).withValues(alpha: 0.75),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicador de estado de escucha
              Text(
                'Escuchando...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorTexto,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _lastWords.isEmpty ? 'Di algo como: "Gasto 50 Bs en comida para la cena"' : _lastWords,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorTexto.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // Animacion de ondas Siri-style usando flutter_animate
              SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    // Genera ondas acrilicas vibrando con delay
                    final List<Color> siriColors = [
                      const Color(0xFF3B82F6), // Azul
                      const Color(0xFF10B981), // Verde
                      const Color(0xFFEF4444), // Rojo
                      const Color(0xFF8B5CF6), // Morado
                      const Color(0xFFF59E0B), // Naranja
                    ];
                    final color = siriColors[index % siriColors.length];
                    final baseHeight = 30.0 + (index * 10);
                    
                    return Container(
                      width: 8,
                      height: baseHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scaleY(
                      begin: 0.3,
                      end: 1.5,
                      duration: Duration(milliseconds: 400 + (index * 100)),
                      curve: Curves.easeInOut,
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 48),
              // Boton para detener y procesar
              GestureDetector(
                onTap: _stopListening,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorTipo,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorTipo.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Listo, Procesar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
    );
  }
}

// Widget auxiliar para bloquear teclado del sistema
class AbsBottomKeyboard extends StatelessWidget {
  final Widget child;
  const AbsBottomKeyboard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: null,
        child: child,
      ),
    );
  }
}
