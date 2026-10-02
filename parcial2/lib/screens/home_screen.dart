//Aquí combinamos todo: obtenemos los ingredientes sugeridos mediante el GET, armamos
// la lista interactiva y disparamos el POST mostrando un estado de carga

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  List<String> _sugerencias = [];
  final List<String> _seleccionados = [];
  final TextEditingController _ingredientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarSugerencias();
  }

  Future<void> _cargarSugerencias() async {
    try {
      final lista = await ApiService.getIngredientesSugeridos();
      if (mounted) setState(() => _sugerencias = lista);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron cargar sugerencias: \$e')),
        );
      }
    }
  }

  void _toggleIngredient(String ingrediente) {
    setState(() {
      _seleccionados.contains(ingrediente)
          ? _seleccionados.remove(ingrediente)
          : _seleccionados.add(ingrediente);
    });
  }

  void _addManualIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty && !_seleccionados.contains(text)) {
      setState(() {
        _seleccionados.add(text);
        _ingredientController.clear();
      });
    }
  }

  Future<void> _generarReceta() async {
    if (_seleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Agrega al menos un ingrediente primero! 🥕'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final recipeData = await ApiService.generarReceta(_seleccionados);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(recipe: recipeData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EcoEat 🍃',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Chef Virtual pensando...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '¿Qué tienes en tu refri?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ingredientController,
                          decoration: InputDecoration(
                            hintText: 'Ej. Champiñones...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          onSubmitted: (_) => _addManualIngredient(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addManualIngredient,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sugerencias:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _sugerencias.map((ingrediente) {
                      return FilterChip(
                        label: Text(ingrediente),
                        selected: _seleccionados.contains(ingrediente),
                        onSelected: (_) => _toggleIngredient(ingrediente),
                        selectedColor: Colors.green.shade200,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  Text(
                    'Seleccionados (${_seleccionados.length}):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _seleccionados.length,
                      itemBuilder: (context, index) {
                        final item = _seleccionados[index];
                        return Card(
                          child: ListTile(
                            title: Text(item),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _toggleIngredient(item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _generarReceta,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar Receta'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
    );
  }
}
