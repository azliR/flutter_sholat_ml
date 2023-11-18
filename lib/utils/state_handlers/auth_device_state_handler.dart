import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';

void handleAuthDeviceState(
  BuildContext context,
  AuthDeviceState? previous,
  AuthDeviceState next, {
  void Function()? onAuthDeviceInitial,
  void Function()? onConnectDeviceLoading,
  void Function()? onConnectDeviceSuccess,
  void Function(Failure failure)? onConnectDeviceFailure,
  void Function()? onSelectDeviceLoading,
  void Function()? onSelectDeviceSuccess,
  void Function(Failure failure)? onSelectDeviceFailure,
  void Function()? onAuthDeviceLoading,
  void Function()? onAuthDeviceSuccess,
  void Function(Failure failure)? onAuthDeviceFailure,
  void Function()? onAuthDeviceResponseFailure,
  void Function()? onAuthWithXiaomiAccountLoading,
  void Function()? onAuthWithXiaomiAccountSuccess,
  void Function(Failure failure)? onAuthWithXiaomiAccountFailure,
  void Function()? onAuthWithXiaomiAccountResponseFailure,
  void Function(Failure failure)? onDisconnectDeviceFailure,
  void Function(Failure failure)? onGetPrimaryDeviceFailure,
  void Function(Failure failure)? onRemoveDeviceFailure,
  void Function()? onGetDeviceNameLoading,
  void Function(Failure failure)? onGetDeviceNameFailure,
}) {
  if (previous?.presentationState != next.presentationState) {
    final presentationState = next.presentationState;
    switch (presentationState) {
      case AuthDeviceInitialState():
        onAuthDeviceInitial?.call();
      case ConnectDeviceLoadingState():
        if (onConnectDeviceLoading != null) {
          onConnectDeviceLoading.call();
        } else {
          context.loaderOverlay.show();
        }
      case ConnectDeviceSuccessState():
        if (onConnectDeviceSuccess != null) {
          onConnectDeviceSuccess.call();
        } else {
          context.loaderOverlay.hide();
        }
      case ConnectDeviceFailureState():
        if (onConnectDeviceFailure != null) {
          onConnectDeviceFailure.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed connecting to device');
        }
      case SelectDeviceLoadingState():
        if (onSelectDeviceLoading != null) {
          onSelectDeviceLoading.call();
        } else {
          context.loaderOverlay.hide();
        }
      case SelectDeviceSuccessState():
        if (onSelectDeviceSuccess != null) {
          onSelectDeviceSuccess.call();
        } else {
          context.loaderOverlay.hide();
        }
      case SelectDeviceFailureState():
        if (onSelectDeviceFailure != null) {
          onSelectDeviceFailure.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed selecting device');
        }
      case AuthDeviceLoadingState():
        if (onAuthDeviceLoading != null) {
          onAuthDeviceLoading.call();
        } else {
          context.loaderOverlay.show();
        }
      case AuthDeviceSuccessState():
        if (onAuthDeviceSuccess != null) {
          onAuthDeviceSuccess.call();
        } else {
          context.loaderOverlay.hide();
        }
      case AuthDeviceFailureState():
        if (onAuthDeviceFailure != null) {
          onAuthDeviceFailure.call(presentationState.failure);
        } else {
          context.loaderOverlay.hide();
          showErrorSnackbar(context, 'Failed authenticating device');
        }
      case AuthDeviceResponseFailureState():
        if (onAuthDeviceResponseFailure != null) {
          onAuthDeviceResponseFailure.call();
        } else {
          context.loaderOverlay.hide();
          showErrorSnackbar(context, 'Failed authenticating device');
        }
      case AuthWithXiaomiAccountLoadingState():
        if (onAuthWithXiaomiAccountLoading != null) {
          onAuthWithXiaomiAccountLoading.call();
        } else {
          context.loaderOverlay.show();
        }
      case AuthWithXiaomiAccountSuccessState():
        if (onAuthWithXiaomiAccountSuccess != null) {
          onAuthWithXiaomiAccountSuccess.call();
        } else {
          context.loaderOverlay.hide();
        }
      case AuthWithXiaomiAccountFailureState():
        if (onAuthWithXiaomiAccountFailure != null) {
          onAuthWithXiaomiAccountFailure.call(presentationState.failure);
        } else {
          context.loaderOverlay.hide();
          showErrorSnackbar(
            context,
            'Failed authenticating with xiaomi account',
          );
        }
      case AuthWithXiaomiAccountResponseFailureState():
        if (onAuthWithXiaomiAccountResponseFailure != null) {
          onAuthWithXiaomiAccountResponseFailure.call();
        } else {
          context.loaderOverlay.hide();
          showErrorSnackbar(context, 'Failed authenticating device');
        }
      case DisconnectDeviceFailureState():
        if (onDisconnectDeviceFailure != null) {
          onDisconnectDeviceFailure.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed to disconnect device');
        }
      case GetPrimaryDeviceFailureState():
        if (onGetPrimaryDeviceFailure != null) {
          onGetPrimaryDeviceFailure.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed to get saved device');
        }
      case RemoveDeviceFailureState():
        if (onRemoveDeviceFailure != null) {
          onRemoveDeviceFailure.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed to remove saved device');
        }
      case GetDeviceNameFailureState():
        if (onGetDeviceNameFailure != null) {
          onGetDeviceNameFailure.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed to get device name');
        }
      case GetDeviceNameLoadingState():
        if (onGetDeviceNameLoading != null) {
          onGetDeviceNameLoading.call();
        }
    }
  }
}
