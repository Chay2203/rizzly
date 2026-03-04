import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ToastType { success, warning, error, info }

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ToastBuilder {
  static late FToast _fToast;
  static bool _isInitialized = false;

  static void globalInit(BuildContext context) {
    _fToast = FToast();
    _fToast.init(context);
    _isInitialized = true;
  }

  static Widget _buildToast(
    String message,
    ToastType type, {
    BuildContext? context,
    double? bottomOffset,
    FToast? fToastInstance,
  }) {
    final double keyboardHeight = MediaQuery.of(
      context ?? navigatorKey.currentContext ?? navigatorKey.currentState!.context,
    ).viewInsets.bottom;
    final double bottomMargin =
        (bottomOffset ??
            (navigatorKey.currentContext != null
                ? MediaQuery.of(navigatorKey.currentContext!).size.height * 0.2
                : 150)) +
        keyboardHeight;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(2, 2),
              blurRadius: 7,
              spreadRadius: 0,
            ),
          ],
        ),
        margin: EdgeInsets.only(bottom: bottomMargin),
        child: GestureDetector(
          onTap: () => (fToastInstance ?? _fToast).removeCustomToast(),
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              (fToastInstance ?? _fToast).removeCustomToast();
            }
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              (fToastInstance ?? _fToast).removeCustomToast();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: const Color(0xFF04001B),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      _getToastIcon(type),
                      size: 14,
                      color: _getToastIconColor(type),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void showToast(
    String message, {
    ToastType type = ToastType.success,
    BuildContext? context,
    bool ignorePointer = true,
    double? bottomOffset,
  }) {
    if (context != null) {
      final fToast = FToast();
      fToast.init(context);
      fToast
        ..removeQueuedCustomToasts()
        ..showToast(
          child: _buildToast(
            message,
            type,
            context: context,
            bottomOffset: bottomOffset,
            fToastInstance: fToast,
          ),
          positionedToastBuilder: (context, child, gravity) {
            return Positioned(bottom: 0, left: 0, right: 0, child: child);
          },
          gravity: ToastGravity.BOTTOM,
          toastDuration: const Duration(seconds: 3),
          ignorePointer: ignorePointer,
        );
      return;
    }

    if (!_isInitialized) return;

    try {
      _fToast
        ..removeQueuedCustomToasts()
        ..showToast(
          child: Builder(
            builder: (builderContext) => _buildToast(
              message,
              type,
              context: builderContext,
              bottomOffset: bottomOffset,
            ),
          ),
          positionedToastBuilder: (context, child, gravity) {
            return Positioned(bottom: 0, left: 0, right: 0, child: child);
          },
          gravity: ToastGravity.BOTTOM,
          toastDuration: const Duration(seconds: 3),
        );
    } catch (e) {
      return;
    }
  }

  static IconData _getToastIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

  static Color _getToastIconColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.warning:
        return Colors.amber;
      case ToastType.error:
        return Colors.redAccent;
      case ToastType.info:
        return Colors.lightBlueAccent;
    }
  }
}
