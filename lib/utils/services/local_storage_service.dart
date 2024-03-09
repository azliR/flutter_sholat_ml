import 'package:flutter_sholat_ml/core/auth_device/models/device/device.dart';
import 'package:hive/hive.dart';

class LocalStorageService {
  LocalStorageService._();

  static const String kBox = 'local_storage_box';
  static const String kSavedDevices = 'saved_devices';

  static const String kPreprocessAutoSave = 'preprocess_auto_save';
  static const String kPreprocessFollowHighlighted =
      'preprocess_follow_highlighted';
  static const String kPreprocessShowBottomPanel =
      'preprocess_show_problem_panel';
  static const String kPreprocessSplitView1Weights =
      'preprocess_split_view_1_weights';
  static const String kPreprocessSplitView2Weights =
      'preprocess_split_view_2_weights';
  static const String kPreprocessSplitView3Weights =
      'preprocess_split_view_3_weights';

  static const String kLabShowBottomPanel = 'lab_show_problem_panel';
  static const String kLabSplitView1Weights = 'lab_split_view_1_weights';
  static const String kLabEnableTeacherForcing = 'lab_enable_teacher_forcing';
  static const String kLabInputDataType = 'lab_input_data_type';
  static const String kLabWindowSize = 'lab_window_size';
  static const String kLabBatchSize = 'lab_batch_size';
  static const String kLabNumberOfFeatures = 'lab_number_of_features';

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

  static void setPreprocessAutoSave({required bool enable}) {
    _box.put(kPreprocessAutoSave, enable);
  }

  static bool? getPreprocessAutoSave() {
    return _box.get(kPreprocessAutoSave) as bool?;
  }

  static void setPreprocessFollowHighlighted({required bool enable}) {
    _box.put(kPreprocessFollowHighlighted, enable);
  }

  static bool? getPreprocessFollowHighlighted() {
    return _box.get(kPreprocessFollowHighlighted) as bool?;
  }

  static void setPreprocessShowBottomPanel({required bool enable}) {
    _box.put(kPreprocessShowBottomPanel, enable);
  }

  static bool? getPreprocessShowBottomPanel() {
    return _box.get(kPreprocessShowBottomPanel) as bool?;
  }

  static void setPreprocessSplitView1Weights(List<double> weights) {
    _box.put(kPreprocessSplitView1Weights, weights);
  }

  static List<double> getPreprocessSplitView1Weights() {
    return (_box.get(kPreprocessSplitView1Weights) as List? ?? [])
        .cast<double>();
  }

  static void setPreprocessSplitView2Weights(List<double> weights) {
    _box.put(kPreprocessSplitView2Weights, weights);
  }

  static List<double> getPreprocessSplitView2Weights() {
    return (_box.get(kPreprocessSplitView2Weights) as List? ?? [])
        .cast<double>();
  }

  static void setPreprocessSplitView3Weights(List<double> weights) {
    _box.put(kPreprocessSplitView3Weights, weights);
  }

  static List<double> getPreprocessSplitView3Weights() {
    return (_box.get(kPreprocessSplitView3Weights) as List? ?? [])
        .cast<double>();
  }

  static void setLabShowBottomPanel({required bool enable}) {
    _box.put(kLabShowBottomPanel, enable);
  }

  static bool getLabShowBottomPanel() {
    return _box.get(kLabShowBottomPanel) as bool? ?? true;
  }

  static void setLabSplitView1Weights(List<double> weights) {
    _box.put(kLabSplitView1Weights, weights);
  }

  static List<double> getLabSplitView1Weights() {
    return (_box.get(kLabSplitView1Weights) as List? ?? []).cast<double>();
  }
}
