enum DatasetVersion {
  v1,
  v2;

  static DatasetVersion fromCode(String value) {
    switch (value) {
      case 'v1':
        return DatasetVersion.v1;
      case 'v2':
        return DatasetVersion.v2;
      default:
        throw Exception('Unknown DatasetVersion: $value');
    }
  }

  String get name {
    switch (this) {
      case DatasetVersion.v1:
        return 'v1';
      case DatasetVersion.v2:
        return 'v2';
    }
  }

  String get code {
    switch (this) {
      case DatasetVersion.v1:
        return 'v1';
      case DatasetVersion.v2:
        return 'v2';
    }
  }
}
