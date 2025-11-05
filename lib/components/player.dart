import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import 'body_component_with_user_data.dart';
import 'game.dart';

const playerSize = 5.0;

enum PlayerColor {
  pink,
  blue,
  green,
  yellow;

  static PlayerColor get randomColor =>
      PlayerColor.values[Random().nextInt(PlayerColor.values.length)];

  String get fileName =>
      'alien${toString().split('.').last.capitalize}_round.png';
}

class Player extends BodyComponentWithUserData with DragCallbacks {
  Player(Vector2 position, Sprite sprite)
    : _sprite = sprite,
      super(
        renderBody: false,
        bodyDef: BodyDef()
          ..position = position
          ..type = BodyType.static
          ..angularDamping = 0.1
          ..linearDamping = 0.1,
        fixtureDefs: [
          FixtureDef(CircleShape()..radius = playerSize / 2)
            ..restitution = 0.4
            ..density = 0.75
            ..friction = 0.5,
        ],
      );

  final Sprite _sprite;

  @override
  Future<void> onLoad() {
    addAll([
      CustomPainterComponent(
        painter: _DragPainter(this),
        anchor: Anchor.center,
        size: Vector2(playerSize, playerSize),
        position: Vector2(0, 0),
      ),
      SpriteComponent(
        anchor: Anchor.center,
        sprite: _sprite,
        size: Vector2(playerSize, playerSize),
        position: Vector2(0, 0),
      ),
    ]);
    return super.onLoad();
  }


  Vector2 _dragStart = Vector2.zero();
  Vector2 _dragDelta = Vector2.zero();
  Vector2 get dragDelta => _dragDelta;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (body.bodyType == BodyType.static) {
      _dragStart = event.localPosition;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (body.bodyType == BodyType.static) {
      _dragDelta = event.localEndPosition - _dragStart;
    }
  }

  final List<Vector2> _trailPositions = [];
  double _trailTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);

    if (!body.isAwake) {
      removeFromParent();
      return;
    }

    // Agregar trail cuando el jugador está en movimiento
    if (body.bodyType == BodyType.dynamic && body.linearVelocity.length > 5) {
      _trailTimer += dt;
      if (_trailTimer > 0.02) {
        _trailPositions.add(position.clone());
        _trailTimer = 0;
        
        // Mantener solo las últimas 15 posiciones
        if (_trailPositions.length > 15) {
          _trailPositions.removeAt(0);
        }
      }
    }

    // Rebote en los bordes horizontales
    if (position.x > camera.visibleWorldRect.right - 2) {
      position.x = camera.visibleWorldRect.right - 2;
      body.linearVelocity = Vector2(-body.linearVelocity.x.abs() * 0.7, body.linearVelocity.y);
    } else if (position.x < camera.visibleWorldRect.left + 2) {
      position.x = camera.visibleWorldRect.left + 2;
      body.linearVelocity = Vector2(body.linearVelocity.x.abs() * 0.7, body.linearVelocity.y);
    }
    
    if (position.y > camera.visibleWorldRect.bottom + 20) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Renderizar trail
    if (_trailPositions.length > 1) {
      for (var i = 0; i < _trailPositions.length - 1; i++) {
        final alpha = (i / _trailPositions.length * 255).toInt();
        final size = (i / _trailPositions.length * 0.8 + 0.2);
        
        canvas.drawCircle(
          (_trailPositions[i] - position).toOffset(),
          size,
          Paint()
            ..color = Colors.orange.withAlpha(alpha)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (body.bodyType == BodyType.static) {
      children
          .whereType<CustomPainterComponent>()
          .firstOrNull
          ?.removeFromParent();
      body.setType(BodyType.dynamic);
      body.applyLinearImpulse(_dragDelta * -50);
      add(RemoveEffect(delay: 5.0));
      
      // Reproducir sonido de disparo
      if (parent?.parent is MyPhysicsGame) {
        final game = parent!.parent! as MyPhysicsGame;
        game.audioManager.playGunshotSound();
        game.addScreenShake(intensity: 0.2);
      }
    }
  }
}

extension on String {
  String get capitalize =>
      characters.first.toUpperCase() + characters.skip(1).toLowerCase().join();
}

class _DragPainter extends CustomPainter {
  _DragPainter(this.player);

  final Player player;

  @override
  void paint(Canvas canvas, Size size) {
    if (player.dragDelta != Vector2.zero()) {
      var center = size.center(Offset.zero);
      var impulse = player.dragDelta * -50;
      
      // Calcular la fuerza del disparo (0-100)
      var power = (player.dragDelta.length / 10 * 100).clamp(0, 100).toInt();
      
      // Color basado en la fuerza
      Color lineColor;
      if (power < 30) {
        lineColor = Colors.yellow;
      } else if (power < 60) {
        lineColor = Colors.orange;
      } else {
        lineColor = Colors.red;
      }
      
      // NUEVA: Trayectoria predicha con física
      _drawTrajectory(canvas, center, impulse, lineColor);
      
      // Indicador de dirección (flecha al final)
      var endPoint = center + (player.dragDelta * -1).toOffset();
      canvas.drawCircle(
        endPoint,
        0.4,
        Paint()..color = lineColor,
      );
      
      // Texto de porcentaje de poder
      if (player.dragDelta.length > 2) {
        final textSpan = TextSpan(
          text: '$power%',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          endPoint + const Offset(-18, -12),
        );
      }
    }
  }
  
  void _drawTrajectory(Canvas canvas, Offset start, Vector2 impulse, Color color) {
    // Simular trayectoria con física
    const gravity = 10.0;
    const mass = 0.75;
    final velocity = impulse / mass;
    
    var pos = Vector2(start.dx, start.dy);
    final dt = 0.05;
    
    // Dibujar puntos de trayectoria predicha
    for (var t = 0.0; t < 2.0; t += dt) {
      // Actualizar posición con física
      pos.x += velocity.x * dt;
      pos.y += velocity.y * dt;
      velocity.y += gravity * dt;
      
      // Dibujar punto
      final alpha = (1 - t / 2.0 * 0.7).clamp(0.0, 1.0);
      final pointSize = 0.15 * (1 - t / 2.0 * 0.3);
      
      canvas.drawCircle(
        Offset(pos.x, pos.y),
        pointSize,
        Paint()
          ..color = color.withOpacity(alpha)
          ..style = PaintingStyle.fill,
      );
      
      // Detener si sale de rango razonable
      if (pos.y > start.dy + 100 || pos.x.abs() > 200) {
        break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

