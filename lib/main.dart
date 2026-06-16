import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'editor_controller.dart';
import 'l10n/app_strings.dart';
import 'ui/top_menu_bar.dart';
import 'ui/tool_bar.dart';
import 'ui/drawing_canvas.dart';
import 'ui/properties_panel.dart';
import 'ui/camera_list_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Обираємо мову за налаштуваннями системи (поки uk або en).
  final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  strings = AppStrings.of(lang);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const SetPlannerApp());
}

class SetPlannerApp extends StatelessWidget {
  const SetPlannerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const EditorScreen(),
    );
  }
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with TickerProviderStateMixin {
  final EditorController _controller = EditorController();
  bool _panelVisible = true;
  bool _cameraListVisible = true;
  final FocusNode _rootFocus = FocusNode();
  bool _wasEditing = false;
  String _appliedLanguage = '';

  late final AnimationController _cameraListAC;
  late final AnimationController _propsPanelAC;
  late final Animation<double> _cameraListAnim;
  late final Animation<double> _propsPanelAnim;

  static const double _sidePanelWidth = 240.0;
  static const Duration _slideDuration = Duration(milliseconds: 260);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);

    _cameraListAC = AnimationController(
      vsync: this,
      duration: _slideDuration,
      value: 1.0,
    );
    _cameraListAnim = CurvedAnimation(
      parent: _cameraListAC,
      curve: Curves.easeInOut,
    );

    _propsPanelAC = AnimationController(
      vsync: this,
      duration: _slideDuration,
      value: 1.0,
    );
    _propsPanelAnim = CurvedAnimation(
      parent: _propsPanelAC,
      curve: Curves.easeInOut,
    );
  }

  // Коли вийшли з редагування тексту — повертаємо фокус головному обробнику клавіш.
  void _onControllerChanged() {
    final editing = _controller.isEditingText;
    if (_wasEditing && !editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rootFocus.requestFocus();
      });
    }
    _wasEditing = editing;

    final newLang = _controller.settings.language;
    if (newLang != _appliedLanguage) {
      _appliedLanguage = newLang;
      setState(() {});
    }
  }

  void _toggleCameraList() {
    setState(() => _cameraListVisible = !_cameraListVisible);
    if (_cameraListVisible) {
      _cameraListAC.forward();
    } else {
      _cameraListAC.reverse();
    }
  }

  void _togglePropsPanel() {
    setState(() => _panelVisible = !_panelVisible);
    if (_panelVisible) {
      _propsPanelAC.forward();
    } else {
      _propsPanelAC.reverse();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _cameraListAC.dispose();
    _propsPanelAC.dispose();
    _rootFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _rootFocus,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TopMenuBar(controller: _controller),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizeTransition(
                      sizeFactor: _cameraListAnim,
                      axis: Axis.horizontal,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        heightFactor: 1.0,
                        child: SizedBox(
                          width: _sidePanelWidth,
                          child: CameraListPanel(controller: _controller),
                        ),
                      ),
                    ),
                    _cameraListToggle(),
                    Expanded(flex: 4, child: DrawingCanvas(controller: _controller)),
                    _panelToggle(),
                    SizeTransition(
                      sizeFactor: _propsPanelAnim,
                      axis: Axis.horizontal,
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        heightFactor: 1.0,
                        child: SizedBox(
                          width: _sidePanelWidth,
                          child: PropertiesPanel(controller: _controller),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ToolBar(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }

  // Клавіатура (на компʼютері): глобальні гарячі клавіші.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    // Якщо фокус не на кореневому вузлі — значить якийсь TextField (пропс-панель,
    // редактор тексту на канвасі тощо) отримав його раніше. Ігноруємо.
    if (!node.hasPrimaryFocus) return KeyEventResult.ignored;
    if (_controller.isEditingText) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final hw = HardwareKeyboard.instance;
    final isMod = hw.isControlPressed || hw.isMetaPressed; // Ctrl (Win/Linux) або Cmd (Mac)
    final isShift = hw.isShiftPressed;

    // ── Cmd/Ctrl + клавіша ────────────────────────────────────────────────
    if (isMod) {
      switch (key) {
        case LogicalKeyboardKey.keyZ:
          isShift ? _controller.redo() : _controller.undo();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyY:
          _controller.redo();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyC:
          _controller.copySelected();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyX:
          _controller.cutSelected();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyV:
          _controller.pasteClipboard();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyA:
          _controller.selectAll();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyD:
          _controller.duplicate();
          return KeyEventResult.handled;
        default:
          break;
      }
    }

    // ── Escape ────────────────────────────────────────────────────────────
    if (key == LogicalKeyboardKey.escape) {
      _controller.escapeAction();
      return KeyEventResult.handled;
    }

    // ── Delete / Backspace ────────────────────────────────────────────────
    final isDelete = key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace;
    if (isDelete && _controller.hasSelection) {
      _controller.deleteSelected();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // Вузька смужка-перемикач показу правої панелі.
  Widget _cameraListToggle() {
    return GestureDetector(
      onTap: _toggleCameraList,
      child: Container(
        width: 22,
        color: const Color(0xFFB0BEC5),
        alignment: Alignment.center,
        child: Icon(
          _cameraListVisible ? Icons.chevron_left : Icons.chevron_right,
          size: 18,
        ),
      ),
    );
  }

  Widget _panelToggle() {
    return GestureDetector(
      onTap: _togglePropsPanel,
      child: Container(
        width: 22,
        color: const Color(0xFFB0BEC5),
        alignment: Alignment.center,
        child: Icon(_panelVisible ? Icons.chevron_right : Icons.chevron_left, size: 18),
      ),
    );
  }
}