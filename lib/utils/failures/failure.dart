import 'dart:developer';

import 'package:stack_trace/stack_trace.dart';

class Failure {
  Failure(this.message, {this.code, this.error, this.stackTrace}) {
    log(
      message,
      error: error,
      stackTrace: stackTrace != null ? Trace.from(stackTrace!) : stackTrace,
    );
  }

  final String message;
  final Object? code;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'Failure(message: $message, code: $code, error: $error, stackTrace: $stackTrace)';
  }
}

class PermissionFailure extends Failure {
  PermissionFailure(super.message);
}
