import 'dart:math';
import '../services/estado_app.dart';

class ResultadoAsistenteVoz {
  final String? titulo;
  final double? importe;
  final String? tipo; // 'gasto', 'ingreso', 'transferencia'
  final String? accountId;
  final String? toAccountId;
  final String? categoria;

  ResultadoAsistenteVoz({
    this.titulo,
    this.importe,
    this.tipo,
    this.accountId,
    this.toAccountId,
    this.categoria,
  });

  @override
  String toString() {
    return 'ResultadoAsistenteVoz(titulo: $titulo, importe: $importe, tipo: $tipo, accountId: $accountId, toAccountId: $toAccountId, categoria: $categoria)';
  }
}

class AsistenteVozHelper {
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
  // Devuelve la opción que supere el umbral mínimo de similitud (ej. 70%)
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

  // Motor NLP principal que procesa la frase dictada de forma offline
  static ResultadoAsistenteVoz procesarFrase(String frase, List<ModeloCuenta> cuentas, List<ModeloCategoria> categorias) {
    if (frase.trim().isEmpty) {
      return ResultadoAsistenteVoz();
    }

    final fraseNorm = _normalizarTexto(frase);
    final tokens = fraseNorm.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    // 1. Extraer Importe (Monto) usando Expresiones Regulares robustas
    double? importe;
    final regExpMonto = RegExp(r'\b\d+(?:[\.,]\d+)?\b');
    final matches = regExpMonto.allMatches(fraseNorm);
    if (matches.isNotEmpty) {
      // Tomamos la primera coincidencia que parezca un número válido
      for (var match in matches) {
        final stringVal = match.group(0)!.replaceAll(',', '.');
        final parseVal = double.tryParse(stringVal);
        if (parseVal != null && parseVal > 0) {
          importe = parseVal;
          break;
        }
      }
    }

    // 2. Clasificar el Tipo de Transacción según intenciones semánticas
    String tipo = 'gasto'; // Gasto por defecto
    
    final palabrasGasto = {'gasto', 'gaste', 'pague', 'pago', 'compra', 'compre', 'salida', 'retire', 'retiro'};
    final palabrasIngreso = {'ingreso', 'gane', 'recibi', 'cobro', 'cobre', 'salario', 'sueldo', 'pago', 'me pagaron', 'deposito', 'depositaron', 'entrada'};
    final palabrasTransferencia = {'transferencia', 'transferi', 'envie', 'mande', 'traspaso', 'traspase', 'mover', 'movi'};

    int puntajeGasto = 0;
    int puntajeIngreso = 0;
    int puntajeTransferencia = 0;

    for (var tok in tokens) {
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

    // 3. Detectar Cuenta de Origen y Cuenta de Destino
    String? accountId;
    String? toAccountId;

    final listaNombresCuentas = cuentas.map((c) => c.name).toList();

    // Buscar tokens o combinaciones de tokens consecutivos que coincidan con las cuentas
    List<String> cuentasDetectadas = [];

    // Algoritmo de emparejamiento por ventana deslizante para nombres de cuentas compuestos (ej: "banco mercantil")
    for (int len = min(3, tokens.length); len >= 1; len--) {
      for (int i = 0; i <= tokens.length - len; i++) {
        final ventana = tokens.sublist(i, i + len).join(' ');
        final match = obtenerCoincidenciaDifusa(ventana, listaNombresCuentas, umbral: 0.75);
        if (match != null) {
          final cuentaAsociada = cuentas.firstWhere((c) => c.name == match);
          if (!cuentasDetectadas.contains(cuentaAsociada.id)) {
            cuentasDetectadas.add(cuentaAsociada.id);
          }
        }
      }
    }

    if (cuentasDetectadas.isNotEmpty) {
      accountId = cuentasDetectadas.first;
      if (cuentasDetectadas.length > 1) {
        toAccountId = cuentasDetectadas[1];
      }
    }

    // 4. Detectar Categoría (solo si no es transferencia)
    String? categoriaDetectada;
    if (tipo != 'transferencia' && categorias.isNotEmpty) {
      final listaNombresCategorias = categorias.map((c) => c.name).toList();
      
      // Buscar coincidencia difusa para categorías
      for (int len = min(3, tokens.length); len >= 1; len--) {
        for (int i = 0; i <= tokens.length - len; i++) {
          final ventana = tokens.sublist(i, i + len).join(' ');
          final match = obtenerCoincidenciaDifusa(ventana, listaNombresCategorias, umbral: 0.70);
          if (match != null) {
            categoriaDetectada = match;
            break;
          }
        }
        if (categoriaDetectada != null) break;
      }
    } else if (tipo == 'transferencia') {
      categoriaDetectada = 'Transferencia';
    }

    // 5. Determinar el Título o Comentario
    // Extraeremos el título eliminando el monto, las stop words y las palabras clave de cuenta/categoría
    String titulo = 'Registro por voz';
    
    // Palabras a ignorar en el título
    final stopWords = {
      'un', 'una', 'el', 'la', 'los', 'las', 'de', 'en', 'para', 'con', 'por', 'a', 'al', 'del',
      'gasto', 'gaste', 'pague', 'pago', 'compra', 'compre', 'salida',
      'ingreso', 'gane', 'recibi', 'cobro', 'cobre', 'salario', 'sueldo',
      'transferencia', 'transferi', 'envie', 'mande', 'traspaso', 'traspase',
      'bs', 'bolivianos', 'boliviano', 'pesos', 'dolares', 'dolar'
    };

    List<String> palabrasTitulo = [];
    for (var tok in tokens) {
      // Ignorar números
      if (RegExp(r'^\d+$').hasMatch(tok)) continue;
      
      // Ignorar stop words y palabras clave
      if (stopWords.contains(tok)) continue;

      // Ignorar si coincide con nombre de cuenta o categoría detectada
      bool coincideConEntidad = false;
      if (accountId != null) {
        final accNameNorm = _normalizarTexto(cuentas.firstWhere((c) => c.id == accountId).name);
        if (accNameNorm.contains(tok)) coincideConEntidad = true;
      }
      if (toAccountId != null) {
        final accNameNorm = _normalizarTexto(cuentas.firstWhere((c) => c.id == toAccountId).name);
        if (accNameNorm.contains(tok)) coincideConEntidad = true;
      }
      if (categoriaDetectada != null) {
        final catNameNorm = _normalizarTexto(categoriaDetectada);
        if (catNameNorm.contains(tok)) coincideConEntidad = true;
      }

      if (!coincideConEntidad) {
        palabrasTitulo.add(tok);
      }
    }

    if (palabrasTitulo.isNotEmpty) {
      // Capitalizar la primera letra del título para estética premium
      final rawTitle = palabrasTitulo.join(' ');
      titulo = rawTitle[0].toUpperCase() + rawTitle.substring(1);
    } else {
      // Si no se extrae un título, poner el nombre de la categoría o tipo como título por defecto
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
    );
  }
}
