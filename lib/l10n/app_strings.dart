import '../models.dart';

class AppStrings {
  final String appTitle;
  // верхнє меню
  final String undo, redo, saveProject, exportImage, saveComingSoon, exportComingSoon, zoom, resetZoom;
  // панель інструментів
  final String cursorMode, freeDraw, shapes, cameras, actors,
      camerasComingSoon, actorsComingSoon, clearAll, importSvg, svgImportError,
      selectMode, group, ungroup, join, joinLines, selectionMultiple;
  // діалог очищення
  final String clearTitle, clearMessage, cancel, clear;
  // панель властивостей
  final String nothingSelected, properties, lineThickness, lineColor,
      fillColor, keepAspect, delete, rotationAngle, layer, toFront, forward, backward, toBack;
  // назви інструментів/фігур
  final String toolSelect, toolPen, toolPolyline, toolLine, toolRectangle, toolEllipse,
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
  // рейки / rig equipment
  final String toolRigs, rigJib, rigDolly, rigRail, rigWidth, rigHeight, railBend;
  // актори
  final String toolActor, actorName, actorProps, noActors;
  // камери
  final String toolCamera;
  final String cameraNumber, showNumber, cameraModel, shotType, lens;
  final String viewfinder, viewfinderNone, viewfinderSmall, viewfinderBig;
  final String headphones, headphonesNone, headphonesSingle, headphonesDouble;
  final String tripod, tripodDescription, wheels, podium, podiumDescription;
  final String cameraLabelItem, goToCamera;
  final String cameraNumberStyle, cameraNumberNumeric, cameraNumberAlphabetic;
  final String cameraColor, description;
  final String yes;
  final String cameraInfoDisplay;
  final String allowResize;
  final String noCameras;
  final String language, languageUk, languageEn;
  // налаштування (settings dialog)
  final String settings;
  final String jpegOutput;
  final String gridSection;
  final String uiSection;
  final String save;
  final String paperSize, orientation;
  final String portrait, landscape;
  final String gridSizeLabel;
  final String showGrid, snapToGrid, showBigGrid;
  final String primaryColor, pickColor, select;
  final String openProject, saveAsProject, saveError, openError, saveToFilesHint, exportError;
  final String exportPdf, pdfColViewfinder, pdfColHeadphones;
  final String toggleCameraKit;
  final String projectsFolder, projectsFolderHint, untitled, newProjectName, projectsSection;

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
    required this.toolPolyline,
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
    required this.join,
    required this.joinLines,
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
    required this.toolRigs,
    required this.rigJib,
    required this.rigDolly,
    required this.rigRail,
    required this.rigWidth,
    required this.rigHeight,
    required this.railBend,
    required this.toolActor,
    required this.actorName,
    required this.actorProps,
    required this.noActors,
    required this.toolCamera,
    required this.cameraNumber,
    required this.showNumber,
    required this.cameraModel,
    required this.shotType,
    required this.lens,
    required this.viewfinder,
    required this.viewfinderNone,
    required this.viewfinderSmall,
    required this.viewfinderBig,
    required this.headphones,
    required this.headphonesNone,
    required this.headphonesSingle,
    required this.headphonesDouble,
    required this.tripod,
    required this.tripodDescription,
    required this.wheels,
    required this.podium,
    required this.podiumDescription,
    required this.cameraLabelItem,
    required this.goToCamera,
    required this.cameraNumberStyle,
    required this.cameraNumberNumeric,
    required this.cameraNumberAlphabetic,
    required this.cameraColor,
    required this.description,
    required this.yes,
    required this.cameraInfoDisplay,
    required this.allowResize,
    required this.noCameras,
    required this.language,
    required this.languageUk,
    required this.languageEn,
    required this.settings,
    required this.jpegOutput,
    required this.gridSection,
    required this.uiSection,
    required this.save,
    required this.paperSize,
    required this.orientation,
    required this.portrait,
    required this.landscape,
    required this.gridSizeLabel,
    required this.showGrid,
    required this.snapToGrid,
    required this.showBigGrid,
    required this.primaryColor,
    required this.pickColor,
    required this.select,
    required this.openProject,
    required this.saveAsProject,
    required this.saveError,
    required this.openError,
    required this.saveToFilesHint,
    required this.exportError,
    required this.exportPdf,
    required this.pdfColViewfinder,
    required this.pdfColHeadphones,
    required this.toggleCameraKit,
    required this.projectsFolder,
    required this.projectsFolderHint,
    required this.untitled,
    required this.newProjectName,
    required this.projectsSection,
  });

  // Назва фігури за інструментом.
  String toolLabel(Tool t) {
    switch (t) {
      case Tool.select: return toolSelect;
      case Tool.pen: return toolPen;
      case Tool.polyline: return toolPolyline;
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
      case Tool.camera: return toolCamera;
      case Tool.actor: return toolActor;
      case Tool.rig: return toolRigs;
    }
  }

  String rigLabel(RigType type) {
    switch (type) {
      case RigType.jib: return rigJib;
      case RigType.dolly: return rigDolly;
      case RigType.rail: return rigRail;
    }
  }

  // ===== Українська =====
  static const AppStrings ua = AppStrings(
    appTitle: 'Set Planner',
    undo: 'Скасувати',
    redo: 'Повторити',
    saveProject: 'Зберегти проєкт (XML)',
    exportImage: 'Зберегти як JPG',
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
    join: 'Об\'єднати',
    joinLines: 'Об\'єднати лінії',
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
    toolPolyline: 'Ламана лінія',
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
    toolRigs: 'Рейки',
    rigJib: 'Кран JIB',
    rigDolly: 'Візок Dolly',
    rigRail: 'Рейки',
    rigWidth: 'Ширина',
    rigHeight: 'Висота',
    railBend: 'Вигин',
    toolActor: 'Актор',
    actorName: 'Ім\'я',
    actorProps: 'Реквізит',
    noActors: 'Акторів ще немає',
    toolCamera: 'Камера',
    cameraNumber: 'Номер камери',
    showNumber: 'Показувати номер',
    cameraModel: 'Модель камери',
    shotType: 'Тип кадру',
    lens: 'Об\'єктив',
    viewfinder: 'Видошукач',
    viewfinderNone: 'Немає',
    viewfinderSmall: 'Малий',
    viewfinderBig: 'Великий',
    headphones: 'Гарнітура',
    headphonesNone: 'Немає',
    headphonesSingle: 'Одинарна',
    headphonesDouble: 'Подвійна',
    tripod: 'Штатив',
    tripodDescription: 'Опис штатива',
    wheels: 'Колеса',
    podium: 'Подіум',
    podiumDescription: 'Опис подіуму',
    cameraLabelItem: 'Мітка номера камери',
    goToCamera: 'Перейти до камери',
    cameraNumberStyle: 'Нумерація камер',
    cameraNumberNumeric: '1, 2, 3...',
    cameraNumberAlphabetic: 'A, B, C...',
    cameraColor: 'Колір камери',
    description: 'Опис',
    yes: 'Так',
    cameraInfoDisplay: 'Відображення властивостей камери',
    allowResize: 'Дозволити зміну розміру',
    noCameras: 'Камер ще немає',
    language: 'Мова',
    languageUk: 'Українська',
    languageEn: 'English',
    settings: 'Налаштування',
    jpegOutput: 'Вихідний файл JPEG',
    gridSection: 'Сітка для привʼязування',
    uiSection: 'Інтерфейс',
    save: 'Зберегти',
    paperSize: 'Розмір',
    orientation: 'Орієнтація',
    portrait: 'Портретна',
    landscape: 'Альбомна',
    gridSizeLabel: 'Розмір комірки',
    showGrid: 'Показувати сітку',
    snapToGrid: 'Привʼязувати до сітки',
    showBigGrid: 'Показувати сітку м²',
    primaryColor: 'Основний колір',
    pickColor: 'Оберіть колір',
    select: 'Вибрати',
    openProject: 'Відкрити проєкт',
    saveAsProject: 'Зберегти як...',
    saveError: 'Помилка збереження',
    openError: 'Помилка відкриття файлу',
    saveToFilesHint: 'Файл буде збережено у програмі «Файли» → Set Planner',
    exportError: 'Помилка експорту',
    exportPdf: 'Зберегти як PDF',
    pdfColViewfinder: 'VF',
    pdfColHeadphones: 'Headset',
    toggleCameraKit: 'Camera Kit',
    projectsSection: 'Проєкти',
    projectsFolder: 'Папка проєктів',
    projectsFolderHint: 'Не вибрано',
    untitled: 'Без назви',
    newProjectName: 'Назва проєкту',
  );

  // ===== English =====
  static const AppStrings en = AppStrings(
    appTitle: 'Set Planner',
    undo: 'Undo',
    redo: 'Redo',
    saveProject: 'Save project (XML)',
    exportImage: 'Save as JPG',
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
    join: 'Join',
    joinLines: 'Join lines',
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
    toolPolyline: 'Polyline',
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
    toolRigs: 'Rigs',
    rigJib: 'JIB Crane',
    rigDolly: 'Dolly',
    rigRail: 'Rails',
    rigWidth: 'Width',
    rigHeight: 'Height',
    railBend: 'Bend',
    toolActor: 'Actor',
    actorName: 'Name',
    actorProps: 'Props',
    noActors: 'No actors yet',
    toolCamera: 'Camera',
    cameraNumber: 'Camera Number',
    showNumber: 'Show Number',
    cameraModel: 'Camera Model',
    shotType: 'Shot Type',
    lens: 'Lens',
    viewfinder: 'Viewfinder',
    viewfinderNone: 'None',
    viewfinderSmall: 'Small',
    viewfinderBig: 'Big',
    headphones: 'Headset',
    headphonesNone: 'None',
    headphonesSingle: 'Single',
    headphonesDouble: 'Double',
    tripod: 'Tripod',
    tripodDescription: 'Tripod Description',
    wheels: 'Wheels',
    podium: 'Podium',
    podiumDescription: 'Podium Description',
    cameraLabelItem: 'Camera Number Label',
    goToCamera: 'Go to Camera',
    cameraNumberStyle: 'Camera Numbering',
    cameraNumberNumeric: '1, 2, 3...',
    cameraNumberAlphabetic: 'A, B, C...',
    cameraColor: 'Camera Color',
    description: 'Description',
    yes: 'Yes',
    cameraInfoDisplay: 'Camera info on canvas',
    allowResize: 'Allow resize',
    noCameras: 'No cameras yet',
    language: 'Language',
    languageUk: 'Українська',
    languageEn: 'English',
    settings: 'Settings',
    jpegOutput: 'JPEG Output',
    gridSection: 'Snapping Grid',
    uiSection: 'Interface',
    save: 'Save',
    paperSize: 'Paper size',
    orientation: 'Orientation',
    portrait: 'Portrait',
    landscape: 'Landscape',
    gridSizeLabel: 'Cell size',
    showGrid: 'Show grid',
    snapToGrid: 'Snap to grid',
    showBigGrid: 'Show m² grid',
    primaryColor: 'Primary color',
    pickColor: 'Pick a color',
    select: 'Select',
    openProject: 'Open project',
    saveAsProject: 'Save As...',
    saveError: 'Save error',
    openError: 'Failed to open file',
    saveToFilesHint: 'File will be saved in Files app → Set Planner',
    exportError: 'Export error',
    exportPdf: 'Save as PDF',
    pdfColViewfinder: 'VF',
    pdfColHeadphones: 'Headset',
    toggleCameraKit: 'Camera Kit',
    projectsSection: 'Projects',
    projectsFolder: 'Projects Folder',
    projectsFolderHint: 'Not set',
    untitled: 'Untitled',
    newProjectName: 'Project Name',
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