import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/estado_app.dart';

class BackdropFilterSafe extends StatelessWidget {
  final ImageFilter filter;
  final Widget child;
  final BorderRadius? borderRadius;

  const BackdropFilterSafe({
    super.key,
    required this.filter,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final bool omitirFiltro = estadoApp.modoRendimiento;

    if (omitirFiltro) {
      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius!,
          child: child,
        );
      }
      return child;
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: BackdropFilter(
          filter: filter,
          child: child,
        ),
      );
    }

    return BackdropFilter(
      filter: filter,
      child: child,
    );
  }
}
