import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/estado_app.dart';

class ResultadoAsistenteVoz {
  final String? titulo;
  final double? importe;
  final String? tipo; // 'gasto', 'ingreso', 'transferencia'
  final String? accountId;
  final String? toAccountId;
  final String? categoria;
  final DateTime? fecha;

  ResultadoAsistenteVoz({
    this.titulo,
    this.importe,
    this.tipo,
    this.accountId,
    this.toAccountId,
    this.categoria,
    this.fecha,
  });

  @override
  String toString() {
    return 'ResultadoAsistenteVoz(titulo: $titulo, importe: $importe, tipo: $tipo, accountId: $accountId, toAccountId: $toAccountId, categoria: $categoria, fecha: $fecha)';
  }
}

// Clases auxiliares para el mapeo de coincidencias local
class _CuentaCoincidencia {
  final ModeloCuenta cuenta;
  final int index;
  final String matchText;
  _CuentaCoincidencia(this.cuenta, this.index, this.matchText);
}

class _CategoriaCoincidencia {
  final ModeloCategoria categoria;
  final int index;
  final String matchText;
  _CategoriaCoincidencia(this.categoria, this.index, this.matchText);
}

class AsistenteVozHelper {
  // Diccionario estático completo de sinónimos de categorías
  static const Map<String, List<String>> sinonimosCategorias = {
    'Alimentación': ['comida', 'almuerzo', 'cena', 'desayuno', 'alimentos', 'merienda', 'comer', 'hamburguesa', 'pizza', 'pan', 'leche', 'carne', 'fruta', 'verdura', 'pollo', 'pescado', 'arroz', 'fideos', 'queso', 'huevo'],
    'Supermercado': ['supermercado', 'super', 'despensa', 'compras del mes', 'merca', 'almacen', 'hipermercado', 'comestibles', 'provisiones'],
    'Restaurantes': ['restaurante', 'cena afuera', 'almuerzo afuera', 'comer afuera', 'bar', 'pizzeria', 'hamburgueseria', 'bodegon', 'parrilla', 'sushi', 'gastronomia'],
    'Cafetería': ['cafe', 'cafeteria', 'starbucks', 'desayuno', 'merienda', 'cafecito', 'te', 'infusion', 'panaderia', 'facturas', 'criollos', 'bizcochos'],
    'Comida Rápida': ['rapida', 'comida rapida', 'burguer', 'mcdonalds', 'kfc', 'papas fritas', 'pizza', 'hot dog', 'pancho', 'lomo', 'lomito', 'empanadas', 'tacos'],
    'Bebidas/Licores': ['bebidas', 'licores', 'cerveza', 'vino', 'alcohol', 'licoreria', 'fernet', 'trago', 'refresco', 'gaseosa', 'agua mineral', 'jugo'],
    'Transporte': ['transporte', 'colectivo', 'subte', 'micro', 'bus', 'pasaje', 'peaje', 'tren', 'metro', 'boleto', 'viaje', 'movilidad'],
    'Combustible': ['combustible', 'gasolina', 'nafta', 'gas', 'diesel', 'cargas gas', 'estacion de servicio', 'ypf', 'shell', 'axion', 'petroleo'],
    'Mantenimiento de Auto': ['mantenimiento', 'taller', 'mecanico', 'repuestos', 'auto', 'coche', 'lavado', 'lavadero', 'aceite', 'filtro', 'neumaticos', 'cubiertas', 'frenos'],
    'Taxi / Uber': ['taxi', 'uber', 'cabify', 'didi', 'remis', 'chofer', 'viaje privado'],
    'Seguro de Auto': ['seguro', 'patente', 'seguro de auto', 'poliza'],
    'Vivienda': ['vivienda', 'casa', 'departamento', 'hogar', 'condominio', 'edificio'],
    'Alquiler / Hipoteca': ['alquiler', 'renta', 'hipoteca', 'cuota de casa', 'expensas', 'expensa', 'alquiler de casa'],
    'Servicios Básicos (Luz/Agua)': ['luz', 'agua', 'electricidad', 'gas natural', 'gas', 'energia', 'servicios', 'factura de luz', 'factura de agua'],
    'Internet / Tv Cable': ['internet', 'wifi', 'cable', 'net', 'fibra', 'television', 'netflix', 'flow', 'telecom'],
    'Limpieza / Mantenimiento': ['limpieza', 'detergente', 'jabon', 'escoba', 'trapo', 'mantenimiento hogar', 'plomero', 'electricista', 'pintor'],
    'Decoración / Muebles': ['decoracion', 'muebles', 'silla', 'mesa', 'cama', 'sofa', 'sillon', 'cuadro', 'lampara', 'sabanas', 'cortinas'],
    'Entretenimiento': ['cine', 'teatro', 'ocio', 'diversion', 'salida', 'entretenimiento', 'boliche', 'recital', 'concierto', 'fiesta', 'evento', 'espectaculo'],
    'Servicios Streaming': ['netflix', 'spotify', 'youtube premium', 'disney', 'hbo', 'streaming', 'prime video', 'suscripcion', 'membresia'],
    'Videojuegos': ['juegos', 'videojuegos', 'steam', 'playstation', 'xbox', 'nintendo', 'gaming', 'pc gamer', 'skins', 'fifa'],
    'Viajes / Vacaciones': ['viaje', 'viajes', 'vacaciones', 'hotel', 'vuelo', 'pasaje de avion', 'pasajes', 'alojamiento', 'turismo', 'excursion'],
    'Conciertos / Eventos': ['concierto', 'recital', 'fiesta', 'evento', 'festival', 'entrada', 'entradas', 'ticket', 'tickets'],
    'Salud y Bienestar': ['salud', 'bienestar', 'medico', 'doctor', 'dentista', 'clinica', 'hospital', 'psicologo', 'terapia', 'analisis', 'consulta'],
    'Consultas Médicas': ['consulta medica', 'doctor', 'dentista', 'oftalmologo', 'pediatra', 'obra social', 'copago'],
    'Farmacia / Medicinas': ['farmacia', 'medicinas', 'remedios', 'pastillas', 'jarabe', 'crema', 'aspirina', 'ibuprofeno', 'remedio'],
    'Gimnasio / Deportes': ['gimnasio', 'gym', 'crossfit', 'futbol', 'padel', 'deportes', 'club', 'entrenamiento', 'personal trainer', 'pileta', 'natacion'],
    'Cuidado Personal': ['cuidado personal', 'peluqueria', 'barberia', 'spa', 'corte de pelo', 'manicura', 'pedicura', 'cosmeticos', 'maquillaje', 'perfume', 'shampoo'],
    'Educación': ['educacion', 'colegio', 'universidad', 'escuela', 'facultad', 'instituto', 'academia', 'estudios'],
    'Matrícula / Mensualidad': ['matricula', 'mensualidad', 'cuota', 'arancel', 'pension', 'colegiatura'],
    'Libros / Útiles': ['libros', 'cuaderno', 'utiles', 'carpeta', 'lapiz', 'lapicera', 'mochila', 'cartuchera', 'manual', 'diccionario'],
    'Cursos / Certificaciones': ['curso', 'taller', 'ingles', 'clase', 'seminario', 'certificacion', 'diplomado', 'bootcamp'],
    'Compras': ['compras', 'shopping', 'regalo', 'regalos', 'tienda', 'mall', 'centro comercial'],
    'Ropa y Calzado': ['ropa', 'zapatos', 'camisa', 'pantalon', 'abrigo', 'remera', 'zapatillas', 'campera', 'saco', 'vestido', 'jeans', 'medias'],
    'Tecnología / Gadgets': ['tecnologia', 'celular', 'telefono', 'computadora', 'laptop', 'tablet', 'cargador', 'auriculares', 'mouse', 'teclado', 'monitor'],
    'Regalos / Detalles': ['regalo', 'obsequio', 'detalles', 'flores', 'chocolates', 'sorpresa', 'cumpleaños'],
    'Mascotas': ['mascota', 'perro', 'gato', 'veterinaria', 'alimento de perro', 'alimento de gato', 'pedigree', 'correa', 'juguete mascota', 'vacuna mascota'],
    'Finanzas': ['finanzas', 'banco', 'ahorro', 'inversion', 'prestamo', 'deuda'],
    'Impuestos': ['impuesto', 'impuestos', 'afip', 'tasas', 'monotributo', 'rentas', 'abl', 'renta', 'declaracion jurada'],
    'Comisiones / Intereses': ['comision', 'comisiones', 'intereses', 'mantenimiento cuenta', 'recargo'],
    'Préstamos / Deudas': ['prestamo', 'deuda', 'cuota prestamo', 'interes prestamo', 'pagar deuda', 'devolver plata'],
    'Inversiones': ['inversion', 'acciones', 'cripto', 'plazo fijo', 'cedears', 'bolsa', 'bitcoin', 'usdt', 'fondos comunes'],
    'Ingresos': ['ingreso', 'ingresos', 'entrada de plata', 'plata extra', 'ganancia', 'deposito'],
    'Salario / Nómina': ['sueldo', 'salario', 'nomina', 'mensualidad laboral', 'sueldito', 'aguinaldo', 'bono', 'quincena'],
    'Freelance / Trabajos': ['freelance', 'trabajo extra', 'proyecto', 'honorarios', 'servicios profesionales', 'changa', 'changas'],
    'Ventas / Negocio': ['ventas', 'negocio', 'tienda', 'local', 'ingreso ventas', 'factura emitida', 'mercaderia', 'cliente'],
    'Otros Ingresos': ['otros ingresos', 'reembolso', 'devolucion', 'regalo plata', 'premio', 'sorteo'],
    'Otros': ['otros', 'varios', 'gasto vario', 'gasto general', 'sin categoria', 'comodín']
  };

