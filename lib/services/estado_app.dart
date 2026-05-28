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
      'name': name,
      'type': type,
      'balance': balance,
      'gradientIndex': gradientIndex,
      'customColorHex': customColorHex,
      'customColorSecondaryHex': customColorSecondaryHex,
      'useDarkText': useDarkText,
    };
  }

  factory ModeloCuenta.fromMap(Map<String, dynamic> map) {
    return ModeloCuenta(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      gradientIndex: map['gradientIndex'] ?? 0,
      customColorHex: map['customColorHex'],
      customColorSecondaryHex: map['customColorSecondaryHex'],
      useDarkText: map['useDarkText'] ?? false,
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
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'type': type,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'photoPath': photoPath,
    };
  }

  factory ModeloTransaccion.fromMap(Map<String, dynamic> map) {
    return ModeloTransaccion(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      type: map['type'] ?? 'gasto',
      accountId: map['accountId'] ?? '',
      toAccountId: map['toAccountId'],
      photoPath: map['photoPath'],
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
      'name': name,
      'parentId': parentId,
      'iconCode': iconCode,
      'hexColor': hexColor,
    };
  }

  factory ModeloCategoria.fromMap(Map<String, dynamic> map) {
    return ModeloCategoria(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      parentId: map['parentId'],
      iconCode: map['iconCode'] ?? 'bubble_chart',
      hexColor: map['hexColor'] ?? '#E2E8F0',
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
  bool _esTemaOscuro = false;
  Color _colorPrincipal = const Color(0xFFFF2D55);

  String get selectedLanguage => _selectedLanguage;
  String get selectedCurrency => _selectedCurrency;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  List<ModeloCuenta> get accounts => _accounts;
  List<ModeloTransaccion> get transactions => _transactions;
  List<ModeloCategoria> get categories => _categories;
  bool get esTemaOscuro => _esTemaOscuro;
  Color get colorPrincipal => _colorPrincipal;

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

    final int colorVal = prefs.getInt('app_primary_color') ?? const Color(0xFFFF2D55).toARGB32();
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

    if (_categories.isEmpty) {
      _inicializarCategoriasPredeterminadas();
      await _saveCategoriesToPrefs(prefs);
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

  Future<void> addAccount(String name, String type, double balance, int gradientIndex, {String? customColorHex, String? customColorSecondaryHex, bool useDarkText = false}) async {
    final newAccount = ModeloCuenta(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
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
    _accounts.clear();
    _transactions.clear();
    _categories.clear();
    _hasCompletedOnboarding = false;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_onboarding_completed');
    await prefs.remove('app_accounts');
    await prefs.remove('app_transactions');
    await prefs.remove('app_categories');
    
    notifyListeners();
  }

  void _inicializarCategoriasPredeterminadas() {
    _categories = [
      ModeloCategoria(id: 'cat_comida', name: 'Comida', iconCode: 'restaurant', hexColor: '#FF9800'),
      ModeloCategoria(id: 'cat_comida_super', name: 'Supermercado', parentId: 'cat_comida', iconCode: 'shopping_cart', hexColor: '#FF9800'),
      ModeloCategoria(id: 'cat_comida_rest', name: 'Restaurantes', parentId: 'cat_comida', iconCode: 'restaurant', hexColor: '#FF9800'),
      ModeloCategoria(id: 'cat_comida_cafe', name: 'Cafetería', parentId: 'cat_comida', iconCode: 'local_cafe', hexColor: '#FF9800'),

      ModeloCategoria(id: 'cat_transporte', name: 'Transporte', iconCode: 'directions_car', hexColor: '#0284C7'),
      ModeloCategoria(id: 'cat_trans_gas', name: 'Combustible', parentId: 'cat_transporte', iconCode: 'local_gas_station', hexColor: '#0284C7'),
      ModeloCategoria(id: 'cat_trans_mantenimiento', name: 'Mantenimiento', parentId: 'cat_transporte', iconCode: 'build', hexColor: '#0284C7'),
      ModeloCategoria(id: 'cat_trans_publico', name: 'Transporte Público', parentId: 'cat_transporte', iconCode: 'directions_bus', hexColor: '#0284C7'),

      ModeloCategoria(id: 'cat_salario', name: 'Salario', iconCode: 'work', hexColor: '#10B981'),
      ModeloCategoria(id: 'cat_sal_mensual', name: 'Nómina', parentId: 'cat_salario', iconCode: 'payments', hexColor: '#10B981'),
      ModeloCategoria(id: 'cat_sal_freelance', name: 'Freelance', parentId: 'cat_salario', iconCode: 'laptop', hexColor: '#10B981'),
      ModeloCategoria(id: 'cat_sal_bonos', name: 'Inversiones', parentId: 'cat_salario', iconCode: 'trending_up', hexColor: '#10B981'),

      ModeloCategoria(id: 'cat_servicios', name: 'Servicios', iconCode: 'electrical_services', hexColor: '#8B5CF6'),
      ModeloCategoria(id: 'cat_serv_luz', name: 'Luz/Agua', parentId: 'cat_servicios', iconCode: 'water_drop', hexColor: '#8B5CF6'),
      ModeloCategoria(id: 'cat_serv_internet', name: 'Internet/TV', parentId: 'cat_servicios', iconCode: 'router', hexColor: '#8B5CF6'),
      ModeloCategoria(id: 'cat_serv_streaming', name: 'Streaming', parentId: 'cat_servicios', iconCode: 'tv', hexColor: '#8B5CF6'),

      ModeloCategoria(id: 'cat_entretenimiento', name: 'Entretenimiento', iconCode: 'sports_esports', hexColor: '#EC4899'),
      ModeloCategoria(id: 'cat_ent_cine', name: 'Cine', parentId: 'cat_entretenimiento', iconCode: 'movie', hexColor: '#EC4899'),
      ModeloCategoria(id: 'cat_ent_salidas', name: 'Salidas', parentId: 'cat_entretenimiento', iconCode: 'celebration', hexColor: '#EC4899'),

      ModeloCategoria(id: 'cat_otros', name: 'Otros', iconCode: 'category', hexColor: '#64748B'),
      ModeloCategoria(id: 'cat_otr_salud', name: 'Médico/Salud', parentId: 'cat_otros', iconCode: 'local_hospital', hexColor: '#64748B'),
      ModeloCategoria(id: 'cat_otr_regalo', name: 'Regalos', parentId: 'cat_otros', iconCode: 'card_giftcard', hexColor: '#64748B'),
    ];
  }

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

  Future<void> sincronizarConNube(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null) {
          if (data['esTemaOscuro'] != null) {
            _esTemaOscuro = data['esTemaOscuro'] as bool;
          }
          if (data['colorPrincipal'] != null) {
            _colorPrincipal = Color(data['colorPrincipal'] as int);
          }

          if (data['accounts'] != null) {
            final List<dynamic> accountsData = data['accounts'];
            _accounts = accountsData.map((item) => ModeloCuenta.fromMap(Map<String, dynamic>.from(item))).toList();
            if (_accounts.isNotEmpty) {
              _hasCompletedOnboarding = true;
            }
          }

          if (data['transactions'] != null) {
            final List<dynamic> transactionsData = data['transactions'];
            _transactions = transactionsData.map((item) => ModeloTransaccion.fromMap(Map<String, dynamic>.from(item))).toList();
          }

          if (data['categories'] != null) {
            final List<dynamic> categoriesData = data['categories'];
            _categories = categoriesData.map((item) => ModeloCategoria.fromMap(Map<String, dynamic>.from(item))).toList();
          }

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('app_dark_mode', _esTemaOscuro);
          await prefs.setInt('app_primary_color', _colorPrincipal.toARGB32());
          await prefs.setBool('app_onboarding_completed', _hasCompletedOnboarding);
          await _saveAccountsToPrefs(prefs);
          await _saveTransactionsToPrefs(prefs);
          await _saveCategoriesToPrefs(prefs);

          super.notifyListeners();
        }
      } else {
        if (_accounts.isNotEmpty) {
          await _subirDatosANube(uid);
        }
      }
    } catch (e) {
      debugPrint('Error en la sincronizacion con la nube: $e');
    }
  }

  Future<void> _subirDatosANube(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final accountsMapList = _accounts.map((acc) => acc.toMap()).toList();
      final transactionsMapList = _transactions.map((tx) => tx.toMap()).toList();
      final categoriesMapList = _categories.map((cat) => cat.toMap()).toList();

      await docRef.set({
        'uid': uid,
        'esTemaOscuro': _esTemaOscuro,
        'colorPrincipal': _colorPrincipal.toARGB32(),
        'accounts': accountsMapList,
        'transactions': transactionsMapList,
        'categories': categoriesMapList,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error al subir datos a la nube: $e');
    }
  }
}
