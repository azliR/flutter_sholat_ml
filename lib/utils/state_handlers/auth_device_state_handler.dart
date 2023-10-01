import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';

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
  void Function()? onAuthWithXiaomiAccountLoadingState,
  void Function()? onAuthWithXiaomiAccountSuccessState,
  void Function(Failure failure)? onAuthWithXiaomiAccountFailureState,
  void Function()? onAuthWithXiaomiAccountResponseFailureState,
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
          context.loaderOverlay.show();
        }
      case ConnectDeviceSuccessState():
        if (onConnectDeviceSuccessState != null) {
          onConnectDeviceSuccessState.call();
        } else {
          context.loaderOverlay.hide();
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
          context.loaderOverlay.hide();
        }
      case SelectDeviceSuccessState():
        if (onSelectDeviceSuccessState != null) {
          onSelectDeviceSuccessState.call();
        } else {
          context.loaderOverlay.hide();
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
          context.loaderOverlay.show();
        }
      case AuthDeviceSuccessState():
        if (onAuthDeviceSuccessState != null) {
          onAuthDeviceSuccessState.call();
        } else {
          context.loaderOverlay.hide();
          context.router
              .pushAndPopUntil(const DatasetsPage(), predicate: (_) => false);
        }
      case AuthDeviceFailureState():
        if (onAuthDeviceFailureState != null) {
          onAuthDeviceFailureState.call(presentationState.failure);
        } else {
          context.loaderOverlay.hide();
          showErrorSnackbar(context, 'Failed authenticating device');
        }
      case AuthDeviceResponseFailureState():
        if (onAuthDeviceResponseFailureState != null) {
          onAuthDeviceResponseFailureState.call();
        } else {
          context.loaderOverlay.hide();
          showErrorSnackbar(context, 'Failed authenticating device');
        }
      case AuthWithXiaomiAccountLoadingState():
        if (onAuthWithXiaomiAccountLoadingState != null) {
          onAuthWithXiaomiAccountLoadingState.call();
        } else {
          context.loaderOverlay.show();
        }
      case AuthWithXiaomiAccountSuccessState():
        if (onAuthWithXiaomiAccountSuccessState != null) {
          onAuthWithXiaomiAccountSuccessState.call();
        } else {
          context.loaderOverlay.hide();
          context.router
              .pushAndPopUntil(const DatasetsPage(), predicate: (_) => false);
        }
      case AuthWithXiaomiAccountFailureState():
        if (onAuthWithXiaomiAccountFailureState != null) {
          onAuthWithXiaomiAccountFailureState.call(presentationState.failure);
        } else {
          showErrorSnackbar(context, 'Failed authenticating device');
        }
      case AuthWithXiaomiAccountResponseFailureState():
        if (onAuthWithXiaomiAccountResponseFailureState != null) {
          onAuthWithXiaomiAccountResponseFailureState.call();
        } else {
          context.loaderOverlay.hide();
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
