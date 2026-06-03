import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/hex_color_picker.dart';
import '../../../widgets/interactive_scale.dart';

class AjustesCategorias extends StatefulWidget {
  final VoidCallback onBack;

  const AjustesCategorias({
    super.key,
    required this.onBack,
  });

  @override
  State<AjustesCategorias> createState() => _AjustesCategoriasState();
}

class _AjustesCategoriasState extends State<AjustesCategorias> {
  bool _isCreatingOrEditingCategory = false;
  ModeloCategoria? _selectedCategoryToEdit;
  final TextEditingController _categoryNameController = TextEditingController();
  String? _selectedCategoryParentId;
  String _selectedCategoryIconCode = 'restaurant';
  String _selectedCategoryColorHex = '#FFE0B2';
  final Set<String> _expandedParentIds = {};

  static final Map<String, IconData> _galleryIcons = {
    'restaurant': Icons.restaurant_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'directions_car': Icons.directions_car_rounded,
    'work': Icons.work_rounded,
    'electrical_services': Icons.electrical_services_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'category': Icons.category_rounded,
    'movie': Icons.movie_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'home': Icons.home_rounded,
    'flight': Icons.flight_rounded,
    'pets': Icons.pets_rounded,
    'school': Icons.school_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'savings': Icons.savings_rounded,
    'phone_android': Icons.phone_android_rounded,
    'celebration': Icons.celebration_rounded,
    'water_drop': Icons.water_drop_rounded,
    'router': Icons.router_rounded,
    'tv': Icons.tv_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'build': Icons.build_rounded,
    'payments': Icons.payments_rounded,
    'laptop': Icons.laptop_chromebook_rounded,
    'trending_up': Icons.trending_up_rounded,
    'directions_bus': Icons.directions_bus_rounded,
  };

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  void _guardarCategoria(EstadoApp estadoApp) {
    final name = _categoryNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un nombre para la categoría.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedCategoryToEdit != null) {
      estadoApp.editCategory(
        _selectedCategoryToEdit!.id,
        name,
        _selectedCategoryParentId,
        _selectedCategoryIconCode,
        _selectedCategoryColorHex,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría actualizada con éxito.'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
    } else {
      estadoApp.addCategory(
        name,
        _selectedCategoryParentId,
        _selectedCategoryIconCode,
        _selectedCategoryColorHex,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría creada con éxito.'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
    }

    setState(() {
      _isCreatingOrEditingCategory = false;
      _selectedCategoryToEdit = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InteractiveScale(
              onTap: () {
                if (_isCreatingOrEditingCategory) {
                  setState(() {
                    _isCreatingOrEditingCategory = false;
                    _selectedCategoryToEdit = null;
                  });
                } else {
                  widget.onBack();
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: colorPrincipal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isCreatingOrEditingCategory ? 'Categorías' : 'Ajustes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorPrincipal,
                    ),
                  ),
                ],
              ),
            ),
            if (_isCreatingOrEditingCategory)
              InteractiveScale(
                onTap: () => _guardarCategoria(estadoApp),
                child: Text(
                  'Guardar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorPrincipal,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _isCreatingOrEditingCategory
              ? (_selectedCategoryToEdit != null ? 'Editar Categoría' : 'Nueva Categoría')
              : 'Categorías',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: colorTexto,
            letterSpacing: -0.8,
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          _isCreatingOrEditingCategory ? 'PERSONALIZAR DETALLES' : 'GESTIONAR FLUJO DE GASTOS',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 24),
        
        if (_isCreatingOrEditingCategory)
          _buildCategoryForm(estadoApp, esOscuro, colorPrincipal, colorTexto)
        else
          _buildCategoriesList(estadoApp, esOscuro, colorPrincipal, colorTexto),
        
        const SizedBox(height: 110),
      ],
    );
  }

