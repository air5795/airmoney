import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModeloCuenta {
  final String id;
  final String name;
  final String type;
  double balance;
  final int gradientIndex;

  ModeloCuenta({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.gradientIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'gradientIndex': gradientIndex,
    };
  }

  factory ModeloCuenta.fromMap(Map<String, dynamic> map) {
    return ModeloCuenta(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      gradientIndex: map['gradientIndex'] ?? 0,
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

class EstadoApp extends ChangeNotifier {
  String _selectedLanguage = 'es';
  String _selectedCurrency = 'BOB';
  bool _hasCompletedOnboarding = false;
  List<ModeloCuenta> _accounts = [];
  List<ModeloTransaccion> _transactions = [];
  bool _esTemaOscuro = false;
  Color _colorPrincipal = const Color(0xFFFF2D55);

  String get selectedLanguage => _selectedLanguage;
  String get selectedCurrency => _selectedCurrency;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  List<ModeloCuenta> get accounts => _accounts;
  List<ModeloTransaccion> get transactions => _transactions;
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

    final int colorVal = prefs.getInt('app_primary_color') ?? const Color(0xFFFF2D55).value;
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
    await prefs.setInt('app_primary_color', color.value);
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

  Future<void> addAccount(String name, String type, double balance, int gradientIndex) async {
    final newAccount = ModeloCuenta(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      balance: balance,
      gradientIndex: gradientIndex,
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

  Future<void> _saveAccountsToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> accountsMapList = _accounts.map((acc) => acc.toMap()).toList();
    await prefs.setString('app_accounts', json.encode(accountsMapList));
  }

  Future<void> _saveTransactionsToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> transactionsMapList = _transactions.map((tx) => tx.toMap()).toList();
    await prefs.setString('app_transactions', json.encode(transactionsMapList));
  }

  Future<void> clearAllData() async {
    _accounts.clear();
    _transactions.clear();
    _hasCompletedOnboarding = false;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_onboarding_completed');
    await prefs.remove('app_accounts');
    await prefs.remove('app_transactions');
    
    notifyListeners();
  }
}
