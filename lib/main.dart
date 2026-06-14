import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'editor_controller.dart';
import 'l10n/app_strings.dart';
import 'ui/top_menu_bar.dart';
import 'ui/tool_bar.dart';
import 'ui/drawing_canvas.dart';
import 'ui/properties_panel.dart';

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

class _EditorScreenState extends State<EditorScreen> {
  final EditorController _controller = EditorController();
  bool _panelVisible = true;
  final FocusNode _rootFocus = FocusNode();
  bool _wasEditing = false;
  String _appliedLanguage = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
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

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
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
                    Expanded(flex: 4, child: DrawingCanvas(controller: _controller)),
                    _panelToggle(),
                    if (_panelVisible)
                      Expanded(flex: 1, child: PropertiesPanel(controller: _controller)),
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

  // Клавіатура (на компʼютері): Delete / Backspace видаляють вибраний елемент.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    // Під час редагування тексту клавіші належать полю вводу, а не видаленню елемента.
    if (_controller.isEditingText) return KeyEventResult.ignored;

    final isDelete = event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace;
    if (event is KeyDownEvent && isDelete && _controller.selectedItem != null) {
      _controller.deleteSelected();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // Вузька смужка-перемикач показу правої панелі.
  Widget _panelToggle() {
    return GestureDetector(
      onTap: () => setState(() => _panelVisible = !_panelVisible),
      child: Container(
        width: 22,
        color: const Color(0xFFB0BEC5),
        alignment: Alignment.center,
        child: Icon(_panelVisible ? Icons.chevron_right : Icons.chevron_left, size: 18),
      ),
    );
  }
}