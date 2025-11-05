import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flutter/material.dart';

import 'audio_manager.dart';
import 'background.dart';
import 'brick.dart';
import 'enemy.dart';
import 'ground.dart';
import 'level.dart';
import 'player.dart';

class MyPhysicsGame extends Forge2DGame {
  MyPhysicsGame({
    required this.onRestart,
    this.currentLevel = GameLevel.level1,
  }) : super(
        gravity: Vector2(0, 10),
        camera: CameraComponent.withFixedResolution(width: 1200, height: 600),
      );
  
  final VoidCallback onRestart;
  final GameLevel currentLevel;
  late final LevelConfig levelConfig;

  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;
  late final AudioManager audioManager;

  @override
  FutureOr<void> onLoad() async {
    // Cargar configuración del nivel
    levelConfig = LevelConfigurations.getConfig(currentLevel);
    
    // Inicializar el sistema de audio
    audioManager = AudioManager();
    await audioManager.initialize();
    
    // Reproducir música de fondo
    unawaited(audioManager.playBackgroundMusic());

    final backgroundImage = await images.load('colored_grass.png');
    final spriteSheets = await Future.wait([
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_aliens.png',
        xmlPath: 'spritesheet_aliens.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_elements.png',
        xmlPath: 'spritesheet_elements.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_tiles.png',
        xmlPath: 'spritesheet_tiles.xml',
      ),
    ]);

    aliens = spriteSheets[0];
    elements = spriteSheets[1];
    tiles = spriteSheets[2];

    await world.add(Background(sprite: Sprite(backgroundImage)));
    await addGround();
    
    // Agregar bloques (estáticos en niveles predefinidos)
    await addBricks();
    
    // Solo esperar un poco para que todo se inicialice
    // (los bloques estáticos no se caen, así que es rápido)
    await Future<void>.delayed(const Duration(milliseconds: 200));
    
    // Agregar enemigos y jugador
    unawaited(addEnemies());
    await addPlayer();

