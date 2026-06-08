import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'servicio_autenticacion.dart';

class ModeloCuenta {
  final String id;
  final String name;
  final String type;
  double balance;
  final int gradientIndex;
  final String? customColorHex;
  final String? customColorSecondaryHex;
  final String? customColorThirdHex;
  final double? stop1;
  final double? stop2;
  final double? stop3;
  final bool? useDarkText;
  final String? currency;
  final bool? contabilizable;

  ModeloCuenta({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.gradientIndex,
    this.customColorHex,
    this.customColorSecondaryHex,
    this.customColorThirdHex,
    this.stop1,
    this.stop2,
    this.stop3,
    this.useDarkText,
    this.currency,
    this.contabilizable,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': name,
      'tipo': type,
      'saldo': balance,
      'indiceGradiente': gradientIndex,
      'colorPersonalizadoHex': customColorHex,
      'colorSecundarioPersonalizadoHex': customColorSecondaryHex,
      'colorTerceroPersonalizadoHex': customColorThirdHex,
      'stop1': stop1,
      'stop2': stop2,
      'stop3': stop3,
      'usarTextoOscuro': useDarkText,
      'moneda': currency,
      'contabilizable': contabilizable,
    };
  }

  factory ModeloCuenta.fromMap(Map<String, dynamic> map) {
    return ModeloCuenta(
      id: map['id'] ?? '',
      name: map['nombre'] ?? '',
      type: map['tipo'] ?? '',
      balance: (map['saldo'] as num?)?.toDouble() ?? 0.0,
      gradientIndex: map['indiceGradiente'] ?? 0,
      customColorHex: map['colorPersonalizadoHex'],
      customColorSecondaryHex: map['colorSecundarioPersonalizadoHex'],
      customColorThirdHex: map['colorTerceroPersonalizadoHex'],
      stop1: (map['stop1'] as num?)?.toDouble(),
      stop2: (map['stop2'] as num?)?.toDouble(),
      stop3: (map['stop3'] as num?)?.toDouble(),
      useDarkText: map['usarTextoOscuro'] ?? false,
      currency: map['moneda'],
      contabilizable: map['contabilizable'] ?? true,
    );
  }
}

class ModeloTransaccion {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final String type; // 'gasto', 'ingreso', 'transferencia'
  final String accountId;
  final String? toAccountId;
  final String? photoPath;
  final bool esProgramada;
  final bool pagada;
  final String? recurrencia;

  ModeloTransaccion({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    required this.accountId,
    this.toAccountId,
    this.photoPath,
    this.esProgramada = false,
    this.pagada = true,
    this.recurrencia,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': title,
      'descripcion': description,
      'monto': amount,
      'categoria': category,
      'fecha': date.toIso8601String(),
      'tipo': type,
      'idCuenta': accountId,
      'idCuentaDestino': toAccountId,
      'rutaFoto': photoPath,
      'esProgramada': esProgramada,
      'pagada': pagada,
      'recurrencia': recurrencia,
    };
  }

  factory ModeloTransaccion.fromMap(Map<String, dynamic> map) {
    return ModeloTransaccion(
      id: map['id'] ?? '',
      title: map['titulo'] ?? '',
      description: map['descripcion'] ?? '',
      amount: (map['monto'] as num?)?.toDouble() ?? 0.0,
      category: map['categoria'] ?? '',
      date: DateTime.parse(map['fecha'] ?? DateTime.now().toIso8601String()),
      type: map['tipo'] ?? 'gasto',
      accountId: map['idCuenta'] ?? '',
      toAccountId: map['idCuentaDestino'],
      photoPath: map['rutaFoto'],
      esProgramada: map['esProgramada'] ?? false,
      pagada: map['pagada'] ?? true,
      recurrencia: map['recurrencia'],
    );
  }

  // Identifica si es una transaccion automatica de apertura de cuenta
  bool get esRegistroApertura =>
      description == 'Monto de apertura de cuenta' ||
      title == 'Saldo inicial' ||
      title == 'Carga inicial';
}

class ModeloAhorro {
  final String id;
  final String name;
  final double targetAmount;
  double currentAmount;
  final DateTime startDate;
  final DateTime? targetDate;
  final String hexColor;
  final String iconCode;
  final String? linkedAccountId;

  ModeloAhorro({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    this.targetDate,
    required this.hexColor,
    required this.iconCode,
    this.linkedAccountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': name,
      'montoObjetivo': targetAmount,
      'montoActual': currentAmount,
      'fechaInicio': startDate.toIso8601String(),
      'fechaObjetivo': targetDate?.toIso8601String(),
      'colorHex': hexColor,
      'codigoIcono': iconCode,
      'idCuentaVinculada': linkedAccountId,
    };
  }

