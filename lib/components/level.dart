import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'brick.dart';

/// Define los diferentes niveles del juego
enum GameLevel {
  level1('Nivel 1: Fácil', Icons.star_outline, Colors.green),
  level2('Nivel 2: Medio', Icons.star_half, Colors.orange),
  level3('Nivel 3: Difícil', Icons.star, Colors.red),
  random('Aleatorio', Icons.shuffle, Colors.purple);

  final String name;
  final IconData icon;
  final Color color;

  const GameLevel(this.name, this.icon, this.color);
}

/// Configuración de un nivel
class LevelConfig {
  final GameLevel level;
  final int numberOfEnemies;
  final int maxPlayers;
  final List<BrickConfig> bricks;

  const LevelConfig({
    required this.level,
    required this.numberOfEnemies,
    required this.maxPlayers,
    required this.bricks,
  });
}

/// Configuración de un bloque individual
class BrickConfig {
  final BrickType type;
  final BrickSize size;
  final Vector2 position;
  final BrickDamage damage;

  const BrickConfig({
    required this.type,
    required this.size,
    required this.position,
    this.damage = BrickDamage.some,
  });
}

/// Configuraciones de todos los niveles
class LevelConfigurations {
  /// NIVEL 1: FÁCIL - Torre simple
  /// Estructura: Torre baja con enemigos fáciles de alcanzar
  static LevelConfig get level1 => LevelConfig(
    level: GameLevel.level1,
    numberOfEnemies: 2,
    maxPlayers: 8,
    bricks: [
      // Base - bloque horizontal grande
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size220x70,
        position: Vector2(0, -2.5),
      ),
      // Columnas verticales a los lados
      BrickConfig(
        type: BrickType.glass,
        size: BrickSize.size70x140,
        position: Vector2(-3.5, -5.5),
      ),
      BrickConfig(
        type: BrickType.glass,
        size: BrickSize.size70x140,
        position: Vector2(3.5, -5.5),
      ),
      // Techo
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size220x70,
        position: Vector2(0, -8.5),
      ),
    ],
  );

  /// NIVEL 2: MEDIO - Pirámide fortificada
  /// Estructura: Pirámide con múltiples capas protegiendo a los enemigos
  static LevelConfig get level2 => LevelConfig(
    level: GameLevel.level2,
    numberOfEnemies: 2,
    maxPlayers: 10,
    bricks: [
      // Base - 4 bloques horizontales para más estabilidad
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size140x70,
        position: Vector2(-5, -2.5),
      ),
      BrickConfig(
        type: BrickType.stone,
        size: BrickSize.size140x70,
        position: Vector2(-1.5, -2.5),
      ),
      BrickConfig(
        type: BrickType.stone,
        size: BrickSize.size140x70,
        position: Vector2(1.5, -2.5),
      ),
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size140x70,
        position: Vector2(5, -2.5),
      ),

      // Paredes laterales protectoras
      BrickConfig(
        type: BrickType.glass,
        size: BrickSize.size70x140,
        position: Vector2(-4, -5.5),
      ),
      BrickConfig(
        type: BrickType.glass,
        size: BrickSize.size70x140,
        position: Vector2(4, -5.5),
      ),

      // Segundo piso - plataforma central donde están los enemigos
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size140x70,
        position: Vector2(-1.5, -5.5),
      ),
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size140x70,
        position: Vector2(1.5, -5.5),
      ),

      // Columnas internas que protegen a los enemigos
      BrickConfig(
        type: BrickType.stone,
        size: BrickSize.size70x140,
        position: Vector2(-2, -8),
      ),
      BrickConfig(
        type: BrickType.stone,
        size: BrickSize.size70x140,
        position: Vector2(2, -8),
      ),

      // Techo que protege desde arriba
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size220x70,
        position: Vector2(0, -10.5),
      ),
    ],
  );

  /// NIVEL 3: DIFÍCIL - Fortaleza blindada
  /// Estructura: Fortaleza muy protegida con múltiples capas defensivas
  static LevelConfig get level3 => LevelConfig(
    level: GameLevel.level3,
    numberOfEnemies: 3,
    maxPlayers: 12,
    bricks: [
      // Torres exteriores de piedra (muy resistentes)
      BrickConfig(
        type: BrickType.stone,
        size: BrickSize.size70x220,
        position: Vector2(-7, -5.5),
      ),
      BrickConfig(
        type: BrickType.stone,
        size: BrickSize.size70x220,
        position: Vector2(7, -5.5),
      ),

      // Base central fortificada
      BrickConfig(
        type: BrickType.stone,
        size: BrickSize.size140x70,
        position: Vector2(-3, -2.5),
      ),
      BrickConfig(
        type: BrickType.metal,
        size: BrickSize.size140x70,
        position: Vector2(0, -2.5),
      ),
      BrickConfig(
        type: BrickType.stone,
        size: BrickSize.size140x70,
        position: Vector2(3, -2.5),
      ),

      // Paredes protectoras internas
      BrickConfig(
        type: BrickType.stone,
        size: BrickSize.size70x140,
        position: Vector2(-4, -5.5),
      ),
      BrickConfig(
        type: BrickType.stone,
        size: BrickSize.size70x140,
        position: Vector2(4, -5.5),
      ),

      // Piso donde están los enemigos (bien protegidos)
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size140x70,
        position: Vector2(-1.5, -5.5),
      ),
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size140x70,
        position: Vector2(1.5, -5.5),
      ),

      // Columnas centrales que protegen desde los lados
      BrickConfig(
        type: BrickType.glass,
        size: BrickSize.size70x140,
        position: Vector2(-2.5, -8),
      ),
      BrickConfig(
        type: BrickType.glass,
        size: BrickSize.size70x140,
        position: Vector2(2.5, -8),
      ),

      // Segundo nivel de paredes
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size140x70,
        position: Vector2(-3, -8),
      ),
      BrickConfig(
        type: BrickType.wood,
        size: BrickSize.size140x70,
        position: Vector2(3, -8),
      ),

      // Techo de metal (muy resistente)
      BrickConfig(
        type: BrickType.metal,
        size: BrickSize.size220x70,
        position: Vector2(-1.5, -10.5),
      ),
      BrickConfig(
        type: BrickType.metal,
        size: BrickSize.size220x70,
        position: Vector2(1.5, -10.5),
      ),
    ],
  );

  /// NIVEL ALEATORIO - Generación aleatoria
  /// (se genera dinámicamente en el código del juego)
  static LevelConfig get random => LevelConfig(
    level: GameLevel.random,
    numberOfEnemies: 2,
    maxPlayers: 10,
    bricks: [], // Se generan aleatoriamente
  );

  /// Obtener configuración por nivel
  static LevelConfig getConfig(GameLevel level) {
    switch (level) {
      case GameLevel.level1:
        return level1;
      case GameLevel.level2:
        return level2;
      case GameLevel.level3:
        return level3;
      case GameLevel.random:
        return random;
    }
  }
}
