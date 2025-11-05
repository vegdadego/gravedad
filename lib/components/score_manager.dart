import 'package:flame/components.dart';

/// Administrador de puntuación del juego
class ScoreManager {
  int _score = 0;
  int _enemiesDestroyed = 0;
  int _blocksDestroyed = 0;
  
  // Puntos por acciones
  static const int pointsPerEnemy = 100;
  static const int pointsPerBlock = 10;
  static const int perfectBonus = 500;
  static const int efficientBonus = 300;

  int get score => _score;
  int get enemiesDestroyed => _enemiesDestroyed;
  int get blocksDestroyed => _blocksDestroyed;

  /// Agregar puntos por eliminar enemigo
  void addEnemyDestroyed() {
    _enemiesDestroyed++;
    _score += pointsPerEnemy;
  }

  /// Agregar puntos por destruir bloque
  void addBlockDestroyed() {
    _blocksDestroyed++;
    _score += pointsPerBlock;
  }

  /// Calcular estrellas basado en eficiencia
  /// Requiere: disparos usados y disparos máximos
  int calculateStars(int shotsUsed, int maxShots) {
    final efficiency = shotsUsed / maxShots;
    
    if (efficiency <= 0.3) {
      // Usó 30% o menos = 3 estrellas
      _score += perfectBonus;
      return 3;
    } else if (efficiency <= 0.5) {
      // Usó 50% o menos = 2 estrellas
      _score += efficientBonus;
      return 2;
    } else {
      // Completó el nivel = 1 estrella
      return 1;
    }
  }

  /// Reiniciar puntuación
  void reset() {
    _score = 0;
    _enemiesDestroyed = 0;
    _blocksDestroyed = 0;
  }

  /// Obtener texto de resumen
  String getSummary() {
    return 'Puntos: $_score | Enemigos: $_enemiesDestroyed | Bloques: $_blocksDestroyed';
  }
}

