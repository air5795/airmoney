
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
  int _selectedIconTab = 0; // 0: Gastos, 1: Ingresos, 2: Todos
  bool _firstCategoryExpanded = false;

  static final Map<String, IconData> _galleryIcons = EstadoApp.galleryIcons;

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

    // Color del título al medio (el mismo color que tiene ajustes pero un poco más oscuro/claro según el tema)
    final Color colorTitulo = esOscuro
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.1), colorPrincipal)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.15), colorPrincipal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              // Botón Retroceso (Izquierda)
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InteractiveScale(
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
                ),
              ),
              
              // Título (Centro) - Color de Ajustes pero en Negrita (W900)
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                    _isCreatingOrEditingCategory
                        ? (_selectedCategoryToEdit != null ? 'Editar Categoría' : 'Nueva Categoría')
                        : 'Categorías',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colorTitulo,
                    ),
                  ),
                ),
              ),
              
              // Botón Agregar / Guardar (Derecha)
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Builder(
                    builder: (context) {
                      if (_isCreatingOrEditingCategory) {
                        return InteractiveScale(
                          onTap: () => _guardarCategoria(estadoApp),
                          child: Text(
                            'Guardar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorPrincipal,
                            ),
                          ),
                        );
                      } else {
                        return InteractiveScale(
                          onTap: () {
                            setState(() {
                              _isCreatingOrEditingCategory = true;
                              _selectedCategoryToEdit = null;
                              _categoryNameController.clear();
                              _selectedCategoryParentId = null;
                              _selectedCategoryIconCode = 'restaurant';
                              _selectedCategoryColorHex = '#FFE0B2';
                              _selectedIconTab = 0;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorPrincipal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 14, color: colorPrincipal),
                                const SizedBox(width: 4),
                                Text(
                                  'Agregar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: colorPrincipal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
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
                color: esOscuro ? const Color(0xFF1E1E1E) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: esOscuro ? const Color(0xFF1E1E1E) : Colors.black.withValues(alpha: 0.05),
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
        InkWell(
          onTap: () => _showParentCategorySelectorBottomSheet(
            context,
            parentCategories,
            esOscuro,
            colorPrincipal,
            colorTexto,
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: esOscuro ? const Color(0xFF1E1E1E) : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Builder(
                  builder: (context) {
                    if (_selectedCategoryParentId == null) {
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorPrincipal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.folder_copy_rounded,
                          color: colorPrincipal,
                          size: 18,
                        ),
                      );
                    } else {
                      final parentCat = parentCategories.firstWhere(
                        (p) => p.id == _selectedCategoryParentId,
                        orElse: () => ModeloCategoria(id: '', name: '', iconCode: 'category', hexColor: '#64748B'),
                      );
                      final pColor = Color(int.parse(parentCat.hexColor.replaceFirst('#', '0xFF')));
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: pColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _galleryIcons[parentCat.iconCode] ?? Icons.category_rounded,
                          color: pColor,
                          size: 18,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCategoryParentId == null
                            ? 'Categoría Principal (Padre)'
                            : (() {
                                final parentCat = parentCategories.firstWhere(
                                  (p) => p.id == _selectedCategoryParentId,
                                  orElse: () => ModeloCategoria(id: '', name: 'Categoría', iconCode: 'category', hexColor: '#64748B'),
                                );
                                return 'Subcategoría de: ${parentCat.name}';
                              })(),
                        style: TextStyle(
                          color: colorTexto,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedCategoryParentId == null
                            ? 'No pertenece a ninguna otra categoría'
                            : 'Hereda propiedades de la categoría padre',
                        style: TextStyle(
                          color: colorTexto.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorTexto.withValues(alpha: 0.4),
                ),
              ],
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
          height: 38,
          decoration: BoxDecoration(
            color: esOscuro
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth / 3;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: _selectedIconTab * width,
                    top: 2,
                    bottom: 2,
                    child: Container(
                      width: width - 4,
                      decoration: BoxDecoration(
                        color: esOscuro
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedIconTab = 0;
                            });
                          },
                          child: Center(
                            child: Text(
                              'Gastos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedIconTab == 0 ? FontWeight.bold : FontWeight.w500,
                                color: _selectedIconTab == 0 ? colorPrincipal : colorTexto.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedIconTab = 1;
                            });
                          },
                          child: Center(
                            child: Text(
                              'Ingresos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedIconTab == 1 ? FontWeight.bold : FontWeight.w500,
                                color: _selectedIconTab == 1 ? colorPrincipal : colorTexto.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedIconTab = 2;
                            });
                          },
                          child: Center(
                            child: Text(
                              'Todos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedIconTab == 2 ? FontWeight.bold : FontWeight.w500,
                                color: _selectedIconTab == 2 ? colorPrincipal : colorTexto.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
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
          child: Builder(
            builder: (context) {
              final List<String> currentTabKeys;
              if (_selectedIconTab == 0) {
                currentTabKeys = EstadoApp.expenseIconKeys.where((key) => _galleryIcons.containsKey(key)).toList();
              } else if (_selectedIconTab == 1) {
                currentTabKeys = EstadoApp.incomeIconKeys.where((key) => _galleryIcons.containsKey(key)).toList();
              } else {
                currentTabKeys = _galleryIcons.keys.toList();
              }

              return GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: currentTabKeys.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final key = currentTabKeys[index];
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? colorPrincipal : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: isSelected ? colorPrincipal : colorTexto.withValues(alpha: 0.6),
                          size: 26,
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ),
        const SizedBox(height: 20),

        if (_selectedCategoryParentId == null) ...[
          Text(
            'COLOR Y VISTA PREVIA EN TIEMPO REAL',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: HexColorPicker(
                  currentColorHex: _selectedCategoryColorHex,
                  onColorChanged: (hex) {
                    setState(() {
                      _selectedCategoryColorHex = hex;
                    });
                  },
                  esOscuro: esOscuro,
                  colorPrincipal: colorPrincipal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VISTA PREVIA',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: esOscuro ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF0F172A).withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDynamicPreview(estadoApp, esOscuro, colorTexto),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorPrincipal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorPrincipal.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: colorPrincipal,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Las subcategorías heredan automáticamente el color de su categoría padre.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorTexto.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'VISTA PREVIA',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 12),
          _buildDynamicPreview(estadoApp, esOscuro, colorTexto),
        ],

      ],
    );
  }

  Widget _buildDynamicPreview(EstadoApp estadoApp, bool esOscuro, Color colorTexto) {
    final hexColorStr = _selectedCategoryColorHex.isEmpty ? '#E2E8F0' : _selectedCategoryColorHex;
    final catColor = Color(int.parse(hexColorStr.replaceFirst('#', '0xFF')));
    final isSubcategory = _selectedCategoryParentId != null;

    if (!isSubcategory) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: esOscuro 
              ? const Color(0xFF0E0E0E).withValues(alpha: 0.55) 
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: esOscuro 
                ? const Color(0xFF1E1E1E) 
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
                  _galleryIcons[_selectedCategoryIconCode] ?? Icons.bubble_chart_rounded,
                  color: catColor,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _categoryNameController.text.isEmpty ? 'Nombre' : _categoryNameController.text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorTexto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '0 subcategorías',
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
      );
    } else {
      final parentCat = estadoApp.categories.firstWhere(
        (cat) => cat.id == _selectedCategoryParentId,
        orElse: () => ModeloCategoria(id: '', name: 'Categoría Padre', iconCode: 'category', hexColor: '#64748B'),
      );
      final parentColor = Color(int.parse(parentCat.hexColor.replaceFirst('#', '0xFF')));

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: esOscuro 
              ? const Color(0xFF0E0E0E).withValues(alpha: 0.55) 
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: esOscuro 
                ? const Color(0xFF1E1E1E) 
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: parentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: parentColor.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _galleryIcons[parentCat.iconCode] ?? Icons.bubble_chart_rounded,
                        color: parentColor,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          parentCat.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorTexto,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1 subcategoría',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorTexto.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: colorTexto.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
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
              child: Padding(
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
                      _galleryIcons[_selectedCategoryIconCode] ?? Icons.bubble_chart_rounded,
                      color: catColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _categoryNameController.text.isEmpty ? 'Nombre' : _categoryNameController.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorTexto,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCategoriesList(EstadoApp estadoApp, bool esOscuro, Color colorPrincipal, Color colorTexto) {
    final parentCategories = estadoApp.categories.where((cat) => cat.parentId == null).toList();

    if (!_firstCategoryExpanded && parentCategories.isNotEmpty) {
      _expandedParentIds.add(parentCategories.first.id);
      _firstCategoryExpanded = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

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
                        ? const Color(0xFF1E1E1E) 
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
                                if (EstadoApp.incomeIconKeys.contains(cat.iconCode) && !EstadoApp.expenseIconKeys.contains(cat.iconCode)) {
                                  _selectedIconTab = 1;
                                } else {
                                  _selectedIconTab = 0;
                                }
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
                                        if (EstadoApp.incomeIconKeys.contains(child.iconCode) && !EstadoApp.expenseIconKeys.contains(child.iconCode)) {
                                          _selectedIconTab = 1;
                                        } else {
                                          _selectedIconTab = 0;
                                        }
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

  void _showParentCategorySelectorBottomSheet(
    BuildContext context,
    List<ModeloCategoria> parentCategories,
    bool esOscuro,
    Color colorPrincipal,
    Color colorTexto,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: esOscuro ? const Color(0xFF0F0F11) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: esOscuro ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categoría Padre',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colorTexto,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: colorTexto.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildParentOption(
                            title: 'Ninguna (Es Categoría Principal)',
                            subtitle: 'Define esta categoría en el nivel superior',
                            icon: Icons.folder_copy_rounded,
                            iconColor: colorPrincipal,
                            isSelected: _selectedCategoryParentId == null,
                            onTap: () {
                              setState(() {
                                _selectedCategoryParentId = null;
                              });
                              Navigator.pop(context);
                            },
                            esOscuro: esOscuro,
                            colorTexto: colorTexto,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                              color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                              height: 1,
                            ),
                          ),
                          ...parentCategories
                              .where((p) => p.id != _selectedCategoryToEdit?.id)
                              .map((cat) {
                            final pColor = Color(int.parse(cat.hexColor.replaceFirst('#', '0xFF')));
                            final isSelected = _selectedCategoryParentId == cat.id;
                            
                            return _buildParentOption(
                              title: cat.name,
                              subtitle: 'Crear como subcategoría de ${cat.name}',
                              icon: _galleryIcons[cat.iconCode] ?? Icons.category_rounded,
                              iconColor: pColor,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedCategoryParentId = cat.id;
                                  _selectedCategoryColorHex = cat.hexColor;
                                });
                                Navigator.pop(context);
                              },
                              esOscuro: esOscuro,
                              colorTexto: colorTexto,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildParentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool esOscuro,
    required Color colorTexto,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: colorTexto,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorTexto.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: iconColor,
                size: 22,
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: esOscuro ? Colors.white24 : Colors.black12,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