  // Diccionario estático para tipos de cuentas (sinónimos comunes)
  static const Map<String, List<String>> sinonimosCuentas = {
    'efectivo': ['efectivo', 'plata', 'bolsillo', 'monedero', 'billetera', 'cash', 'fisico', 'mano', 'caja'],
    'tarjeta': ['tarjeta', 'credito', 'debito', 'visa', 'mastercard', 'amex', 'tarjeta de credito', 'tarjeta de debito'],
    'banco': ['banco', 'bancaria', 'cuenta', 'corriente', 'ahorro', 'caja de ahorro', 'transferencia', 'bancario'],
    'digital': ['mercado pago', 'mp', 'paypal', 'binance', 'wallet', 'virtual', 'ueno', 'bcp', 'mercantil', 'bbva', 'santander', 'galicia'],
  };

  // Algoritmo de Distancia de Levenshtein para medir la similitud entre dos cadenas
  static int calcularDistanciaLevenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.filled(s2.length + 1, 0);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v0[s2.length];
  }

  // Calcular la similitud relativa en porcentaje (0.0 a 1.0) basada en Levenshtein
  static double calcularSimilitud(String s1, String s2) {
    int maxLen = max(s1.length, s2.length);
    if (maxLen == 0) return 1.0;
    int distancia = calcularDistanciaLevenshtein(s1, s2);
    return 1.0 - (distancia / maxLen);
  }

  // Normalizar cadena de texto: minúsculas, remover acentos y stop words básicos
  static String _normalizarTexto(String texto) {
    String normalizado = texto.toLowerCase().trim();
    
    // Remover acentos del español de forma simple y robusta
    normalizado = normalizado
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');

    // Remover signos de puntuación molestos
    normalizado = normalizado.replaceAll(RegExp(r'[.,;:?¿!¡\-\_\(\)]'), ' ');

    return normalizado;
  }

  // Obtener la mejor coincidencia difusa para un token dado sobre una lista de opciones
  static String? obtenerCoincidenciaDifusa(String token, List<String> opciones, {double umbral = 0.70}) {
    if (token.isEmpty || opciones.isEmpty) return null;

    final tokenNorm = _normalizarTexto(token);
    String? mejorOpcion;
    double maximaSimilitud = 0.0;

    for (var opc in opciones) {
      final opcNorm = _normalizarTexto(opc);
      
      // Coincidencia exacta o contenida directa
      if (opcNorm.contains(tokenNorm) || tokenNorm.contains(opcNorm)) {
        return opc;
      }

      double sim = calcularSimilitud(tokenNorm, opcNorm);
      if (sim > maximaSimilitud) {
        maximaSimilitud = sim;
        mejorOpcion = opc;
      }
    }

    if (maximaSimilitud >= umbral) {
      return mejorOpcion;
    }

    return null;
  }

  // Extraer fecha del texto y registrar el substring coincidente para removerlo después
  static DateTime? extraerFecha(String fraseNorm, {required List<String> matchedSubstrings}) {
    final ahora = DateTime.now();

    // 1. Palabras clave simples
    final mapeoSimples = {
      'antes de ayer': ahora.subtract(const Duration(days: 2)),
      'anteayer': ahora.subtract(const Duration(days: 2)),
      'ayer': ahora.subtract(const Duration(days: 1)),
      'hoy': ahora,
      'manana': ahora.add(const Duration(days: 1)),
    };

    for (var entry in mapeoSimples.entries) {
      if (fraseNorm.contains(entry.key)) {
        matchedSubstrings.add(entry.key);
        return entry.value;
      }
    }

    // 2. Días de la semana
    final diasSemana = {
      'lunes': 1,
      'martes': 2,
      'miercoles': 3,
      'jueves': 4,
      'viernes': 5,
      'sabado': 6,
      'domingo': 7,
    };

    for (var entry in diasSemana.entries) {
      if (fraseNorm.contains(entry.key)) {
        int targetWeekday = entry.value;
        int currentWeekday = ahora.weekday;
        int diff = currentWeekday - targetWeekday;
        if (diff < 0) {
          diff += 7;
        }
        
        String matchedText = entry.key;
        if (fraseNorm.contains('${entry.key} pasado') || fraseNorm.contains('pasado ${entry.key}')) {
          diff += 7;
          if (fraseNorm.contains('${entry.key} pasado')) {
            matchedText = '${entry.key} pasado';
          } else {
            matchedText = 'pasado ${entry.key}';
          }
        }
        
        matchedSubstrings.add(matchedText);
        return ahora.subtract(Duration(days: diff));
      }
    }

    // 3. Patrón "el X de Y" o "X de Y" (ej: "12 de junio")
    final meses = {
      'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5, 'junio': 6,
      'julio': 7, 'agosto': 8, 'septiembre': 9, 'octubre': 10, 'noviembre': 11, 'diciembre': 12
    };

    final regexDeMes = RegExp(r'\b(\d{1,2})\s+de\s+([a-z]+)\b');
    final matchMes = regexDeMes.firstMatch(fraseNorm);
    if (matchMes != null) {
      final dia = int.tryParse(matchMes.group(1) ?? '');
      final mesNombre = matchMes.group(2);
      if (dia != null && mesNombre != null && meses.containsKey(mesNombre)) {
        matchedSubstrings.add(matchMes.group(0)!);
        return DateTime(ahora.year, meses[mesNombre]!, dia, ahora.hour, ahora.minute);
      }
    }

    // 4. Patrón "el [numero]" (ej: "el 12" de este mes o del anterior)
    final regexDiaSolo = RegExp(r'\bel\s+(\d{1,2})\b');
    final matchDia = regexDiaSolo.firstMatch(fraseNorm);
    if (matchDia != null) {
      final dia = int.tryParse(matchDia.group(1) ?? '');
      if (dia != null && dia >= 1 && dia <= 31) {
        matchedSubstrings.add(matchDia.group(0)!);
        if (dia > ahora.day) {
          int mesPrevio = ahora.month - 1;
          int anio = ahora.year;
          if (mesPrevio == 0) {
            mesPrevio = 12;
            anio--;
          }
          int maxDias = DateTime(anio, mesPrevio + 1, 0).day;
          return DateTime(anio, mesPrevio, min(dia, maxDias), ahora.hour, ahora.minute);
        } else {
          return DateTime(ahora.year, ahora.month, dia, ahora.hour, ahora.minute);
        }
      }
    }

    return null;
  }

  // Helper para buscar palabra previa a una posición
  static String? _obtenerPalabraPrevia(String frase, int index) {
    final sub = frase.substring(0, index).trim();
    if (sub.isEmpty) return null;
    final parts = sub.split(RegExp(r'\s+'));
    return parts.last;
  }

  // Motor NLP principal (Gemini Asíncrono con Fallback Local)
  static Future<ResultadoAsistenteVoz> procesarFrase(
    String frase,
    List<ModeloCuenta> cuentas,
    List<ModeloCategoria> categorias, {
    String? geminiApiKey,
  }) async {
    if (geminiApiKey == null || geminiApiKey.trim().isEmpty) {
      return procesarFraseLocal(frase, cuentas, categorias);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: geminiApiKey.trim(),
      );

      final String nowIso = DateTime.now().toIso8601String();

      final String systemPrompt = '''
Eres el motor de análisis de voz de una aplicación de finanzas personales.
Tu tarea es analizar una frase transcrita por voz y extraer un JSON estructurado con la información de la transacción.
Debes basarte en la lista de cuentas y categorías disponibles en la aplicación.

Cuentas disponibles en la app:
${cuentas.map((c) => '- Nombre: "${c.name}", ID: "${c.id}", Tipo: "${c.type}"').join('\n')}

Categorías disponibles en la app:
${categorias.map((c) => '- Nombre: "${c.name}", ID: "${c.id}"').join('\n')}

La fecha actual del sistema es: $nowIso

Debes devolver obligatoriamente y únicamente un JSON con la estructura detallada abajo.
NO uses bloques de formato tipo ```json, responde solo con el JSON crudo en texto plano:
{
  "titulo": "Un título descriptivo y limpio del gasto (ej: Almuerzo familiar, Carga de Gasolina, Compra de Zapatos, etc.)",
  "importe": 150.0, // número decimal (float), null si no se detecta
  "tipo": "gasto" | "ingreso" | "transferencia",
  "accountId": "ID de la cuenta de origen (de la lista de cuentas proporcionada). null si no se detecta", 
  "toAccountId": "ID de la cuenta de destino (solo si es transferencia y se detecta, de lo contrario null)", 
  "categoria": "Nombre exacto de la categoría detectada (de la lista de categorías proporcionada). null si es transferencia o no se detecta", 
  "fecha": "Fecha detectada en formato ISO 8601 (ej: 2026-06-12T12:00:00Z). Calcula esta fecha en base a la fecha actual y palabras como 'ayer', 'hoy', 'hace 3 días', 'el lunes pasado', 'el 12 de junio'"
}

Ejemplos:
1. "Gasto 50 pesos en comida con Efectivo hoy" -> {"titulo": "Comida", "importe": 50.0, "tipo": "gasto", "accountId": "ID_efectivo", "toAccountId": null, "categoria": "Alimentación", "fecha": "$nowIso"}
2. "Sueldo de 5000 en Mi Banco ayer" -> {"titulo": "Sueldo", "importe": 5000.0, "tipo": "ingreso", "accountId": "ID_mi_banco", "toAccountId": null, "categoria": "Ingresos", "fecha": "2026-06-11T12:00:00Z"}
3. "Transferí 100 de Efectivo a Mi Banco" -> {"titulo": "Transferencia", "importe": 100.0, "tipo": "transferencia", "accountId": "ID_efectivo", "toAccountId": "ID_mi_banco", "categoria": null, "fecha": "$nowIso"}
''';

      final response = await model.generateContent([
        Content.text('$systemPrompt\n\nFrase dictada por el usuario:\n"$frase"')
      ]);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return procesarFraseLocal(frase, cuentas, categorias);
      }

      // Limpiar posibles bloques markdown de código si Gemini los devolvió
      String cleanJson = text.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```json\s*'), '');
        cleanJson = cleanJson.replaceAll(RegExp(r'^```\s*'), '');
        cleanJson = cleanJson.replaceAll(RegExp(r'\s*```$'), '');
      }

      final Map<String, dynamic> data = json.decode(cleanJson);

      double? parsedImporte;
      if (data['importe'] != null) {
        parsedImporte = (data['importe'] as num).toDouble();
      }

      DateTime? parsedFecha;
      if (data['fecha'] != null) {
        parsedFecha = DateTime.tryParse(data['fecha'] as String);
      }

      // Buscar si el nombre o ID de la categoría coincide
      String? catFinal;
      if (data['categoria'] != null) {
        final catStr = data['categoria'] as String;
        final match = categorias.firstWhere(
          (c) => c.name.toLowerCase() == catStr.toLowerCase() || c.id == catStr,
          orElse: () => categorias.firstWhere(
            (c) => c.name.toLowerCase().contains(catStr.toLowerCase()) || catStr.toLowerCase().contains(c.name.toLowerCase()),
            orElse: () => ModeloCategoria(id: '', name: '', iconCode: '', hexColor: ''),
          ),
        );
        if (match.name.isNotEmpty) {
          catFinal = match.name;
        }
      }

      return ResultadoAsistenteVoz(
        titulo: data['titulo'] as String?,
        importe: parsedImporte,
        tipo: data['tipo'] as String?,
        accountId: data['accountId'] as String?,
        toAccountId: data['toAccountId'] as String?,
        categoria: catFinal,
        fecha: parsedFecha,
      );

    } catch (e) {
      debugPrint('Error invocando Gemini API: $e. Usando parser local de respaldo.');
      return procesarFraseLocal(frase, cuentas, categorias);
    }
  }

  // Parser Local Offline (Mantenido como fallback)
  static ResultadoAsistenteVoz procesarFraseLocal(String frase, List<ModeloCuenta> cuentas, List<ModeloCategoria> categorias) {
    if (frase.trim().isEmpty) {
      return ResultadoAsistenteVoz();
    }

    final fraseNorm = _normalizarTexto(frase);

    // 1. Extraer Fecha
    final List<String> matchedDates = [];
    final fecha = extraerFecha(fraseNorm, matchedSubstrings: matchedDates);

    // Limpiar fecha de la frase para evitar conflictos con el importe
    String fraseLimpiaDeFecha = fraseNorm;
    for (var match in matchedDates) {
      fraseLimpiaDeFecha = fraseLimpiaDeFecha.replaceAll(match, '');
    }

    // 2. Extraer Importe (Monto) de la frase sin fecha
    double? importe;
    String? amountMatchedString;
    final regExpMonto = RegExp(r'\b\d+(?:[\.,]\d+)?\b');
    final matchesMonto = regExpMonto.allMatches(fraseLimpiaDeFecha);
    
    if (matchesMonto.isNotEmpty) {
      for (var match in matchesMonto) {
        final stringVal = match.group(0)!.replaceAll(',', '.');
        final parseVal = double.tryParse(stringVal);
        if (parseVal != null && parseVal > 0) {
          importe = parseVal;
          amountMatchedString = match.group(0);
          break;
        }
      }
    }

    // Limpiar importe de la frase
    String fraseLimpiaDeMonto = fraseLimpiaDeFecha;
    if (amountMatchedString != null) {
      fraseLimpiaDeMonto = fraseLimpiaDeMonto.replaceAll(amountMatchedString, '');
    }

    // 3. Clasificar el Tipo de Transacción
    String tipo = 'gasto';
    final palabrasGasto = {'gasto', 'gaste', 'pague', 'pago', 'compra', 'compre', 'salida', 'retire', 'retiro', 'comprar'};
    final palabrasIngreso = {'ingreso', 'gane', 'recibi', 'cobro', 'cobre', 'salario', 'sueldo', 'me pagaron', 'deposito', 'depositaron', 'entrada', 'ganar', 'cobrar'};
    final palabrasTransferencia = {'transferencia', 'transferi', 'envie', 'mande', 'traspaso', 'traspase', 'mover', 'movi', 'transferir'};

    int puntajeGasto = 0;
    int puntajeIngreso = 0;
    int puntajeTransferencia = 0;

    final tokensLimpia = fraseLimpiaDeMonto.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    for (var tok in tokensLimpia) {
      if (palabrasGasto.contains(tok)) puntajeGasto++;
      if (palabrasIngreso.contains(tok)) puntajeIngreso++;
      if (palabrasTransferencia.contains(tok)) puntajeTransferencia++;
    }

    if (puntajeTransferencia > 0 && puntajeTransferencia >= puntajeGasto && puntajeTransferencia >= puntajeIngreso) {
      tipo = 'transferencia';
    } else if (puntajeIngreso > puntajeGasto && puntajeIngreso >= puntajeTransferencia) {
      tipo = 'ingreso';
    } else {
      tipo = 'gasto';
    }

    // 4. Detectar Cuentas (Origen y Destino)
    String? accountId;
    String? toAccountId;
    final List<String> matchedAccountsTexts = [];

    List<_CuentaCoincidencia> coincidenciasCuentas = [];

    for (var acc in cuentas) {
      List<String> terminosBusqueda = [_normalizarTexto(acc.name)];
      
      final nameNorm = _normalizarTexto(acc.name);
      for (var entry in sinonimosCuentas.entries) {
        if (nameNorm.contains(entry.key)) {
          terminosBusqueda.addAll(entry.value);
        }
      }
      
      final typeNorm = _normalizarTexto(acc.type);
      for (var entry in sinonimosCuentas.entries) {
        if (typeNorm.contains(entry.key)) {
          terminosBusqueda.addAll(entry.value);
        }
      }

      terminosBusqueda = terminosBusqueda.toSet().toList();

      for (var term in terminosBusqueda) {
        if (term.length < 3) continue;
        final regex = RegExp(r'\b' + RegExp.escape(term) + r'\b');
        final match = regex.firstMatch(fraseLimpiaDeMonto);
        if (match != null) {
          coincidenciasCuentas.add(_CuentaCoincidencia(acc, match.start, match.group(0)!));
          break;
        }
      }
    }

    coincidenciasCuentas.sort((a, b) => a.index.compareTo(b.index));

    if (coincidenciasCuentas.isNotEmpty) {
      for (var coinc in coincidenciasCuentas) {
        matchedAccountsTexts.add(coinc.matchText);
      }

      if (coincidenciasCuentas.length == 1) {
        accountId = coincidenciasCuentas.first.cuenta.id;
      } else {
        // Analizar preposiciones para determinar origen y destino en transferencias
        final String? prev1 = _obtenerPalabraPrevia(fraseLimpiaDeMonto, coincidenciasCuentas[0].index);
        final String? prev2 = _obtenerPalabraPrevia(fraseLimpiaDeMonto, coincidenciasCuentas[1].index);

        final prepOrigen = {'de', 'desde'};
        final prepDestino = {'a', 'al', 'hacia', 'para'};

        bool is1Origen = prev1 != null && prepOrigen.contains(prev1);
        bool is1Destino = prev1 != null && prepDestino.contains(prev1);
        bool is2Origen = prev2 != null && prepOrigen.contains(prev2);
        bool is2Destino = prev2 != null && prepDestino.contains(prev2);

        if (is1Origen || is2Destino) {
          accountId = coincidenciasCuentas[0].cuenta.id;
          toAccountId = coincidenciasCuentas[1].cuenta.id;
        } else if (is1Destino || is2Origen) {
          accountId = coincidenciasCuentas[1].cuenta.id;
          toAccountId = coincidenciasCuentas[0].cuenta.id;
        } else {
          accountId = coincidenciasCuentas[0].cuenta.id;
          toAccountId = coincidenciasCuentas[1].cuenta.id;
        }
      }
    }

    // 5. Detectar Categoría por Sinónimos
    String? categoriaDetectada;
    String? matchedCategoryText;
    
    if (tipo != 'transferencia' && categorias.isNotEmpty) {
      List<_CategoriaCoincidencia> coincidenciasCategorias = [];

      for (var cat in categorias) {
        List<String> terminos = [_normalizarTexto(cat.name)];
        
        final nameNorm = _normalizarTexto(cat.name);
        for (var entry in sinonimosCategorias.entries) {
          if (nameNorm.contains(_normalizarTexto(entry.key))) {
            terminos.addAll(entry.value);
          }
        }

        terminos = terminos.map((t) => _normalizarTexto(t)).toSet().toList();

        for (var term in terminos) {
          if (term.length < 3) continue;
          final regex = RegExp(r'\b' + RegExp.escape(term) + r'\b');
          final match = regex.firstMatch(fraseLimpiaDeMonto);
          if (match != null) {
            coincidenciasCategorias.add(_CategoriaCoincidencia(cat, match.start, match.group(0)!));
            break;
          }
        }
      }

      if (coincidenciasCategorias.isNotEmpty) {
        // Priorizar la coincidencia de texto más específica (más larga)
        coincidenciasCategorias.sort((a, b) => b.matchText.length.compareTo(a.matchText.length));
        categoriaDetectada = coincidenciasCategorias.first.categoria.name;
        matchedCategoryText = coincidenciasCategorias.first.matchText;
      }
    } else if (tipo == 'transferencia') {
      categoriaDetectada = 'Transferencia';
    }

    // 6. Extraer Título Limpio (comenzando de la frase original para preservar mayúsculas)
    String titulo = frase.trim();
    final List<String> aRemover = [];

    // Agregar fechas
    aRemover.addAll(matchedDates);

    // Agregar importe e indicativos de moneda
    if (amountMatchedString != null) {
      aRemover.add(amountMatchedString);
    }
    aRemover.addAll(['bs', 'bolivianos', 'boliviano', 'pesos', 'dolares', 'dolar', 'euros', 'euro', 'usd', r'$', '€', '¥']);

    // Agregar textos de cuenta
    aRemover.addAll(matchedAccountsTexts);

    // Agregar texto de categoría
    if (matchedCategoryText != null) {
      aRemover.add(matchedCategoryText);
    }

    // Agregar palabras de intención
    aRemover.addAll([
      'gasto', 'gaste', 'pague', 'pago', 'compra', 'compre', 'salida', 'retire', 'retiro', 'comprar',
      'ingreso', 'gane', 'recibi', 'cobro', 'cobre', 'salario', 'sueldo', 'me pagaron', 'deposito', 'depositaron', 'entrada', 'ganar', 'cobrar',
      'transferencia', 'transferi', 'envie', 'mande', 'traspaso', 'traspase', 'mover', 'movi', 'transferir'
    ]);

    // Ordenar de mayor a menor longitud para no eliminar partes de palabras más largas
    aRemover.sort((a, b) => b.length.compareTo(a.length));

    String tituloNorm = _normalizarTexto(titulo);
    for (var item in aRemover) {
      if (item.trim().isEmpty) continue;
      final itemNorm = _normalizarTexto(item);
      
      int idx = tituloNorm.indexOf(itemNorm);
      while (idx != -1) {
        titulo = titulo.substring(0, idx) + ' ' + titulo.substring(idx + item.length);
        tituloNorm = _normalizarTexto(titulo);
        idx = tituloNorm.indexOf(itemNorm);
      }
    }

    // Limpiar espacios dobles
    titulo = titulo.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Limpiar preposiciones de bordes
    final stopWordsBordes = {
      'de', 'desde', 'en', 'para', 'con', 'por', 'a', 'al', 'del', 'mi', 'mis', 'un', 'una', 'el', 'la', 'los', 'las', 'y', 'o'
    };

    bool cambio = true;
    while (cambio) {
      cambio = false;
      final palabras = titulo.split(' ');
      if (palabras.isEmpty || (palabras.length == 1 && palabras.first.isEmpty)) break;
      
      final firstNorm = _normalizarTexto(palabras.first);
      final lastNorm = _normalizarTexto(palabras.last);
      
      if (stopWordsBordes.contains(firstNorm)) {
        palabras.removeAt(0);
        titulo = palabras.join(' ');
        cambio = true;
      } else if (stopWordsBordes.contains(lastNorm) && palabras.isNotEmpty) {
        palabras.removeLast();
        titulo = palabras.join(' ');
        cambio = true;
      }
    }

    titulo = titulo.trim();

    if (titulo.isNotEmpty) {
      titulo = titulo[0].toUpperCase() + titulo.substring(1);
    } else {
      if (categoriaDetectada != null) {
        titulo = categoriaDetectada;
      } else {
        titulo = tipo == 'gasto'
            ? 'Gasto General'
            : (tipo == 'ingreso' ? 'Ingreso General' : 'Transferencia');
      }
    }

    return ResultadoAsistenteVoz(
      titulo: titulo,
      importe: importe,
      tipo: tipo,
      accountId: accountId,
      toAccountId: toAccountId,
      categoria: categoriaDetectada,
      fecha: fecha,
    );
  }
}
