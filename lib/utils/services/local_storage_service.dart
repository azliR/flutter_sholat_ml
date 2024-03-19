import 'package:flutter_sholat_ml/core/auth_device/models/device/device.dart';
import 'package:flutter_sholat_ml/features/ml_models/blocs/ml_models/ml_models_notifer.dart';
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

  static const String kMlModelsSortType = 'ml_models_sort_type';
  static const String kMlModelsSortDirection = 'ml_models_sort_direction';

  static const String kMlModelShowBottomPanel = 'ml_model_show_problem_panel';
  static const String kMlModelSplitView1Weights =
      'ml_model_split_view_1_weights';
  static const String kMlModelEnableTeacherForcing =
      'ml_model_enable_teacher_forcing';
  static const String kMlModelInputDataType = 'ml_model_input_data_type';
  static const String kMlModelWindowSize = 'ml_model_window_size';
  static const String kMlModelBatchSize = 'ml_model_batch_size';
  static const String kMlModelNumberOfFeatures = 'ml_model_number_of_features';

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

  static void setMlModelsSortType(SortType value) {
    _box.put(kMlModelsSortType, value.index);
  }

  static SortType getMlModelsSortType() {
    return SortType.values[_box.get(kMlModelsSortType) as int? ?? 0];
  }

  static void setMlModelsSortDirection(SortDirection value) {
    _box.put(kMlModelsSortDirection, value.index);
  }

  static SortDirection getMlModelsSortDirection() {
    return SortDirection.values[_box.get(kMlModelsSortDirection) as int? ?? 0];
  }

  static void setMlModelShowBottomPanel({required bool enable}) {
    _box.put(kMlModelShowBottomPanel, enable);
  }

  static bool getMlModelShowBottomPanel() {
    return _box.get(kMlModelShowBottomPanel) as bool? ?? true;
  }

  static void setMlModelSplitView1Weights(List<double> weights) {
    _box.put(kMlModelSplitView1Weights, weights);
  }

  static List<double> getMlModelSplitView1Weights() {
    return (_box.get(kMlModelSplitView1Weights) as List? ?? []).cast<double>();
  }
}
