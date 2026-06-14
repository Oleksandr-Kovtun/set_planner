import '../models.dart';

class AppStrings {
  final String appTitle;
  // верхнє меню
  final String undo, redo, saveProject, exportImage, saveComingSoon, exportComingSoon, zoom, resetZoom;
  // панель інструментів
  final String cursorMode, freeDraw, shapes, cameras, actors,
      camerasComingSoon, actorsComingSoon, clearAll, importSvg, svgImportError,
      selectMode, group, ungroup, selectionMultiple;
  // діалог очищення
  final String clearTitle, clearMessage, cancel, clear;
  // панель властивостей
  final String nothingSelected, properties, lineThickness, lineColor,
      fillColor, keepAspect, delete, rotationAngle, layer, toFront, forward, backward, toBack;
  // назви інструментів/фігур
  final String toolSelect, toolPen, toolLine, toolRectangle, toolEllipse,
      toolTriangle, toolArrow, toolStar;
  // текстові властивості
  final String textTool, textContent, fontSizeLabel, bold, italic,
      fontFamily, alignment, colorLabel, fontDefault;
  // завантаження зображень
  final String importImage, imageImportError, imageTool, opacity;
  // властивість "заблоковано" (для майбутніх камер/акторів)
  final String locked, lockedHint;
  final String convertToCurve;
  final String arrowHeadStart, arrowHeadEnd;

  const AppStrings({
    required this.appTitle,
    required this.undo,
    required this.redo,
    required this.saveProject,
    required this.exportImage,
    required this.saveComingSoon,
    required this.exportComingSoon,
    required this.zoom,
    required this.resetZoom,
    required this.cursorMode,
    required this.freeDraw,
    required this.shapes,
    required this.cameras,
    required this.actors,
    required this.camerasComingSoon,
    required this.actorsComingSoon,
    required this.clearAll,
    required this.clearTitle,
    required this.clearMessage,
    required this.cancel,
    required this.clear,
    required this.nothingSelected,
    required this.properties,
    required this.lineThickness,
    required this.lineColor,
    required this.fillColor,
    required this.keepAspect,
    required this.delete,
    required this.toolSelect,
    required this.toolPen,
    required this.toolLine,
    required this.toolRectangle,
    required this.toolEllipse,
    required this.toolTriangle,
    required this.toolArrow,
    required this.toolStar,
    required this.rotationAngle,
    required this.layer,
    required this.toFront,
    required this.forward,
    required this.backward,
    required this.toBack,
    required this.importSvg,
    required this.svgImportError,
    required this.selectMode,
    required this.group,
    required this.ungroup,
    required this.selectionMultiple,
    required this.textTool,
    required this.textContent,
    required this.fontSizeLabel,
    required this.bold,
    required this.italic,
    required this.fontFamily,
    required this.alignment,
    required this.colorLabel,
    required this.fontDefault,
    required this.importImage,
    required this.imageImportError,
    required this.imageTool,
    required this.locked,
    required this.lockedHint,
    required this.convertToCurve,
    required this.arrowHeadStart,
    required this.arrowHeadEnd,
    required this.opacity,
  });

  // Назва фігури за інструментом.
  String toolLabel(Tool t) {
    switch (t) {
      case Tool.select: return toolSelect;
      case Tool.pen: return toolPen;
      case Tool.line: return toolLine;
      case Tool.rectangle: return toolRectangle;
      case Tool.ellipse: return toolEllipse;
      case Tool.triangle: return toolTriangle;
      case Tool.arrow: return toolLine;
      case Tool.star: return toolStar;
      case Tool.svg: return 'SVG';
      case Tool.svgPath: return 'SVG';
      case Tool.lasso: return selectMode;
      case Tool.text: return textTool;
      case Tool.image: return imageTool;
    }
  }