    return super.onLoad();
  }

  Future<void> addGround() {
    return world.addAll([
      for (
        var x = camera.visibleWorldRect.left;
        x < camera.visibleWorldRect.right + groundSize;
        x += groundSize
      )
        Ground(
          Vector2(x, (camera.visibleWorldRect.height - groundSize) / 2),
          tiles.getSprite('grass.png'),
        ),
    ]);
  }

  final _random = Random();
  
  // Configuración del juego desde el nivel
  int get numberOfEnemies => levelConfig.numberOfEnemies;
  int get maxPlayers => levelConfig.maxPlayers;
  int _playersUsed = 0;
  
  Future<void> addBricks() async {
    if (currentLevel == GameLevel.random) {
      // Modo aleatorio (como antes)
      await _addRandomBricks();
    } else {
      // Niveles con estructuras predefinidas
      await _addStructuredBricks();
    }
  }
  
  Future<void> _addRandomBricks() async {
    final easyTypes = [BrickType.wood, BrickType.glass];
    final smallSizes = [BrickSize.size70x70, BrickSize.size140x70];
    
    for (var i = 0; i < 3; i++) {
      final type = easyTypes[_random.nextInt(easyTypes.length)];
      final size = smallSizes[_random.nextInt(smallSizes.length)];
      
      await world.add(
        Brick(
          type: type,
          size: size,
          damage: BrickDamage.some,
          position: Vector2(
            camera.visibleWorldRect.right / 3 +
                (_random.nextDouble() * 4 - 2),
            0,
          ),
          sprites: brickFileNames(
            type,
            size,
          ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }
  
  Future<void> _addStructuredBricks() async {
    // Crear todos los bloques ESTÁTICOS (tipo Angry Birds)
    // No se caen hasta que algo los golpea
    final bricks = levelConfig.bricks.map((brickConfig) {
      return Brick(
        type: brickConfig.type,
        size: brickConfig.size,
        damage: brickConfig.damage,
        position: Vector2(
          camera.visibleWorldRect.right / 3 + brickConfig.position.x,
          brickConfig.position.y,
        ),
        sprites: brickFileNames(
          brickConfig.type,
          brickConfig.size,
        ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
        isStatic: true, // ← Bloques estáticos (no se caen hasta el impacto)
      );
    }).toList();
    
    // Agregar todos los bloques simultáneamente
    await world.addAll(bricks);
    
    // Esperar un frame para que se inicialicen
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  Future<void> addPlayer() async => world.add(
    Player(
      Vector2(camera.visibleWorldRect.left * 2 / 3, 0),
      aliens.getSprite(PlayerColor.randomColor.fileName),
    ),
  );

  TextComponent? _shotsCounter;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Agregar nuevo jugador si no hay ninguno y aún quedan intentos
    if (isMounted &&
        world.children.whereType<Player>().isEmpty &&
        world.children.whereType<Enemy>().isNotEmpty &&
        _playersUsed < maxPlayers) {
      _playersUsed++;
      addPlayer();
      _updateShotsCounter();
    }
    
    // Mensaje de victoria
    if (isMounted &&
        enemiesFullyAdded &&
        world.children.whereType<Enemy>().isEmpty &&
        world.children.whereType<TextComponent>().where((c) => c != _shotsCounter).isEmpty) {
      _showVictoryScreen();
    }
    
    // Mensaje de derrota
    if (isMounted &&
        enemiesFullyAdded &&
        world.children.whereType<Player>().isEmpty &&
        world.children.whereType<Enemy>().isNotEmpty &&
        _playersUsed >= maxPlayers &&
        world.children.whereType<TextComponent>().where((c) => c != _shotsCounter && !c.text.contains('Victoria')).isEmpty) {
      _showDefeatScreen();
    }
  }
  
  void _updateShotsCounter() {
    final remaining = maxPlayers - _playersUsed;
    final text = 'Disparos: $_playersUsed/$maxPlayers (Quedan: $remaining)';
    
    if (_shotsCounter != null) {
      _shotsCounter!.text = text;
    } else {
      _shotsCounter = TextComponent(
        text: text,
        anchor: Anchor.topLeft,
        position: Vector2(
          camera.visibleWorldRect.left + 5,
          camera.visibleWorldRect.top + 5,
        ),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      );
      world.add(_shotsCounter!);
    }
  }

  var enemiesFullyAdded = false;
  bool _victoryScreenShown = false;
  bool _defeatScreenShown = false;

  void _showVictoryScreen() {
    if (_victoryScreenShown) return;
    _victoryScreenShown = true;
    
    overlays.add('victory');
  }

  void _showDefeatScreen() {
    if (_defeatScreenShown) return;
    _defeatScreenShown = true;
    
    overlays.add('defeat');
  }

  Future<void> addEnemies() async {
    // Esperar poco tiempo ya que los bloques estáticos no se mueven
    await Future<void>.delayed(const Duration(milliseconds: 500));
    
    // Usar solo enemigos normales (no bosses) para hacerlo más fácil
    final normalColors = [
      EnemyColor.pink,
      EnemyColor.blue,
      EnemyColor.green,
      EnemyColor.yellow,
    ];
    
    // Posiciones de enemigos según el nivel
    List<Vector2> enemyPositions;
    
    switch (currentLevel) {
      case GameLevel.level1:
        // Enemigos dentro de la caja (nivel 1)
        enemyPositions = [
          Vector2(camera.visibleWorldRect.right / 3 - 1, -5),
          Vector2(camera.visibleWorldRect.right / 3 + 1, -5),
        ];
        break;
      case GameLevel.level2:
        // Enemigos bien protegidos en el segundo piso de la pirámide
        enemyPositions = [
          Vector2(camera.visibleWorldRect.right / 3 - 1.2, -7),
          Vector2(camera.visibleWorldRect.right / 3 + 1.2, -7),
        ];
        break;
      case GameLevel.level3:
        // Enemigos muy protegidos en el centro de la fortaleza
        enemyPositions = [
          Vector2(camera.visibleWorldRect.right / 3 - 1.5, -7),
          Vector2(camera.visibleWorldRect.right / 3, -7),
          Vector2(camera.visibleWorldRect.right / 3 + 1.5, -7),
        ];
        break;
      case GameLevel.random:
        // Posiciones aleatorias (modo aleatorio)
        enemyPositions = List.generate(
          numberOfEnemies,
          (i) => Vector2(
            camera.visibleWorldRect.right / 3 +
                (_random.nextDouble() * 5 - 2.5),
            (_random.nextDouble() * 2),
          ),
        );
    }
    
    for (var i = 0; i < numberOfEnemies && i < enemyPositions.length; i++) {
      await world.add(
        Enemy(
          enemyPositions[i],
          aliens.getSprite(normalColors[_random.nextInt(normalColors.length)].fileName),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    enemiesFullyAdded = true;
    _updateShotsCounter(); // Mostrar contador cuando empiece el juego
  }
}

