//Este archivo se encarga de convertir el JSON que envía el backend
//a un objeto de Dart para que Flutter lo pueda pintar fácilmente sin errores.

class RecipeResponse {
  final String titulo;
  final String tiempo;
  final List<String> ingredientes;
  final List<String> pasos;

  RecipeResponse({
    required this.titulo,
    required this.tiempo,
    required this.ingredientes,
    required this.pasos,
  });

  factory RecipeResponse.fromJson(Map<String, dynamic> json) {
    return RecipeResponse(
      titulo: json['titulo'] ?? 'Receta sin título',
      tiempo: json['tiempo'] ?? 'Tiempo no especificado',
      ingredientes: List<String>.from(json['ingredientes'] ?? []),
      pasos: List<String>.from(json['pasos'] ?? []),
    );
  }
}
