/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2021- Scandit AG. All rights reserved.
 */

import 'package:TextCaptureSample/settings/model/recognition_area.dart';
import 'package:TextCaptureSample/settings/model/text_type.dart';
import 'package:scandit_flutter_datacapture_core/scandit_flutter_datacapture_core.dart';
import 'package:scandit_flutter_datacapture_text/scandit_flutter_datacapture_text.dart';

const String licenseKey = 'AZ707AsCLmJWHbYO4RjqcVAEgAxmNGYcF3Ytg4RiKa/lWTQ3IXkfVZhSSi0yOzuabn9STRdnzTLybIiJVkVZU2QK5jeqbn1HGCGXQ+9lqsN8VUaTw1IeuHJo+9mYVdv3I1DhedtSy89aKA4QugKI5d9ykKaXGohXjlI+PB5ju8Tyc80FPAC3WP9D8oKBcWyemTLQjoUu0Nl3T7mVyFIXMPshQeYddkjMQ1sVV9Jcuf1CbI9riUJWzbNUb4NcB4MoV0BHuyALUPtuM2+cBkX3bPN0AxjD9WC7KflL2UrsZeenvl/aDx2yU4t5vsa2BImNTyEqdVs+rmrGUzRdbYvSUFzKBeiBncLAASqnexTuSzh9KfEm/cKrVlWekP+zOkrilICkn3KVNY6g9RQd8FrsHTBI9OBbMpC79BTwuzHcnlFUG5S3ru/viJ2+f9JEEejxDbdJ7u4JohfBuUYBSEBQ/XzEPMdpqWcmxHGWF4j7jQy83B9Wlgrhd8xNWKjgAViI0bcebjnB7o6yuKacXICH/lo787RhnXSjqjQhJBCbEvwxHQZiEfWPdVKtY7EM+x8HFr6j3orKllKOMJ9asZ5bJYz9aIHlOWeRGm90guQn0KWiPwuKbUOQIMxFAOem2zcSTt4OfqS6Ci0Y6lk7FIrgpbaz8L1PW64kkjrZB6FtQ8OppmsyZ/QTvrHYFQFTH7MpamDviRjEKMyiD2ID6ypl+Meeme6cZYRJVujr6b4tweQCsfNEYhuDiMJaWQ57R0n2XdF0zkepLVc0yA2Q3wWhxSIASLnv6GTCYYVnDJnkrr6VaTv8RVUOp8h8U34wGDanamQ+39+rESMD59E288OKgFvZZWN9Ltu/VQCcjYCYT1RTDcA9co3Y18aGpDxvtLVEGJ8QDPv1E//IYAYEhXqu8r9xbsx/hTwZmLpNKyXGPRr9+hpufTAcAj908f2kuQ==';

class SettingsRepository {
  static final SettingsRepository _singleton = SettingsRepository._internal()..init();

  factory SettingsRepository() {
    return _singleton;
  }

  SettingsRepository._internal();

  // Create data capture context using your license key.
  late DataCaptureContext _dataCaptureContext;

  // Use the world-facing (back) camera.
  Camera? _camera = Camera.defaultCamera;

  final CameraSettings _cameraSettings = TextCapture.recommendedCameraSettings;

  late TextCapture _textCapture;

  late DataCaptureView _dataCaptureView;

  late TextCaptureOverlay _overlay;

  DataCaptureContext get dataCaptureContext {
    return _dataCaptureContext;
  }

  DataCaptureView get dataCaptureView {
    return _dataCaptureView;
  }

  TextCapture get textCapture {
    return _textCapture;
  }

  Camera? get camera {
    return _camera;
  }

  TextType _textType = TextType(Mode.gs1Ai);

  TextType get textType {
    return _textType;
  }

  set textType(TextType newType) {
    _textType = newType;
    applyNewSettings();
    setupViewfinder();
  }

  RecognitionArea _recognitionArea = RecognitionArea(Position.center);

  RecognitionArea get recognitionArea {
    return _recognitionArea;
  }

  set recognitionArea(RecognitionArea newRecognitionArea) {
    _recognitionArea = newRecognitionArea;
    setupPosition();
  }

  void init() {
    _camera?.applySettings(_cameraSettings);

    // Create data capture context using your license key and set the camera as the frame source.
    _dataCaptureContext = DataCaptureContext.forLicenseKey(licenseKey);
    if (_camera != null) _dataCaptureContext.setFrameSource(_camera!);

    // Initialize settings from the default text type
    var settings = getSettings();

    // Create new text capture mode with the initial settings
    _textCapture = TextCapture.forContext(_dataCaptureContext, settings);

    // To visualize the on-going text capturing process on screen, setup a data capture view that renders the
    // camera preview. The view must be connected to the data capture context.
    _dataCaptureView = DataCaptureView.forContext(dataCaptureContext);

    // Add a text capture overlay to the data capture view to render the location of captured texts on top of
    // the video preview. This is optional, but recommended for better visual feedback.
    _overlay = TextCaptureOverlay.withTextCaptureForView(_textCapture, _dataCaptureView);

    setupViewfinder();
    setupPosition();
  }

  LocationSelection get locationSelection {
    var locationWidth = (_textType.mode == Mode.gs1Ai) ? 0.9 : 0.6;
    return RectangularLocationSelection.withWidthAndAspect(DoubleWithUnit(locationWidth, MeasureUnit.fraction), 0.2);
  }

  void setupViewfinder() {
    var viewfinderWidth = (_textType.mode == Mode.gs1Ai) ? 0.9 : 0.6;

    var viewfinder = RectangularViewfinder.withStyleAndLineStyle(
      RectangularViewfinderStyle.square,
      RectangularViewfinderLineStyle.light,
    );
    viewfinder.dimming = 0.2;
    viewfinder.setWidthAndAspectRatio(new DoubleWithUnit(viewfinderWidth, MeasureUnit.fraction), 0.2);
    _overlay.viewfinder = viewfinder;
  }

  void setupPosition() {
    // Set the point of interest of the capture view, which will automatically move the center of the viewfinder
    // and the location selection area to this point.
    var pointOfInterest = PointWithUnit(
        DoubleWithUnit(0.5, MeasureUnit.fraction), DoubleWithUnit(_recognitionArea.centerY, MeasureUnit.fraction));
    dataCaptureView.pointOfInterest = pointOfInterest;
  }

  void applyNewSettings() {
    textCapture.applySettings(getSettings());
  }

  TextCaptureSettings getSettings() {
    return TextCaptureSettings.fromJSON({'regex': _textType.regex})..locationSelection = locationSelection;
  }
}