  factory ModeloAhorro.fromMap(Map<String, dynamic> map) {
    return ModeloAhorro(
      id: map['id'] ?? '',
      name: map['nombre'] ?? '',
      targetAmount: (map['montoObjetivo'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['montoActual'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(map['fechaInicio'] ?? DateTime.now().toIso8601String()),
      targetDate: map['fechaObjetivo'] != null ? DateTime.parse(map['fechaObjetivo']) : null,
      hexColor: map['colorHex'] ?? '#10B981',
      iconCode: map['codigoIcono'] ?? 'savings_rounded',
      linkedAccountId: map['idCuentaVinculada'],
    );
  }
}

class ModeloCategoria {
  final String id;
  final String name;
  final String? parentId; // Si es null es categoria principal, si no, es subcategoria
  final String iconCode;  // Identificador del icono
  final String hexColor;  // Color en hexadecimal

  ModeloCategoria({
    required this.id,
    required this.name,
    this.parentId,
    required this.iconCode,
    required this.hexColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': name,
      'idPadre': parentId,
      'codigoIcono': iconCode,
      'colorHex': hexColor,
    };
  }

  factory ModeloCategoria.fromMap(Map<String, dynamic> map) {
    return ModeloCategoria(
      id: map['id'] ?? '',
      name: map['nombre'] ?? '',
      parentId: map['idPadre'],
      iconCode: map['codigoIcono'] ?? 'bubble_chart',
      hexColor: map['colorHex'] ?? '#E2E8F0',
    );
  }
}

class ModeloPresupuesto {
  final String id;
  final String categoryName; // E.g., 'Alimentación' or 'Global'
  final double limitAmount;
  final String period; // 'mensual'

  ModeloPresupuesto({
    required this.id,
    required this.categoryName,
    required this.limitAmount,
    this.period = 'mensual',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreCategoria': categoryName,
      'montoLimite': limitAmount,
      'periodo': period,
    };
  }

  factory ModeloPresupuesto.fromMap(Map<String, dynamic> map) {
    return ModeloPresupuesto(
      id: map['id'] ?? '',
      categoryName: map['nombreCategoria'] ?? '',
      limitAmount: (map['montoLimite'] as num?)?.toDouble() ?? 0.0,
      period: map['periodo'] ?? 'mensual',
    );
  }
}

class EstadoApp extends ChangeNotifier {
  String _selectedLanguage = 'es';
  String _selectedCurrency = 'BOB';
  Map<String, double> _tiposCambio = {};
  bool _hasCompletedOnboarding = false;
  List<ModeloCuenta> _accounts = [];
  List<ModeloTransaccion> _transactions = [];
  List<ModeloCategoria> _categories = [];
  List<ModeloAhorro> _savingsGoals = [];
  List<ModeloPresupuesto> _budgets = [];
  bool _esTemaOscuro = false;
  Color _colorPrincipal = const Color(0xFF000000);
  int _selectedDockIndex = 0;
  int _selectedSettingsSubView = 0;
  int _lastLocalUpdateMillis = 0;
  StreamSubscription<DocumentSnapshot>? _nubeSubscription;
  bool _isSyncing = false;
  Timer? _debounceSubida;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  String _hashedPin = '';

  String get selectedLanguage => _selectedLanguage;
  String get selectedCurrency => _selectedCurrency;
  Map<String, double> get tiposCambio => _tiposCambio;
  double get tipoCambioUsd => _tiposCambio['USD'] ?? 6.97;
  int get lastLocalUpdateMillis => _lastLocalUpdateMillis;
  String get currencySymbol => getSymbolOfCurrency(_selectedCurrency);
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  List<ModeloCuenta> get accounts => _accounts;
  List<ModeloTransaccion> get transactions => _transactions;
  List<ModeloCategoria> get categories {
    return [...categoriasPorDefecto, ..._categories];
  }
  List<ModeloAhorro> get savingsGoals {
    for (var goal in _savingsGoals) {
      if (goal.linkedAccountId != null) {
        final accIdx = _accounts.indexWhere((acc) => acc.id == goal.linkedAccountId);
        if (accIdx != -1) {
          goal.currentAmount = _accounts[accIdx].balance;
        }
      }
    }
    return _savingsGoals;
  }
  List<ModeloPresupuesto> get budgets => _budgets;
  bool get esTemaOscuro => _esTemaOscuro;
  Color get colorPrincipal => _colorPrincipal;

  bool get biometricEnabled => _biometricEnabled;
  bool get pinEnabled => _pinEnabled;
  String get hashedPin => _hashedPin;

  int get selectedDockIndex => _selectedDockIndex;
  set selectedDockIndex(int val) {
    _selectedDockIndex = val;
    notifyListeners();
  }

  int get selectedSettingsSubView => _selectedSettingsSubView;
  set selectedSettingsSubView(int val) {
    _selectedSettingsSubView = val;
    notifyListeners();
  }

  double convertirMoneda(double monto, String monedaOrigen, String monedaDestino) {
    if (monedaOrigen == monedaDestino) return monto;
    
    final tasaOrigen = _tiposCambio[monedaOrigen] ?? 1.0;
    final tasaDestino = _tiposCambio[monedaDestino] ?? 1.0;
    
    final montoEnMonedaPrincipal = monto * tasaOrigen;
    return montoEnMonedaPrincipal / tasaDestino;
  }

  static String getSymbolOfCurrency(String currencyCode) {
    switch (currencyCode) {
      case 'BOB':
        return 'Bs';
      case 'MXN':
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
      case 'CNY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'INR':
        return '₹';
      default:
        return 'Bs';
    }
  }

  Future<void> setTasaCambio(String code, double valor) async {
    _tiposCambio[code] = valor;
    _tiposCambio[_selectedCurrency] = 1.0; // Siempre forzar divisa principal en 1.0
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_tipos_cambio', json.encode(_tiposCambio));
    _notificarYSincronizar();
  }

  Future<void> setTipoCambioUsd(double valor) async {
    await setTasaCambio('USD', valor);
  }

  double get totalBalance {
    double total = 0.0;
    for (var acc in _accounts) {
      if (acc.contabilizable == false) continue;
      final accCurrency = acc.currency ?? _selectedCurrency;
      final balanceConvertido = convertirMoneda(acc.balance, accCurrency, _selectedCurrency);
      
      if (acc.type == 'Credito' || acc.type == 'Crédito') {
        total -= balanceConvertido;
      } else {
        total += balanceConvertido;
      }
    }
    return total;
  }

  double get totalIncome {
    double total = 0.0;
    for (var tx in _transactions) {
      if (!tx.pagada) continue;
      if (tx.type == 'ingreso' && !tx.esRegistroApertura) {
        final acc = _accounts.firstWhere(
          (a) => a.id == tx.accountId,
          orElse: () => _accounts.isNotEmpty ? _accounts.first : ModeloCuenta(id: '', name: '', type: '', balance: 0, gradientIndex: 0),
        );
        if (acc.contabilizable == false) continue;
        final txCurrency = acc.currency ?? _selectedCurrency;
        total += convertirMoneda(tx.amount, txCurrency, _selectedCurrency);
      }
    }
    return total;
  }

  double get totalExpenses {
    double total = 0.0;
    for (var tx in _transactions) {
      if (!tx.pagada) continue;
      if (tx.type == 'gasto') {
        final acc = _accounts.firstWhere(
          (a) => a.id == tx.accountId,
          orElse: () => _accounts.isNotEmpty ? _accounts.first : ModeloCuenta(id: '', name: '', type: '', balance: 0, gradientIndex: 0),
        );
        if (acc.contabilizable == false) continue;
        final txCurrency = acc.currency ?? _selectedCurrency;
        total += convertirMoneda(tx.amount, txCurrency, _selectedCurrency);
      }
    }
    return total;
  }

  void _inicializarTasasDefecto() {
    _tiposCambio = {
      'BOB': 1.0,
      'USD': 6.97,
      'EUR': 7.50,
      'MXN': 0.40,
      'GBP': 8.80,
      'JPY': 0.045,
      'CNY': 0.96,
      'KRW': 0.005,
      'INR': 0.08,
    };
  }

  EstadoApp() {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    _lastLocalUpdateMillis = prefs.getInt('app_last_local_update_millis') ?? 0;
    _selectedLanguage = prefs.getString('app_language') ?? 'es';
    _selectedCurrency = prefs.getString('app_currency') ?? 'BOB';
    
    final String? tiposCambioJson = prefs.getString('app_tipos_cambio');
    if (tiposCambioJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(tiposCambioJson);
        _tiposCambio = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } catch (_) {
        _inicializarTasasDefecto();
      }
    } else {
      _inicializarTasasDefecto();
    }
    
    _tiposCambio[_selectedCurrency] = 1.0; // Garantizar que la moneda principal tenga siempre tasa 1.0
    
    _hasCompletedOnboarding = prefs.getBool('app_onboarding_completed') ?? false;
    _esTemaOscuro = prefs.getBool('app_dark_mode') ?? false;

    _biometricEnabled = prefs.getBool('app_biometric_enabled') ?? false;
    _pinEnabled = prefs.getBool('app_pin_enabled') ?? false;
    _hashedPin = prefs.getString('app_pin_code') ?? '';

    final int colorVal = prefs.getInt('app_primary_color') ?? const Color(0xFF000000).toARGB32();
    _colorPrincipal = Color(colorVal);

    final String? accountsJson = prefs.getString('app_accounts');
    if (accountsJson != null) {
      final List<dynamic> decoded = json.decode(accountsJson);
      _accounts = decoded.map((item) => ModeloCuenta.fromMap(item)).toList();
    }

    final String? transactionsJson = prefs.getString('app_transactions');
    if (transactionsJson != null) {
      final List<dynamic> decoded = json.decode(transactionsJson);
      _transactions = decoded.map((item) => ModeloTransaccion.fromMap(item)).toList();
    }

    final String? categoriesJson = prefs.getString('app_categories');
    if (categoriesJson != null) {
      final List<dynamic> decoded = json.decode(categoriesJson);
      _categories = decoded.map((item) => ModeloCategoria.fromMap(item)).toList();
      
      // Migrar colores antiguos (pasteles/bajos) a nuevos colores (fuertes/vibrantes)
      bool cambioRealizado = false;
      for (int i = 0; i < _categories.length; i++) {
        final cat = _categories[i];
        String? nuevoHex;
        if (cat.hexColor.toUpperCase() == '#FFE0B2') {
          nuevoHex = '#FF9800'; // Comida
        } else if (cat.hexColor.toUpperCase() == '#B3E5FC') {
          nuevoHex = '#0284C7'; // Transporte
        } else if (cat.hexColor.toUpperCase() == '#C8E6C9') {
          nuevoHex = '#10B981'; // Salario
        } else if (cat.hexColor.toUpperCase() == '#D1C4E9') {
          nuevoHex = '#8B5CF6'; // Servicios
        } else if (cat.hexColor.toUpperCase() == '#F8BBD0') {
          nuevoHex = '#EC4899'; // Entretenimiento
        } else if (cat.hexColor.toUpperCase() == '#E2E8F0') {
          nuevoHex = '#64748B'; // Otros
        }
        
        if (nuevoHex != null) {
          _categories[i] = ModeloCategoria(
            id: cat.id,
            name: cat.name,
            parentId: cat.parentId,
            iconCode: cat.iconCode,
            hexColor: nuevoHex,
          );
          cambioRealizado = true;
        }
      }
      if (cambioRealizado) {
        await _saveCategoriesToPrefs(prefs);
      }
    }

    final String? savingsJson = prefs.getString('app_savings_goals');
    if (savingsJson != null) {
      final List<dynamic> decoded = json.decode(savingsJson);
      _savingsGoals = decoded.map((item) => ModeloAhorro.fromMap(item)).toList();
    }

    final String? budgetsJson = prefs.getString('app_budgets');
    if (budgetsJson != null) {
      final List<dynamic> decoded = json.decode(budgetsJson);
      _budgets = decoded.map((item) => ModeloPresupuesto.fromMap(item)).toList();
    }

    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _selectedLanguage = lang;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    _notificarYSincronizar();
  }

  Future<void> setCurrency(String currency) async {
    _selectedCurrency = currency;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_currency', currency);
    _notificarYSincronizar();
  }

  Future<void> toggleTema(bool value) async {
    _esTemaOscuro = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_dark_mode', value);

    if (value && _colorPrincipal.toARGB32() == const Color(0xFF000000).toARGB32()) {
      _colorPrincipal = const Color(0xFFFFFFFF);
      await prefs.setInt('app_primary_color', const Color(0xFFFFFFFF).toARGB32());
    } else if (!value && _colorPrincipal.toARGB32() == const Color(0xFFFFFFFF).toARGB32()) {
      _colorPrincipal = const Color(0xFF000000);
      await prefs.setInt('app_primary_color', const Color(0xFF000000).toARGB32());
    }

    _notificarYSincronizar();
  }

  Future<void> setColorPrincipal(Color color) async {
    _colorPrincipal = color;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_primary_color', color.toARGB32());
    _notificarYSincronizar();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_biometric_enabled', value);
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final hashed = _hashPin(pin);
    _hashedPin = hashed;
    _pinEnabled = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin_code', hashed);
    await prefs.setBool('app_pin_enabled', true);
    notifyListeners();
  }

  Future<void> disablePin() async {
    _hashedPin = '';
    _pinEnabled = false;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_pin_code');
    await prefs.setBool('app_pin_enabled', false);
    notifyListeners();
  }

  bool verifyPin(String pin) {
    if (!_pinEnabled || _hashedPin.isEmpty) return false;
    return _hashPin(pin) == _hashedPin;
  }

  Future<void> completeOnboarding(String firstAccountName, String firstAccountType, double initialBalance, {String? currency}) async {
    _accounts.clear();
    _transactions.clear();

    final firstAccount = ModeloCuenta(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      name: firstAccountName,
      type: firstAccountType,
      balance: initialBalance,
      gradientIndex: 0,
      currency: currency ?? _selectedCurrency,
    );
    _accounts.add(firstAccount);

    if (initialBalance > 0) {
      final initialTx = ModeloTransaccion(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Saldo inicial',
        description: 'Monto de apertura de cuenta',
        amount: initialBalance,
        category: 'Ingresos',
        date: DateTime.now(),
        type: 'ingreso',
        accountId: firstAccount.id,
      );
      _transactions.add(initialTx);
    }

    _hasCompletedOnboarding = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_onboarding_completed', true);
    await _saveAccountsToPrefs(prefs);
    await _saveTransactionsToPrefs(prefs);

    _notificarYSincronizar();
  }

  Future<ModeloCuenta> addAccount(String name, String type, double balance, int gradientIndex, {String? customColorHex, String? customColorSecondaryHex, String? customColorThirdHex, double? stop1, double? stop2, double? stop3, bool useDarkText = false, String? currency, bool contabilizable = true}) async {
    final newAccount = ModeloCuenta(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}_${_accounts.length}',
      name: name,
      type: type,
      balance: balance,
      gradientIndex: gradientIndex,
      customColorHex: customColorHex,
      customColorSecondaryHex: customColorSecondaryHex,
      customColorThirdHex: customColorThirdHex,
      stop1: stop1,
      stop2: stop2,
      stop3: stop3,
      useDarkText: useDarkText,
      currency: currency ?? _selectedCurrency,
      contabilizable: contabilizable,
    );
    _accounts.add(newAccount);

    if (balance > 0) {
      final initialTx = ModeloTransaccion(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Carga inicial',
        description: 'Monto de apertura de cuenta',
        amount: balance,
        category: 'Otros',
        date: DateTime.now(),
        type: 'ingreso',
        accountId: newAccount.id,
      );
      _transactions.add(initialTx);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _saveTransactionsToPrefs(prefs);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    _notificarYSincronizar();
    return newAccount;
  }

  Future<void> addTransaction({
    required String title,
    required String description,
    required double amount,
    required String category,
    required String type,
    required String accountId,
    String? toAccountId,
    String? photoPath,
    DateTime? date,
    bool esProgramada = false,
    bool pagada = true,
    String? recurrencia,
  }) async {
    final transactionDate = date ?? DateTime.now();
    final newTx = ModeloTransaccion(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      amount: amount,
      category: category,
      date: transactionDate,
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
      photoPath: photoPath,
      esProgramada: esProgramada,
      pagada: pagada,
      recurrencia: recurrencia,
    );

    _transactions.insert(0, newTx);

    if (pagada) {
      if (type == 'gasto') {
        final idx = _accounts.indexWhere((acc) => acc.id == accountId);
        if (idx != -1) {
          _accounts[idx].balance -= amount;
        }
      } else if (type == 'ingreso') {
        final idx = _accounts.indexWhere((acc) => acc.id == accountId);
        if (idx != -1) {
          _accounts[idx].balance += amount;
        }
      } else if (type == 'transferencia' && toAccountId != null) {
        final originIdx = _accounts.indexWhere((acc) => acc.id == accountId);
        final destIdx = _accounts.indexWhere((acc) => acc.id == toAccountId);
        if (originIdx != -1) {
          _accounts[originIdx].balance -= amount;
        }
        if (originIdx != -1 && destIdx != -1) {
          final originAcc = _accounts[originIdx];
          final destAcc = _accounts[destIdx];
          final originCurrency = originAcc.currency ?? _selectedCurrency;
          final destCurrency = destAcc.currency ?? _selectedCurrency;
          
          final amountConvertido = convertirMoneda(amount, originCurrency, destCurrency);
          _accounts[destIdx].balance += amountConvertido;
        }
      }
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    await _saveTransactionsToPrefs(prefs);

    _notificarYSincronizar();
  }

  Future<void> updateTransaction({
    required String id,
    required String title,
    required String description,
    required double amount,
    required String category,
    required String type,
    required String accountId,
    String? toAccountId,
    String? photoPath,
    required DateTime date,
    bool esProgramada = false,
    bool pagada = true,
    String? recurrencia,
  }) async {
    // Buscar la transaccion original
    final idxTx = _transactions.indexWhere((tx) => tx.id == id);
    if (idxTx == -1) return;
    final oldTx = _transactions[idxTx];

    // Revertir balances de la transaccion original si estaba pagada
    if (oldTx.pagada) {
      if (oldTx.type == 'gasto') {
        final idx = _accounts.indexWhere((acc) => acc.id == oldTx.accountId);
        if (idx != -1) {
          _accounts[idx].balance += oldTx.amount;
        }
      } else if (oldTx.type == 'ingreso') {
        final idx = _accounts.indexWhere((acc) => acc.id == oldTx.accountId);
        if (idx != -1) {
          _accounts[idx].balance -= oldTx.amount;
        }
      } else if (oldTx.type == 'transferencia' && oldTx.toAccountId != null) {
        final originIdx = _accounts.indexWhere((acc) => acc.id == oldTx.accountId);
        final destIdx = _accounts.indexWhere((acc) => acc.id == oldTx.toAccountId);
        if (originIdx != -1) {
          _accounts[originIdx].balance += oldTx.amount;
        }
        if (originIdx != -1 && destIdx != -1) {
          final originAcc = _accounts[originIdx];
          final destAcc = _accounts[destIdx];
          final originCurrency = originAcc.currency ?? _selectedCurrency;
          final destCurrency = destAcc.currency ?? _selectedCurrency;
          
          final amountConvertido = convertirMoneda(oldTx.amount, originCurrency, destCurrency);
          _accounts[destIdx].balance -= amountConvertido;
        }
      }
    }

    // Aplicar balances de la nueva transaccion si está pagada
    if (pagada) {
      if (type == 'gasto') {
        final idx = _accounts.indexWhere((acc) => acc.id == accountId);
        if (idx != -1) {
          _accounts[idx].balance -= amount;
        }
      } else if (type == 'ingreso') {
        final idx = _accounts.indexWhere((acc) => acc.id == accountId);
        if (idx != -1) {
          _accounts[idx].balance += amount;
        }
      } else if (type == 'transferencia' && toAccountId != null) {
        final originIdx = _accounts.indexWhere((acc) => acc.id == accountId);
        final destIdx = _accounts.indexWhere((acc) => acc.id == toAccountId);
        if (originIdx != -1) {
          _accounts[originIdx].balance -= amount;
        }
        if (originIdx != -1 && destIdx != -1) {
          final originAcc = _accounts[originIdx];
          final destAcc = _accounts[destIdx];
          final originCurrency = originAcc.currency ?? _selectedCurrency;
          final destCurrency = destAcc.currency ?? _selectedCurrency;
          
          final amountConvertido = convertirMoneda(amount, originCurrency, destCurrency);
          _accounts[destIdx].balance += amountConvertido;
        }
      }
    }

    // Actualizar la transaccion en la lista
    _transactions[idxTx] = ModeloTransaccion(
      id: id,
      title: title,
      description: description,
      amount: amount,
      category: category,
      date: date,
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
      photoPath: photoPath,
      esProgramada: esProgramada,
      pagada: pagada,
      recurrencia: recurrencia,
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    await _saveTransactionsToPrefs(prefs);

    _notificarYSincronizar();
  }

  Future<void> deleteTransaction(String id) async {
    final idxTx = _transactions.indexWhere((tx) => tx.id == id);
    if (idxTx == -1) return;
    final oldTx = _transactions[idxTx];

    // Revertir balances antes de eliminar si estaba pagada
    if (oldTx.pagada) {
      if (oldTx.type == 'gasto') {
        final idx = _accounts.indexWhere((acc) => acc.id == oldTx.accountId);
        if (idx != -1) {
          _accounts[idx].balance += oldTx.amount;
        }
      } else if (oldTx.type == 'ingreso') {
        final idx = _accounts.indexWhere((acc) => acc.id == oldTx.accountId);
        if (idx != -1) {
          _accounts[idx].balance -= oldTx.amount;
        }
      } else if (oldTx.type == 'transferencia' && oldTx.toAccountId != null) {
        final originIdx = _accounts.indexWhere((acc) => acc.id == oldTx.accountId);
        final destIdx = _accounts.indexWhere((acc) => acc.id == oldTx.toAccountId);
        if (originIdx != -1) {
          _accounts[originIdx].balance += oldTx.amount;
        }
        if (originIdx != -1 && destIdx != -1) {
          final originAcc = _accounts[originIdx];
          final destAcc = _accounts[destIdx];
          final originCurrency = originAcc.currency ?? _selectedCurrency;
          final destCurrency = destAcc.currency ?? _selectedCurrency;
          
          final amountConvertido = convertirMoneda(oldTx.amount, originCurrency, destCurrency);
          _accounts[destIdx].balance -= amountConvertido;
        }
      }
    }

    _transactions.removeAt(idxTx);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    await _saveTransactionsToPrefs(prefs);

    _notificarYSincronizar();
  }

  DateTime calcularProximaFecha(DateTime fecha, String recurrencia) {
    if (recurrencia == 'diario') {
      return fecha.add(const Duration(days: 1));
    } else if (recurrencia == 'semanal') {
      return fecha.add(const Duration(days: 7));
    } else if (recurrencia == 'mensual') {
      return DateTime(fecha.year, fecha.month + 1, fecha.day);
    } else if (recurrencia == 'anual') {
      return DateTime(fecha.year + 1, fecha.month, fecha.day);
    }
    return fecha;
  }

  Future<void> confirmarPagoTransaccion(String id, {DateTime? fechaPago}) async {
    final idxTx = _transactions.indexWhere((tx) => tx.id == id);
    if (idxTx == -1) return;
    final tx = _transactions[idxTx];
    if (tx.pagada) return;

    // Modificar saldo real de la cuenta
    if (tx.type == 'gasto') {
      final idx = _accounts.indexWhere((acc) => acc.id == tx.accountId);
      if (idx != -1) {
        _accounts[idx].balance -= tx.amount;
      }
    } else if (tx.type == 'ingreso') {
      final idx = _accounts.indexWhere((acc) => acc.id == tx.accountId);
      if (idx != -1) {
        _accounts[idx].balance += tx.amount;
      }
    } else if (tx.type == 'transferencia' && tx.toAccountId != null) {
      final originIdx = _accounts.indexWhere((acc) => acc.id == tx.accountId);
      final destIdx = _accounts.indexWhere((acc) => acc.id == tx.toAccountId);
      if (originIdx != -1) {
        _accounts[originIdx].balance -= tx.amount;
      }
      if (originIdx != -1 && destIdx != -1) {
        final originAcc = _accounts[originIdx];
        final destAcc = _accounts[destIdx];
        final originCurrency = originAcc.currency ?? _selectedCurrency;
        final destCurrency = destAcc.currency ?? _selectedCurrency;
        
        final amountConvertido = convertirMoneda(tx.amount, originCurrency, destCurrency);
        _accounts[destIdx].balance += amountConvertido;
      }
    }

    // Actualizar transacción a pagada = true, y cambiar su fecha a la de hoy o la elegida
    _transactions[idxTx] = ModeloTransaccion(
      id: tx.id,
      title: tx.title,
      description: tx.description,
      amount: tx.amount,
      category: tx.category,
      date: fechaPago ?? DateTime.now(),
      type: tx.type,
      accountId: tx.accountId,
      toAccountId: tx.toAccountId,
      photoPath: tx.photoPath,
      esProgramada: tx.esProgramada,
      pagada: true,
      recurrencia: tx.recurrencia,
    );

    // Si tiene recurrencia, generar la siguiente transacción programada para el futuro
    if (tx.recurrencia != null && tx.recurrencia != 'una_vez') {
      final proximaFecha = calcularProximaFecha(tx.date, tx.recurrencia!);
      final proximaTx = ModeloTransaccion(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch + 1}',
        title: tx.title,
        description: tx.description,
        amount: tx.amount,
        category: tx.category,
        date: proximaFecha,
        type: tx.type,
        accountId: tx.accountId,
        toAccountId: tx.toAccountId,
        photoPath: tx.photoPath,
        esProgramada: true,
        pagada: false,
        recurrencia: tx.recurrencia,
      );
      _transactions.insert(0, proximaTx);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    await _saveTransactionsToPrefs(prefs);

    _notificarYSincronizar();
  }

  Future<void> _updateLocalTimestamp(SharedPreferences prefs) async {
    _lastLocalUpdateMillis = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('app_last_local_update_millis', _lastLocalUpdateMillis);
  }

  Future<void> _saveAccountsToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> accountsMapList = _accounts.map((acc) => acc.toMap()).toList();
    await prefs.setString('app_accounts', json.encode(accountsMapList));
    await _updateLocalTimestamp(prefs);
  }

  Future<void> _saveTransactionsToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> transactionsMapList = _transactions.map((tx) => tx.toMap()).toList();
    await prefs.setString('app_transactions', json.encode(transactionsMapList));
    await _updateLocalTimestamp(prefs);
  }

  Future<void> _saveSavingsGoalsToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> mapped = _savingsGoals.map((g) => g.toMap()).toList();
    await prefs.setString('app_savings_goals', json.encode(mapped));
    await _updateLocalTimestamp(prefs);
  }

  Future<void> _saveBudgetsToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> mapped = _budgets.map((b) => b.toMap()).toList();
    await prefs.setString('app_budgets', json.encode(mapped));
    await _updateLocalTimestamp(prefs);
  }

