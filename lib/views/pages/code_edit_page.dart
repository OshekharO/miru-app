import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/nord.dart';
import 'package:flutter_highlight/themes/tomorrow-night.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/utils/extension.dart';
import 'package:miru_app/views/widgets/messenger.dart';

class SaveIntent extends Intent {
  const SaveIntent();
}

class ToggleSearchIntent extends Intent {
  const ToggleSearchIntent();
}

class CodeEditPage extends StatefulWidget {
  const CodeEditPage({
    required this.extension,
    super.key,
  });

  final Extension extension;

  @override
  State<CodeEditPage> createState() => _CodeEditPageState();
}

class _CodeEditPageState extends State<CodeEditPage> {
  late CodeController controller;
  final FocusNode focusNode = FocusNode();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController replaceController = TextEditingController();

  String _initialText = '';
  bool _isModified = false;

  bool _isWrap = false;
  double _fontSize = 14.0;
  String _selectedThemeName = 'Monokai Sublime';

  bool _showSearch = false;
  List<int> _searchMatches = [];
  int _currentMatchIndex = -1;

  final Map<String, Map<String, TextStyle>> _themes = {
    'Monokai Sublime': monokaiSublimeTheme,
    'Atom One Dark': atomOneDarkTheme,
    'VS2015': vs2015Theme,
    'Dracula': draculaTheme,
    'Nord': nordTheme,
    'Tomorrow Night': tomorrowNightTheme,
    'GitHub (Light)': githubTheme,
  };

  final List<String> _quickSymbols = [
    '{',
    '}',
    '(',
    ')',
    '[',
    ']',
    ';',
    '=',
    '=>',
    '.',
    '"',
    "'",
    '+',
    '-',
  ];

  @override
  void initState() {
    super.initState();
    controller = CodeController(
      language: javascript,
    );

    controller.addListener(_onCodeChanged);
    searchController.addListener(_performSearch);

    _init();
  }

  Future<void> _init() async {
    final dir = ExtensionUtils.extensionsDir;
    final file = File('$dir/${widget.extension.package}.js');
    if (await file.exists()) {
      final content = await file.readAsString();
      controller.text = content;
      _initialText = content;
      if (mounted) {
        setState(() {
          _isModified = false;
        });
      }
    }
  }

  void _onCodeChanged() {
    final modified = controller.text != _initialText;
    if (modified != _isModified) {
      setState(() {
        _isModified = modified;
      });
    } else {
      // Force status bar update for cursor position
      setState(() {});
    }
    if (_showSearch && searchController.text.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onCodeChanged);
    controller.dispose();
    searchController.dispose();
    replaceController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final dir = ExtensionUtils.extensionsDir;
    final file = File('$dir/${widget.extension.package}.js');
    await file.writeAsString(controller.text);
    _initialText = controller.text;
    if (mounted) {
      setState(() {
        _isModified = false;
      });
      showPlatformSnackbar(
        context: context,
        title: 'Save Code',
        content: 'Code saved successfully',
      );
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    if (!_isModified) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Do you want to save before exiting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _save();
      return true;
    } else if (result == 'discard') {
      return true;
    }
    return false;
  }

