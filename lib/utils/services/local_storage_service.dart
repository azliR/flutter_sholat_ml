import 'package:flutter_sholat_ml/modules/device/models/device/device.dart';
import 'package:hive/hive.dart';

class LocalStorageService {
  LocalStorageService._();

  static const String kBox = 'local_storage_box';
  static const String kSavedDevices = 'saved_devices';
  static const String kAutoSave = 'auto_save';

  static final _box = Hive.box<dynamic>(name: kBox);

  static Stream<List<Device>> get savedDevicesStream =>
      _box.watchKey(kSavedDevices).map((event) {
        if (event == null || event is! List) return [];
        return event.cast<Map<String, dynamic>>().map(Device.fromJson).toList();
      });

  static void setSavedDevice(Device device) {
    final updatedDevices = getSavedDevices()
      ..removeWhere((savedDevice) => savedDevice.deviceId == device.deviceId)
      ..insert(0, device);
    final devicesJson =
        updatedDevices.map((device) => device.toJson()).toList();
    _box.put(kSavedDevices, devicesJson);
  }

  static List<Device> getSavedDevices() {
    final devicesJson = _box.get(kSavedDevices) as List? ?? [];
    final devices =
        devicesJson.cast<Map<String, dynamic>>().map(Device.fromJson).toList();
    return devices;
  }

  static void deleteSavedDevice(Device device) {
    final devices = getSavedDevices()
      ..removeWhere((savedDevice) => savedDevice.deviceId == device.deviceId);
    final devicesJson = devices.map((device) => device.toJson()).toList();
    _box.put(kSavedDevices, devicesJson);
  }

  static void setAutoSave({required bool isAutoSave}) {
    _box.put(kAutoSave, isAutoSave);
  }

  static bool getAutoSave() {
    return _box.get(kAutoSave) as bool? ?? false;
  }
}
