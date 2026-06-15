import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'servicio_autenticacion.dart';
import 'servicio_notificaciones.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';

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

class ModeloDeuda {
  final String id;
  final String lender; // Acreedor
  final double totalAmount; // Monto total
  double paidAmount; // Monto pagado
  final DateTime date; // Fecha de inicio
  final DateTime dueDate; // Fecha límite
  final String hexColor;
  final String notes;
  final String? accountId; // Cuenta origen predeterminada para abonos

  ModeloDeuda({
    required this.id,
    required this.lender,
    required this.totalAmount,
    required this.paidAmount,
    required this.date,
    required this.dueDate,
    required this.hexColor,
    required this.notes,
    this.accountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'acreedor': lender,
      'montoTotal': totalAmount,
      'montoPagado': paidAmount,
      'fecha': date.toIso8601String(),
      'fechaLimite': dueDate.toIso8601String(),
      'colorHex': hexColor,
      'notas': notes,
      'idCuenta': accountId,
    };
  }

  factory ModeloDeuda.fromMap(Map<String, dynamic> map) {
    return ModeloDeuda(
      id: map['id'] ?? '',
      lender: map['acreedor'] ?? '',
      totalAmount: (map['montoTotal'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['montoPagado'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['fecha'] ?? DateTime.now().toIso8601String()),
      dueDate: DateTime.parse(map['fechaLimite'] ?? DateTime.now().toIso8601String()),
      hexColor: map['colorHex'] ?? '#EF4444',
      notes: map['notas'] ?? '',
      accountId: map['idCuenta'],
    );
  }
}

class EstadoApp extends ChangeNotifier {
  static const List<Map<String, String>> listaMonedas = [
    {'code': 'BOB', 'symbol': 'Bs', 'name': 'Boliviano boliviano', 'flag': '🇧🇴'},
    {'code': 'USD', 'symbol': r'$', 'name': 'Dólar estadounidense', 'flag': '🇺🇸'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro', 'flag': '🇪🇺'},
    {'code': 'MXN', 'symbol': r'$', 'name': 'Peso mexicano', 'flag': '🇲🇽'},
    {'code': 'ARS', 'symbol': r'$', 'name': 'Peso argentino', 'flag': '🇦🇷'},
    {'code': 'BRL', 'symbol': r'R$', 'name': 'Real brasileño', 'flag': '🇧🇷'},
    {'code': 'CLP', 'symbol': r'$', 'name': 'Peso chileno', 'flag': '🇨🇱'},
    {'code': 'COP', 'symbol': r'$', 'name': 'Peso colombiano', 'flag': '🇨🇴'},
    {'code': 'PEN', 'symbol': 'S/.', 'name': 'Sol peruano', 'flag': '🇵🇪'},
    {'code': 'UYU', 'symbol': r'$U', 'name': 'Peso uruguayo', 'flag': '🇺🇾'},
    {'code': 'PYG', 'symbol': '₲', 'name': 'Guaraní paraguayo', 'flag': '🇵🇾'},
    {'code': 'CRC', 'symbol': '₡', 'name': 'Colón costarricense', 'flag': '🇨🇷'},
    {'code': 'GTQ', 'symbol': 'Q', 'name': 'Quetzal guatemalteco', 'flag': '🇬🇹'},
    {'code': 'HNL', 'symbol': 'L', 'name': 'Lempira hondureña', 'flag': '🇭🇳'},
    {'code': 'NIO', 'symbol': r'C$', 'name': 'Córdoba nicaragüense', 'flag': '🇳🇮'},
    {'code': 'VES', 'symbol': 'Bs.S', 'name': 'Bolívar venezolano', 'flag': '🇻🇪'},
    {'code': 'DOP', 'symbol': r'RD$', 'name': 'Peso dominicano', 'flag': '🇩🇴'},
    {'code': 'PAB', 'symbol': 'B/.', 'name': 'Balboa panameño', 'flag': '🇵🇦'},
    {'code': 'CAD', 'symbol': r'$', 'name': 'Dólar canadiense', 'flag': '🇨🇦'},
    {'code': 'GBP', 'symbol': '£', 'name': 'Libra esterlina', 'flag': '🇬🇧'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Yen japonés', 'flag': '🇯🇵'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Yuan chino', 'flag': '🇨🇳'},
    {'code': 'KRW', 'symbol': '₩', 'name': 'Won surcoreano', 'flag': '🇰🇷'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Rupia india', 'flag': '🇮🇳'},
    {'code': 'AUD', 'symbol': r'$', 'name': 'Dólar australiano', 'flag': '🇦🇺'},
    {'code': 'NZD', 'symbol': r'$', 'name': 'Dólar neozelandés', 'flag': '🇳🇿'},
    {'code': 'CHF', 'symbol': 'CHF', 'name': 'Franco suizo', 'flag': '🇨🇭'},
    {'code': 'RUB', 'symbol': '₽', 'name': 'Rublo ruso', 'flag': '🇷🇺'},
    {'code': 'TRY', 'symbol': '₺', 'name': 'Lira turca', 'flag': '🇹🇷'},
    {'code': 'ZAR', 'symbol': 'R', 'name': 'Rand sudafricano', 'flag': '🇿🇦'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'Dírham de los Emiratos Árabes Unidos', 'flag': '🇦🇪'},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': 'Riyal saudí', 'flag': '🇸🇦'},
    {'code': 'SGD', 'symbol': r'S$', 'name': 'Dólar de Singapur', 'flag': '🇸🇬'},
    {'code': 'HKD', 'symbol': r'HK$', 'name': 'Dólar de Hong Kong', 'flag': '🇭🇰'},
    {'code': 'SEK', 'symbol': 'kr', 'name': 'Corona sueca', 'flag': '🇸🇪'},
    {'code': 'NOK', 'symbol': 'kr', 'name': 'Corona noruega', 'flag': '🇳🇴'},
    {'code': 'DKK', 'symbol': 'kr', 'name': 'Corona danesa', 'flag': '🇩🇰'},
    {'code': 'PLN', 'symbol': 'zł', 'name': 'Zloty polaco', 'flag': '🇵🇱'},
    {'code': 'ILS', 'symbol': '₪', 'name': 'Nuevo séquel israelí', 'flag': '🇮🇱'},
    {'code': 'EGP', 'symbol': 'E£', 'name': 'Libra egipcia', 'flag': '🇪🇬'},
    {'code': 'NGN', 'symbol': '₦', 'name': 'Naira nigeriana', 'flag': '🇳🇬'},
    {'code': 'KES', 'symbol': 'KSh', 'name': 'Chelín keniano', 'flag': '🇰🇪'},
    {'code': 'GHS', 'symbol': 'GH₵', 'name': 'Cedi ghanés', 'flag': '🇬🇭'},
    {'code': 'MAD', 'symbol': 'DH', 'name': 'Dírham marroquí', 'flag': '🇲🇦'},
    {'code': 'DZD', 'symbol': 'DA', 'name': 'Dinar argelino', 'flag': '🇩🇿'},
    {'code': 'TND', 'symbol': 'DT', 'name': 'Dinar tunecino', 'flag': '🇹🇳'},
    {'code': 'QAR', 'symbol': 'QR', 'name': 'Riyal qatarí', 'flag': '🇶🇦'},
    {'code': 'KWD', 'symbol': 'KD', 'name': 'Dinar kuwaití', 'flag': '🇰🇼'},
    {'code': 'BHD', 'symbol': 'BD', 'name': 'Dinar bahreiní', 'flag': '🇧🇭'},
    {'code': 'OMR', 'symbol': 'RO', 'name': 'Riyal omaní', 'flag': '🇴🇲'},
    {'code': 'JOD', 'symbol': 'JD', 'name': 'Dinar jordano', 'flag': '🇯🇴'},
    {'code': 'IDR', 'symbol': 'Rp', 'name': 'Rupia indonesia', 'flag': '🇮🇩'},
    {'code': 'MYR', 'symbol': 'RM', 'name': 'Ringgit malasio', 'flag': '🇲🇾'},
    {'code': 'PHP', 'symbol': '₱', 'name': 'Peso filipino', 'flag': '🇵🇭'},
    {'code': 'THB', 'symbol': '฿', 'name': 'Baht tailandés', 'flag': '🇹🇭'},
    {'code': 'VND', 'symbol': '₫', 'name': 'Dong vietnamés', 'flag': '🇻🇳'},
    {'code': 'PKR', 'symbol': '₨', 'name': 'Rupia pakistaní', 'flag': '🇵🇰'},
    {'code': 'BDT', 'symbol': '৳', 'name': 'Taka bangladesí', 'flag': '🇧🇩'},
    {'code': 'LKR', 'symbol': 'Rs', 'name': 'Rupia de Sri Lanka', 'flag': '🇱🇰'},
    {'code': 'HUF', 'symbol': 'Ft', 'name': 'Florín húngaro', 'flag': '🇭🇺'},
    {'code': 'CZK', 'symbol': 'Kč', 'name': 'Corona checa', 'flag': '🇨🇿'},
    {'code': 'RON', 'symbol': 'lei', 'name': 'Leu rumano', 'flag': '🇷🇴'},
    {'code': 'BGN', 'symbol': 'лв', 'name': 'Lev búlgaro', 'flag': '🇧🇬'},
    {'code': 'UAH', 'symbol': '₴', 'name': 'Grivna ucraniana', 'flag': '🇺🇦'},
    {'code': 'ISK', 'symbol': 'kr', 'name': 'Corona islandesa', 'flag': '🇮🇸'},
    {'code': 'RSD', 'symbol': 'din', 'name': 'Dinar serbio', 'flag': '🇷🇸'},
    {'code': 'TWD', 'symbol': r'NT$', 'name': 'Nuevo dólar taiwanés', 'flag': '🇹🇼'},
    {'code': 'TJS', 'symbol': 'ЅМ', 'name': 'Somoni tayiko', 'flag': '🇹🇯'},
    {'code': 'KZT', 'symbol': '₸', 'name': 'Tenge kazajo', 'flag': '🇰🇿'},
    {'code': 'UZS', 'symbol': "so'm", 'name': 'Som uzbeko', 'flag': '🇺🇿'},
    {'code': 'GEL', 'symbol': '₾', 'name': 'Lari georgiano', 'flag': '🇬🇪'},
    {'code': 'AMD', 'symbol': '֏', 'name': 'Dram armenio', 'flag': '🇦🇲'},
    {'code': 'AZN', 'symbol': '₼', 'name': 'Manat azerbaiyano', 'flag': '🇦🇿'},
    {'code': 'MNT', 'symbol': '₮', 'name': 'Tugrik mongol', 'flag': '🇲🇳'},
    {'code': 'LBP', 'symbol': 'L£', 'name': 'Libra libanesa', 'flag': '🇱🇧'},
    {'code': 'IQD', 'symbol': 'ع.د', 'name': 'Dinar iraquí', 'flag': '🇮🇶'},
    {'code': 'IRR', 'symbol': '﷼', 'name': 'Rial iraní', 'flag': '🇮🇷'},
    {'code': 'YER', 'symbol': '﷼', 'name': 'Rial yemení', 'flag': '🇾🇪'},
    {'code': 'AFN', 'symbol': '؋', 'name': 'Afgani afgano', 'flag': '🇦🇫'},
    {'code': 'NPR', 'symbol': 'Rs', 'name': 'Rupia nepalesa', 'flag': '🇳🇵'},
    {'code': 'MVR', 'symbol': 'Rf', 'name': 'Rufiyaa de Maldivas', 'flag': '🇲🇻'},
    {'code': 'LAK', 'symbol': '₭', 'name': 'Kip laosiano', 'flag': '🇱🇦'},
    {'code': 'KHR', 'symbol': '៛', 'name': 'Riel camboyano', 'flag': '🇰🇭'},
    {'code': 'MMK', 'symbol': 'K', 'name': 'Kyat birmano', 'flag': '🇲🇲'},
    {'code': 'BND', 'symbol': r'B$', 'name': 'Dólar de Brunéi', 'flag': '🇧🇳'},
    {'code': 'FJD', 'symbol': r'FJ$', 'name': 'Dólar fiyiano', 'flag': '🇫🇯'},
    {'code': 'PGK', 'symbol': 'K', 'name': 'Kina de Papúa Nueva Guinea', 'flag': '🇵🇬'},
    {'code': 'SBD', 'symbol': r'SI$', 'name': 'Dólar de las Islas Salomón', 'flag': '🇸🇧'},
    {'code': 'VUV', 'symbol': 'VT', 'name': 'Vatu vanuatu', 'flag': '🇻🇺'},
    {'code': 'WST', 'symbol': r'WS$', 'name': 'Tala samoano', 'flag': '🇼🇸'},
    {'code': 'TOP', 'symbol': r'T$', 'name': 'Paʻanga tongano', 'flag': '🇹🇴'},
    {'code': 'BWP', 'symbol': 'P', 'name': 'Pula de Botsuana', 'flag': '🇧🇼'},
    {'code': 'TZS', 'symbol': 'TSh', 'name': 'Chelín tanzano', 'flag': '🇹🇿'},
    {'code': 'UGX', 'symbol': 'USh', 'name': 'Chelín ugandés', 'flag': '🇺🇬'},
    {'code': 'ETB', 'symbol': 'Br', 'name': 'Birr etíope', 'flag': '🇪🇹'},
    {'code': 'RWF', 'symbol': 'FRw', 'name': 'Franco ruandés', 'flag': '🇷🇼'},
    {'code': 'BIF', 'symbol': 'FBu', 'name': 'Franco burundés', 'flag': '🇧🇮'},
    {'code': 'MWK', 'symbol': 'MK', 'name': 'Kwacha malauí', 'flag': '🇲🇼'},
    {'code': 'ZMW', 'symbol': 'ZK', 'name': 'Kwacha zambiano', 'flag': '🇿🇲'},
    {'code': 'AOA', 'symbol': 'Kz', 'name': 'Kwanza angoleño', 'flag': '🇦🇴'},
    {'code': 'MZN', 'symbol': 'MT', 'name': 'Metical mozambiqueño', 'flag': '🇲🇿'},
    {'code': 'NAD', 'symbol': r'N$', 'name': 'Dólar namibio', 'flag': '🇳🇦'},
    {'code': 'SZL', 'symbol': 'L', 'name': 'Lilangeni suazi', 'flag': '🇸🇿'},
    {'code': 'LSL', 'symbol': 'L', 'name': 'Loti lesotense', 'flag': '🇱🇸'},
    {'code': 'SCR', 'symbol': 'SR', 'name': 'Rupia de Seychelles', 'flag': '🇸🇨'},
    {'code': 'MUR', 'symbol': 'Rs', 'name': 'Rupia mauriciana', 'flag': '🇲🇺'},
    {'code': 'MGA', 'symbol': 'Ar', 'name': 'Ariary malgache', 'flag': '🇲🇬'},
    {'code': 'CDF', 'symbol': 'FC', 'name': 'Franco congoleño', 'flag': '🇨🇩'},
    {'code': 'CVE', 'symbol': 'Esc', 'name': 'Escudo caboverdiano', 'flag': '🇨🇻'},
    {'code': 'GMD', 'symbol': 'D', 'name': 'Dalasi gambiano', 'flag': '🇬🇲'},
    {'code': 'SLL', 'symbol': 'Le', 'name': 'Leona de Sierra Leona', 'flag': '🇸🇱'},
    {'code': 'LRD', 'symbol': r'L$', 'name': 'Dólar liberiano', 'flag': '🇱🇷'},
    {'code': 'LYD', 'symbol': 'LD', 'name': 'Dinar libio', 'flag': '🇱🇾'},
    {'code': 'SDG', 'symbol': 'LSd', 'name': 'Libra sudanesa', 'flag': '🇸🇩'},
    {'code': 'MRO', 'symbol': 'UM', 'name': 'Ouguiya mauritana', 'flag': '🇲🇷'},
    {'code': 'XAF', 'symbol': 'FCFA', 'name': 'Franco CFA de África Central', 'flag': '🇨🇲'},
    {'code': 'XOF', 'symbol': 'CFA', 'name': 'Franco CFA de África Occidental', 'flag': '🇸🇳'},
    {'code': 'ALL', 'symbol': 'L', 'name': 'Lek albanés', 'flag': '🇦🇱'},
    {'code': 'BAM', 'symbol': 'KM', 'name': 'Marco convertible', 'flag': '🇧🇦'},
    {'code': 'MKD', 'symbol': 'den', 'name': 'Denar macedonio', 'flag': '🇲🇰'},
    {'code': 'MDL', 'symbol': 'L', 'name': 'Leu moldavo', 'flag': '🇲🇩'},
    {'code': 'BYN', 'symbol': 'Br', 'name': 'Rublo bielorruso', 'flag': '🇧🇾'},
    {'code': 'CUC', 'symbol': r'CUC$', 'name': 'Peso cubano convertible', 'flag': '🇨🇺'},
    {'code': 'HTG', 'symbol': 'G', 'name': 'Gourde haitiano', 'flag': '🇭🇹'},
    {'code': 'JMD', 'symbol': r'J$', 'name': 'Dólar jamaicano', 'flag': '🇯🇲'},
    {'code': 'BSD', 'symbol': r'B$', 'name': 'Dólar bahameño', 'flag': '🇧🇸'},
    {'code': 'BZD', 'symbol': r'BZ$', 'name': 'Dólar beliceño', 'flag': '🇧🇿'},
    {'code': 'TTD', 'symbol': r'TT$', 'name': 'Dólar de Trinidad y Tobago', 'flag': '🇹🇹'},
    {'code': 'XCD', 'symbol': r'EC$', 'name': 'Dólar del Caribe Oriental', 'flag': '🇦🇬'},
  ];

  static List<String> get todosCodigosMoneda => listaMonedas.map((m) => m['code']!).toList();
  
  static bool esMonedaValida(String code) => todosCodigosMoneda.contains(code);

  static String getNameOfCurrency(String currencyCode) {
    final moneda = listaMonedas.firstWhere(
      (m) => m['code'] == currencyCode,
      orElse: () => {'name': currencyCode},
    );
    return moneda['name']!;
  }

  static String getFlagOfCurrency(String currencyCode) {
    final moneda = listaMonedas.firstWhere(
      (m) => m['code'] == currencyCode,
      orElse: () => {'flag': '🏳️'},
    );
    return moneda['flag']!;
  }

  String _selectedLanguage = 'es';
  String _selectedCurrency = 'BOB';
  Map<String, double> _tiposCambio = {};
  Set<String> _monedasPersonalizadas = {};
  bool _hasCompletedOnboarding = false;
  List<ModeloCuenta> _accounts = [];
  List<ModeloTransaccion> _transactions = [];
  List<ModeloCategoria> _categories = [];
  List<ModeloAhorro> _savingsGoals = [];
  List<ModeloPresupuesto> _budgets = [];
  List<ModeloDeuda> _debts = [];
  bool _modoRendimiento = false;
  bool _esTemaOscuro = false;
  Color _colorPrincipal = const Color(0xFF000000);
  int _selectedDockIndex = 0;
  int _selectedSettingsSubView = 0;
  int _lastLocalUpdateMillis = 0;
  ModeloCuenta? _accountToEditDirectly;
  StreamSubscription<DocumentSnapshot>? _nubeSubscription;
  bool _isSyncing = false;
  Timer? _debounceSubida;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  String _hashedPin = '';
  String _geminiApiKey = '';
  
  bool _notificacionFijaHabilitada = false;
  String _notificacionPlantilla = 'resumen';
  bool _notificacionMostrarSaldo = true;
  bool _notificacionMostrarIngresos = true;
  bool _notificacionMostrarGastos = true;
  bool _notificacionMostrarGastosHoy = true;
  bool _notificacionMostrarPresupuesto = true;
  bool _notificacionMostrarAcciones = true;
  bool _debeMostrarFormularioTransaccion = false;

  String get selectedLanguage => _selectedLanguage;
  String get selectedCurrency => _selectedCurrency;
  Map<String, double> get tiposCambio => _tiposCambio;
  Set<String> get monedasPersonalizadas => _monedasPersonalizadas;
  double get tipoCambioUsd => _tiposCambio['USD'] ?? 6.97;
  int get lastLocalUpdateMillis => _lastLocalUpdateMillis;
  String get currencySymbol => getSymbolOfCurrency(_selectedCurrency);
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  List<ModeloCuenta> get accounts => _accounts;
  List<ModeloTransaccion> get transactions => _transactions;
  String get geminiApiKey => _geminiApiKey.isEmpty ? ApiKeys.geminiDefaultApiKey : _geminiApiKey;
  String get rawGeminiApiKey => _geminiApiKey;
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
  List<ModeloDeuda> get debts => _debts;
  bool get modoRendimiento => _modoRendimiento;
  bool get esTemaOscuro => _esTemaOscuro;
  Color get colorPrincipal => _colorPrincipal;

  bool get biometricEnabled => _biometricEnabled;
  bool get pinEnabled => _pinEnabled;
  String get hashedPin => _hashedPin;

  bool get notificacionFijaHabilitada => _notificacionFijaHabilitada;
  String get notificacionPlantilla => _notificacionPlantilla;
  bool get notificacionMostrarSaldo => _notificacionMostrarSaldo;
  bool get notificacionMostrarIngresos => _notificacionMostrarIngresos;
  bool get notificacionMostrarGastos => _notificacionMostrarGastos;
  bool get notificacionMostrarGastosHoy => _notificacionMostrarGastosHoy;
  bool get notificacionMostrarPresupuesto => _notificacionMostrarPresupuesto;
  bool get notificacionMostrarAcciones => _notificacionMostrarAcciones;

  bool get debeMostrarFormularioTransaccion => _debeMostrarFormularioTransaccion;
  set debeMostrarFormularioTransaccion(bool val) {
    _debeMostrarFormularioTransaccion = val;
    notifyListeners();
  }

  Future<void> setModoRendimiento(bool val) async {
    _modoRendimiento = val;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_performance_mode', val);
    notifyListeners();
  }

  Future<void> setNotificacionFijaHabilitada(bool val) async {
    _notificacionFijaHabilitada = val;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_notificacion_fija_habilitada', val);
    _notificarYSincronizar();
  }

  Future<void> setNotificacionPlantilla(String val) async {
    _notificacionPlantilla = val;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_notificacion_plantilla', val);
    _notificarYSincronizar();
  }

  Future<void> setNotificacionMostrarSaldo(bool val) async {
    _notificacionMostrarSaldo = val;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_notificacion_mostrar_saldo', val);
    _notificarYSincronizar();
  }

  Future<void> setNotificacionMostrarIngresos(bool val) async {
    _notificacionMostrarIngresos = val;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_notificacion_mostrar_ingresos', val);
    _notificarYSincronizar();
  }

  Future<void> setNotificacionMostrarGastos(bool val) async {
    _notificacionMostrarGastos = val;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_notificacion_mostrar_gastos', val);
    _notificarYSincronizar();
  }

  Future<void> setNotificacionMostrarGastosHoy(bool val) async {
    _notificacionMostrarGastosHoy = val;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_notificacion_mostrar_gastos_hoy', val);
    _notificarYSincronizar();
  }

  Future<void> setNotificacionMostrarPresupuesto(bool val) async {
    _notificacionMostrarPresupuesto = val;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_notificacion_mostrar_presupuesto', val);
    _notificarYSincronizar();
  }

  Future<void> setNotificacionMostrarAcciones(bool val) async {
    _notificacionMostrarAcciones = val;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_notificacion_mostrar_acciones', val);
    _notificarYSincronizar();
  }

  double get totalExpensesToday {
    double total = 0.0;
    final now = DateTime.now();
    for (var tx in _transactions) {
      if (!tx.pagada) continue;
      if (tx.type == 'gasto' &&
          tx.date.year == now.year &&
          tx.date.month == now.month &&
          tx.date.day == now.day) {
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

  ModeloCuenta? get accountToEditDirectly => _accountToEditDirectly;
  set accountToEditDirectly(ModeloCuenta? val) {
    _accountToEditDirectly = val;
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
    final moneda = listaMonedas.firstWhere(
      (m) => m['code'] == currencyCode,
      orElse: () => {'symbol': '\$'},
    );
    return moneda['symbol']!;
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

  Future<void> marcarMonedaComoPersonalizada(String code) async {
    _monedasPersonalizadas.add(code);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('app_monedas_personalizadas', _monedasPersonalizadas.toList());
    notifyListeners();
  }

  Future<void> removerMonedaPersonalizada(String code) async {
    _monedasPersonalizadas.remove(code);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('app_monedas_personalizadas', _monedasPersonalizadas.toList());
    notifyListeners();
  }

  Future<bool> actualizarTasasDesdeInternet({bool respetarPersonalizadas = true}) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://open.er-api.com/v6/latest/$_selectedCurrency');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 10));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final data = json.decode(jsonString);
        
        if (data['result'] == 'success') {
          final Map<String, dynamic> ratesJson = data['rates'];
          
          ratesJson.forEach((moneda, valorEnMoneda) {
            final double val = (valorEnMoneda as num).toDouble();
            if (val > 0) {
              if (!respetarPersonalizadas || !_monedasPersonalizadas.contains(moneda)) {
                _tiposCambio[moneda] = 1.0 / val;
              }
            }
          });
          
          _tiposCambio[_selectedCurrency] = 1.0;
          _lastLocalUpdateMillis = DateTime.now().millisecondsSinceEpoch;
          
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_tipos_cambio', json.encode(_tiposCambio));
          await prefs.setInt('app_last_local_update_millis', _lastLocalUpdateMillis);
          
          _notificarYSincronizar();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error al actualizar tasas desde internet: $e");
    }
    return false;
  }

  double get totalBalance {
    double total = 0.0;
    for (var acc in _accounts) {
      if (acc.contabilizable == false) continue;
      final accCurrency = acc.currency ?? _selectedCurrency;
      // El saldo siempre representa el dinero/valor de la cuenta.
      // Una deuda de tarjeta de credito se registra como saldo negativo
      // y se resta sola; no hay que invertir el signo por tipo de cuenta.
      total += convertirMoneda(acc.balance, accCurrency, _selectedCurrency);
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
      'ARS': 0.0048,
      'BRL': 1.25,
      'CLP': 0.0075,
      'COP': 0.0017,
      'PEN': 1.85,
      'UYU': 0.18,
      'PYG': 0.00092,
      'CRC': 0.013,
      'GTQ': 0.90,
      'HNL': 0.28,
      'NIO': 0.19,
      'VES': 0.19,
      'DOP': 0.12,
      'PAB': 6.97,
    };
    
    for (var m in listaMonedas) {
      final code = m['code']!;
      if (!_tiposCambio.containsKey(code)) {
        _tiposCambio[code] = 1.0;
      }
    }
  }

  late final Future<void> initFuture;

  EstadoApp() {
    initFuture = _loadFromPreferences();
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

        bool huboFaltantes = false;
        for (var m in listaMonedas) {
          final code = m['code']!;
          if (!_tiposCambio.containsKey(code)) {
            final Map<String, double> tasasReferenciales = {
              'ARS': 0.0048,
              'BRL': 1.25,
              'CLP': 0.0075,
              'COP': 0.0017,
              'PEN': 1.85,
              'UYU': 0.18,
              'PYG': 0.00092,
              'CRC': 0.013,
              'GTQ': 0.90,
              'HNL': 0.28,
              'NIO': 0.19,
              'VES': 0.19,
              'DOP': 0.12,
              'PAB': 6.97,
            };
            _tiposCambio[code] = tasasReferenciales[code] ?? 1.0;
            huboFaltantes = true;
          }
        }
        if (huboFaltantes) {
          await prefs.setString('app_tipos_cambio', json.encode(_tiposCambio));
        }
      } catch (_) {
        _inicializarTasasDefecto();
      }
    } else {
      _inicializarTasasDefecto();
    }

    _tiposCambio[_selectedCurrency] = 1.0;

    final List<String>? personalizadasList = prefs.getStringList('app_monedas_personalizadas');
    if (personalizadasList != null) {
      _monedasPersonalizadas = personalizadasList.toSet();
    }
    
    _hasCompletedOnboarding = prefs.getBool('app_onboarding_completed') ?? false;
    _esTemaOscuro = prefs.getBool('app_dark_mode') ?? false;

    _biometricEnabled = prefs.getBool('app_biometric_enabled') ?? false;
    _pinEnabled = prefs.getBool('app_pin_enabled') ?? false;
    _hashedPin = prefs.getString('app_pin_code') ?? '';
    _geminiApiKey = prefs.getString('app_gemini_api_key') ?? '';

    _notificacionFijaHabilitada = prefs.getBool('app_notificacion_fija_habilitada') ?? false;
    _notificacionPlantilla = prefs.getString('app_notificacion_plantilla') ?? 'resumen';
    _notificacionMostrarSaldo = prefs.getBool('app_notificacion_mostrar_saldo') ?? true;
    _notificacionMostrarIngresos = prefs.getBool('app_notificacion_mostrar_ingresos') ?? true;
    _notificacionMostrarGastos = prefs.getBool('app_notificacion_mostrar_gastos') ?? true;
    _notificacionMostrarGastosHoy = prefs.getBool('app_notificacion_mostrar_gastos_hoy') ?? true;
    _notificacionMostrarPresupuesto = prefs.getBool('app_notificacion_mostrar_presupuesto') ?? true;
    _notificacionMostrarAcciones = prefs.getBool('app_notificacion_mostrar_acciones') ?? true;

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

    _modoRendimiento = prefs.getBool('app_performance_mode') ?? false;

    final String? debtsJson = prefs.getString('app_debts');
    if (debtsJson != null) {
      final List<dynamic> decoded = json.decode(debtsJson);
      _debts = decoded.map((item) => ModeloDeuda.fromMap(item)).toList();
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

  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key.trim();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_gemini_api_key', _geminiApiKey);
    notifyListeners();
  }

  Future<bool> probarConexionGemini(String key) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: key.trim(),
      );
      final response = await model.generateContent([
        Content.text('responde con la palabra OK')
      ]);
      return response.text != null && response.text!.toUpperCase().contains('OK');
    } catch (e) {
      debugPrint('Error de prueba Gemini: $e');
      return false;
    }
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

    _subirTransaccionASubcoleccion(newTx);

    _notificarYSincronizar();
  }

  Future<void> importarTransaccionesMasivas(List<ModeloTransaccion> nuevasTxs) async {
    for (var tx in nuevasTxs) {
      _transactions.add(tx);
      if (tx.pagada) {
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
      }
    }

    // Ordenar todas las transacciones por fecha descendente
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveAccountsToPrefs(prefs);
    await _saveTransactionsToPrefs(prefs);

    final user = ServicioAutenticacion().currentUser;
    if (user != null && !user.uid.startsWith('demo_')) {
      _migrarTransaccionesASubcolecciones(user.uid, nuevasTxs);
    }

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

    _subirTransaccionASubcoleccion(_transactions[idxTx]);

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

    _eliminarTransaccionDeSubcoleccion(id);

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

  Future<void> _saveDebtsToPrefs(SharedPreferences prefs) async {
    final List<Map<String, dynamic>> mapped = _debts.map((d) => d.toMap()).toList();
    await prefs.setString('app_debts', json.encode(mapped));
    await _updateLocalTimestamp(prefs);
  }

  Future<void> addDebt(ModeloDeuda debt) async {
    _debts.add(debt);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveDebtsToPrefs(prefs);
    _notificarYSincronizar();
  }

  Future<void> updateDebt(ModeloDeuda debt) async {
    final idx = _debts.indexWhere((d) => d.id == debt.id);
    if (idx != -1) {
      _debts[idx] = debt;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _saveDebtsToPrefs(prefs);
      _notificarYSincronizar();
    }
  }

  Future<void> deleteDebt(String id) async {
    _debts.removeWhere((d) => d.id == id);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _saveDebtsToPrefs(prefs);
    _notificarYSincronizar();
  }

  Future<void> addPaymentToDebt(String id, double amount, {String? accountId}) async {
    final idx = _debts.indexWhere((d) => d.id == id);
    if (idx != -1) {
      final debt = _debts[idx];
      debt.paidAmount += amount;
      
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _saveDebtsToPrefs(prefs);
      
      // Registrar transaccion real en la contabilidad
      if (accountId != null) {
        await addTransaction(
          title: 'Abono: ${debt.lender}',
          description: 'Abono a deuda registrada',
          amount: amount,
          category: 'Préstamos / Deudas',
          type: 'gasto',
          accountId: accountId,
        );
      } else {
        _notificarYSincronizar();
      }
    }
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
    desactivarEscuchaTiempoReal();
    _accounts.clear();
    _transactions.clear();
    _categories.clear();
    _savingsGoals.clear();
    _hasCompletedOnboarding = false;
    _biometricEnabled = false;
    _pinEnabled = false;
    _hashedPin = '';
    _lastLocalUpdateMillis = 0;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_onboarding_completed');
    await prefs.remove('app_accounts');
    await prefs.remove('app_transactions');
    await prefs.remove('app_categories');
    await prefs.remove('app_savings_goals');
    await prefs.remove('app_biometric_enabled');
    await prefs.remove('app_pin_enabled');
    await prefs.remove('app_pin_code');
    await prefs.remove('app_last_local_update_millis');

    notifyListeners();
  }

  Future<void> eliminarDatosNubeYLocal(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      await docRef.delete().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error al eliminar datos de la nube: $e');
    }
    await clearAllData();
  }

  static final Map<String, IconData> galleryIcons = {
    // === ALIMENTACIÓN Y BEBIDAS ===
    'restaurant': Icons.restaurant_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'fastfood': Icons.fastfood_rounded,
    'local_bar': Icons.local_bar_rounded,
    'bakery_dining': Icons.bakery_dining_rounded,
    'icecream': Icons.icecream_rounded,
    'local_pizza': Icons.local_pizza_rounded,
    'cake': Icons.cake_rounded,
    'soup_kitchen': Icons.soup_kitchen_rounded,
    'dinner_dining': Icons.dinner_dining_rounded,
    'brunch_dining': Icons.brunch_dining_rounded,
    'lunch_dining': Icons.lunch_dining_rounded,
    'breakfast_dining': Icons.breakfast_dining_rounded,
    'ramen_dining': Icons.ramen_dining_rounded,
    'liquor': Icons.liquor_rounded,
    'wine_bar': Icons.wine_bar_rounded,
    'coffee': Icons.coffee_rounded,
    'kitchen': Icons.kitchen_rounded,
    'cookie': Icons.cookie_rounded,
    'egg': Icons.egg_rounded,
    'flatware': Icons.flatware_rounded,
    'takeout_dining': Icons.takeout_dining_rounded,
    'restaurant_menu': Icons.restaurant_menu_rounded,
    'delivery_dining': Icons.delivery_dining_rounded,
    'sports_bar': Icons.sports_bar_rounded,

    // === COMPRAS Y RETAIL ===
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
    'shopping_basket': Icons.shopping_basket_rounded,
    'store_mall_directory': Icons.store_mall_directory_rounded,
    'price_check': Icons.price_check_rounded,
    'price_change': Icons.price_change_rounded,
    'qr_code': Icons.qr_code_rounded,
    'badge': Icons.badge_rounded,
    'card_membership': Icons.card_membership_rounded,
    'receipt': Icons.receipt_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'point_of_sale': Icons.point_of_sale_rounded,

    // === TRANSPORTE Y VIAJES ===
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
    'car_rental': Icons.car_rental_rounded,
    'car_repair': Icons.car_repair_rounded,
    'ev_station': Icons.ev_station_rounded,
    'tire_repair': Icons.tire_repair_rounded,
    'electric_car': Icons.electric_car_rounded,
    'local_parking': Icons.local_parking_rounded,
    'traffic': Icons.traffic_rounded,
    'flight_takeoff': Icons.flight_takeoff_rounded,
    'flight_land': Icons.flight_land_rounded,
    'directions_boat': Icons.directions_boat_rounded,
    'motorcycle': Icons.motorcycle_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,

    // === SERVICIOS Y FACTURAS ===
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
    'electric_meter': Icons.electric_meter_rounded,
    'smart_toy': Icons.smart_toy_rounded,
    'print': Icons.print_rounded,
    'memory': Icons.memory_rounded,
    'headset_mic': Icons.headset_mic_rounded,
    'sim_card': Icons.sim_card_rounded,
    'security': Icons.security_rounded,
    'shield': Icons.shield_rounded,
    'vpn_lock': Icons.vpn_lock_rounded,

    // === ENTRETENIMIENTO Y OCIO ===
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
    'videogame_asset': Icons.videogame_asset_rounded,
    'sports_basketball': Icons.sports_basketball_rounded,
    'sports_tennis': Icons.sports_tennis_rounded,
    'sports_baseball': Icons.sports_baseball_rounded,
    'sports_volleyball': Icons.sports_volleyball_rounded,
    'sports_golf': Icons.sports_golf_rounded,
    'sports_mma': Icons.sports_mma_rounded,
    'sports_motorsports': Icons.sports_motorsports_rounded,
    'golf_course': Icons.golf_course_rounded,
    'mic': Icons.mic_rounded,
    'radio': Icons.radio_rounded,
    'piano': Icons.piano_rounded,
    'headphones': Icons.headphones_rounded,
    'camera_alt': Icons.camera_alt_rounded,
    'videocam': Icons.videocam_rounded,
    'toys': Icons.toys_rounded,

    // === HOGAR Y FAMILIA ===
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
    'yard': Icons.yard_rounded,
    'deck': Icons.deck_rounded,
    'fireplace': Icons.fireplace_rounded,
    'ac_unit': Icons.ac_unit_rounded,
    'solar_power': Icons.solar_power_rounded,
    'roofing': Icons.roofing_rounded,
    'window': Icons.window_rounded,
    'door_front': Icons.meeting_room_rounded,
    'bedroom_parent': Icons.bedroom_parent_rounded,
    'bedroom_child': Icons.bedroom_child_rounded,
    'bathroom': Icons.bathroom_rounded,
    'shower': Icons.shower_rounded,
    'bathtub': Icons.bathtub_rounded,
    'plumbing': Icons.plumbing_rounded,
    'microwave': Icons.microwave_rounded,
    'pest_control': Icons.pest_control_rounded,
    'coffee_maker': Icons.coffee_maker_rounded,
    'blender': Icons.blender_rounded,

    // === EDUCACIÓN Y TRABAJO ===
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
    'book': Icons.book_rounded,
    'auto_stories': Icons.auto_stories_rounded,
    'backpack': Icons.backpack_rounded,
    'architecture': Icons.architecture_rounded,
    'calculate': Icons.calculate_rounded,
    'history_edu': Icons.history_edu_rounded,

    // === SALUD Y BIENESTAR ===
    'local_hospital': Icons.local_hospital_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'medication': Icons.medication_rounded,
    'spa': Icons.spa_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'healing': Icons.healing_rounded,
    'medical_services': Icons.medical_services_rounded,
    'face': Icons.face_rounded,
    'masks': Icons.masks_rounded,
    'coronavirus': Icons.coronavirus_rounded,
    'vaccines': Icons.vaccines_rounded,
    'health_and_safety': Icons.health_and_safety_rounded,
    'elderly': Icons.elderly_rounded,
    'baby_changing_station': Icons.baby_changing_station_rounded,
    'wheelchair_pickup': Icons.wheelchair_pickup_rounded,
    'personal_injury': Icons.personal_injury_rounded,

    // === FINANZAS E INGRESOS ===
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
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'work_history': Icons.work_history_rounded,
    'add_card': Icons.add_card_rounded,
    'analytics': Icons.analytics_rounded,
    'pie_chart': Icons.pie_chart_rounded,
    'insights': Icons.insights_rounded,
    'bar_chart': Icons.bar_chart_rounded,
    'currency_exchange': Icons.currency_exchange_rounded,
    'toll': Icons.toll_rounded,
    'currency_bitcoin': Icons.currency_bitcoin_rounded,
    'euro': Icons.euro_symbol_rounded,
    'emoji_events': Icons.emoji_events_rounded,
    'star': Icons.star_rounded,
    'workspace_premium': Icons.workspace_premium_rounded,
    'add_business': Icons.add_business_rounded,
    'real_estate_agent': Icons.real_estate_agent_rounded,
    'domain': Icons.domain_rounded,

    // === SOCIAL Y COMUNIDAD ===
    'group': Icons.group_rounded,
    'people': Icons.people_rounded,
    'diversity_1': Icons.diversity_1_rounded,
    'diversity_2': Icons.diversity_2_rounded,
    'diversity_3': Icons.diversity_3_rounded,
    'handshake': Icons.handshake_rounded,
    'sentiment_satisfied': Icons.sentiment_satisfied_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,

    // === VIAJES Y AIRE LIBRE ===
    'explore': Icons.explore_rounded,
    'hiking': Icons.hiking_rounded,
    'landscape': Icons.landscape_rounded,
    'forest': Icons.forest_rounded,
    'mountain': Icons.forest_rounded,
    'pool': Icons.pool_rounded,
    'sailing': Icons.sailing_rounded,
    'kayaking': Icons.kayaking_rounded,
    'cabin': Icons.cabin_rounded,
    'camping': Icons.forest_rounded,
    'attractions': Icons.attractions_rounded,
    'map': Icons.map_rounded,

    // === CUIDADO PERSONAL ===
    'content_cut': Icons.content_cut_rounded,
    'dry_cleaning': Icons.dry_cleaning_rounded,
    'iron': Icons.iron_rounded,
    'umbrella': Icons.umbrella_rounded,
    'soap': Icons.soap_rounded,

    // === OTROS Y VARIOS ===
    'category': Icons.category_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'build': Icons.build_rounded,
    'redeem': Icons.redeem_rounded,
    'verified_user': Icons.verified_user_rounded,
    'clean_hands': Icons.clean_hands_rounded,
    'vpn_key': Icons.vpn_key_rounded,
    'favorite': Icons.favorite_rounded,
    'remove_circle_outline': Icons.remove_circle_outline_rounded,
    'gavel': Icons.gavel_rounded,
    'balance': Icons.balance_rounded,
    'policy': Icons.policy_rounded,
  };

  static final List<String> expenseIconKeys = [
    'restaurant', 'local_cafe', 'fastfood', 'local_bar', 'bakery_dining', 'icecream', 'local_pizza', 'cake', 'soup_kitchen',
    'dinner_dining', 'brunch_dining', 'lunch_dining', 'breakfast_dining', 'ramen_dining', 'liquor', 'wine_bar', 'coffee',
    'kitchen', 'cookie', 'egg', 'flatware', 'takeout_dining', 'restaurant_menu', 'delivery_dining', 'sports_bar',
    'shopping_cart', 'shopping_bag', 'store', 'sell', 'checkroom', 'local_mall', 'storefront', 'local_offer', 'outlet',
    'shopping_basket', 'store_mall_directory', 'price_check', 'qr_code', 'receipt', 'receipt_long',
    'directions_car', 'directions_bus', 'directions_subway', 'flight', 'local_taxi', 'pedal_bike', 'train', 'hotel',
    'beach_access', 'commute', 'luggage', 'car_rental', 'car_repair', 'ev_station', 'tire_repair', 'electric_car',
    'local_parking', 'traffic', 'flight_takeoff', 'flight_land', 'directions_boat', 'motorcycle', 'local_gas_station',
    'electrical_services', 'water_drop', 'router', 'tv', 'phone_android', 'bolt', 'lightbulb', 'wifi', 'gas_meter',
    'power', 'electric_meter', 'smart_toy', 'print', 'memory', 'headset_mic', 'sim_card', 'security', 'shield', 'vpn_lock',
    'sports_esports', 'movie', 'celebration', 'music_note', 'sports_soccer', 'palette', 'casino', 'theater_comedy',
    'brush', 'confirmation_number', 'videogame_asset', 'sports_basketball', 'sports_tennis', 'sports_baseball',
    'sports_volleyball', 'sports_golf', 'sports_mma', 'sports_motorsports', 'golf_course', 'mic', 'radio', 'piano',
    'headphones', 'camera_alt', 'videocam', 'toys',
    'home', 'pets', 'child_care', 'family_restroom', 'handyman', 'chair', 'house', 'grass', 'cleaning_services', 'weekend',
    'yard', 'deck', 'fireplace', 'ac_unit', 'solar_power', 'roofing', 'window', 'door_front', 'bedroom_parent',
    'bedroom_child', 'bathroom', 'shower', 'bathtub', 'plumbing', 'microwave', 'pest_control', 'coffee_maker', 'blender',
    'school', 'work', 'laptop', 'laptop_chromebook', 'business_center', 'menu_book', 'assignment', 'science', 'psychology',
    'draw', 'book', 'auto_stories', 'backpack', 'architecture', 'calculate', 'history_edu',
    'local_hospital', 'fitness_center', 'medication', 'spa', 'self_improvement', 'healing', 'medical_services', 'face',
    'masks', 'coronavirus', 'vaccines', 'health_and_safety', 'elderly', 'baby_changing_station', 'wheelchair_pickup',
    'personal_injury',
    'group', 'people', 'diversity_1', 'diversity_2', 'diversity_3', 'handshake', 'sentiment_satisfied', 'volunteer_activism',
    'explore', 'hiking', 'landscape', 'forest', 'mountain', 'pool', 'sailing', 'kayaking', 'cabin', 'camping', 'attractions', 'map',
    'content_cut', 'dry_cleaning', 'iron', 'umbrella', 'soap',
    'category', 'build', 'favorite', 'remove_circle_outline', 'gavel', 'balance', 'policy'
  ];

  static final List<String> incomeIconKeys = [
    'savings', 'payments', 'trending_up', 'account_balance', 'monetization_on', 'show_chart', 'attach_money', 'wallet',
    'percent', 'credit_card', 'account_balance_wallet', 'work_history', 'add_card', 'analytics', 'pie_chart', 'insights',
    'bar_chart', 'currency_exchange', 'toll', 'currency_bitcoin', 'euro', 'emoji_events', 'star', 'workspace_premium',
    'add_business', 'real_estate_agent', 'domain', 'store', 'sell', 'price_check', 'price_change', 'point_of_sale',
    'card_giftcard', 'redeem', 'verified_user', 'clean_hands', 'vpn_key', 'favorite'
  ];

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

      // Si es categoría padre, actualizar el color de todos sus hijos
      if (parentId == null) {
        for (int i = 0; i < _categories.length; i++) {
          if (_categories[i].parentId == id) {
            _categories[i] = ModeloCategoria(
              id: _categories[i].id,
              name: _categories[i].name,
              parentId: _categories[i].parentId,
              iconCode: _categories[i].iconCode,
              hexColor: hexColor,
            );
          }
        }
      }

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
    ServicioNotificaciones.actualizarNotificacion(this);
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

  void _subirTransaccionASubcoleccion(ModeloTransaccion tx) {
    final user = ServicioAutenticacion().currentUser;
    if (user != null && !user.uid.startsWith('demo_')) {
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('transacciones')
          .doc(tx.id)
          .set(tx.toMap())
          .catchError((e) => debugPrint('Error al subir transaccion: $e'));
    }
  }

  void _eliminarTransaccionDeSubcoleccion(String id) {
    final user = ServicioAutenticacion().currentUser;
    if (user != null && !user.uid.startsWith('demo_')) {
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('transacciones')
          .doc(id)
          .delete()
          .catchError((e) => debugPrint('Error al eliminar transaccion: $e'));
    }
  }

  Future<void> _migrarTransaccionesASubcolecciones(String uid, List<ModeloTransaccion> transacciones) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final subCollRef = userDocRef.collection('transacciones');

      // Escribir en lotes de 400 para respetar el límite de 500 por lote de Firestore
      final int chunkSize = 400;
      for (int i = 0; i < transacciones.length; i += chunkSize) {
        final chunk = transacciones.sublist(i, i + chunkSize > transacciones.length ? transacciones.length : i + chunkSize);
        final batch = FirebaseFirestore.instance.batch();
        for (var tx in chunk) {
          final txDocRef = subCollRef.doc(tx.id);
          batch.set(txDocRef, tx.toMap());
        }
        await batch.commit().timeout(const Duration(seconds: 10));
      }

      // Marcar como migrado en el documento principal y borrar array antiguo
      await userDocRef.update({
        'transacciones_migradas': true,
        'transacciones': FieldValue.delete(),
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      debugPrint('Migración a subcolecciones completada con éxito para $uid (${transacciones.length} txs)');
    } catch (e) {
      debugPrint('Error durante la migración de transacciones: $e');
    }
  }

  Future<List<ModeloTransaccion>> _cargarTransaccionesDesdeNube(String uid) async {
    try {
      final querySnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('transacciones')
          .get()
          .timeout(const Duration(seconds: 10));
      
      final List<ModeloTransaccion> list = querySnap.docs.map((doc) {
        return ModeloTransaccion.fromMap(Map<String, dynamic>.from(doc.data()));
      }).toList();

      // Ordenar por fecha descendente
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      debugPrint('Error al cargar transacciones desde nube: $e');
      return [];
    }
  }

  Future<bool> sincronizarConNube(String uid, {bool forceUploadLocal = false}) async {
    activarEscuchaTiempoReal(uid);
    _isSyncing = true; // Bloquear re-subida durante sincronizacion inicial
    try {
      // Registrar a que cuenta pertenecen los datos locales de este dispositivo.
      try {
        final SharedPreferences prefsUid = await SharedPreferences.getInstance();
        await prefsUid.setString('app_last_uid', uid);
      } catch (_) {}
      if (forceUploadLocal) {
        await _subirDatosANube(uid);
        return true;
      }
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final docSnap = await docRef.get().timeout(const Duration(seconds: 10));

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

          // Cargar / migrar transacciones desde subcolecciones
          final tieneBanderaMigrado = data['transacciones_migradas'] == true;
          if (!tieneBanderaMigrado && data['transacciones'] != null && (data['transacciones'] as List).isNotEmpty) {
            final List<dynamic> transactionsData = data['transacciones'];
            _transactions = transactionsData.map((item) => ModeloTransaccion.fromMap(Map<String, dynamic>.from(item))).toList();
            await _migrarTransaccionesASubcolecciones(uid, _transactions);
          } else {
            _transactions = await _cargarTransaccionesDesdeNube(uid);
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

          if (data['deudas'] != null) {
            final List<dynamic> debtsData = data['deudas'];
            _debts = debtsData.map((item) => ModeloDeuda.fromMap(Map<String, dynamic>.from(item))).toList();
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
          await _saveDebtsToPrefs(prefs);

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
      final categoriesMapList = _categories.map((cat) => cat.toMap()).toList();
      final savingsMapList = _savingsGoals.map((g) => g.toMap()).toList();
      final budgetsMapList = _budgets.map((b) => b.toMap()).toList();
      final debtsMapList = _debts.map((d) => d.toMap()).toList();

      await docRef.set({
        'uid': uid,
        'esTemaOscuro': _esTemaOscuro,
        'colorPrincipal': _colorPrincipal.toARGB32(),
        'tiposCambio': _tiposCambio,
        'tipoCambioUsd': _tiposCambio['USD'] ?? 6.97,
        'cuentas': accountsMapList,
        'categorias': categoriesMapList,
        'ahorros': savingsMapList,
        'presupuestos': budgetsMapList,
        'deudas': debtsMapList,
        'transacciones_migradas': true,
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      // Actualizar timestamp local al momento actual tras la subida exitosa
      _lastLocalUpdateMillis = DateTime.now().millisecondsSinceEpoch;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_last_local_update_millis', _lastLocalUpdateMillis);
    } catch (e) {
      debugPrint('Error al subir datos a la nube: $e');
      return;
    }
  }
  void desactivarEscuchaTiempoReal() {
    _nubeSubscription?.cancel();
    _nubeSubscription = null;
  }

  Future<bool> importarDatosDesdeJson(String jsonString) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      if (data['version'] == null) return false;

      // Parse accounts
      if (data['cuentas'] != null) {
        final List<dynamic> accountsData = data['cuentas'];
        _accounts = accountsData.map((item) => ModeloCuenta.fromMap(Map<String, dynamic>.from(item))).toList();
      }

      // Parse transactions
      if (data['transacciones'] != null) {
        final List<dynamic> transactionsData = data['transacciones'];
        _transactions = transactionsData.map((item) => ModeloTransaccion.fromMap(Map<String, dynamic>.from(item))).toList();
      }

      // Parse categories
      if (data['categorias'] != null) {
        final List<dynamic> categoriesData = data['categorias'];
        _categories = categoriesData.map((item) => ModeloCategoria.fromMap(Map<String, dynamic>.from(item))).toList();
      }

      // Parse savings
      if (data['ahorros'] != null) {
        final List<dynamic> savingsData = data['ahorros'];
        _savingsGoals = savingsData.map((item) => ModeloAhorro.fromMap(Map<String, dynamic>.from(item))).toList();
      }

      // Parse budgets
      if (data['presupuestos'] != null) {
        final List<dynamic> budgetsData = data['presupuestos'];
        _budgets = budgetsData.map((item) => ModeloPresupuesto.fromMap(Map<String, dynamic>.from(item))).toList();
      }

      if (_accounts.isNotEmpty) {
        _hasCompletedOnboarding = true;
      }

      _lastLocalUpdateMillis = DateTime.now().millisecondsSinceEpoch;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_onboarding_completed', _hasCompletedOnboarding);
      await _saveAccountsToPrefs(prefs);
      await _saveTransactionsToPrefs(prefs);
      await _saveCategoriesToPrefs(prefs);
      await _saveSavingsGoalsToPrefs(prefs);
      await _saveBudgetsToPrefs(prefs);
      await prefs.setInt('app_last_local_update_millis', _lastLocalUpdateMillis);

      _notificarYSincronizar();
      return true;
    } catch (e) {
      debugPrint('Error al importar datos desde JSON: $e');
      return false;
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

          // Cargar / migrar transacciones desde subcolecciones
          final tieneBanderaMigrado = data['transacciones_migradas'] == true;
          if (!tieneBanderaMigrado && data['transacciones'] != null && (data['transacciones'] as List).isNotEmpty) {
            final List<dynamic> transactionsData = data['transacciones'];
            _transactions = transactionsData.map((item) => ModeloTransaccion.fromMap(Map<String, dynamic>.from(item))).toList();
            await _migrarTransaccionesASubcolecciones(uid, _transactions);
          } else {
            _transactions = await _cargarTransaccionesDesdeNube(uid);
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

          if (data['deudas'] != null) {
            final List<dynamic> debtsData = data['deudas'];
            _debts = debtsData.map((item) => ModeloDeuda.fromMap(Map<String, dynamic>.from(item))).toList();
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
          await _saveDebtsToPrefs(prefs);

          if (cloudTimestamp != null && cloudTimestamp is Timestamp) {
            _lastLocalUpdateMillis = cloudTimestamp.millisecondsSinceEpoch;
            await prefs.setInt('app_last_local_update_millis', _lastLocalUpdateMillis);
          }
          
          notifyListeners();
        } catch (e) {
          debugPrint('Error procesando actualizacion en tiempo real: $e');
        } finally {
          _isSyncing = false;
        }
      } catch (e) {
        debugPrint('Error general en listener: $e');
      }
    });
  }
}
