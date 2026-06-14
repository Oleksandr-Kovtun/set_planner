import 'package:flutter/material.dart';

enum PaperSize { a5, a4, a3, a2 }

enum PaperOrientation { portrait, landscape }

extension PaperSizeExt on PaperSize {
  String get displayName {
    switch (this) {
      case PaperSize.a5:
        return 'A5 (148×210 мм)';
      case PaperSize.a4:
        return 'A4 (210×297 мм)';
      case PaperSize.a3:
        return 'A3 (297×420 мм)';
      case PaperSize.a2:
        return 'A2 (420×594 мм)';
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

extension PaperOrientationExt on PaperOrientation {
  String get displayName =>
      this == PaperOrientation.portrait ? 'Портретна' : 'Альбомна';
}

class AppSettings {
  // Вихідне JPEG
  PaperSize paperSize;
  PaperOrientation paperOrientation;

  // Сітка
  double gridSize; // розмір комірки сітки в пікселях
  bool showGrid; // видимість сітки
  bool snapToGrid; // привʼязування до сітки

  // Інтерфейс
  Color primaryColor; // основний колір UI

  AppSettings({
    this.paperSize = PaperSize.a4,
    this.paperOrientation = PaperOrientation.landscape,
    this.gridSize = 20.0,
    this.showGrid = true,
    this.snapToGrid = true,
    this.primaryColor = Colors.blue,
  });

  AppSettings copy({
    PaperSize? paperSize,
    PaperOrientation? paperOrientation,
    double? gridSize,
    bool? showGrid,
    bool? snapToGrid,
    Color? primaryColor,
  }) {
    return AppSettings(
      paperSize: paperSize ?? this.paperSize,
      paperOrientation: paperOrientation ?? this.paperOrientation,
      gridSize: gridSize ?? this.gridSize,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}
