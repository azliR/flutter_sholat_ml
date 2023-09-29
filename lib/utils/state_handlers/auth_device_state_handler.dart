import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:flutter_sholat_ml/utils/ui/dialogs.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';

void handleAuthDeviceState(
  BuildContext context,
  AuthDeviceState? previous,
  AuthDeviceState next, {
  void Function()? onAuthDeviceInitialState,
  void Function()? onConnectDeviceLoadingState,
  void Function()? onConnectDeviceSuccessState,
  void Function(Failure failure)? onConnectDeviceFailureState,
  void Function()? onSelectDeviceLoadingState,
  void Function()? onSelectDeviceSuccessState,
  void Function(Failure failure)? onSelectDeviceFailureState,
  void Function()? onAuthDeviceLoadingState,
  void Function()? onAuthDeviceSuccessState,
  void Function(Failure failure)? onAuthDeviceFailureState,
  void Function()? onAuthDeviceResponseFailureState,
  void Function(Failure failure)? onDisconnectDeviceFailure,
  void Function(Failure failure)? onGetPrimaryDeviceFailure,
  void Function(Failure failure)? onRemoveDeviceFailure,
}) {
  if (previous?.presentationState != next.presentationState) {
    final presentationState = next.presentationState;
    switch (presentationState) {
      case AuthDeviceInitialState():
        onAuthDeviceInitialState?.call();
      case ConnectDeviceLoadingState():
        if (onConnectDeviceLoadingState != null) {
          onConnectDeviceLoadingState.call();
        } else {
          showLoadingDialog(context);
        }
      case ConnectDeviceSuccessState():
        if (onConnectDeviceSuccessState != null) {
          onConnectDeviceSuccessState.call();
        } else {
          Navigator.pop(context);
        }
      case ConnectDeviceFailureState():
        if (onConnectDeviceFailureState != null) {
          onConnectDeviceFailureState.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed connecting to device');
        }
      case SelectDeviceLoadingState():
        if (onSelectDeviceLoadingState != null) {
          onSelectDeviceLoadingState.call();
        } else {
          showLoadingDialog(context);
        }
      case SelectDeviceSuccessState():
        if (onSelectDeviceSuccessState != null) {
          onSelectDeviceSuccessState.call();
        } else {
          Navigator.pop(context);
        }
      case SelectDeviceFailureState():
        if (onSelectDeviceFailureState != null) {
          onSelectDeviceFailureState.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed selecting device');
        }
      case AuthDeviceLoadingState():
        if (onAuthDeviceLoadingState != null) {
          onAuthDeviceLoadingState.call();
        } else {
          showLoadingDialog(context);
        }
      case AuthDeviceSuccessState():
        if (onAuthDeviceSuccessState != null) {
          onAuthDeviceSuccessState.call();
        } else {
          context.router
              .pushAndPopUntil(const DatasetsPage(), predicate: (_) => false);
        }
      case AuthDeviceFailureState():
        if (onAuthDeviceFailureState != null) {
          onAuthDeviceFailureState.call(presentationState.failure);
        } else {
          Navigator.pop(context);
          showErrorSnackbar(context, 'Failed authenticating device');
        }
      case AuthDeviceResponseFailureState():
        if (onAuthDeviceResponseFailureState != null) {
          onAuthDeviceResponseFailureState.call();
        } else {
          Navigator.pop(context);
          showErrorSnackbar(context, 'Failed authenticating device');
        }
      case DisconnectDeviceFailure():
        if (onDisconnectDeviceFailure != null) {
          onDisconnectDeviceFailure.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed to disconnect device');
        }
      case GetPrimaryDeviceFailure():
        if (onGetPrimaryDeviceFailure != null) {
          onGetPrimaryDeviceFailure.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed to get saved device');
        }
      case RemoveDeviceFailure():
        if (onRemoveDeviceFailure != null) {
          onRemoveDeviceFailure.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed to remove saved device');
        }
    }
  }
}