  // ===== Українська =====
  static const AppStrings ua = AppStrings(
    appTitle: 'Set Planner',
    undo: 'Скасувати',
    redo: 'Повторити',
    saveProject: 'Зберегти проєкт (XML)',
    exportImage: 'Експортувати зображення',
    saveComingSoon: 'Збереження у XML — зробимо наступним кроком',
    exportComingSoon: 'Експорт зображення — зробимо наступним кроком',
    zoom: 'Масштаб',
    resetZoom: 'Скинути (100%)',
    cursorMode: 'Режим курсора',
    freeDraw: 'Вільне малювання',
    shapes: 'Фігури',
    cameras: 'Камери',
    actors: 'Актори',
    camerasComingSoon: 'Камери — додамо пізніше',
    actorsComingSoon: 'Актори — додамо пізніше',
    clearAll: 'Очистити все',
    importSvg: 'Імпортувати SVG',
    svgImportError: 'Не вдалося імпортувати SVG-файл',
    selectMode: 'Вибір (рамкою)',
    group: 'Обʼєднати в групу',
    ungroup: 'Розгрупувати',
    selectionMultiple: 'Вибрано елементів',
    clearTitle: 'Очистити полотно?',
    clearMessage: 'Усі елементи буде видалено. Це можна повернути кнопкою undo угорі.',
    cancel: 'Скасувати',
    clear: 'Очистити',
    nothingSelected: 'Нічого не вибрано.\n\nУвімкніть режим курсора\nі торкніться фігури.',
    properties: 'Властивості',
    lineThickness: 'Товщина лінії',
    lineColor: 'Колір лінії',
    fillColor: 'Колір заливки',
    keepAspect: 'Зберігати пропорції',
    delete: 'Видалити',
    toolSelect: 'Вибір',
    toolPen: 'Лінія від руки',
    toolLine: 'Лінія',
    toolRectangle: 'Прямокутник',
    toolEllipse: 'Коло / Еліпс',
    toolTriangle: 'Трикутник',
    toolArrow: 'Стрілка',
    toolStar: 'Зірка',
    rotationAngle: 'Кут обертання (°)',
    layer: 'Шар',
    toFront: 'На передній план',
    forward: 'Підняти вище',
    backward: 'Опустити нижче',
    toBack: 'На задній план',
    textTool: 'Текст',
    textContent: 'Вміст',
    fontSizeLabel: 'Розмір шрифту',
    bold: 'Жирний',
    italic: 'Курсив',
    fontFamily: 'Шрифт',
    alignment: 'Вирівнювання',
    colorLabel: 'Колір',
    fontDefault: 'За замовчанням',
    opacity: 'Прозорість',
    importImage: 'Завантажити зображення',
    imageImportError: 'Не вдалося завантажити зображення',
    imageTool: 'Зображення',
    locked: 'Заблоковано',
    lockedHint: 'Елемент заблоковано. Зніміть блокування, щоб редагувати.',
    convertToCurve: 'Спростити криву',
    arrowHeadStart: 'Вістря на початку',
    arrowHeadEnd: 'Вістря в кінці',
  );

  // ===== English =====
  static const AppStrings en = AppStrings(
    appTitle: 'Set Planner',
    undo: 'Undo',
    redo: 'Redo',
    saveProject: 'Save project (XML)',
    exportImage: 'Export image',
    saveComingSoon: 'XML saving — coming in the next step',
    exportComingSoon: 'Image export — coming in the next step',
    zoom: 'Zoom',
    resetZoom: 'Reset (100%)',
    cursorMode: 'Cursor mode',
    freeDraw: 'Free drawing',
    shapes: 'Shapes',
    cameras: 'Cameras',
    actors: 'Actors',
    camerasComingSoon: 'Cameras — coming later',
    actorsComingSoon: 'Actors — coming later',
    clearAll: 'Clear all',
    importSvg: 'Import SVG',
    svgImportError: 'Could not import the SVG file',
    selectMode: 'Select (marquee)',
    group: 'Group',
    ungroup: 'Ungroup',
    selectionMultiple: 'Selected items',
    clearTitle: 'Clear the canvas?',
    clearMessage: 'All elements will be removed. You can undo this with the undo button at the top.',
    cancel: 'Cancel',
    clear: 'Clear',
    nothingSelected: 'Nothing selected.\n\nTurn on cursor mode\nand tap a shape.',
    properties: 'Properties',
    lineThickness: 'Line thickness',
    lineColor: 'Line color',
    fillColor: 'Fill color',
    keepAspect: 'Keep proportions',
    delete: 'Delete',
    toolSelect: 'Select',
    toolPen: 'Freehand line',
    toolLine: 'Line',
    toolRectangle: 'Rectangle',
    toolEllipse: 'Circle / Ellipse',
    toolTriangle: 'Triangle',
    toolArrow: 'Arrow',
    toolStar: 'Star',
    rotationAngle: 'Rotation angle (°)',
    layer: 'Layer',
    toFront: 'Bring to front',
    forward: 'Bring forward',
    backward: 'Send backward',
    toBack: 'Send to back',
    textTool: 'Text',
    textContent: 'Content',
    fontSizeLabel: 'Font size',
    bold: 'Bold',
    italic: 'Italic',
    fontFamily: 'Font',
    alignment: 'Alignment',
    colorLabel: 'Color',
    fontDefault: 'Default',
    opacity: 'Opacity',
    importImage: 'Load image',
    imageImportError: 'Could not load image',
    imageTool: 'Image',
    locked: 'Locked',
    lockedHint: 'Item is locked. Unlock it to edit.',
    convertToCurve: 'Simplify curve',
    arrowHeadStart: 'Head at start',
    arrowHeadEnd: 'Head at end',
  );

  static AppStrings of(String languageCode) {
    switch (languageCode) {
      case 'en':
        return en;
      default:
        return ua;
    }
  }
}

// Поточні рядки. Встановлюються в main() за мовою системи.
AppStrings strings = AppStrings.ua;