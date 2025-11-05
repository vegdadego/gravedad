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

  @override
  void update(double dt) {
    super.update(dt);

    if (!body.isAwake) {
      removeFromParent();
      return;
    }

    // Rebote en los bordes horizontales
    if (position.x > camera.visibleWorldRect.right - 2) {
      // Rebote en el borde derecho
      position.x = camera.visibleWorldRect.right - 2;
      body.linearVelocity = Vector2(-body.linearVelocity.x.abs() * 0.7, body.linearVelocity.y);
    } else if (position.x < camera.visibleWorldRect.left + 2) {
      // Rebote en el borde izquierdo
      position.x = camera.visibleWorldRect.left + 2;
      body.linearVelocity = Vector2(body.linearVelocity.x.abs() * 0.7, body.linearVelocity.y);
    }
    
    // Eliminar si cae muy abajo o se sale demasiado
    if (position.y > camera.visibleWorldRect.bottom + 20) {
      removeFromParent();
    }
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
      var endPoint = center + (player.dragDelta * -1).toOffset();
      
      // Calcular la fuerza del disparo (0-100)
      var power = (player.dragDelta.length / 10 * 100).clamp(0, 100).toInt();
      
      // Color basado en la fuerza: amarillo (débil) -> naranja -> rojo (fuerte)
      Color lineColor;
      if (power < 30) {
        lineColor = Colors.yellow;
      } else if (power < 60) {
        lineColor = Colors.orange;
      } else {
        lineColor = Colors.red;
      }
      
      // Línea principal más gruesa y con degradado visual
      canvas.drawLine(
        center,
        endPoint,
        Paint()
          ..color = lineColor.withAlpha(200)
          ..strokeWidth = 0.6
          ..strokeCap = StrokeCap.round,
      );
      
      // Línea de sombra para más visibilidad
      canvas.drawLine(
        center,
        endPoint,
        Paint()
          ..color = Colors.black.withAlpha(100)
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round,
      );
      
      // Dibujar puntos en la trayectoria para simular línea punteada
      final direction = (player.dragDelta * -1).normalized();
      final distance = player.dragDelta.length;
      for (var i = 0.5; i < distance; i += 0.8) {
        final point = center + (direction * i).toOffset();
        canvas.drawCircle(
          point,
          0.15,
          Paint()..color = lineColor.withAlpha(150),
        );
      }
      
      // Indicador de potencia al final de la línea
      canvas.drawCircle(
        endPoint,
        0.3,
        Paint()..color = lineColor,
      );
      
      // Texto de porcentaje de poder (solo si hay suficiente espacio)
      if (distance > 2) {
        final textSpan = TextSpan(
          text: '$power%',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                color: Colors.black,
                offset: Offset(0.5, 0.5),
                blurRadius: 1,
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
          endPoint + const Offset(-15, -10),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

