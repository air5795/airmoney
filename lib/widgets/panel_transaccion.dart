import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/estado_app.dart';
import '../helpers/asistente_voz_helper.dart';
import 'toast_ios.dart';
import 'interactive_scale.dart';
import 'hex_color_picker.dart';

class PanelTransaccion extends StatefulWidget {
  final ModeloTransaccion? transaccion;
  final bool iniciarConVoz;
  final bool esPlanificacion;

  const PanelTransaccion({
    super.key,
    this.transaccion,
    this.iniciarConVoz = false,
    this.esPlanificacion = false,
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

  // Variables de Planificación
  bool _esProgramada = false;
  bool _pagada = true;
  String _selectedRecurrencia = 'una_vez';

  // Variables del Asistente de Voz
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  // Galería de iconos que coincide con la de Ajustes para pintar el dropdown
  static final Map<String, IconData> _galleryIcons = EstadoApp.galleryIcons;

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
          _esProgramada = tx.esProgramada;
          _pagada = tx.pagada;
          _selectedRecurrencia = tx.recurrencia ?? 'una_vez';
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
            if (widget.esPlanificacion) {
              _esProgramada = true;
              _pagada = false;
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
      if (res.fecha != null) {
        _selectedDate = res.fecha!;
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

  List<ModeloTransaccion> _getPredictiveSuggestions(String currentType, String query) {
    final transactions = Provider.of<EstadoApp>(context, listen: false).transactions;
    final filtered = transactions.where((tx) => tx.type == currentType).toList();
    
    // Count frequency of each title
    final Map<String, int> frequencies = {};
    final Map<String, ModeloTransaccion> lastTxForTitle = {};
    for (var tx in filtered) {
      if (tx.title.trim().isEmpty) continue;
      final titleLower = tx.title.trim().toLowerCase();
      frequencies[titleLower] = (frequencies[titleLower] ?? 0) + 1;
      
      if (!lastTxForTitle.containsKey(titleLower) || tx.date.isAfter(lastTxForTitle[titleLower]!.date)) {
        lastTxForTitle[titleLower] = tx;
      }
    }

    var titles = lastTxForTitle.keys.toList();
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      titles = titles.where((t) => t.contains(q)).toList();
    }

    // Sort by frequency descending
    titles.sort((a, b) => (frequencies[b] ?? 0).compareTo(frequencies[a] ?? 0));

    return titles.take(5).map((t) => lastTxForTitle[t]!).toList();
  }

  void _selectSuggestion(ModeloTransaccion tx) {
    setState(() {
      _titleController.text = tx.title;
      if (tx.type != 'transferencia') {
        _selectedCategory = tx.category;
      }
      if (tx.amount > 0) {
        _amountController.text = tx.amount.toStringAsFixed(2);
      }
      final accounts = Provider.of<EstadoApp>(context, listen: false).accounts;
      if (accounts.any((acc) => acc.id == tx.accountId)) {
        _selectedAccountId = tx.accountId;
      }
      if (tx.type == 'transferencia' && tx.toAccountId != null && accounts.any((acc) => acc.id == tx.toAccountId)) {
        _selectedToAccountId = tx.toAccountId;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final Color colorTipo = _getTipoColor();
    final lang = estadoApp.selectedLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;
        DateTime tempDate = _selectedDate;
        int viewYear = tempDate.year;
        int viewMonth = tempDate.month;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final isEs = lang.toLowerCase() == 'es';
            final monthNames = isEs
                ? ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']
                : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
            
            final weekdays = isEs
                ? ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
                : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

            final firstDayOfMonth = DateTime(viewYear, viewMonth, 1);
            final daysInMonth = DateTime(viewYear, viewMonth + 1, 0).day;
            final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
            
            final prevMonthDaysCount = firstWeekday - 1;
            final prevMonthYear = viewMonth == 1 ? viewYear - 1 : viewYear;
            final prevMonthVal = viewMonth == 1 ? 12 : viewMonth - 1;
            final daysInPrevMonth = DateTime(prevMonthYear, prevMonthVal + 1, 0).day;
            
            final List<DateTime> gridDays = [];
            for (int i = prevMonthDaysCount - 1; i >= 0; i--) {
              gridDays.add(DateTime(prevMonthYear, prevMonthVal, daysInPrevMonth - i));
            }
            for (int i = 1; i <= daysInMonth; i++) {
              gridDays.add(DateTime(viewYear, viewMonth, i));
            }
            int nextDay = 1;
            final nextMonthYear = viewMonth == 12 ? viewYear + 1 : viewYear;
            final nextMonthVal = viewMonth == 12 ? 1 : viewMonth + 1;
            while (gridDays.length < 42) {
              gridDays.add(DateTime(nextMonthYear, nextMonthVal, nextDay++));
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEs ? 'Seleccionar Fecha' : 'Select Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempDate = DateTime.now();
                                viewYear = tempDate.year;
                                viewMonth = tempDate.month;
                              });
                            },
                            child: Text(
                              isEs ? 'Hoy' : 'Today',
                              style: TextStyle(
                                color: colorTipo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Fila de control de mes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left_rounded, color: colorTexto),
                            onPressed: () {
                              setModalState(() {
                                if (viewMonth == 1) {
                                  viewMonth = 12;
                                  viewYear--;
                                } else {
                                  viewMonth--;
                                }
                              });
                            },
                          ),
                          Text(
                            '${monthNames[viewMonth - 1]} $viewYear',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right_rounded, color: colorTexto),
                            onPressed: () {
                              setModalState(() {
                                if (viewMonth == 12) {
                                  viewMonth = 1;
                                  viewYear++;
                                } else {
                                  viewMonth++;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Cabeceras de días de la semana
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: weekdays.map((day) {
                          return SizedBox(
                            width: 32,
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: colorTexto.withValues(alpha: 0.4),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      // Grid de días
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: 42,
                        itemBuilder: (context, index) {
                          final date = gridDays[index];
                          final isCurrentMonth = date.month == viewMonth;
                          final isSelected = date.year == tempDate.year &&
                              date.month == tempDate.month &&
                              date.day == tempDate.day;
                          final isToday = date.year == DateTime.now().year &&
                              date.month == DateTime.now().month &&
                              date.day == DateTime.now().day;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                tempDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  tempDate.hour,
                                  tempDate.minute,
                                  tempDate.second,
                                );
                                viewYear = tempDate.year;
                                viewMonth = tempDate.month;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorTipo
                                    : (isToday ? colorTipo.withValues(alpha: 0.08) : Colors.transparent),
                                shape: BoxShape.circle,
                                border: isToday && !isSelected
                                    ? Border.all(color: colorTipo, width: 1.2)
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isCurrentMonth
                                          ? colorTexto
                                          : colorTexto.withValues(alpha: 0.25)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, color: colorTexto.withValues(alpha: 0.6), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                isEs ? 'Hora:' : 'Time:',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: colorTexto.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(tempDate),
                                builder: (BuildContext context, Widget? child) {
                                  return Theme(
                                    data: ThemeData(
                                      colorScheme: ColorScheme.fromSeed(
                                        seedColor: colorTipo,
                                        brightness: esOscuro ? Brightness.dark : Brightness.light,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() {
                                  tempDate = DateTime(
                                    tempDate.year,
                                    tempDate.month,
                                    tempDate.day,
                                    picked.hour,
                                    picked.minute,
                                    tempDate.second,
                                  );
                                });
                              }
                            },
                            icon: Icon(Icons.edit_rounded, color: colorTipo, size: 14),
                            label: Text(
                              '${tempDate.hour.toString().padLeft(2, '0')}:${tempDate.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: colorTipo,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              isEs ? 'Cancelar' : 'Cancel',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedDate = tempDate;
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              isEs ? 'Aceptar' : 'OK',
                              style: TextStyle(
                                color: colorTipo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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

  Future<void> _selectTime(BuildContext context) async {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final esOscuro = estadoApp.esTemaOscuro;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _getTipoColor(),
              brightness: esOscuro ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
          _selectedDate.second,
        );
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
    final bool esProgramada = _esProgramada;
    final bool pagada = _esProgramada ? _pagada : true;
    final String? recurrencia = _esProgramada ? _selectedRecurrencia : null;

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
        esProgramada: esProgramada,
        pagada: pagada,
        recurrencia: recurrencia,
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
        date: _selectedDate,
        esProgramada: esProgramada,
        pagada: pagada,
        recurrencia: recurrencia,
      );
      successMessage = 'Movimiento registrado con éxito';
    }

    Navigator.pop(context);
    
    ToastHelper.showSuccess(context, successMessage);
  }

  Widget _buildRecurrenciaChip(String code, String label, bool esOscuro, Color colorTipo) {
    final isSelected = _selectedRecurrencia == code;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRecurrencia = code;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorTipo.withValues(alpha: esOscuro ? 0.20 : 0.12)
              : (esOscuro ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colorTipo
                : (esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
            width: 1.0,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? colorTipo : colorTexto.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final size = MediaQuery.of(context).size;
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorTipo = _getTipoColor();

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final baseHeight = widget.transaccion != null
        ? (size.height * 0.82).clamp(620.0, 780.0)
        : (size.height * 0.78).clamp(580.0, 700.0);

    String type = 'gasto';
    if (_tabController.index == 1) {
      type = 'ingreso';
    } else if (_tabController.index == 2) {
      type = 'transferencia';
    }

    final activeAcc = estadoApp.accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
      orElse: () => estadoApp.accounts.isNotEmpty ? estadoApp.accounts.first : ModeloCuenta(id: '', name: '', type: '', balance: 0.0, gradientIndex: 0),
    );
    final activeCurrency = activeAcc.currency ?? estadoApp.selectedCurrency;
    final activeSymbol = EstadoApp.getSymbolOfCurrency(activeCurrency);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: baseHeight + keyboardHeight,
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
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: 8 + keyboardHeight,
          ),
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
                
                if (!widget.esPlanificacion) ...[
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
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Gasto'))),
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Ingreso'))),
                        Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Transferencia'))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila 1: Título
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('TÍTULO', esOscuro),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _titleController,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorTexto,
                              ),
                              decoration: _buildInputDecoration('Ej. Almuerzo familiar', esOscuro, colorTipo).copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa un título';
                                }
                                return null;
                              },
                            ),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _titleController,
                              builder: (context, value, child) {
                                final suggestions = _getPredictiveSuggestions(type, value.text);
                                if (suggestions.isEmpty) return const SizedBox.shrink();
                                
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: suggestions.map((tx) {
                                        return GestureDetector(
                                          onTap: () => _selectSuggestion(tx),
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: colorTipo.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: colorTipo.withValues(alpha: 0.2),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.history_rounded,
                                                  size: 12,
                                                  color: colorTipo.withValues(alpha: 0.6),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  tx.title,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorTexto.withValues(alpha: 0.85),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Fila 2: Importe
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('IMPORTE ($activeSymbol)', esOscuro),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _showCalculatorBottomSheet(esOscuro, colorTexto, colorTipo),
                              child: AbsBottomKeyboard(
                                child: TextFormField(
                                  controller: _amountController,
                                  enabled: false,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colorTexto,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: colorTexto.withValues(alpha: 0.25),
                                    ),
                                    suffixIcon: Icon(
                                      Icons.calculate_rounded,
                                      color: colorTipo,
                                      size: 18,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                      return 'Requerido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Fila 2: Cuenta y Categoría / Cuentas Origen-Destino
                        if (widget.esPlanificacion) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CATEGORÍA', esOscuro),
                              const SizedBox(height: 4),
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
                                compacto: false,
                              ),
                            ],
                          ),
                        ] else if (_tabController.index == 2) ...[
                          // ORIGEN
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('ORIGEN', esOscuro),
                              const SizedBox(height: 4),
                              _buildHorizontalAccountSelector(
                                selectedAccountId: _selectedAccountId,
                                accounts: estadoApp.accounts,
                                onSelected: (val) {
                                  setState(() {
                                    _selectedAccountId = val;
                                  });
                                },
                                esOscuro: esOscuro,
                                colorTipo: colorTipo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // DESTINO
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('DESTINO', esOscuro),
                              const SizedBox(height: 4),
                              _buildHorizontalAccountSelector(
                                selectedAccountId: _selectedToAccountId,
                                accounts: estadoApp.accounts,
                                onSelected: (val) {
                                  setState(() {
                                    _selectedToAccountId = val;
                                  });
                                },
                                esOscuro: esOscuro,
                                colorTipo: colorTipo,
                              ),
                            ],
                          ),
                        ] else ...[
                          // CUENTA
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(_tabController.index == 0 ? 'CUENTA ORIGEN' : 'CUENTA DESTINO', esOscuro),
                              const SizedBox(height: 4),
                              _buildHorizontalAccountSelector(
                                selectedAccountId: _selectedAccountId,
                                accounts: estadoApp.accounts,
                                onSelected: (val) {
                                  setState(() {
                                    _selectedAccountId = val;
                                  });
                                },
                                esOscuro: esOscuro,
                                colorTipo: colorTipo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // CATEGORÍA
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CATEGORÍA', esOscuro),
                              const SizedBox(height: 4),
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
                                compacto: false,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        
                        // Fila 3: Fecha y Foto
                        if (widget.esPlanificacion) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('FECHA', esOscuro),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                      Expanded(
                                        child: Text(
                                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year} • ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: colorTexto,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        color: colorTipo,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ] else ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('FECHA', esOscuro),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                      Expanded(
                                        child: Text(
                                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year} • ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: colorTexto,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        color: colorTipo,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // FOTO ADJUNTA
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('FOTO ADJUNTA', esOscuro),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _simulatedPhotoPath = 'photo_simulated_path.jpg';
                                  });
                                  ToastHelper.showInfo(context, 'Foto simulada adjuntada correctamente');
                                },
                                child: Container(
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _simulatedPhotoPath != null
                                              ? 'Foto cargada'
                                              : 'Agregar foto',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _simulatedPhotoPath != null
                                                ? const Color(0xFF10B981)
                                                : colorTexto.withValues(alpha: 0.5),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Fila 4: Comentario
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('COMENTARIO', esOscuro),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _commentController,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: colorTexto,
                                ),
                                decoration: _buildInputDecoration('Ej. Pago de la cena...', esOscuro, colorTipo).copyWith(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                        
                        // Planificación mensual y transacciones programadas
                        if (widget.esPlanificacion || (widget.transaccion != null && widget.transaccion!.esProgramada)) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: esOscuro ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: esOscuro ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          color: colorTipo,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'PLANIFICACIÓN',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: colorTexto.withValues(alpha: 0.7),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorTipo.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'PROGRAMADA',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: colorTipo,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(
                                  color: esOscuro ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                                  height: 1,
                                ),
                                const SizedBox(height: 10),
                                if (!widget.esPlanificacion) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Marcar como pagado hoy',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: colorTexto,
                                        ),
                                      ),
                                      Switch(
                                        value: _pagada,
                                        activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                                        activeThumbColor: const Color(0xFF10B981),
                                        onChanged: (val) {
                                          setState(() {
                                            _pagada = val;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Text(
                                  'RECURRENCIA',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: colorTexto.withValues(alpha: 0.45),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: [
                                    _buildRecurrenciaChip('una_vez', 'Una vez', esOscuro, colorTipo),
                                    _buildRecurrenciaChip('diario', 'Cada día', esOscuro, colorTipo),
                                    _buildRecurrenciaChip('semanal', 'Cada semana', esOscuro, colorTipo),
                                    _buildRecurrenciaChip('mensual', 'Cada mes', esOscuro, colorTipo),
                                    _buildRecurrenciaChip('anual', 'Cada año', esOscuro, colorTipo),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
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

  // --- Mini Tarjeta Real ---
  Widget _buildMiniAccountCard({
    required ModeloCuenta acc,
    required bool isSelected,
    required bool esOscuro,
    required Color colorTipo,
    required VoidCallback onTap,
  }) {
    final colors = _getAccountColors(acc, esOscuro);
    final topBgColor = colors.background;
    final topTextColor = colors.text;
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);

    return InteractiveScale(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 64,
        decoration: BoxDecoration(
          color: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (esOscuro ? Colors.white : colorTipo)
                : (esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFCBD5E1).withValues(alpha: 0.4)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: (esOscuro ? Colors.white : colorTipo).withValues(alpha: 0.25),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: esOscuro ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección Superior de Color Sólido
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: topBgColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            acc.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 7.0,
                              fontWeight: FontWeight.w900,
                              color: topTextColor.withValues(alpha: 0.75),
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildAccountIcon(acc, topTextColor, topBgColor),
                      ],
                    ),
                    Text(
                      acc.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                        color: topTextColor,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Sección Inferior con Saldo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getBottomBgColor(topBgColor),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                '${EstadoApp.getSymbolOfCurrency(acc.currency ?? estadoApp.selectedCurrency)} ${_formatearMonto(acc.balance, forzarDecimales: true)}',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: topTextColor,
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
    );
  }

  // --- Selector Horizontal de Cuentas Premium ---
  Widget _buildHorizontalAccountSelector({
    required String? selectedAccountId,
    required List<ModeloCuenta> accounts,
    required ValueChanged<String?> onSelected,
    required bool esOscuro,
    required Color colorTipo,
  }) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final acc = accounts[index];
          final isSelected = acc.id == selectedAccountId;
          return _buildMiniAccountCard(
            acc: acc,
            isSelected: isSelected,
            esOscuro: esOscuro,
            colorTipo: colorTipo,
            onTap: () => onSelected(acc.id),
          );
        },
      ),
    );
  }

  Widget _buildAccountIcon(ModeloCuenta acc, Color color, Color bgColor) {
    if (acc.type.toLowerCase().contains('efectivo')) {
      return Icon(
        Icons.wallet_rounded,
        color: color,
        size: 14,
      );
    }
    
    // De lo contrario, pintar el chip de tarjeta de crédito
    return Container(
      width: 16,
      height: 12,
      decoration: BoxDecoration(
        color: color,
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
              color: bgColor.withValues(alpha: 0.8),
            ),
          ),
          Positioned(
            bottom: 3,
            left: 0,
            right: 0,
            child: Container(
              height: 0.5,
              color: bgColor.withValues(alpha: 0.8),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 8,
            child: Container(
              width: 0.5,
              color: bgColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
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

  Color _getDarkShade(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - 0.5).clamp(0.12, 0.35))
        .withSaturation((hsl.saturation + 0.2).clamp(0.6, 0.95))
        .toColor();
  }

  Color _getBottomBgColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();
  }

  String _formatearMonto(double monto, {bool forzarDecimales = false}) {
    final bool esEntero = (monto % 1 == 0) && !forzarDecimales;
    final String formatBase = monto.toStringAsFixed(esEntero ? 0 : 2);

    final parts = formatBase.split('.');
    String entero = parts[0];
    final String decimal = parts.length > 1 ? parts[1] : '';

    final regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');
    entero = entero.replaceAllMapped(regExp, (Match m) => '.');

    if (decimal.isNotEmpty) {
      return '$entero,$decimal';
    }
    return entero;
  }

  // --- Selector de Categorías Premium ---
  Widget _buildCategorySelectorCard({
    required String selectedCategoryName,
    required List<ModeloCategoria> categories,
    required ValueChanged<String> onSelected,
    required bool esOscuro,
    required Color colorTexto,
    required Color colorTipo,
    bool compacto = false,
  }) {
    final activeCat = categories.firstWhere(
      (cat) => cat.name.toLowerCase() == selectedCategoryName.toLowerCase(),
      orElse: () => ModeloCategoria(id: '', name: selectedCategoryName, iconCode: 'bubble_chart', hexColor: '#FFCC80'),
    );
    final catColor = Color(int.parse(activeCat.hexColor.replaceFirst('#', '0xFF')));

    String catNameDisplay = activeCat.name;
    if (activeCat.parentId != null) {
      try {
        final parentCat = categories.firstWhere((cat) => cat.id == activeCat.parentId);
        catNameDisplay = '${parentCat.name} > ${activeCat.name}';
      } catch (_) {}
    }

    return InteractiveScale(
      onTap: () => _showCategorySelectorBottomSheet(categories, selectedCategoryName, onSelected, esOscuro, colorTexto, colorTipo),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compacto ? 10 : 16,
          vertical: compacto ? 6 : 12,
        ),
        height: compacto ? 46 : null,
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
              width: compacto ? 28 : 38,
              height: compacto ? 28 : 38,
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
                  size: compacto ? 13 : 16,
                ),
              ),
            ),
            SizedBox(width: compacto ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    catNameDisplay,
                    style: TextStyle(
                      fontSize: compacto ? 13 : 14.5,
                      fontWeight: FontWeight.bold,
                      color: colorTexto,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compacto)
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
              size: compacto ? 16 : 20,
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

    final Set<String> expandedParentIds = {}; // Cerrados por defecto

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;

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
                        children: [
                          Text(
                            'Seleccionar Categoría',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showQuickCreateCategoryDialog(context, esOscuro, colorTexto, colorTipo, onSelected),
                            icon: Icon(Icons.add_rounded, size: 16, color: colorTipo),
                            label: Text(
                              'Nueva',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorTipo,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              backgroundColor: colorTipo.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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

  void _showQuickCreateCategoryDialog(
    BuildContext context,
    bool esOscuro,
    Color colorTexto,
    Color colorTipo,
    ValueChanged<String> onSelected,
  ) {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final parentCategories = estadoApp.categories.where((cat) => cat.parentId == null).toList();
    
    final nameController = TextEditingController();
    String? selectedParentId;
    String selectedIcon = 'category';
    String selectedColor = '#FFE0B2';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: esOscuro ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              title: Text(
                'Nueva Categoría',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorTexto,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre input
                      Text(
                        'NOMBRE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorTexto.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: TextStyle(color: colorTexto),
                        decoration: _buildInputDecoration('Ej. Regalos, Gym...', esOscuro, colorTipo).copyWith(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Categoría Padre dropdown
                      Text(
                        'CATEGORÍA SUPERIOR (OPCIONAL)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorTexto.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: selectedParentId,
                            hint: Text(
                              'Ninguna (Principal)',
                              style: TextStyle(color: colorTexto.withValues(alpha: 0.5), fontSize: 14),
                            ),
                            dropdownColor: esOscuro ? const Color(0xFF0F172A) : Colors.white,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorTexto.withValues(alpha: 0.5)),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Ninguna (Principal)',
                                  style: TextStyle(color: colorTexto, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                              ...parentCategories.map((cat) {
                                return DropdownMenuItem<String?>(
                                  value: cat.id,
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(color: colorTexto, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setDialogState(() {
                                selectedParentId = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Selector de icono rápido
                      Text(
                        'SELECCIONAR ICONO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorTexto.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 130,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: esOscuro
                              ? const Color(0xFF0A0A0A).withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: esOscuro
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.65),
                            width: 1.0,
                          ),
                        ),
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _galleryIcons.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemBuilder: (dialogContext, index) {
                            final key = _galleryIcons.keys.elementAt(index);
                            final icon = _galleryIcons[key]!;
                            final isSelected = selectedIcon == key;

                            return InteractiveScale(
                              onTap: () {
                                setDialogState(() {
                                  selectedIcon = key;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorTipo.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? colorTipo : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    icon,
                                    color: isSelected ? colorTipo : colorTexto.withValues(alpha: 0.6),
                                    size: 18,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selector de color avanzado
                      Text(
                        'COLOR DE LA CATEGORÍA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorTexto.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      HexColorPicker(
                        currentColorHex: selectedColor,
                        onColorChanged: (hex) {
                          setDialogState(() {
                            selectedColor = hex;
                          });
                        },
                        esOscuro: esOscuro,
                        colorPrincipal: colorTipo,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ToastHelper.showError(context, 'Ingresa un nombre para la categoría');
                      return;
                    }
                    
                    await estadoApp.addCategory(
                      name,
                      selectedParentId,
                      selectedIcon,
                      selectedColor,
                    );
                    
                    if (!dialogContext.mounted) return;
                    // Cerrar el diálogo de creación
                    Navigator.pop(dialogContext);
                    
                    if (!context.mounted) return;
                    // Invocar callback de selección y cerrar selector de categorías
                    onSelected(name);
                    Navigator.pop(context);
                    
                    ToastHelper.showSuccess(context, 'Categoría "$name" creada con éxito');
                  },
                  child: Text('Crear', style: TextStyle(color: colorTipo, fontWeight: FontWeight.bold)),
                ),
              ],
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
                          _buildCalcButton('C', colorTexto, calcPress, esOscuro, isAction: true),
                          _buildCalcButton('DEL', colorTexto, calcPress, esOscuro, isAction: true),
                          _buildCalcButton('%', colorTexto, calcPress, esOscuro, isOperator: true),
                          _buildCalcButton('/', colorTexto, calcPress, esOscuro, isOperator: true),
                          
                          _buildCalcButton('7', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('8', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('9', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('*', colorTexto, calcPress, esOscuro, isOperator: true),
                          
                          _buildCalcButton('4', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('5', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('6', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('-', colorTexto, calcPress, esOscuro, isOperator: true),
                          
                          _buildCalcButton('1', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('2', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('3', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('+', colorTexto, calcPress, esOscuro, isOperator: true),
                          
                          _buildCalcButton('0', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('.', colorTexto, calcPress, esOscuro, isNum: true),
                          _buildCalcButton('=', colorTipo, calcPress, esOscuro, isSubmit: true),
                          _buildCalcButton('LISTO', colorTipo, calcPress, esOscuro, isBig: true, isSubmit: true),
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
    bool isOperator = false,
    bool isAction = false,
    bool isSubmit = false,
  }) {
    Color buttonColor;
    Color fontColor;

    if (isSubmit) {
      buttonColor = color;
      fontColor = Colors.white;
    } else if (isNum) {
      buttonColor = esOscuro ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);
      fontColor = esOscuro ? Colors.white : const Color(0xFF0F172A);
    } else if (isOperator) {
      buttonColor = esOscuro ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
      fontColor = esOscuro ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF334155);
    } else if (isAction) {
      buttonColor = esOscuro ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      fontColor = esOscuro ? Colors.white : const Color(0xFF0F172A);
    } else {
      buttonColor = esOscuro ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);
      fontColor = esOscuro ? Colors.white : const Color(0xFF0F172A);
    }

    return InteractiveScale(
      onTap: () => onPress(label),
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: esOscuro ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: label == 'LISTO' ? 14 : 18,
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

  Widget _buildExampleCard(String tipo, String ejemplos, Color colorTipo, bool esOscuro) {
    final baseColor = esOscuro ? Colors.white : const Color(0xFF0F172A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (esOscuro ? Colors.white : Colors.black).withValues(alpha: esOscuro ? 0.04 : 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorTipo.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorTipo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorTipo.withValues(alpha: 0.25), width: 0.8),
            ),
            child: Text(
              tipo,
              style: TextStyle(
                color: colorTipo,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ejemplos,
              style: TextStyle(
                color: baseColor.withValues(alpha: 0.75),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningOverlay(Color colorTexto, Color colorTipo) {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final esOscuro = estadoApp.esTemaOscuro;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: (esOscuro ? Colors.black : Colors.white).withValues(alpha: esOscuro ? 0.82 : 0.88),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Indicador de estado de escucha
              Text(
                'Escuchando...',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorTexto,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _lastWords.isEmpty ? 'Di tu movimiento de forma natural' : _lastWords,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _lastWords.isEmpty ? FontWeight.normal : FontWeight.w600,
                    color: colorTexto.withValues(alpha: _lastWords.isEmpty ? 0.6 : 0.9),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Animacion de ondas Siri-style usando flutter_animate
              SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final List<Color> siriColors = [
                      const Color(0xFF3B82F6), // Azul
                      const Color(0xFF10B981), // Verde
                      const Color(0xFFEF4444), // Rojo
                      const Color(0xFF8B5CF6), // Morado
                      const Color(0xFFF59E0B), // Naranja
                    ];
                    final color = siriColors[index % siriColors.length];
                    final baseHeight = 20.0 + (index * 5);
                    
                    return Container(
                      width: 5,
                      height: baseHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scaleY(
                      begin: 0.4,
                      end: 1.4,
                      duration: Duration(milliseconds: 350 + (index * 80)),
                      curve: Curves.easeInOut,
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Guía de voz rápida / Ejemplos
              Text(
                'GUÍA DE VOZ RÁPIDA',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: colorTexto.withValues(alpha: 0.45),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildExampleCard(
                      'GASTO',
                      '“Gasto 120 Bs en comida desde Efectivo hoy”\n“Pagué 450 en combustible con Tarjeta ayer”',
                      const Color(0xFFEF4444),
                      esOscuro,
                    ),
                    const SizedBox(height: 8),
                    _buildExampleCard(
                      'INGRESO',
                      '“Sueldo de 5000 en Mi Banco hoy”\n“Recibí 800 por venta en Efectivo ayer”',
                      const Color(0xFF10B981),
                      esOscuro,
                    ),
                    const SizedBox(height: 8),
                    _buildExampleCard(
                      'TRANSFERENCIA',
                      '“Transferí 300 de Efectivo a Mi Banco ayer”\n“Mover 150 de BCP a Efectivo hoy”',
                      const Color(0xFF3B82F6),
                      esOscuro,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Boton para detener y procesar
              GestureDetector(
                onTap: _stopListening,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                  decoration: BoxDecoration(
                    color: colorTipo,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: colorTipo.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.stop_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Listo, Procesar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
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

class SolidCardColors {
  final Color background;
  final Color text;
  const SolidCardColors(this.background, this.text);
}
