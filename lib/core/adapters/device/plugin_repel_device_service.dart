import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:hosh/core/analytics/app_analytics.dart';
import 'package:hosh/core/models/app_models.dart';
import 'package:hosh/core/repositories/contracts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:torch_light/torch_light.dart';

const double _minRepelFrequencyKhz = 15.0;
const double _maxRepelFrequencyKhz = 18.0;
const int _repelSampleRate = 48000;
const int _toneBurstMs = 420;
const int _toneSilenceMs = 260;
const int _audioCooldownEveryBursts = 8;
const int _audioCooldownMs = 700;
const double _toneAmplitude = 0.48;
const int _torchToggleMs = 120;
const int _torchCooldownEveryToggles = 18;
const int _torchCooldownTicks = 3;

class PluginRepelDeviceService implements RepelDeviceService {
  PluginRepelDeviceService({required this.analyticsService});

  final AnalyticsService analyticsService;
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _playerReady = false;
  bool _loopActive = false;
  bool _torchEnabled = false;
  Timer? _torchTimer;
  int _audioLoopToken = 0;

  @override
  Future<RepelSessionState> startRepel(RepelSettings settings) async {
    await stopRepel(
      RepelSessionState.idle(frequencyKhz: settings.frequencyKhz),
    );

    final double tunedFrequencyKhz = _clampFrequencyKhz(settings.frequencyKhz);
    String? lastError;
    bool audioEnabled = false;
    try {
      if (!_playerReady) {
        await _player.openPlayer();
        _playerReady = true;
      }
      _loopActive = true;
      audioEnabled = true;
      final int loopToken = ++_audioLoopToken;
      unawaited(
        _loopAudio(baseFrequencyKhz: tunedFrequencyKhz, token: loopToken),
      );
    } catch (error) {
      lastError = _mergeErrors(lastError, 'Speaker output unavailable.');
    }

    bool torchEnabled = false;
    if (settings.strobeEnabled) {
      try {
        torchEnabled = await _beginTorchPulse();
      } catch (error) {
        lastError = _mergeErrors(lastError, error.toString());
      }
    }

    final bool isActive = audioEnabled || torchEnabled;
    if (!isActive) {
      lastError = _mergeErrors(
        lastError,
        'No deterrent output is available on this device right now.',
      );
    }

    return RepelSessionState(
      isActive: isActive,
      frequencyKhz: tunedFrequencyKhz,
      torchEnabled: torchEnabled,
      audioEnabled: audioEnabled,
      outputLabel: settings.outputLabel,
      lastError: lastError?.isEmpty ?? true ? null : lastError,
    );
  }

  @override
  Future<RepelSessionState> stopRepel(RepelSessionState current) async {
    _loopActive = false;
    _audioLoopToken++;
    _torchTimer?.cancel();
    if (_playerReady) {
      try {
        await _player.stopPlayer();
      } catch (_) {}
    }
    if (_torchEnabled) {
      try {
        await TorchLight.disableTorch();
      } catch (_) {}
    }
    _torchEnabled = false;
    return current.copyWith(
      isActive: false,
      audioEnabled: false,
      torchEnabled: false,
    );
  }

