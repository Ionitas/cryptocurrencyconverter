import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'logging_system.dart';
import 'firebase_analytics_service.dart';

/// App Tracking Transparency Service
/// Handles iOS ATT permission requests
class TrackingService {
  static TrackingService? _instance;
  static TrackingService get instance {
    _instance ??= TrackingService._();
    return _instance!;
  }

  TrackingService._();

  TrackingStatus? _status;
  bool _hasRequestedPermission = false;

  /// Get the current tracking status
  TrackingStatus? get status => _status;

  /// Check if tracking is authorized
  bool get isAuthorized => _status == TrackingStatus.authorized;

  /// Check if permission has been requested
  bool get hasRequestedPermission => _hasRequestedPermission;

  /// Request tracking authorization (iOS only)
  /// Should be called after a short delay when app starts or during onboarding
  Future<TrackingStatus> requestTrackingAuthorization() async {
    // Only applicable on iOS
    if (!Platform.isIOS) {
      _status = TrackingStatus.notSupported;
      return _status!;
    }

    try {
      // Check current status first
      _status = await AppTrackingTransparency.trackingAuthorizationStatus;
      AppLogger.i('TrackingService', 'Current status: $_status');

      // If not determined, request permission
      if (_status == TrackingStatus.notDetermined) {
        // Small delay recommended by Apple
        await Future.delayed(const Duration(milliseconds: 200));

        _status = await AppTrackingTransparency.requestTrackingAuthorization();
        _hasRequestedPermission = true;

        AppLogger.i('TrackingService', 'Authorization result: $_status');
      }

      // Log the tracking status
      await FirebaseAnalyticsService.instance.logTrackingAuthorizationStatus(
        status: _statusToString(_status!),
      );

      return _status!;
    } catch (e) {
      AppLogger.e('TrackingService', 'Failed to request authorization',
          error: e);
      _status = TrackingStatus.notSupported;
      return _status!;
    }
  }

  /// Get the advertising identifier (IDFA)
  /// Returns null if tracking is not authorized
  Future<String?> getAdvertisingIdentifier() async {
    if (!Platform.isIOS) return null;

    try {
      if (_status == TrackingStatus.authorized) {
        final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
        return uuid;
      }
      return null;
    } catch (e) {
      AppLogger.e('TrackingService', 'Failed to get IDFA', error: e);
      return null;
    }
  }

  /// Check current tracking status without requesting
  Future<TrackingStatus> checkStatus() async {
    if (!Platform.isIOS) {
      return TrackingStatus.notSupported;
    }

    try {
      _status = await AppTrackingTransparency.trackingAuthorizationStatus;
      return _status!;
    } catch (e) {
      return TrackingStatus.notSupported;
    }
  }

  String _statusToString(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.notDetermined:
        return 'not_determined';
      case TrackingStatus.restricted:
        return 'restricted';
      case TrackingStatus.denied:
        return 'denied';
      case TrackingStatus.authorized:
        return 'authorized';
      case TrackingStatus.notSupported:
        return 'not_supported';
    }
  }

  /// Get user-friendly description of current status
  String getStatusDescription() {
    switch (_status) {
      case TrackingStatus.authorized:
        return 'Tracking enabled';
      case TrackingStatus.denied:
        return 'Tracking disabled';
      case TrackingStatus.restricted:
        return 'Tracking restricted';
      case TrackingStatus.notDetermined:
        return 'Not yet determined';
      case TrackingStatus.notSupported:
      case null:
        return 'Not supported';
    }
  }
}
