import 'package:file_picker/file_picker.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';

class LabsRepository {
  Future<(Failure?, String?)> pickModel() async {
    try {
      final filePicker = FilePicker.platform;

      await filePicker.clearTemporaryFiles();

      final pickedFile = await filePicker.pickFiles();
      if (pickedFile == null || pickedFile.files.isEmpty) {
        return (Failure('No file picked'), null);
      }

      final file = pickedFile.files.first;

      if (file.extension != 'onnx') {
        return (Failure('File must be tflite'), null);
      }

      return (null, file.path!);
    } catch (e, stackTrace) {
      const message = 'Failed picking model';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }
}