  @override
  Future<bool> setTorchEnabled(bool enabled) async {
    if (!enabled) {
      _torchTimer?.cancel();
      if (_torchEnabled) {
        await TorchLight.disableTorch();
      }
      _torchEnabled = false;
      return false;
    }
    try {
      return _beginTorchPulse();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> triggerPanicMode() async {
    return 'Panic mode armed. Trusted contacts and alerts can be added next.';
  }

  Future<void> _loopAudio({
    required double baseFrequencyKhz,
    required int token,
  }) async {
    int burstIndex = 0;
    while (_loopActive && token == _audioLoopToken) {
      try {
        final double burstFrequencyKhz = _burstFrequencyKhz(
          baseFrequencyKhz,
          burstIndex,
        );
        await _player.startPlayer(
          codec: Codec.pcm16,
          fromDataBuffer: _buildPcmBurst(
            frequencyHz: burstFrequencyKhz * 1000,
            sampleRate: _repelSampleRate,
            toneMs: _toneBurstMs,
            silenceMs: _toneSilenceMs,
          ),
          sampleRate: _repelSampleRate,
          numChannels: 1,
          whenFinished: () {},
        );
        burstIndex += 1;
        final int cooldownMs = burstIndex % _audioCooldownEveryBursts == 0
            ? _audioCooldownMs
            : 0;
        await Future<void>.delayed(
          Duration(milliseconds: _toneBurstMs + _toneSilenceMs + cooldownMs),
        );
      } catch (_) {
        _loopActive = false;
      }
    }
  }

  Uint8List _buildPcmBurst({
    required double frequencyHz,
    required int sampleRate,
    required int toneMs,
    required int silenceMs,
  }) {
    final int toneSamples = (sampleRate * toneMs / 1000).round();
    final int silenceSamples = (sampleRate * silenceMs / 1000).round();
    final ByteData data = ByteData(
      (toneSamples + silenceSamples) * Int16List.bytesPerElement,
    );
    const double amplitude = _toneAmplitude;
    for (int index = 0; index < toneSamples; index++) {
      final double envelope = _edgeEnvelope(index, toneSamples);
      final double sample = math.sin(
        2 * math.pi * index * frequencyHz / sampleRate,
      );
      final int value = (sample * amplitude * envelope * 32767).round();
      data.setInt16(index * 2, value, Endian.little);
    }
    return data.buffer.asUint8List();
  }

  Future<bool> _beginTorchPulse() async {
    analyticsService.logPermissionPromptShown(
      permission: AnalyticsPermissionType.camera,
      sourceScreen: 'repel',
    );
    final PermissionStatus status = await Permission.camera.request();
    analyticsService.logPermissionResult(
      permission: AnalyticsPermissionType.camera,
      status: status.isGranted
          ? AppPermissionStatus.granted
          : AppPermissionStatus.denied,
      sourceScreen: 'repel',
    );
    if (status.isPermanentlyDenied) {
      throw StateError('Camera permission is permanently denied.');
    }
    if (!status.isGranted) {
      throw StateError('Camera permission is required for the strobe light.');
    }
    final bool available = await TorchLight.isTorchAvailable();
    if (!available) {
      throw StateError('Torch is not available on this device.');
    }
    bool on = false;
    int toggleCount = 0;
    int cooldownTicksRemaining = 0;
    _torchTimer?.cancel();
    _torchTimer = Timer.periodic(const Duration(milliseconds: _torchToggleMs), (
      Timer timer,
    ) async {
      if (cooldownTicksRemaining > 0) {
        cooldownTicksRemaining -= 1;
        on = false;
      } else {
        on = !on;
        toggleCount += 1;
        if (toggleCount % _torchCooldownEveryToggles == 0) {
          cooldownTicksRemaining = _torchCooldownTicks;
          on = false;
        }
      }
      try {
        if (on) {
          await TorchLight.enableTorch();
        } else {
          await TorchLight.disableTorch();
        }
      } catch (_) {}
    });
    _torchEnabled = true;
    return true;
  }

  double _burstFrequencyKhz(double baseFrequencyKhz, int burstIndex) {
    const List<double> offsets = <double>[0.0, 0.35, -0.25, 0.55, -0.4, 0.2];
    return _clampFrequencyKhz(
      baseFrequencyKhz + offsets[burstIndex % offsets.length],
    );
  }

  double _clampFrequencyKhz(double frequencyKhz) {
    return frequencyKhz.clamp(_minRepelFrequencyKhz, _maxRepelFrequencyKhz);
  }

  double _edgeEnvelope(int sampleIndex, int totalSamples) {
    final int fadeSamples = math.max(1, (totalSamples * 0.08).round());
    if (sampleIndex < fadeSamples) {
      return sampleIndex / fadeSamples;
    }
    if (sampleIndex > totalSamples - fadeSamples) {
      return (totalSamples - sampleIndex).clamp(0, fadeSamples) / fadeSamples;
    }
    return 1;
  }

  String _mergeErrors(String? current, String next) {
    if (current == null || current.isEmpty) {
      return next;
    }
    return '$current • $next';
  }
}
