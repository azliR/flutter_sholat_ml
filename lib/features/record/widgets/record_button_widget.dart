import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/features/record/blocs/record/record_notifier.dart';
import 'package:material_symbols_icons/symbols.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({
    required this.cameraState,
    required this.cameraController,
    required this.onRecordPressed,
    required this.onLockPressed,
    required this.onSwitchPressed,
    super.key,
    this.leading,
  });

  final Widget? leading;
  final CameraState cameraState;
  final CameraController cameraController;
  final void Function() onRecordPressed;
  final void Function() onLockPressed;
  final void Function()? onSwitchPressed;

  @override
  State<RecordButton> createState() => __RecordButtonState();
}

class __RecordButtonState extends State<RecordButton> {
  var _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leading != null) widget.leading!,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton.outlined(
                iconSize: 36,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                onPressed: widget.onLockPressed,
                icon: const Icon(Symbols.lock_rounded, grade: -25),
              ),
              GestureDetector(
                onTap: () {
                  _isButtonPressed = false;
                  widget.onRecordPressed();
                },
                onTapDown: (details) {
                  if (widget.cameraState == CameraState.recording ||
                      widget.cameraState == CameraState.saving) return;
                  setState(() {
                    _isButtonPressed = true;
                  });
                },
                onTapCancel: () {
                  if (widget.cameraState == CameraState.recording ||
                      widget.cameraState == CameraState.saving) return;
                  setState(() {
                    _isButtonPressed = false;
                  });
                },
                onTapUp: (details) {
                  if (widget.cameraState == CameraState.recording ||
                      widget.cameraState == CameraState.saving) return;
                  setState(() {
                    _isButtonPressed = false;
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.bounceInOut,
                        margin: EdgeInsets.all(
                          widget.cameraState == CameraState.recording
                              ? 24
                              : (_isButtonPressed ? 10 : 5),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(
                              widget.cameraState == CameraState.recording
                                  ? 6
                                  : 36,
                            ),
                          ),
                          color: Colors.red,
                        ),
                      ),
                    ),
                    if (widget.cameraState == CameraState.preparing ||
                        widget.cameraState == CameraState.saving)
                      const SizedBox(
                        height: 72,
                        width: 72,
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                          strokeWidth: 6,
                          strokeAlign: -1,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.onSwitchPressed != null &&
                  widget.cameraState == CameraState.ready)
                IconButton.outlined(
                  iconSize: 36,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  onPressed: widget.onSwitchPressed,
                  icon: const Icon(Symbols.sync_rounded),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }
}
