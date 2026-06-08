/// Helper para formatear fechas y horas de transacciones de forma premium.
String formatearFechaHora(DateTime dt, String idioma) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final txDate = DateTime(dt.year, dt.month, dt.day);
  
  final isEs = idioma.toLowerCase() == 'es';
  final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  
  if (txDate == today) {
    return isEs ? 'HOY $timeStr' : 'TODAY $timeStr';
  } else if (txDate == yesterday) {
    return isEs ? 'AYER $timeStr' : 'YESTERDAY $timeStr';
  } else {
    final day = dt.day.toString().padLeft(2, '0');
    final monthsEs = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    final monthsEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final monthStr = isEs ? monthsEs[dt.month - 1] : monthsEn[dt.month - 1];
    return '$day $monthStr • $timeStr';
  }
}
