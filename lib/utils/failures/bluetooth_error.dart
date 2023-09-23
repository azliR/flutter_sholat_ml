import 'dart:developer';

class Failure {
  Failure(this.message, {this.error, this.stackTrace}) {
    log(message, error: error, stackTrace: stackTrace);
  }

  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'Failure(message: $message, error: $error, stackTrace: $stackTrace)';
  }
}

class PermissionFailure extends Failure {
  PermissionFailure(super.message);
}