  Future<void> addSavingGoal(ModeloAhorro goal) async {
    _savingsGoals.add(goal);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveSavingsGoalsToPrefs(prefs);
    _notificarYSincronizar();
  }

  Future<void> updateSavingGoal(ModeloAhorro goal) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _savingsGoals[idx] = goal;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _saveSavingsGoalsToPrefs(prefs);
      _notificarYSincronizar();
    }
  }

  Future<void> deleteSavingGoal(String id) async {
    _savingsGoals.removeWhere((g) => g.id == id);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveSavingsGoalsToPrefs(prefs);
    _notificarYSincronizar();
  }

  Future<void> addFundsToSavingGoal(String id, double amount) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _savingsGoals[idx].currentAmount += amount;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _saveSavingsGoalsToPrefs(prefs);
      _notificarYSincronizar();
    }
  }

  Future<void> addOrUpdateBudget(String categoryName, double limitAmount) async {
    final idx = _budgets.indexWhere((b) => b.categoryName.toLowerCase() == categoryName.toLowerCase());
    if (idx != -1) {
      _budgets[idx] = ModeloPresupuesto(
        id: _budgets[idx].id,
        categoryName: categoryName,
        limitAmount: limitAmount,
      );
    } else {
      _budgets.add(ModeloPresupuesto(
        id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
        categoryName: categoryName,
        limitAmount: limitAmount,
      ));
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveBudgetsToPrefs(prefs);
    _notificarYSincronizar();
  }

  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveBudgetsToPrefs(prefs);
    _notificarYSincronizar();
  }

  double obtenerGastoMesActual({String? categoria}) {
    final now = DateTime.now();
    
    double total = 0.0;
    for (var tx in _transactions) {
      if (tx.pagada && tx.type == 'gasto' && tx.date.year == now.year && tx.date.month == now.month) {
        if (categoria == null || categoria == 'Global' || tx.category.toLowerCase() == categoria.toLowerCase()) {
          final acc = _accounts.firstWhere(
            (a) => a.id == tx.accountId,
            orElse: () => _accounts.isNotEmpty ? _accounts.first : ModeloCuenta(id: '', name: '', type: '', balance: 0, gradientIndex: 0),
          );
          final txCurrency = acc.currency ?? _selectedCurrency;
          total += convertirMoneda(tx.amount, txCurrency, _selectedCurrency);
        }
      }
    }
    return total;
  }

  Future<void> editAccount(String id, String name, String type, double balance, int gradientIndex, {String? customColorHex, String? customColorSecondaryHex, String? customColorThirdHex, double? stop1, double? stop2, double? stop3, bool useDarkText = false, String? currency, bool contabilizable = true}) async {
    final idx = _accounts.indexWhere((acc) => acc.id == id);
    if (idx != -1) {
       _accounts[idx] = ModeloCuenta(
        id: id,
        name: name,
        type: type,
        balance: balance,
        gradientIndex: gradientIndex,
        customColorHex: customColorHex,
        customColorSecondaryHex: customColorSecondaryHex,
        customColorThirdHex: customColorThirdHex,
        stop1: stop1,
        stop2: stop2,
        stop3: stop3,
        useDarkText: useDarkText,
        currency: currency ?? _accounts[idx].currency,
        contabilizable: contabilizable,
      );
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _saveAccountsToPrefs(prefs);
      _notificarYSincronizar();
    }
  }

  Future<bool> deleteAccount(String id) async {
    if (_accounts.length <= 1) {
      return false;
    }
    _accounts.removeWhere((acc) => acc.id == id);
    _transactions.removeWhere((tx) => tx.accountId == id || tx.toAccountId == id);
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    await _saveTransactionsToPrefs(prefs);
    _notificarYSincronizar();
    return true;
  }

  Future<void> clearAllData() async {
    print('=== DEBUG ESTADO: clearAllData - Iniciando ===');
    desactivarEscuchaTiempoReal();
    _accounts.clear();
    _transactions.clear();
    _categories.clear();
    _savingsGoals.clear();
    _hasCompletedOnboarding = false;
    _biometricEnabled = false;
    _pinEnabled = false;
    _hashedPin = '';

    print('=== DEBUG ESTADO: clearAllData - Obteniendo SharedPreferences ===');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print('=== DEBUG ESTADO: clearAllData - Removiendo SharedPreferences keys ===');
    await prefs.remove('app_onboarding_completed');
    await prefs.remove('app_accounts');
    await prefs.remove('app_transactions');
    await prefs.remove('app_categories');
    await prefs.remove('app_savings_goals');
    await prefs.remove('app_biometric_enabled');
    await prefs.remove('app_pin_enabled');
    await prefs.remove('app_pin_code');
    
    print('=== DEBUG ESTADO: clearAllData - Notificando listeners ===');
    notifyListeners();
    print('=== DEBUG ESTADO: clearAllData - Fin ===');
  }

  Future<void> eliminarDatosNubeYLocal(String uid) async {
    try {
      print('=== DEBUG ESTADO: Intentando borrar Firestore doc: usuarios/$uid ===');
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      await docRef.delete().timeout(const Duration(seconds: 4));
      print('=== DEBUG ESTADO: Firestore doc borrado con exito ===');
    } catch (e) {
      print('=== DEBUG ESTADO: Error al eliminar datos de la nube: $e ===');
    }
    print('=== DEBUG ESTADO: Llamando a clearAllData ===');
    await clearAllData();
    print('=== DEBUG ESTADO: clearAllData completado ===');
  }

  static final Map<String, IconData> galleryIcons = {
    // Alimentos y Bebidas
    'restaurant': Icons.restaurant_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'fastfood': Icons.fastfood_rounded,
    'local_bar': Icons.local_bar_rounded,
    'bakery_dining': Icons.bakery_dining_rounded,
    'icecream': Icons.icecream_rounded,
    'local_pizza': Icons.local_pizza_rounded,
    'cake': Icons.cake_rounded,
    'soup_kitchen': Icons.soup_kitchen_rounded,

    // Compras y Retail
    'shopping_cart': Icons.shopping_cart_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'store': Icons.store_rounded,
    'sell': Icons.sell_rounded,
    'checkroom': Icons.checkroom_rounded,
    'local_mall': Icons.local_mall_rounded,
    'loyalty': Icons.loyalty_rounded,
    'storefront': Icons.storefront_rounded,
    'local_offer': Icons.local_offer_rounded,
    'outlet': Icons.outlet_rounded,

    // Transporte y Viajes
    'directions_car': Icons.directions_car_rounded,
    'directions_bus': Icons.directions_bus_rounded,
    'directions_subway': Icons.directions_subway_rounded,
    'flight': Icons.flight_rounded,
    'local_taxi': Icons.local_taxi_rounded,
    'pedal_bike': Icons.pedal_bike_rounded,
    'train': Icons.train_rounded,
    'hotel': Icons.hotel_rounded,
    'beach_access': Icons.beach_access_rounded,
    'commute': Icons.commute_rounded,
    'luggage': Icons.luggage_rounded,

    // Servicios y Facturas
    'electrical_services': Icons.electrical_services_rounded,
    'water_drop': Icons.water_drop_rounded,
    'router': Icons.router_rounded,
    'tv': Icons.tv_rounded,
    'phone_android': Icons.phone_android_rounded,
    'bolt': Icons.bolt_rounded,
    'lightbulb': Icons.lightbulb_rounded,
    'wifi': Icons.wifi_rounded,
    'gas_meter': Icons.gas_meter_rounded,
    'power': Icons.power_rounded,

    // Entretenimiento y Ocio
    'sports_esports': Icons.sports_esports_rounded,
    'movie': Icons.movie_rounded,
    'celebration': Icons.celebration_rounded,
    'music_note': Icons.music_note_rounded,
    'sports_soccer': Icons.sports_soccer_rounded,
    'palette': Icons.palette_rounded,
    'casino': Icons.casino_rounded,
    'theater_comedy': Icons.theater_comedy_rounded,
    'brush': Icons.brush_rounded,
    'confirmation_number': Icons.confirmation_number_rounded,

    // Hogar y Familia
    'home': Icons.home_rounded,
    'pets': Icons.pets_rounded,
    'child_care': Icons.child_care_rounded,
    'family_restroom': Icons.family_restroom_rounded,
    'handyman': Icons.handyman_rounded,
    'chair': Icons.chair_rounded,
    'house': Icons.house_rounded,
    'grass': Icons.grass_rounded,
    'cleaning_services': Icons.cleaning_services_rounded,
    'weekend': Icons.weekend_rounded,

    // Educación y Trabajo
    'school': Icons.school_rounded,
    'work': Icons.work_rounded,
    'laptop': Icons.laptop_chromebook_rounded,
    'laptop_chromebook': Icons.laptop_chromebook_rounded,
    'business_center': Icons.business_center_rounded,
    'menu_book': Icons.menu_book_rounded,
    'assignment': Icons.assignment_rounded,
    'science': Icons.science_rounded,
    'psychology': Icons.psychology_rounded,
    'draw': Icons.draw_rounded,

    // Salud y Bienestar
    'local_hospital': Icons.local_hospital_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'medication': Icons.medication_rounded,
    'spa': Icons.spa_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'healing': Icons.healing_rounded,
    'medical_services': Icons.medical_services_rounded,
    'face': Icons.face_rounded,
    'masks': Icons.masks_rounded,

    // Finanzas
    'savings': Icons.savings_rounded,
    'payments': Icons.payments_rounded,
    'trending_up': Icons.trending_up_rounded,
    'account_balance': Icons.account_balance_rounded,
    'monetization_on': Icons.monetization_on_rounded,
    'show_chart': Icons.show_chart_rounded,
    'attach_money': Icons.attach_money_rounded,
    'wallet': Icons.wallet_rounded,
    'percent': Icons.percent_rounded,
    'credit_card': Icons.credit_card_rounded,

    // Otros y Varios
    'category': Icons.category_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'build': Icons.build_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'redeem': Icons.redeem_rounded,
    'verified_user': Icons.verified_user_rounded,
    'clean_hands': Icons.clean_hands_rounded,
    'vpn_key': Icons.vpn_key_rounded,
    'favorite': Icons.favorite_rounded,
    'remove_circle_outline': Icons.remove_circle_outline_rounded,
  };

  static final List<ModeloCategoria> categoriasPorDefecto = [
    // ALIMENTACIÓN (Comida)
    ModeloCategoria(id: 'cat_comida', name: 'Alimentación', parentId: null, iconCode: 'restaurant', hexColor: '#FF9800'),
    ModeloCategoria(id: 'cat_comida_super', name: 'Supermercado', parentId: 'cat_comida', iconCode: 'shopping_cart', hexColor: '#FF9800'),
    ModeloCategoria(id: 'cat_comida_rest', name: 'Restaurantes', parentId: 'cat_comida', iconCode: 'restaurant', hexColor: '#FF9800'),
    ModeloCategoria(id: 'cat_comida_cafe', name: 'Cafetería', parentId: 'cat_comida', iconCode: 'local_cafe', hexColor: '#FF9800'),
    ModeloCategoria(id: 'cat_comida_rapida', name: 'Comida Rápida', parentId: 'cat_comida', iconCode: 'fastfood', hexColor: '#FF9800'),
    ModeloCategoria(id: 'cat_comida_bebidas', name: 'Bebidas/Licores', parentId: 'cat_comida', iconCode: 'local_bar', hexColor: '#FF9800'),

    // TRANSPORTE
    ModeloCategoria(id: 'cat_transporte', name: 'Transporte', parentId: null, iconCode: 'directions_car', hexColor: '#0284C7'),
    ModeloCategoria(id: 'cat_trans_gas', name: 'Combustible', parentId: 'cat_transporte', iconCode: 'local_gas_station', hexColor: '#0284C7'),
    ModeloCategoria(id: 'cat_trans_mantenimiento', name: 'Mantenimiento de Auto', parentId: 'cat_transporte', iconCode: 'build', hexColor: '#0284C7'),
    ModeloCategoria(id: 'cat_trans_publico', name: 'Transporte Público', parentId: 'cat_transporte', iconCode: 'directions_bus', hexColor: '#0284C7'),
    ModeloCategoria(id: 'cat_trans_taxi', name: 'Taxi / Uber', parentId: 'cat_transporte', iconCode: 'local_taxi', hexColor: '#0284C7'),
    ModeloCategoria(id: 'cat_trans_seguro', name: 'Seguro de Auto', parentId: 'cat_transporte', iconCode: 'verified_user', hexColor: '#0284C7'),

    // VIVIENDA / HOGAR
    ModeloCategoria(id: 'cat_vivienda', name: 'Vivienda', parentId: null, iconCode: 'home', hexColor: '#009688'),
    ModeloCategoria(id: 'cat_viv_alquiler', name: 'Alquiler / Hipoteca', parentId: 'cat_vivienda', iconCode: 'vpn_key', hexColor: '#009688'),
    ModeloCategoria(id: 'cat_viv_servicios', name: 'Servicios Básicos (Luz/Agua)', parentId: 'cat_vivienda', iconCode: 'water_drop', hexColor: '#009688'),
    ModeloCategoria(id: 'cat_viv_internet', name: 'Internet / Tv Cable', parentId: 'cat_vivienda', iconCode: 'router', hexColor: '#009688'),
    ModeloCategoria(id: 'cat_viv_limpieza', name: 'Limpieza / Mantenimiento', parentId: 'cat_vivienda', iconCode: 'clean_hands', hexColor: '#009688'),
    ModeloCategoria(id: 'cat_viv_muebles', name: 'Decoración / Muebles', parentId: 'cat_vivienda', iconCode: 'weekend', hexColor: '#009688'),

    // ENTRETENIMIENTO / OCIO
    ModeloCategoria(id: 'cat_entretenimiento', name: 'Entretenimiento', parentId: null, iconCode: 'sports_esports', hexColor: '#EC4899'),
    ModeloCategoria(id: 'cat_ent_cine', name: 'Cine y Teatro', parentId: 'cat_entretenimiento', iconCode: 'movie', hexColor: '#EC4899'),
    ModeloCategoria(id: 'cat_ent_streaming', name: 'Servicios Streaming', parentId: 'cat_entretenimiento', iconCode: 'tv', hexColor: '#EC4899'),
    ModeloCategoria(id: 'cat_ent_videojuegos', name: 'Videojuegos', parentId: 'cat_entretenimiento', iconCode: 'sports_esports', hexColor: '#EC4899'),
    ModeloCategoria(id: 'cat_ent_viajes', name: 'Viajes / Vacaciones', parentId: 'cat_entretenimiento', iconCode: 'flight', hexColor: '#EC4899'),
    ModeloCategoria(id: 'cat_ent_eventos', name: 'Conciertos / Eventos', parentId: 'cat_entretenimiento', iconCode: 'confirmation_number', hexColor: '#EC4899'),

    // SALUD Y BIENESTAR
    ModeloCategoria(id: 'cat_salud', name: 'Salud y Bienestar', parentId: null, iconCode: 'local_hospital', hexColor: '#EF5350'),
    ModeloCategoria(id: 'cat_sal_medico', name: 'Consultas Médicas', parentId: 'cat_salud', iconCode: 'medical_services', hexColor: '#EF5350'),
    ModeloCategoria(id: 'cat_sal_farmacia', name: 'Farmacia / Medicinas', parentId: 'cat_salud', iconCode: 'medication', hexColor: '#EF5350'),
    ModeloCategoria(id: 'cat_sal_gimnasio', name: 'Gimnasio / Deportes', parentId: 'cat_salud', iconCode: 'fitness_center', hexColor: '#EF5350'),
    ModeloCategoria(id: 'cat_sal_personal', name: 'Cuidado Personal', parentId: 'cat_salud', iconCode: 'face', hexColor: '#EF5350'),

    // EDUCACIÓN
    ModeloCategoria(id: 'cat_educacion', name: 'Educación', parentId: null, iconCode: 'school', hexColor: '#3F51B5'),
    ModeloCategoria(id: 'cat_edu_matricula', name: 'Matrícula / Mensualidad', parentId: 'cat_educacion', iconCode: 'receipt_long', hexColor: '#3F51B5'),
    ModeloCategoria(id: 'cat_edu_libros', name: 'Libros / Útiles', parentId: 'cat_educacion', iconCode: 'book', hexColor: '#3F51B5'),
    ModeloCategoria(id: 'cat_edu_cursos', name: 'Cursos / Certificaciones', parentId: 'cat_educacion', iconCode: 'laptop_chromebook', hexColor: '#3F51B5'),

    // COMPRAS
    ModeloCategoria(id: 'cat_compras', name: 'Compras', parentId: null, iconCode: 'shopping_bag', hexColor: '#E91E63'),
    ModeloCategoria(id: 'cat_comp_ropa', name: 'Ropa y Calzado', parentId: 'cat_compras', iconCode: 'checkroom', hexColor: '#E91E63'),
    ModeloCategoria(id: 'cat_comp_tecnologia', name: 'Tecnología / Gadgets', parentId: 'cat_compras', iconCode: 'devices', hexColor: '#E91E63'),
    ModeloCategoria(id: 'cat_comp_regalos', name: 'Regalos / Detalles', parentId: 'cat_compras', iconCode: 'card_giftcard', hexColor: '#E91E63'),
    ModeloCategoria(id: 'cat_comp_mascotas', name: 'Mascotas', parentId: 'cat_compras', iconCode: 'pets', hexColor: '#E91E63'),

    // FINANZAS Y BANCO
    ModeloCategoria(id: 'cat_finanzas', name: 'Finanzas', parentId: null, iconCode: 'account_balance', hexColor: '#607D8B'),
    ModeloCategoria(id: 'cat_fin_impuestos', name: 'Impuestos', parentId: 'cat_finanzas', iconCode: 'receipt', hexColor: '#607D8B'),
    ModeloCategoria(id: 'cat_fin_comisiones', name: 'Comisiones / Intereses', parentId: 'cat_finanzas', iconCode: 'monetization_on', hexColor: '#607D8B'),
    ModeloCategoria(id: 'cat_fin_deudas', name: 'Préstamos / Deudas', parentId: 'cat_finanzas', iconCode: 'credit_card', hexColor: '#607D8B'),
    ModeloCategoria(id: 'cat_fin_inversiones', name: 'Inversiones', parentId: 'cat_finanzas', iconCode: 'trending_up', hexColor: '#607D8B'),

    // INGRESOS
    ModeloCategoria(id: 'cat_ingresos', name: 'Ingresos', parentId: null, iconCode: 'work', hexColor: '#10B981'),
    ModeloCategoria(id: 'cat_ing_nomina', name: 'Salario / Nómina', parentId: 'cat_ingresos', iconCode: 'payments', hexColor: '#10B981'),
    ModeloCategoria(id: 'cat_ing_freelance', name: 'Freelance / Trabajos', parentId: 'cat_ingresos', iconCode: 'laptop', hexColor: '#10B981'),
    ModeloCategoria(id: 'cat_ing_ventas', name: 'Ventas / Negocio', parentId: 'cat_ingresos', iconCode: 'storefront', hexColor: '#10B981'),
    ModeloCategoria(id: 'cat_ing_regalos', name: 'Regalos / Donaciones', parentId: 'cat_ingresos', iconCode: 'volunteer_activism', hexColor: '#10B981'),

    // OTROS
    ModeloCategoria(id: 'cat_otros', name: 'Otros', parentId: null, iconCode: 'category', hexColor: '#64748B'),
    ModeloCategoria(id: 'cat_otr_donaciones', name: 'Ayuda social / Donación', parentId: 'cat_otros', iconCode: 'favorite', hexColor: '#64748B'),
    ModeloCategoria(id: 'cat_otr_perdidas', name: 'Ajustes / Pérdidas', parentId: 'cat_otros', iconCode: 'remove_circle_outline', hexColor: '#64748B'),
  ];

  Future<void> _saveCategoriesToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> categoriesMapList = _categories.map((cat) => cat.toMap()).toList();
    await prefs.setString('app_categories', json.encode(categoriesMapList));
    await _updateLocalTimestamp(prefs);
  }

  Future<void> addCategory(String name, String? parentId, String iconCode, String hexColor) async {
    final newCategory = ModeloCategoria(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      parentId: parentId,
      iconCode: iconCode,
      hexColor: hexColor,
    );
    _categories.add(newCategory);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveCategoriesToPrefs(prefs);
    _notificarYSincronizar();
  }

  Future<void> editCategory(String id, String name, String? parentId, String iconCode, String hexColor) async {
    final idx = _categories.indexWhere((cat) => cat.id == id);
    if (idx != -1) {
      _categories[idx] = ModeloCategoria(
        id: id,
        name: name,
        parentId: parentId,
        iconCode: iconCode,
        hexColor: hexColor,
      );
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _saveCategoriesToPrefs(prefs);
      _notificarYSincronizar();
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((cat) => cat.id == id || cat.parentId == id);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveCategoriesToPrefs(prefs);
    _notificarYSincronizar();
  }

  /// Notifica la UI y programa sincronizacion con la nube.
  /// Usar SOLO en metodos que modifican datos persistentes.
  void _notificarYSincronizar() {
    notifyListeners();
    _programarSubidaANube();
  }

  /// Programa una subida a Firestore con debounce de 3 segundos.
  /// Seguro de llamar multiples veces: agrupa las llamadas.
  void _programarSubidaANube() {
    if (_isSyncing) return;
    final user = ServicioAutenticacion().currentUser;
    if (user == null || user.uid.startsWith('demo_') || _accounts.isEmpty) return;
    
    _debounceSubida?.cancel();
    _debounceSubida = Timer(const Duration(seconds: 3), () {
      if (!_isSyncing) {
        _subirDatosANube(user.uid);
      }
    });
  }

  Future<bool> sincronizarConNube(String uid) async {
    activarEscuchaTiempoReal(uid);
    _isSyncing = true; // Bloquear re-subida durante sincronizacion inicial
    try {
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final docSnap = await docRef.get().timeout(const Duration(seconds: 4));

      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null) {
          // Comprobar marcas de tiempo para evitar sobrescribir datos locales offline
          final dynamic cloudTimestamp = data['ultimaActualizacion'];
          if (cloudTimestamp != null && cloudTimestamp is Timestamp) {
            final int cloudMillis = cloudTimestamp.millisecondsSinceEpoch;
            // Si los datos locales son significativamente mas nuevos, subimos los locales en lugar de descargar
            if (_lastLocalUpdateMillis > cloudMillis + 2000) {
              await _subirDatosANube(uid);
              return true;
            }
          }

          if (data['esTemaOscuro'] != null) {
            _esTemaOscuro = data['esTemaOscuro'] as bool;
          }
          if (data['colorPrincipal'] != null) {
            _colorPrincipal = Color(data['colorPrincipal'] as int);
          }
          if (data['tiposCambio'] != null) {
            final Map<String, dynamic> mapCloud = data['tiposCambio'] as Map<String, dynamic>;
            _tiposCambio = mapCloud.map((key, val) => MapEntry(key, (val as num).toDouble()));
          } else if (data['tipoCambioUsd'] != null) {
            _tiposCambio['USD'] = (data['tipoCambioUsd'] as num).toDouble();
          }

          if (data['cuentas'] != null) {
            final List<dynamic> accountsData = data['cuentas'];
            _accounts = accountsData.map((item) => ModeloCuenta.fromMap(Map<String, dynamic>.from(item))).toList();
            if (_accounts.isNotEmpty) {
              _hasCompletedOnboarding = true;
            }
          }

          if (data['transacciones'] != null) {
            final List<dynamic> transactionsData = data['transacciones'];
            _transactions = transactionsData.map((item) => ModeloTransaccion.fromMap(Map<String, dynamic>.from(item))).toList();
          }

          if (data['categorias'] != null) {
            final List<dynamic> categoriesData = data['categorias'];
            _categories = categoriesData.map((item) => ModeloCategoria.fromMap(Map<String, dynamic>.from(item))).toList();
          }

          if (data['ahorros'] != null) {
            final List<dynamic> savingsData = data['ahorros'];
            _savingsGoals = savingsData.map((item) => ModeloAhorro.fromMap(Map<String, dynamic>.from(item))).toList();
          }

          if (data['presupuestos'] != null) {
            final List<dynamic> budgetsData = data['presupuestos'];
            _budgets = budgetsData.map((item) => ModeloPresupuesto.fromMap(Map<String, dynamic>.from(item))).toList();
          }

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('app_dark_mode', _esTemaOscuro);
          await prefs.setInt('app_primary_color', _colorPrincipal.toARGB32());
          await prefs.setString('app_tipos_cambio', json.encode(_tiposCambio));
          await prefs.setDouble('app_tipo_cambio_usd', _tiposCambio['USD'] ?? 6.97);
          await prefs.setBool('app_onboarding_completed', _hasCompletedOnboarding);
          
          await _saveAccountsToPrefs(prefs);
          await _saveTransactionsToPrefs(prefs);
          await _saveCategoriesToPrefs(prefs);
          await _saveSavingsGoalsToPrefs(prefs);
          await _saveBudgetsToPrefs(prefs);

          // Asignar el timestamp oficial de la nube al final para evitar que los metodos de guardado lo pisen
          if (cloudTimestamp != null && cloudTimestamp is Timestamp) {
            _lastLocalUpdateMillis = cloudTimestamp.millisecondsSinceEpoch;
            await prefs.setInt('app_last_local_update_millis', _lastLocalUpdateMillis);
          }

          super.notifyListeners();
        }
      } else {
        if (_accounts.isNotEmpty) {
          await _subirDatosANube(uid);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error en la sincronizacion con la nube: $e');
      return false;
    } finally {
      _isSyncing = false; // Siempre desbloquear al terminar
    }
  }

  Future<void> _subirDatosANube(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final accountsMapList = _accounts.map((acc) => acc.toMap()).toList();
      final transactionsMapList = _transactions.map((tx) => tx.toMap()).toList();
      final categoriesMapList = _categories.map((cat) => cat.toMap()).toList();
      final savingsMapList = _savingsGoals.map((g) => g.toMap()).toList();
      final budgetsMapList = _budgets.map((b) => b.toMap()).toList();

      await docRef.set({
        'uid': uid,
        'esTemaOscuro': _esTemaOscuro,
        'colorPrincipal': _colorPrincipal.toARGB32(),
        'tiposCambio': _tiposCambio,
        'tipoCambioUsd': _tiposCambio['USD'] ?? 6.97,
        'cuentas': accountsMapList,
        'transacciones': transactionsMapList,
        'categorias': categoriesMapList,
        'ahorros': savingsMapList,
        'presupuestos': budgetsMapList,
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 4));

      // Actualizar timestamp local al momento actual tras la subida exitosa
      _lastLocalUpdateMillis = DateTime.now().millisecondsSinceEpoch;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_last_local_update_millis', _lastLocalUpdateMillis);
    } catch (e) {
      debugPrint('Error al subir datos a la nube: $e');
    }
  }

  void activarEscuchaTiempoReal(String uid) {
    _nubeSubscription?.cancel();
    _nubeSubscription = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .snapshots()
        .listen((docSnap) async {
      try {
        if (!docSnap.exists) return;
        final data = docSnap.data();
        if (data == null) return;

        // Verificar timestamps ANTES de bloquear
        final dynamic cloudTimestamp = data['ultimaActualizacion'];
        if (cloudTimestamp != null && cloudTimestamp is Timestamp) {
          final int cloudMillis = cloudTimestamp.millisecondsSinceEpoch;
          if (_lastLocalUpdateMillis > cloudMillis + 2000) return;
          if (_lastLocalUpdateMillis == cloudMillis) return;
        }

        // Solo ahora bloquear la sincronizacion (despues de las comprobaciones de early-return)
        _isSyncing = true;
        try {
          if (data['esTemaOscuro'] != null) {
            _esTemaOscuro = data['esTemaOscuro'] as bool;
          }
          if (data['colorPrincipal'] != null) {
            _colorPrincipal = Color(data['colorPrincipal'] as int);
          }
          if (data['tiposCambio'] != null) {
            final Map<String, dynamic> mapCloud = data['tiposCambio'] as Map<String, dynamic>;
            _tiposCambio = mapCloud.map((key, val) => MapEntry(key, (val as num).toDouble()));
          } else if (data['tipoCambioUsd'] != null) {
            _tiposCambio['USD'] = (data['tipoCambioUsd'] as num).toDouble();
          }

          if (data['cuentas'] != null) {
            final List<dynamic> accountsData = data['cuentas'];
            _accounts = accountsData.map((item) => ModeloCuenta.fromMap(Map<String, dynamic>.from(item))).toList();
            if (_accounts.isNotEmpty) {
              _hasCompletedOnboarding = true;
            }
          }

          if (data['transacciones'] != null) {
            final List<dynamic> transactionsData = data['transacciones'];
            _transactions = transactionsData.map((item) => ModeloTransaccion.fromMap(Map<String, dynamic>.from(item))).toList();
          }

          if (data['categorias'] != null) {
            final List<dynamic> categoriesData = data['categorias'];
            _categories = categoriesData.map((item) => ModeloCategoria.fromMap(Map<String, dynamic>.from(item))).toList();
          }

          if (data['ahorros'] != null) {
            final List<dynamic> savingsData = data['ahorros'];
            _savingsGoals = savingsData.map((item) => ModeloAhorro.fromMap(Map<String, dynamic>.from(item))).toList();
          }

          if (data['presupuestos'] != null) {
            final List<dynamic> budgetsData = data['presupuestos'];
            _budgets = budgetsData.map((item) => ModeloPresupuesto.fromMap(Map<String, dynamic>.from(item))).toList();
          }

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('app_dark_mode', _esTemaOscuro);
          await prefs.setInt('app_primary_color', _colorPrincipal.toARGB32());
          await prefs.setString('app_tipos_cambio', json.encode(_tiposCambio));
          await prefs.setDouble('app_tipo_cambio_usd', _tiposCambio['USD'] ?? 6.97);
          await prefs.setBool('app_onboarding_completed', _hasCompletedOnboarding);
          
          await _saveAccountsToPrefs(prefs);
          await _saveTransactionsToPrefs(prefs);
          await _saveCategoriesToPrefs(prefs);
          await _saveSavingsGoalsToPrefs(prefs);
          await _saveBudgetsToPrefs(prefs);

          if (cloudTimestamp != null && cloudTimestamp is Timestamp) {
            _lastLocalUpdateMillis = cloudTimestamp.millisecondsSinceEpoch;
            await prefs.setInt('app_last_local_update_millis', _lastLocalUpdateMillis);
          }

          notifyListeners(); // Ya no hay override, es seguro llamar directamente
        } finally {
          _isSyncing = false; // SIEMPRE desbloquear, incluso si hay error
        }
      } catch (e) {
        _isSyncing = false;
        debugPrint('Error en la escucha en tiempo real: $e');
      }
    }, onError: (error) {
      _isSyncing = false;
      debugPrint('Error en la escucha en tiempo real: $error');
    });
  }

  void desactivarEscuchaTiempoReal() {
    _nubeSubscription?.cancel();
    _nubeSubscription = null;
  }
}
