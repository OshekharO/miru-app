import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/views/widgets/debug/extension_log_tile.dart';
import 'package:highlight/languages/json.dart';

// 待执行的方法
final List<Map<String, dynamic>> _methodList = [];
// 执行结果 key 和 completer
final Map<String, Completer> _resultMap = {};

// 调用方法 往方法列表里添加方法
Future<dynamic> callMethod(String method, [dynamic arguments]) async {
  final key = UniqueKey().toString();
  _methodList.add({
    "key": key,
    "method": method,
    "arguments": arguments,
  });
  // 等待结果
  final completer = Completer();
  _resultMap[key] = completer;
  final result = await completer.future;
  _resultMap.remove(key);
  return result;
}

class ExtensionDebugWindow extends StatefulWidget {
  const ExtensionDebugWindow({
    super.key,
    required this.windowController,
  });
  final WindowController windowController;

  @override
  State<ExtensionDebugWindow> createState() => _ExtensionDebugWindowState();
}

class _ExtensionDebugWindowState extends State<ExtensionDebugWindow> {
  final List<ExtensionLog> _logs = [];
  final Map<String, ExtensionNetworkLog> _networkLogs = {};

  // tab 列表
  final List<String> _tabs = [
    "Log",
    "Network",
    "Debug",
  ];
  // 当前选中的 tab
  String _currentTab = "Log";

  // 扩展列表
  final List<Extension> _extensions = [];

  // 选择的扩展
  Extension? _selectedExtension;