  Widget _buildCategoryForm(EstadoApp estadoApp, bool esOscuro, Color colorPrincipal, Color colorTexto) {
    final parentCategories = estadoApp.categories.where((cat) => cat.parentId == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'PREVISUALIZACIÓN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: esOscuro ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF0F172A).withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(int.parse(_selectedCategoryColorHex.replaceFirst('#', '0xFF'))).withValues(alpha: esOscuro ? 0.25 : 0.45),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Color(int.parse(_selectedCategoryColorHex.replaceFirst('#', '0xFF'))).withValues(alpha: esOscuro ? 0.35 : 0.8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse(_selectedCategoryColorHex.replaceFirst('#', '0xFF'))).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Icon(
                          _galleryIcons[_selectedCategoryIconCode] ?? Icons.bubble_chart_rounded,
                          color: Color(int.parse(_selectedCategoryColorHex.replaceFirst('#', '0xFF'))),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _categoryNameController.text.isEmpty ? 'Nombre' : _categoryNameController.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorTexto,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 28),

        Text(
          'NOMBRE DE LA CATEGORÍA',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _categoryNameController,
          style: TextStyle(
            color: colorTexto,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Ej. Supermercado',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorPrincipal,
                width: 1.0,
              ),
            ),
          ),
          onChanged: (val) {
            setState(() {});
          },
        ),
        const SizedBox(height: 20),

        Text(
          'TIPO / CATEGORÍA PADRE',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: _selectedCategoryParentId,
          dropdownColor: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
          style: TextStyle(
            color: colorTexto,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Categoría Principal (Padre)'),
            ),
            ...parentCategories.where((p) => p.id != _selectedCategoryToEdit?.id).map((cat) => DropdownMenuItem<String?>(
                  value: cat.id,
                  child: Text('Subcategoría de: ${cat.name}'),
                )),
          ],
          onChanged: (val) {
            setState(() {
              _selectedCategoryParentId = val;
            });
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorPrincipal,
                width: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'SELECCIONAR ICONO',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: esOscuro
                ? const Color(0xFF0A0A0A).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(20),
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
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final key = _galleryIcons.keys.elementAt(index);
              final icon = _galleryIcons[key]!;
              final isSelected = _selectedCategoryIconCode == key;

              return InteractiveScale(
                onTap: () {
                  setState(() {
                    _selectedCategoryIconCode = key;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorPrincipal.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? colorPrincipal : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isSelected ? colorPrincipal : colorTexto.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'COLOR DE LA CATEGORÍA (PASTEL / HEXADECIMAL)',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 12),
        HexColorPicker(
          currentColorHex: _selectedCategoryColorHex,
          onColorChanged: (hex) {
            setState(() {
              _selectedCategoryColorHex = hex;
            });
          },
          esOscuro: esOscuro,
          colorPrincipal: colorPrincipal,
        ),

      ],
    );
  }

  Widget _buildCategoriesList(EstadoApp estadoApp, bool esOscuro, Color colorPrincipal, Color colorTexto) {
    final parentCategories = estadoApp.categories.where((cat) => cat.parentId == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InteractiveScale(
          onTap: () {
            setState(() {
              _isCreatingOrEditingCategory = true;
              _selectedCategoryToEdit = null;
              _categoryNameController.clear();
              _selectedCategoryParentId = null;
              _selectedCategoryIconCode = 'restaurant';
              _selectedCategoryColorHex = '#FFE0B2';
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              color: colorPrincipal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorPrincipal.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: colorPrincipal, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Agregar nueva categoría',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorPrincipal,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 350.ms),
        const SizedBox(height: 24),

        if (parentCategories.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No hay categorías creadas.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorTexto.withValues(alpha: 0.3),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: parentCategories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final cat = parentCategories[index];
              final hexColor = cat.hexColor;
              final Color catColor = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
              final childCategories = estadoApp.categories.where((child) => child.parentId == cat.id).toList();
              final isExpanded = _expandedParentIds.contains(cat.id);

              return Container(
                decoration: BoxDecoration(
                  color: esOscuro 
                      ? const Color(0xFF0E0E0E).withValues(alpha: 0.55) 
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: esOscuro 
                        ? Colors.white.withValues(alpha: 0.08) 
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: esOscuro ? 0.15 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (childCategories.isNotEmpty) {
                                  setState(() {
                                    if (_expandedParentIds.contains(cat.id)) {
                                      _expandedParentIds.remove(cat.id);
                                    } else {
                                      _expandedParentIds.add(cat.id);
                                    }
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: catColor.withValues(alpha: 0.25),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _galleryIcons[cat.iconCode] ?? Icons.bubble_chart_rounded,
                                        color: catColor,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: colorTexto,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${childCategories.length} subcategorías',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: colorTexto.withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (childCategories.isNotEmpty)
                            InteractiveScale(
                              onTap: () {
                                setState(() {
                                  if (_expandedParentIds.contains(cat.id)) {
                                    _expandedParentIds.remove(cat.id);
                                  } else {
                                    _expandedParentIds.add(cat.id);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: colorTexto.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          InteractiveScale(
                            onTap: () {
                              setState(() {
                                _isCreatingOrEditingCategory = true;
                                _selectedCategoryToEdit = cat;
                                _categoryNameController.text = cat.name;
                                _selectedCategoryParentId = cat.parentId;
                                _selectedCategoryIconCode = cat.iconCode;
                                _selectedCategoryColorHex = cat.hexColor;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Icon(Icons.edit_rounded, size: 18, color: colorTexto.withValues(alpha: 0.4)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InteractiveScale(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: esOscuro ? const Color(0xFF0A0A0A) : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: BorderSide(
                                      color: esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFCBD5E1),
                                      width: 1.0,
                                    ),
                                  ),
                                  title: const Text('¿Eliminar categoría?', style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: Text('Esto eliminará la categoría "${cat.name}" y todas sus subcategorías de forma permanente.'),
                                  actions: [
                                    InteractiveScale(
                                      onTap: () => Navigator.pop(context),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Text('Cancelar', style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    InteractiveScale(
                                      onTap: () {
                                        estadoApp.deleteCategory(cat.id);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Categoría eliminada.'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent.withValues(alpha: 0.7)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (childCategories.isNotEmpty && isExpanded) ...[
                      Divider(
                        color: esOscuro ? const Color(0xFF1E1E1E) : const Color(0xFFE2E8F0),
                        height: 1,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: esOscuro ? Colors.white.withValues(alpha: 0.01) : const Color(0xFFF8FAFC).withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: childCategories.length,
                          itemBuilder: (context, childIdx) {
                            final child = childCategories[childIdx];
                            final childColor = Color(int.parse(child.hexColor.replaceFirst('#', '0xFF')));

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: colorTexto.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Icon(
                                    _galleryIcons[child.iconCode] ?? Icons.bubble_chart_rounded,
                                    color: childColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      child.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colorTexto,
                                      ),
                                    ),
                                  ),
                                  InteractiveScale(
                                    onTap: () {
                                      setState(() {
                                        _isCreatingOrEditingCategory = true;
                                        _selectedCategoryToEdit = child;
                                        _categoryNameController.text = child.name;
                                        _selectedCategoryParentId = child.parentId;
                                        _selectedCategoryIconCode = child.iconCode;
                                        _selectedCategoryColorHex = child.hexColor;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.edit_rounded, size: 14, color: colorTexto.withValues(alpha: 0.35)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InteractiveScale(
                                    onTap: () {
                                      estadoApp.deleteCategory(child.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Subcategoría eliminada.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.close_rounded, size: 15, color: Colors.redAccent.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
      ],
    );
  }
}
