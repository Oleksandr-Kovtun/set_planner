import 'package:flutter/material.dart';

enum PaperSize { a5, a4, a3, a2 }

enum PaperOrientation { portrait, landscape }

enum CameraNumberStyle { numeric, alphabetic }

enum CameraInfoField { cameraModel, shotTypes, lens, viewfinder, headphones, tripod, wheels, podium, description }

extension PaperSizeExt on PaperSize {
  String get displayName {
    switch (this) {
      case PaperSize.a5:
        return 'A5 (148×210 mm)';
      case PaperSize.a4:
        return 'A4 (210×297 mm)';
      case PaperSize.a3:
        return 'A3 (297×420 mm)';
      case PaperSize.a2:
        return 'A2 (420×594 mm)';
    }
  }

  // Розміри в мм
  ({double width, double height}) get mmSize {
    switch (this) {
      case PaperSize.a5:
        return (width: 148, height: 210);
      case PaperSize.a4:
        return (width: 210, height: 297);
      case PaperSize.a3:
        return (width: 297, height: 420);
      case PaperSize.a2:
        return (width: 420, height: 594);
    }
  }
}


class AppSettings {
  // Вихідне JPEG
  PaperSize paperSize;
  PaperOrientation paperOrientation;

  // Сітка
  double gridSize; // розмір комірки сітки для привʼязки
  bool showGrid; // видимість сітки привʼязки
  bool snapToGrid; // привʼязування до сітки
  bool showBigGrid; // відображення великої сітки 100 px

  // Інтерфейс
  Color primaryColor; // основний колір UI

  // Камери
  CameraNumberStyle cameraNumberStyle;
  Set<CameraInfoField> cameraInfoFields;

  // Мова
  String language; // 'uk' | 'en'

  AppSettings({
    this.paperSize = PaperSize.a4,
    this.paperOrientation = PaperOrientation.landscape,
    this.gridSize = 20.0,
    this.showGrid = true,
    this.snapToGrid = true,
    this.showBigGrid = false,
    this.primaryColor = Colors.blue,
    this.cameraNumberStyle = CameraNumberStyle.numeric,
    Set<CameraInfoField>? cameraInfoFields,
    this.language = 'uk',
  }) : cameraInfoFields = cameraInfoFields ?? {};

  AppSettings copy({
    PaperSize? paperSize,
    PaperOrientation? paperOrientation,
    double? gridSize,
    bool? showGrid,
    bool? snapToGrid,
    bool? showBigGrid,
    Color? primaryColor,
    CameraNumberStyle? cameraNumberStyle,
    Set<CameraInfoField>? cameraInfoFields,
    String? language,
  }) {
    return AppSettings(
      paperSize: paperSize ?? this.paperSize,
      paperOrientation: paperOrientation ?? this.paperOrientation,
      gridSize: gridSize ?? this.gridSize,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      showBigGrid: showBigGrid ?? this.showBigGrid,
      primaryColor: primaryColor ?? this.primaryColor,
      cameraNumberStyle: cameraNumberStyle ?? this.cameraNumberStyle,
      cameraInfoFields: cameraInfoFields ?? Set.of(this.cameraInfoFields),
      language: language ?? this.language,
    );
  }
}
