class Directories {
  const Directories._();

  static const String savedDatasetDirPath = 'saved_datasets';
  static const String needReviewDirPath = '$savedDatasetDirPath/need_review';
  static const String reviewedDirPath = '$savedDatasetDirPath/reviewed';

  static const String savedMlModelDirPath = 'saved_ml_models';
}