  void _insertSymbol(String symbol) {
    final selection = controller.selection;
    final text = controller.text;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;

    final newText = text.replaceRange(start, end, symbol);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + symbol.length),
    );
    focusNode.requestFocus();
  }

  void _foldAll() {
    for (final block in controller.code.foldableBlocks) {
      controller.foldAt(block.firstLine);
    }
  }

  void _unfoldAll() {
    for (final block in controller.code.foldableBlocks) {
      controller.unfoldAt(block.firstLine);
    }
  }

  void _performSearch() {
    final query = searchController.text;
    if (query.isEmpty) {
      setState(() {
        _searchMatches = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    final matches = <int>[];
    final text = controller.text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int index = text.indexOf(lowerQuery);

    while (index != -1) {
      matches.add(index);
      index = text.indexOf(lowerQuery, index + lowerQuery.length);
    }

    setState(() {
      _searchMatches = matches;
      if (matches.isNotEmpty) {
        if (_currentMatchIndex < 0 || _currentMatchIndex >= matches.length) {
          _currentMatchIndex = 0;
        }
        _highlightMatch(_currentMatchIndex);
      } else {
        _currentMatchIndex = -1;
      }
    });
  }

  void _highlightMatch(int matchIdx) {
    if (matchIdx < 0 || matchIdx >= _searchMatches.length) return;
    final start = _searchMatches[matchIdx];
    final length = searchController.text.length;
    controller.selection = TextSelection(
      baseOffset: start,
      extentOffset: start + length,
    );
  }

  void _nextMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
      _highlightMatch(_currentMatchIndex);
    });
  }

  void _prevMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatches.length) %
          _searchMatches.length;
      _highlightMatch(_currentMatchIndex);
    });
  }

  void _replace() {
    if (_currentMatchIndex < 0 || _currentMatchIndex >= _searchMatches.length) {
      return;
    }
    final start = _searchMatches[_currentMatchIndex];
    final queryLen = searchController.text.length;
    final replaceText = replaceController.text;

    final newText = controller.text.replaceRange(
      start,
      start + queryLen,
      replaceText,
    );
    controller.text = newText;
    _performSearch();
  }

  void _replaceAll() {
    final query = searchController.text;
    if (query.isEmpty) return;
    final replaceText = replaceController.text;
    final newText = controller.text.replaceAll(query, replaceText);
    controller.text = newText;
    _performSearch();
  }

  (int line, int col) _getCursorPosition() {
    final selection = controller.selection;
    if (selection.start < 0 || selection.start > controller.text.length) {
      return (1, 1);
    }
    final textBefore = controller.text.substring(0, selection.start);
    final lines = textBefore.split('\n');
    return (lines.length, lines.last.length + 1);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _themes[_selectedThemeName] ?? monokaiSublimeTheme;
    final (cursorLine, cursorCol) = _getCursorPosition();
    final totalLines = controller.text.split('\n').length;
    final totalChars = controller.text.length;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
            const SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const ToggleSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF):
            const ToggleSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (intent) => _save(),
          ),
          ToggleSearchIntent: CallbackAction<ToggleSearchIntent>(
            onInvoke: (intent) {
              setState(() {
                _showSearch = !_showSearch;
              });
              return null;
            },
          ),
        },
        child: PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.extension.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isModified) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Text(
                        'Unsaved',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Search / Replace (Ctrl+F)',
                  icon: Icon(
                    Icons.search,
                    color: _showSearch ? Theme.of(context).primaryColor : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                    });
                  },
                ),
                IconButton(
                  tooltip: 'Save (Ctrl+S)',
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                ),
              ],
            ),
            body: Column(
              children: [
                // Toolbar
                Container(
                  color: Theme.of(context).cardColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Undo (Ctrl+Z)',
                          icon: const Icon(Icons.undo, size: 20),
                          onPressed: () {
                            controller.historyController.undo();
                          },
                        ),
                        IconButton(
                          tooltip: 'Redo (Ctrl+Y)',
                          icon: const Icon(Icons.redo, size: 20),
                          onPressed: () {
                            controller.historyController.redo();
                          },
                        ),
                        const VerticalDivider(width: 16),
                        IconButton(
                          tooltip: 'Fold All',
                          icon: const Icon(Icons.unfold_less, size: 20),
                          onPressed: _foldAll,
                        ),
                        IconButton(
                          tooltip: 'Unfold All',
                          icon: const Icon(Icons.unfold_more, size: 20),
                          onPressed: _unfoldAll,
                        ),
                        const VerticalDivider(width: 16),
                        IconButton(
                          tooltip:
                              _isWrap ? 'Disable Word Wrap' : 'Enable Word Wrap',
                          icon: Icon(
                            _isWrap ? Icons.wrap_text : Icons.notes,
                            size: 20,
                            color: _isWrap
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          onPressed: () {
                            setState(() {
                              _isWrap = !_isWrap;
                            });
                          },
                        ),
                        const VerticalDivider(width: 16),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Decrease Font Size',
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () {
                                if (_fontSize > 10) {
                                  setState(() => _fontSize -= 1);
                                }
                              },
                            ),
                            Text(
                              '${_fontSize.toInt()}px',
                              style: const TextStyle(fontSize: 12),
                            ),
                            IconButton(
                              tooltip: 'Increase Font Size',
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                if (_fontSize < 30) {
                                  setState(() => _fontSize += 1);
                                }
                              },
                            ),
                          ],
                        ),
                        const VerticalDivider(width: 16),
                        DropdownButton<String>(
                          value: _selectedThemeName,
                          isDense: true,
                          underline: const SizedBox(),
                          style: Theme.of(context).textTheme.bodySmall,
                          items: _themes.keys.map((String theme) {
                            return DropdownMenuItem<String>(
                              value: theme,
                              child: Text(theme),
                            );
                          }).toList(),
                          onChanged: (String? newTheme) {
                            if (newTheme != null) {
                              setState(() {
                                _selectedThemeName = newTheme;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Search Panel
                if (_showSearch) ...[
                  Container(
                    color: Theme.of(context).cardColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Find',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _searchMatches.isNotEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              '${_currentMatchIndex + 1}/${_searchMatches.length}',
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Previous Match',
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              onPressed: _prevMatch,
                            ),
                            IconButton(
                              tooltip: 'Next Match',
                              icon: const Icon(Icons.arrow_downward, size: 18),
                              onPressed: _nextMatch,
                            ),
                            IconButton(
                              tooltip: 'Close Search',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _showSearch = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: TextField(
                                  controller: replaceController,
                                  decoration: const InputDecoration(
                                    hintText: 'Replace with',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _replace,
                              child: const Text('Replace'),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              onPressed: _replaceAll,
                              child: const Text('Replace All'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],

                // Quick Symbols Bar
                Container(
                  color: Theme.of(context).cardColor,
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickSymbols.length,
                    itemBuilder: (context, index) {
                      final symbol = _quickSymbols[index];
                      return InkWell(
                        onTap: () => _insertSymbol(symbol),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          child: Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),

                // Code Editor Container
                Expanded(
                  child: CodeTheme(
                    data: CodeThemeData(styles: themeData),
                    child: CodeField(
                      controller: controller,
                      focusNode: focusNode,
                      wrap: _isWrap,
                      expands: true,
                      textStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: _fontSize,
                      ),
                    ),
                  ),
                ),

                const Divider(height: 1),
                // Status Bar
                Container(
                  color: Theme.of(context).cardColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Ln $cursorLine, Col $cursorCol',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        '$totalLines lines, $totalChars chars',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
