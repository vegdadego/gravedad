import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Efecto de partículas para explosiones y destrucción
class ParticleEffect extends Component {
  ParticleEffect({
    required this.position,
    required this.color,
    this.particleCount = 20,
    this.explosionRadius = 3.0,
  });

  final Vector2 position;
  final Color color;
  final int particleCount;
  final double explosionRadius;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  Future<void> onLoad() async {
    // Crear partículas
    for (var i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * explosionRadius + 2;
      
      _particles.add(
        _Particle(
          position: position.clone(),
          velocity: Vector2(cos(angle), sin(angle)) * speed,
          color: color,
          size: _random.nextDouble() * 0.3 + 0.2,
          lifetime: _random.nextDouble() * 0.5 + 0.5,
        ),
      );
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Actualizar partículas
    for (var particle in _particles) {
      particle.update(dt);
    }

    // Eliminar si todas las partículas expiraron
    if (_particles.every((p) => p.isDead)) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (var particle in _particles) {
      if (!particle.isDead) {
        particle.render(canvas);
      }
    }
  }
}

class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  });

  Vector2 position;
  Vector2 velocity;
  final Color color;
  final double size;
  final double lifetime;
  double _elapsed = 0;

  bool get isDead => _elapsed >= lifetime;

  void update(double dt) {
    _elapsed += dt;
    position += velocity * dt;
    velocity.y += 15 * dt; // Gravedad
    velocity *= 0.98; // Fricción del aire
  }

  void render(Canvas canvas) {
    final alpha = (1 - _elapsed / lifetime).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withOpacity(alpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      position.toOffset(),
      size * (1 - _elapsed / lifetime * 0.5),
      paint,
    );
  }
}

/// Efecto de polvo cuando caen bloques
class DustEffect extends Component {
  DustEffect({required this.position});

  final Vector2 position;
  final List<_DustParticle> _particles = [];
  final Random _random = Random();

  @override
  Future<void> onLoad() async {
    // Crear partículas de polvo
    for (var i = 0; i < 10; i++) {
      final angle = _random.nextDouble() * pi - pi / 2;
      final speed = _random.nextDouble() * 2 + 1;
      
      _particles.add(
        _DustParticle(
          position: position.clone(),
          velocity: Vector2(cos(angle), sin(angle)) * speed,
          size: _random.nextDouble() * 0.4 + 0.3,
          lifetime: _random.nextDouble() * 0.4 + 0.3,
        ),
      );
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (var particle in _particles) {
      particle.update(dt);
    }

    if (_particles.every((p) => p.isDead)) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (var particle in _particles) {
      if (!particle.isDead) {
        particle.render(canvas);
      }
    }
  }
}

class _DustParticle {
  _DustParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.lifetime,
  });

  Vector2 position;
  Vector2 velocity;
  final double size;
  final double lifetime;
  double _elapsed = 0;

  bool get isDead => _elapsed >= lifetime;

  void update(double dt) {
    _elapsed += dt;
    position += velocity * dt;
    velocity *= 0.95; // Fricción
  }

  void render(Canvas canvas) {
    final alpha = (1 - _elapsed / lifetime).clamp(0.0, 1.0) * 0.6;
    final paint = Paint()
      ..color = Colors.brown.withOpacity(alpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      position.toOffset(),
      size,
      paint,
    );
  }
}

