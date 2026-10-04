import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Representation of Android device hardware properties for Solana Seeker identification.
class DeviceInfo {
  final String model;
  final String brand;
  final String manufacturer;
  final bool hasSeedVault;
  final bool isSeeker;

  const DeviceInfo({
    this.model = '',
    this.brand = '',
    this.manufacturer = '',
    this.hasSeedVault = false,
    this.isSeeker = false,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      model: map['model'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      manufacturer: map['manufacturer'] as String? ?? '',
      hasSeedVault: map['hasSeedVault'] as bool? ?? false,
      isSeeker: map['isSeeker'] as bool? ?? false,
    );
  }
}

/// Service that interacts with native Android platform to detect Seeker hardware features.
class DeviceService {
  static const MethodChannel _channel = MethodChannel('com.clockin.clockin/device');

  Future<bool> isSeekerDevice() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isSeekerDevice');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<DeviceInfo> getDeviceInfo() async {
    try {
      final Map? result = await _channel.invokeMethod<Map>('getDeviceInfo');
      if (result == null) return const DeviceInfo();
      return DeviceInfo.fromMap(Map<String, dynamic>.from(result));
    } catch (_) {
      return const DeviceInfo();
    }
  }
}

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

/// Combined state representing physical Seeker detection and demo simulation status.
class SeekerDeviceState {
  final bool isPhysicalSeeker;
  final bool isSimulated;
  final DeviceInfo deviceInfo;

  const SeekerDeviceState({
    this.isPhysicalSeeker = false,
    this.isSimulated = false,
    this.deviceInfo = const DeviceInfo(),
  });

  /// True if the hardware is an authentic Solana Seeker OR simulation is active.
  bool get isSeeker => isPhysicalSeeker || isSimulated;

  SeekerDeviceState copyWith({
    bool? isPhysicalSeeker,
    bool? isSimulated,
    DeviceInfo? deviceInfo,
  }) {
    return SeekerDeviceState(
      isPhysicalSeeker: isPhysicalSeeker ?? this.isPhysicalSeeker,
      isSimulated: isSimulated ?? this.isSimulated,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}

class SeekerDeviceNotifier extends StateNotifier<SeekerDeviceState> {
  final DeviceService _service;

  SeekerDeviceNotifier(this._service) : super(const SeekerDeviceState()) {
    checkDevice();
  }

  Future<void> checkDevice() async {
    final info = await _service.getDeviceInfo();
    state = state.copyWith(
      isPhysicalSeeker: info.isSeeker,
      deviceInfo: info,
    );
  }

  void toggleSimulation(bool simulate) {
    state = state.copyWith(isSimulated: simulate);
  }
}

/// Main provider for observing Seeker device status and hardware activation across the app.
final seekerDeviceProvider = StateNotifierProvider<SeekerDeviceNotifier, SeekerDeviceState>((ref) {
  final service = ref.watch(deviceServiceProvider);
  return SeekerDeviceNotifier(service);
});
