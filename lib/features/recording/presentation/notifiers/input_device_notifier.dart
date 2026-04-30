import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSelectedDeviceIdKey = 'selected_input_device_id';

class InputDeviceState {
  const InputDeviceState({
    this.selectedDeviceId,
    this.availableDevices = const <InputDevice>[],
    this.isEnumerating = false,
    this.permissionDenied = false,
    this.permissionNotYetGranted = false,
  });

  final String? selectedDeviceId;
  final List<InputDevice> availableDevices;
  final bool isEnumerating;
  final bool permissionDenied;
  final bool permissionNotYetGranted;

  InputDevice? get selectedDevice {
    if (selectedDeviceId == null) return null;
    for (final d in availableDevices) {
      if (d.id == selectedDeviceId) return d;
    }
    return null;
  }

  InputDeviceState copyWith({
    String? selectedDeviceId,
    List<InputDevice>? availableDevices,
    bool? isEnumerating,
    bool? permissionDenied,
    bool? permissionNotYetGranted,
    bool clearSelectedDeviceId = false,
  }) {
    return InputDeviceState(
      selectedDeviceId: clearSelectedDeviceId
          ? null
          : (selectedDeviceId ?? this.selectedDeviceId),
      availableDevices: availableDevices ?? this.availableDevices,
      isEnumerating: isEnumerating ?? this.isEnumerating,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      permissionNotYetGranted:
          permissionNotYetGranted ?? this.permissionNotYetGranted,
    );
  }
}

final inputDeviceNotifierProvider =
    NotifierProvider<InputDeviceNotifier, InputDeviceState>(
      InputDeviceNotifier.new,
    );

class InputDeviceNotifier extends Notifier<InputDeviceState> {
  @override
  InputDeviceState build() {
    _loadPreferred();
    return const InputDeviceState();
  }

  Future<void> _loadPreferred() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kSelectedDeviceIdKey);
    if (saved != null && saved.isNotEmpty) {
      state = state.copyWith(selectedDeviceId: saved);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isEnumerating: true);
    try {
      final recorder = AudioRecorder();
      try {
        final devices = await recorder.listInputDevices();
        final permissionNotYetGranted =
            kIsWeb && devices.any((d) => d.label.isEmpty);
        state = state.copyWith(
          availableDevices: devices,
          isEnumerating: false,
          permissionNotYetGranted: permissionNotYetGranted,
          permissionDenied: false,
        );
      } finally {
        await recorder.dispose();
      }
    } catch (_) {
      state = state.copyWith(
        availableDevices: const <InputDevice>[],
        isEnumerating: false,
      );
    }
  }

  Future<void> requestPermissionThenRefresh() async {
    final recorder = AudioRecorder();
    try {
      final granted = await recorder.hasPermission();
      if (!granted) {
        state = state.copyWith(
          permissionDenied: true,
          permissionNotYetGranted: false,
          isEnumerating: false,
        );
        return;
      }
    } catch (_) {
      state = state.copyWith(permissionDenied: true, isEnumerating: false);
      return;
    } finally {
      await recorder.dispose();
    }
    await refresh();
  }

  Future<void> setSelected(String? id) async {
    state = state.copyWith(
      selectedDeviceId: id,
      clearSelectedDeviceId: id == null,
    );
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_kSelectedDeviceIdKey);
    } else {
      await prefs.setString(_kSelectedDeviceIdKey, id);
    }
  }
}