  @override
  void initState() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == "addLog") {
        final log = ExtensionLog.fromJson(jsonDecode(call.arguments));
        if (_selectedExtension == null) {
          setState(() {
            _logs.add(log);
          });
          return null;
        }
        if (_selectedExtension!.package == log.extension.package) {
          setState(() {
            _logs.add(log);
          });
        }
      }

      if (call.method == "addNetworkLog") {
        final args = jsonDecode(call.arguments);
        final key = args["key"];
        final log = ExtensionNetworkLog.fromJson(args["log"]);
        if (_selectedExtension == null) {
          setState(() {
            _networkLogs[key] = log;
          });
          return null;
        }
        if (_selectedExtension!.package == log.extension.package) {
          setState(() {
            _networkLogs[key] = log;
          });
        }
      }

      if (call.method == "state") {
        return "yes";
      }
      // 主窗口轮询，返回方法列表里的方法
      if (call.method == "getMethods") {
        final methods = [..._methodList];
        _methodList.clear();
        return methods;
      }

      // 主窗口返回执行结果
      if (call.method == "result") {
        final arg = call.arguments;
        final key = arg["key"];
        final result = arg["result"];
        final completer = _resultMap[key];
        if (completer != null) {
          completer.complete(
            result,
          );
        }
      }
    });
    _getInstalledExtensions();
    super.initState();
  }

  // 获取已安装扩展列表
  _getInstalledExtensions() async {
    final extensions = await callMethod("getInstalledExtensions");
    debugPrint(extensions.toString());
    List<dynamic> list = List<dynamic>.from(extensions);
    final extList = list.map((e) => Map<String, dynamic>.from(e)).toList();
    setState(() {
      _extensions.clear();
      _extensions.addAll(
        extList.map((e) => Extension.fromJson(e)).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final views = [
      ConsoleView(
        logs: _logs,
        onClear: () {
          setState(() {
            _logs.clear();
          });
        },
      ),
      NetworkView(
        logs: _networkLogs,
        onClear: () {
          setState(() {
            _networkLogs.clear();
          });
        },
      ),
      DebugView(
        selectedExtension: _selectedExtension,
      ),
    ];

    return FluentApp(
      debugShowCheckedModeBanner: false,
      theme: FluentThemeData.dark(),
      home: ScaffoldPage(
        header: PageHeader(
          title: Row(
            children: [
              const Icon(FluentIcons.bug, size: 20),
              const SizedBox(width: 8),
              const Text("Extension Debugger", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              // 获取扩展列表
              Button(
                onPressed: _getInstalledExtensions,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.refresh, size: 12),
                    SizedBox(width: 6),
                    Text("Refresh"),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 选择扩展
              SizedBox(
                width: 220,
                child: ComboBox<Extension>(
                  placeholder: const Text("Select Extension"),
                  onChanged: (value) {
                    setState(() {
                      _selectedExtension = value;
                    });
                  },
                  items: [
                    for (var ext in _extensions)
                      ComboBoxItem<Extension>(
                        value: ext,
                        child: Row(
                          children: [
                            Text(ext.name, overflow: TextOverflow.ellipsis),
                            const SizedBox(width: 6),
                            Text(
                              ext.package,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        ),
                      ),
                  ],
                  value: _selectedExtension,
                ),
              ),
              const SizedBox(width: 8),
              // 清空选择
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedExtension = null;
                  });
                },
                icon: const Icon(
                  FluentIcons.clear,
                  size: 12,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var tab in _tabs) ...[
                    ToggleButton(
                      checked: _currentTab == tab,
                      onChanged: (value) {
                        if (!value) return;
                        setState(() {
                          _currentTab = tab;
                        });
                      },
                      child: Text(tab),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const Divider(style: DividerThemeData(verticalMargin: EdgeInsets.symmetric(vertical: 8))),
            Expanded(
              child: IndexedStack(
                index: _tabs.indexOf(_currentTab),
                children: views,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsoleView extends StatefulWidget {
  const ConsoleView({
    super.key,
    required this.logs,
    this.onClear,
  });
  final List<ExtensionLog> logs;
  final VoidCallback? onClear;

  @override
  State<ConsoleView> createState() => _ConsoleViewState();
}

class _ConsoleViewState extends State<ConsoleView> {
  final ScrollController _controller = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<ExtensionLog> get logs => widget.logs;
  // 是否滚动到底部
  bool _isScrollToBottom = true;
  String _filterLevel = "All"; // "All", "Info", "Error"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant ConsoleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!_isScrollToBottom) {
        return;
      }
      scrollToBottom();
    });
  }

  // 滚动到底部
  void scrollToBottom() {
    if (!_controller.hasClients) {
      return;
    }
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ExtensionLog> get _filteredLogs {
    final query = _searchController.text.trim().toLowerCase();
    return logs.where((log) {
      if (_filterLevel == "Info" && log.level != ExtensionLogLevel.info) {
        return false;
      }
      if (_filterLevel == "Error" && log.level != ExtensionLogLevel.error) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesContent = log.content.toLowerCase().contains(query);
        final matchesName = log.extension.name.toLowerCase().contains(query);
        final matchesPkg = log.extension.package.toLowerCase().contains(query);
        if (!matchesContent && !matchesName && !matchesPkg) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: TextBox(
                  controller: _searchController,
                  placeholder: "Filter logs...",
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(FluentIcons.search, size: 12),
                  ),
                  suffix: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(FluentIcons.clear, size: 10),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              ComboBox<String>(
                value: _filterLevel,
                items: const [
                  ComboBoxItem(value: "All", child: Text("Level: All")),
                  ComboBoxItem(value: "Info", child: Text("Level: Info")),
                  ComboBoxItem(value: "Error", child: Text("Level: Error")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _filterLevel = val;
                    });
                  }
                },
              ),
              const Spacer(),
              Button(
                onPressed: widget.onClear,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.delete, size: 12),
                    SizedBox(width: 4),
                    Text("Clear"),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 自动滚动到底部
              ToggleButton(
                checked: _isScrollToBottom,
                onChanged: (value) {
                  setState(() {
                    _isScrollToBottom = value;
                  });
                },
                child: const Text("Auto Scroll"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text("No logs matching filter"))
              : ListView.builder(
                  controller: _controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return ExtensionLogTile(
                      key: ValueKey(filtered[index].time.millisecondsSinceEpoch.toString() + index.toString()),
                      log: filtered[index],
                    );
                  },
                ),
        )
      ],
    );
  }
}

class NetworkView extends StatefulWidget {
  const NetworkView({
    super.key,
    required this.logs,
    required this.onClear,
  });
  final Map<String, ExtensionNetworkLog> logs;
  final VoidCallback? onClear;

  @override
  State<NetworkView> createState() => _NetworkViewState();
}

class _NetworkViewState extends State<NetworkView> {
  String _selectLogKey = "";
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = "All"; // "All", "2xx", "Error", "Waiting"

  ExtensionNetworkLog? get _selectLog => widget.logs[_selectLogKey];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, ExtensionNetworkLog>> get _filteredLogs {
    final query = _searchController.text.trim().toLowerCase();
    return widget.logs.entries.where((entry) {
      final log = entry.value;
      if (_filterStatus == "2xx") {
        if (log.statusCode == null || log.statusCode! < 200 || log.statusCode! >= 300) {
          return false;
        }
      } else if (_filterStatus == "Error") {
        if (log.statusCode == null || (log.statusCode! >= 200 && log.statusCode! < 300)) {
          return false;
        }
      } else if (_filterStatus == "Waiting") {
        if (log.statusCode != null) {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final matchesUrl = log.url.toLowerCase().contains(query);
        final matchesMethod = log.method.toLowerCase().contains(query);
        if (!matchesUrl && !matchesMethod) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: TextBox(
                  controller: _searchController,
                  placeholder: "Filter requests...",
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(FluentIcons.search, size: 12),
                  ),
                  suffix: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(FluentIcons.clear, size: 10),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              ComboBox<String>(
                value: _filterStatus,
                items: const [
                  ComboBoxItem(value: "All", child: Text("Status: All")),
                  ComboBoxItem(value: "2xx", child: Text("Status: 2xx")),
                  ComboBoxItem(value: "Error", child: Text("Status: Error")),
                  ComboBoxItem(value: "Waiting", child: Text("Status: Waiting")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _filterStatus = val;
                    });
                  }
                },
              ),
              const Spacer(),
              Button(
                onPressed: widget.onClear,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.delete, size: 12),
                    SizedBox(width: 4),
                    Text("Clear"),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: widget.logs.isEmpty
              ? const Center(child: Text("No network logs"))
              : Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: filtered.isEmpty
                          ? const Center(child: Text("No requests match filter"))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final log = filtered[index];
                                final isSelected = _selectLogKey == log.key;
                                final isSuccess = log.value.statusCode != null &&
                                    log.value.statusCode! >= 200 &&
                                    log.value.statusCode! < 300;
                                final statusColor = log.value.statusCode == null
                                    ? Colors.orange
                                    : (isSuccess ? Colors.green : Colors.red);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: ListTile.selectable(
                                    selected: isSelected,
                                    selectionMode: ListTileSelectionMode.none,
                                    leading: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        log.value.statusCode == null ? "WAIT" : log.value.statusCode.toString(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      "${log.value.method.toUpperCase()} ${log.value.url.split('/').last.isEmpty ? log.value.url : log.value.url.split('/').last}",
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      log.value.url,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (_selectLogKey == log.key) {
                                          _selectLogKey = "";
                                          return;
                                        }
                                        _selectLogKey = log.key;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(direction: Axis.vertical),
                    Expanded(
                      flex: 3,
                      child: _selectLogKey.isNotEmpty && _selectLog != null
                          ? ListView(
                              padding: const EdgeInsets.all(12),
                              children: [
                                Card(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("URL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      SelectableText(_selectLog!.url, style: const TextStyle(fontSize: 13)),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text("Method: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          SelectableText(_selectLog!.method, style: const TextStyle(fontSize: 13)),
                                          const SizedBox(width: 20),
                                          const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          SelectableText(_selectLog!.statusCode?.toString() ?? "waiting", style: const TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_selectLog!.requestHeaders != null && _selectLog!.requestHeaders!.isNotEmpty) ...[
                                  Expander(
                                    header: const Text("Request Headers", style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        for (var header in _selectLog!.requestHeaders!.entries)
                                          SelectableText(
                                            "${header.key}: ${header.value}",
                                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (_selectLog!.requestBody != null && _selectLog!.requestBody.toString().isNotEmpty) ...[
                                  Expander(
                                    header: const Text("Request Body", style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: SelectableText(
                                      _selectLog!.requestBody.toString(),
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (_selectLog!.responseHeaders != null && _selectLog!.responseHeaders!.isNotEmpty) ...[
                                  Expander(
                                    header: const Text("Response Headers", style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        for (var header in _selectLog!.responseHeaders!.entries)
                                          SelectableText(
                                            "${header.key}: ${header.value}",
                                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Expander(
                                  initiallyExpanded: true,
                                  header: const Text("Response Body", style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: SelectableText(
                                    _selectLog!.responseBody ?? "",
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: Text("Select a request to view details"),
                            ),
                    ),
                  ],
                ),
        )
      ],
    );
  }
}

class DebugView extends StatefulWidget {
  const DebugView({
    super.key,
    required this.selectedExtension,
  });
  final Extension? selectedExtension;

  @override
  State<DebugView> createState() => _DebugViewState();
}

class _DebugViewState extends State<DebugView> {
  // 方法列表
  final Map<String, String> _methods = {
    "latest(page: number)": "Get latest data form search page",
    "search(keyword: string, page: number, filter: map)":
        "Search data by keyword",
    "detail(url: string)": "Get detail data by url",
    "createFilter(filter: map)": "Create filter by url",
    "watch(url: string)": "Watch data by url",
  };

  final _controller = TextEditingController();

  final _resultController = CodeController(
    language: json,
  );

  // 是否等待接收数据
  bool _isLoading = false;

  // 执行方法
  void execute() async {
    _isLoading = true;
    final method = _controller.text;
    if (method.isEmpty) {
      return;
    }
    final result = await callMethod("debugExecute", {
      "method": method,
      "package": widget.selectedExtension!.package,
    });
    debugPrint(result.toString());
    _resultController.text = result.toString();
    _isLoading = false;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedExtension == null) {
      return const Center(
        child: Text("No extension selected, please select an extension first"),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (var method in _methods.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ListTile.selectable(
                    title: Text(
                      method.key,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(method.value, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    onSelectionChange: (value) {
                      if (!value) {
                        return;
                      }
                      setState(() {
                        _controller.text = 'extension.${method.key}';
                      });
                    },
                  ),
                )
            ],
          ),
        ),
        const Divider(direction: Axis.vertical),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        placeholder: "e.g., extension.latest(1)",
                        controller: _controller,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Button(
                      onPressed: _isLoading
                          ? null
                          : () {
                              execute();
                            },
                      child: _isLoading
                          ? const ProgressRing(strokeWidth: 2)
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(FluentIcons.play, size: 12),
                                SizedBox(width: 4),
                                Text("Execute"),
                              ],
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Execution Result", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: material.MaterialApp(
                      debugShowCheckedModeBanner: false,
                      home: material.Scaffold(
                        backgroundColor: const Color(0xFF272822),
                        body: CodeTheme(
                          data: CodeThemeData(
                            styles: monokaiSublimeTheme,
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: CodeField(
                              controller: _resultController,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
