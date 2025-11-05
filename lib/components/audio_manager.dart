import 'package:flutter_soloud/flutter_soloud.dart';

/// Administrador de audio para el juego Gravedad
/// 
/// Maneja la reproducción de música de fondo y efectos de sonido.
/// Usa flutter_soloud para mejor compatibilidad con Web y múltiples formatos.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  
  factory AudioManager() {
    return _instance;
  }
  
  AudioManager._internal();

  final SoLoud _soloud = SoLoud.instance;
  bool _initialized = false;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;

  // Audio sources
  AudioSource? _backgroundMusic;
  AudioSource? _gunshotSound;
  
  // Handle para la música de fondo (para controlarla)
  SoundHandle? _backgroundMusicHandle;
  
  bool _backgroundMusicAvailable = false;
  bool _gunshotSoundAvailable = false;
  String _backgroundMusicFile = '';
  String _gunshotSoundFile = '';

  /// Inicializa el sistema de audio
  /// Debe llamarse una vez al inicio del juego
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Inicializar SoLoud
      await _soloud.init();
      print('AudioManager: SoLoud inicializado correctamente');
    } catch (e) {
      print('AudioManager: Error al inicializar SoLoud: $e');
      return;
    }

    // Intentar cargar música de fondo (probar múltiples formatos)
    for (final ext in ['mp3', 'ogg', 'wav']) {
      try {
        _backgroundMusic = await _soloud.loadAsset(
          'sounds/background.$ext',
          mode: LoadMode.memory,
        );
        _backgroundMusicFile = 'background.$ext';
        _backgroundMusicAvailable = true;
        print('AudioManager: Música de fondo cargada (background.$ext)');
        break;
      } catch (e) {
        // Intentar siguiente formato
      }
    }
    
    if (!_backgroundMusicAvailable) {
      print('AudioManager: Música de fondo no disponible');
      print('  Formatos intentados: background.mp3, background.ogg, background.wav');
    }

    // Intentar cargar sonido de disparo (probar múltiples formatos)
    for (final ext in ['mp3', 'ogg', 'wav']) {
      try {
        _gunshotSound = await _soloud.loadAsset(
          'sounds/gunshot.$ext',
          mode: LoadMode.memory,
        );
        _gunshotSoundFile = 'gunshot.$ext';
        _gunshotSoundAvailable = true;
        print('AudioManager: Sonido de disparo cargado (gunshot.$ext)');
        break;
      } catch (e) {
        // Intentar siguiente formato
      }
    }
    
    if (!_gunshotSoundAvailable) {
      print('AudioManager: Sonido de disparo no disponible');
      print('  Formatos intentados: gunshot.mp3, gunshot.ogg, gunshot.wav');
    }
    
    _initialized = true;
    
    if (!_backgroundMusicAvailable && !_gunshotSoundAvailable) {
      print('════════════════════════════════════════════════════════════════');
      print('⚠️  NOTA: No se encontraron archivos de audio');
      print('   El juego funcionará sin sonido.');
      print('   Agrega estos archivos a la carpeta sounds/:');
      print('   - background.mp3 (música de fondo)');
      print('   - gunshot.mp3 (sonido de disparo)');
      print('   Con flutter_soloud, los MP3 deberían funcionar en Web también.');
      print('════════════════════════════════════════════════════════════════');
    }
  }

  /// Reproduce la música de fondo en bucle
  Future<void> playBackgroundMusic() async {
    if (!_initialized || !_musicEnabled || !_backgroundMusicAvailable) return;
    if (_backgroundMusic == null) return;

    try {
      // Detener música anterior si existe
      if (_backgroundMusicHandle != null) {
        await _soloud.stop(_backgroundMusicHandle!);
      }

      // Reproducir en bucle
      _backgroundMusicHandle = await _soloud.play(
        _backgroundMusic!,
        volume: _musicVolume,
        looping: true,
      );
      
      print('AudioManager: Música de fondo iniciada ($_backgroundMusicFile) 🎵');
    } catch (e) {
      print('AudioManager: Error al reproducir música de fondo: $e');
      _backgroundMusicAvailable = false;
    }
  }

  /// Detiene la música de fondo
  Future<void> stopBackgroundMusic() async {
    if (_backgroundMusicHandle != null) {
      await _soloud.stop(_backgroundMusicHandle!);
      _backgroundMusicHandle = null;
    }
  }

  /// Pausa la música de fondo
  void pauseBackgroundMusic() {
    if (_backgroundMusicHandle != null) {
      _soloud.pauseSwitch(_backgroundMusicHandle!);
    }
  }

  /// Reanuda la música de fondo
  void resumeBackgroundMusic() {
    if (_musicEnabled && _backgroundMusicHandle != null) {
      _soloud.pauseSwitch(_backgroundMusicHandle!);
    }
  }

  /// Reproduce el sonido de disparo
  Future<void> playGunshotSound() async {
    if (!_initialized || !_sfxEnabled || !_gunshotSoundAvailable) return;
    if (_gunshotSound == null) return;

    try {
      await _soloud.play(
        _gunshotSound!,
        volume: _sfxVolume,
      );
      // Debug: descomentar para ver cuándo se dispara
      // print('AudioManager: Disparo reproducido ($_gunshotSoundFile) 🔫');
    } catch (e) {
      print('AudioManager: Error al reproducir sonido ($_gunshotSoundFile): $e');
      _gunshotSoundAvailable = false;
    }
  }

  /// Habilita o deshabilita la música
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (enabled) {
      if (_backgroundMusicHandle == null && _backgroundMusicAvailable) {
        playBackgroundMusic();
      } else {
        resumeBackgroundMusic();
      }
    } else {
      pauseBackgroundMusic();
    }
  }

  /// Habilita o deshabilita los efectos de sonido
  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  /// Ajusta el volumen de la música (0.0 a 1.0)
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    if (_backgroundMusicHandle != null) {
      _soloud.setVolume(_backgroundMusicHandle!, _musicVolume);
    }
  }

  /// Ajusta el volumen de los efectos de sonido (0.0 a 1.0)
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Libera todos los recursos de audio
  Future<void> dispose() async {
    if (_backgroundMusicHandle != null) {
      await _soloud.stop(_backgroundMusicHandle!);
    }
    
    if (_backgroundMusic != null) {
      await _soloud.disposeSource(_backgroundMusic!);
    }
    
    if (_gunshotSound != null) {
      await _soloud.disposeSource(_gunshotSound!);
    }
    
    _soloud.deinit();
    _initialized = false;
  }

  // Getters
  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get isInitialized => _initialized;
  bool get isBackgroundMusicPlaying => 
      _backgroundMusicHandle != null && 
      _soloud.getIsValidVoiceHandle(_backgroundMusicHandle!);
}
