import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'servicio_autenticacion.dart';

class ModeloCuenta {
  final String id;
  final String name;
  final String type;
  double balance;
  final int gradientIndex;
  final String? customColorHex;
  final String? customColorSecondaryHex;
  final bool? useDarkText;

  ModeloCuenta({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.gradientIndex,
    this.customColorHex,
    this.customColorSecondaryHex,
    this.useDarkText,
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
      'usarTextoOscuro': useDarkText,
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
      useDarkText: map['usarTextoOscuro'] ?? false,
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
    );
  }
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

class EstadoApp extends ChangeNotifier {
  String _selectedLanguage = 'es';
  String _selectedCurrency = 'BOB';
  bool _hasCompletedOnboarding = false;
  List<ModeloCuenta> _accounts = [];
  List<ModeloTransaccion> _transactions = [];
  List<ModeloCategoria> _categories = [];
  List<ModeloAhorro> _savingsGoals = [];
  bool _esTemaOscuro = false;
  Color _colorPrincipal = const Color(0xFF000000);
  int _selectedDockIndex = 0;
  int _selectedSettingsSubView = 0;

  String get selectedLanguage => _selectedLanguage;
  String get selectedCurrency => _selectedCurrency;
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
  bool get esTemaOscuro => _esTemaOscuro;
  Color get colorPrincipal => _colorPrincipal;

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

  double get totalBalance {
    double total = 0.0;
    for (var acc in _accounts) {
      if (acc.type == 'Credito' || acc.type == 'Crédito') {
        total -= acc.balance;
      } else {
        total += acc.balance;
      }
    }
    return total;
  }

  double get totalIncome {
    double total = 0.0;
    for (var tx in _transactions) {
      if (tx.type == 'ingreso') {
        total += tx.amount;
      }
    }
    return total;
  }

  double get totalExpenses {
    double total = 0.0;
    for (var tx in _transactions) {
      if (tx.type == 'gasto') {
        total += tx.amount;
      }
    }
    return total;
  }

  EstadoApp() {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    _selectedLanguage = prefs.getString('app_language') ?? 'es';
    _selectedCurrency = prefs.getString('app_currency') ?? 'BOB';
    _hasCompletedOnboarding = prefs.getBool('app_onboarding_completed') ?? false;
    _esTemaOscuro = prefs.getBool('app_dark_mode') ?? false;

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

    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _selectedLanguage = lang;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _selectedCurrency = currency;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_currency', currency);
    notifyListeners();
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

    notifyListeners();
  }

  Future<void> setColorPrincipal(Color color) async {
    _colorPrincipal = color;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_primary_color', color.toARGB32());
    notifyListeners();
  }

  Future<void> completeOnboarding(String firstAccountName, String firstAccountType, double initialBalance) async {
    _accounts.clear();
    _transactions.clear();

    final firstAccount = ModeloCuenta(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      name: firstAccountName,
      type: firstAccountType,
      balance: initialBalance,
      gradientIndex: 0,
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

    notifyListeners();
  }

  Future<ModeloCuenta> addAccount(String name, String type, double balance, int gradientIndex, {String? customColorHex, String? customColorSecondaryHex, bool useDarkText = false}) async {
    final newAccount = ModeloCuenta(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}_${_accounts.length}',
      name: name,
      type: type,
      balance: balance,
      gradientIndex: gradientIndex,
      customColorHex: customColorHex,
      customColorSecondaryHex: customColorSecondaryHex,
      useDarkText: useDarkText,
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
    notifyListeners();
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
  }) async {
    final newTx = ModeloTransaccion(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      amount: amount,
      category: category,
      date: DateTime.now(),
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
      photoPath: photoPath,
    );

    _transactions.insert(0, newTx);

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
      if (destIdx != -1) {
        _accounts[destIdx].balance += amount;
      }
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    await _saveTransactionsToPrefs(prefs);

    notifyListeners();
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
  }) async {
    // Buscar la transaccion original
    final idxTx = _transactions.indexWhere((tx) => tx.id == id);
    if (idxTx == -1) return;
    final oldTx = _transactions[idxTx];

    // Revertir balances de la transaccion original
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
      if (destIdx != -1) {
        _accounts[destIdx].balance -= oldTx.amount;
      }
    }

    // Aplicar balances de la nueva transaccion
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
      if (destIdx != -1) {
        _accounts[destIdx].balance += amount;
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
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    await _saveTransactionsToPrefs(prefs);

    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final idxTx = _transactions.indexWhere((tx) => tx.id == id);
    if (idxTx == -1) return;
    final oldTx = _transactions[idxTx];

    // Revertir balances antes de eliminar
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
      if (destIdx != -1) {
        _accounts[destIdx].balance -= oldTx.amount;
      }
    }

    _transactions.removeAt(idxTx);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    await _saveTransactionsToPrefs(prefs);

