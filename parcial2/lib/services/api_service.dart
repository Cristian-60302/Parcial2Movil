//Aquí manejamos las peticiones HTTP GET y POST,
//adaptadas exactamente a la estructura que tu compañero armó en Flask.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recipe_model.dart';

class ApiService {
  // 10.0.2.2 es el localhost del emulador Android.
  // Si el backend corre en otra PC, cambia esto por su IP (ej. 192.168.1.15)
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static Future<List<String>> getIngredientesSugeridos() async {
    try {
      final response = await http.get(
        Uri.parse('\$baseUrl/ingredientes/sugeridos'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['ingredientes'] ?? []);
        }
      }
      throw Exception('Error al cargar ingredientes');
    } catch (e) {
      throw Exception('Error de red: \$e');
    }
  }

  static Future<RecipeResponse> generarReceta(List<String> ingredientes) async {
    try {
      final response = await http.post(
        Uri.parse('\$baseUrl/receta/generar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ingredientes': ingredientes}),
      );

      final data = json.decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        return RecipeResponse.fromJson(data['receta']);
      } else {
        throw Exception(data['error'] ?? 'Error desconocido del servidor');
      }
    } catch (e) {
      throw Exception('Error de red al contactar la IA: \$e');
    }
  }
}
