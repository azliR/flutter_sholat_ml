import 'package:flutter_sholat_ml/modules/device/models/device/device.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  LocalStorageService._();

  static const String kBox = 'local_storage_box';
  static const String kSavedDevices = 'saved_devices';
  static const String kDatasetUploadInfos = 'dataset_upload_infos';

  static final _box = Hive.box<List<dynamic>>(name: kBox);

  static Future<void> initialise() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.defaultDirectory = dir.path;
  }

  static Stream<List<Device>> get savedDevicesStream =>
      _box.watchKey(kSavedDevices).map((event) {
        if (event == null) return [];
        return event.cast<Map<String, dynamic>>().map(Device.fromJson).toList();
      });

  static Future<void> setSavedDevice(Device device) async {
    final updatedDevices = getSavedDevices()
      ..removeWhere((savedDevice) => savedDevice.deviceId == device.deviceId)
      ..insert(0, device);
    final devicesJson =
        updatedDevices.map((device) => device.toJson()).toList();
    _box.put(kSavedDevices, devicesJson);
  }

  static List<Device> getSavedDevices() {
    final devicesJson = _box.get(kSavedDevices) ?? [];
    final devices =
        devicesJson.cast<Map<String, dynamic>>().map(Device.fromJson).toList();
    return devices;
  }

  static Future<void> deleteSavedDevice(Device device) async {
    final devices = getSavedDevices()
      ..removeWhere((savedDevice) => savedDevice.deviceId == device.deviceId);
    final devicesJson = devices.map((device) => device.toJson()).toList();
    _box.put(kSavedDevices, devicesJson);
  }
}