    notifyListeners();
  }

  Future<void> _saveAccountsToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> accountsMapList = _accounts.map((acc) => acc.toMap()).toList();
    await prefs.setString('app_accounts', json.encode(accountsMapList));
  }

  Future<void> _saveTransactionsToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> transactionsMapList = _transactions.map((tx) => tx.toMap()).toList();
    await prefs.setString('app_transactions', json.encode(transactionsMapList));
  }

  Future<void> _saveSavingsGoalsToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> mapped = _savingsGoals.map((g) => g.toMap()).toList();
    await prefs.setString('app_savings_goals', json.encode(mapped));
  }

  Future<void> addSavingGoal(ModeloAhorro goal) async {
    _savingsGoals.add(goal);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveSavingsGoalsToPrefs(prefs);
    notifyListeners();
  }

  Future<void> updateSavingGoal(ModeloAhorro goal) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _savingsGoals[idx] = goal;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _saveSavingsGoalsToPrefs(prefs);
      notifyListeners();
    }
  }

  Future<void> deleteSavingGoal(String id) async {
    _savingsGoals.removeWhere((g) => g.id == id);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveSavingsGoalsToPrefs(prefs);
    notifyListeners();
  }

  Future<void> addFundsToSavingGoal(String id, double amount) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _savingsGoals[idx].currentAmount += amount;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _saveSavingsGoalsToPrefs(prefs);
      notifyListeners();
    }
  }

  Future<void> editAccount(String id, String name, String type, double balance, int gradientIndex, {String? customColorHex, String? customColorSecondaryHex, bool useDarkText = false}) async {
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
        useDarkText: useDarkText,
      );
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _saveAccountsToPrefs(prefs);
      notifyListeners();
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
    notifyListeners();
    return true;
  }

  Future<void> clearAllData() async {
    print('=== DEBUG ESTADO: clearAllData - Iniciando ===');
    _accounts.clear();
    _transactions.clear();
    _categories.clear();
    _savingsGoals.clear();
    _hasCompletedOnboarding = false;

    print('=== DEBUG ESTADO: clearAllData - Obteniendo SharedPreferences ===');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print('=== DEBUG ESTADO: clearAllData - Removiendo SharedPreferences keys ===');
    await prefs.remove('app_onboarding_completed');
    await prefs.remove('app_accounts');
    await prefs.remove('app_transactions');
    await prefs.remove('app_categories');
    await prefs.remove('app_savings_goals');
    
    print('=== DEBUG ESTADO: clearAllData - Notificando listeners ===');
    notifyListeners();
    print('=== DEBUG ESTADO: clearAllData - Fin ===');
  }

  Future<void> eliminarDatosNubeYLocal(String uid) async {
    try {
      if (!uid.startsWith('demo_')) {
        print('=== DEBUG ESTADO: Intentando borrar Firestore doc: usuarios/$uid ===');
        final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
        await docRef.delete().timeout(const Duration(seconds: 4));
        print('=== DEBUG ESTADO: Firestore doc borrado con exito ===');
      } else {
        print('=== DEBUG ESTADO: Es usuario demo, omitiendo borrado Firestore ===');
      }
    } catch (e) {
      print('=== DEBUG ESTADO: Error al eliminar datos de la nube: $e ===');
    }
    print('=== DEBUG ESTADO: Llamando a clearAllData ===');
    await clearAllData();
    print('=== DEBUG ESTADO: clearAllData completado ===');
  }

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
    notifyListeners();
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
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((cat) => cat.id == id || cat.parentId == id);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveCategoriesToPrefs(prefs);
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    final user = ServicioAutenticacion().currentUser;
    if (user != null && !user.uid.startsWith('demo_') && _accounts.isNotEmpty) {
      _subirDatosANube(user.uid);
    }
  }

  Future<bool> sincronizarConNube(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final docSnap = await docRef.get().timeout(const Duration(seconds: 4));

      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null) {
          if (data['esTemaOscuro'] != null) {
            _esTemaOscuro = data['esTemaOscuro'] as bool;
          }
          if (data['colorPrincipal'] != null) {
            _colorPrincipal = Color(data['colorPrincipal'] as int);
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

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('app_dark_mode', _esTemaOscuro);
          await prefs.setInt('app_primary_color', _colorPrincipal.toARGB32());
          await prefs.setBool('app_onboarding_completed', _hasCompletedOnboarding);
          await _saveAccountsToPrefs(prefs);
          await _saveTransactionsToPrefs(prefs);
          await _saveCategoriesToPrefs(prefs);
          await _saveSavingsGoalsToPrefs(prefs);

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
    }
  }

  Future<void> _subirDatosANube(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final accountsMapList = _accounts.map((acc) => acc.toMap()).toList();
      final transactionsMapList = _transactions.map((tx) => tx.toMap()).toList();
      final categoriesMapList = _categories.map((cat) => cat.toMap()).toList();
      final savingsMapList = _savingsGoals.map((g) => g.toMap()).toList();

      await docRef.set({
        'uid': uid,
        'esTemaOscuro': _esTemaOscuro,
        'colorPrincipal': _colorPrincipal.toARGB32(),
        'cuentas': accountsMapList,
        'transacciones': transactionsMapList,
        'categorias': categoriesMapList,
        'ahorros': savingsMapList,
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error al subir datos a la nube: $e');
    }
  }
}
