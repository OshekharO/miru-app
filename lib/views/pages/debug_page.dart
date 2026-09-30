import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Row(
            children: [
              Icon(Icons.bug_report_rounded, size: 24),
              SizedBox(width: 10),
              Text("Extension Debugger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          actions: [
            IconButton.filledTonal(
              tooltip: "Refresh Extensions",
              onPressed: _getInstalledExtensions,
              icon: const Icon(Icons.refresh_rounded, size: 18),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<Extension>(
                value: _selectedExtension,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelText: "Filter Extension",
                ),
                items: [
                  for (var ext in _extensions)
                    DropdownMenuItem<Extension>(
                      value: ext,
                      child: Text(
                        ext.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    )
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedExtension = val;
                  });
                },
              ),
            ),
            if (_selectedExtension != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: "Clear Extension Filter",
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  setState(() {
                    _selectedExtension = null;
                  });
                },
              ),
            ],
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<String>(
                segments: [
                  for (var tab in _tabs)
                    ButtonSegment<String>(
                      value: tab,
                      label: Text(tab, style: const TextStyle(fontWeight: FontWeight.bold)),
                      icon: Icon(
                        tab == "Log"
                            ? Icons.terminal_rounded
                            : (tab == "Network" ? Icons.language_rounded : Icons.code_rounded),
                        size: 18,
                      ),
                    ),
                ],
                selected: {_currentTab},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _currentTab = newSelection.first;
                  });
                },
              ),
            ),
            const Divider(height: 1),
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
  bool _isScrollToBottom = true;
  String _filterLevel = "All";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant ConsoleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isScrollToBottom) {
        scrollToBottom();
      }
    });
  }

  void scrollToBottom() {
    if (!_controller.hasClients) {
      return;
    }
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
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
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _searchController,
                  hintText: "Search logs...",
                  leading: const Icon(Icons.search_rounded, size: 20),
                  trailing: _searchController.text.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        ]
                      : null,
                  onChanged: (_) => setState(() {}),
                  elevation: MaterialStateProperty.all(1),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 6,
                children: [
                  FilterChip(
                    label: const Text("All"),
                    selected: _filterLevel == "All",
                    onSelected: (_) => setState(() => _filterLevel = "All"),
                  ),
                  FilterChip(
                    label: const Text("Info"),
                    selected: _filterLevel == "Info",
                    onSelected: (_) => setState(() => _filterLevel = "Info"),
                  ),
                  FilterChip(
                    label: const Text("Error"),
                    selected: _filterLevel == "Error",
                    onSelected: (_) => setState(() => _filterLevel = "Error"),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: "Clear Logs",
                onPressed: widget.onClear,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: Icon(
                  _isScrollToBottom ? Icons.south_rounded : Icons.swap_vert_rounded,
                  size: 16,
                ),
                label: const Text("Auto Scroll"),
                selected: _isScrollToBottom,
                onSelected: (val) {
                  setState(() {
                    _isScrollToBottom = val;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    "No logs available",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _controller,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
  String _filterStatus = "All";

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
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _searchController,
                  hintText: "Filter request URLs...",
                  leading: const Icon(Icons.search_rounded, size: 20),
                  trailing: _searchController.text.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        ]
                      : null,
                  onChanged: (_) => setState(() {}),
                  elevation: MaterialStateProperty.all(1),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (var status in ["All", "2xx", "Error", "Waiting"])
                    FilterChip(
                      label: Text(status),
                      selected: _filterStatus == status,
                      onSelected: (_) => setState(() => _filterStatus = status),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: "Clear Requests",
                onPressed: widget.onClear,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.logs.isEmpty
              ? Center(
                  child: Text(
                    "No network activity recorded",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
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
                                    ? Colors.amber
                                    : (isSuccess ? Colors.green : theme.colorScheme.error);

                                return Card(
                                  elevation: isSelected ? 2 : 0,
                                  color: isSelected
                                      ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                                      : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outlineVariant.withOpacity(0.4),
                                    ),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    leading: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        log.value.statusCode?.toString() ?? "WAIT",
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
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      log.value.url,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectLogKey = _selectLogKey == log.key ? "" : log.key;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 3,
                      child: _selectLogKey.isNotEmpty && _selectLog != null
                          ? ListView(
                              padding: const EdgeInsets.all(12),
                              children: [
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("URL", style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        SelectableText(_selectLog!.url, style: theme.textTheme.bodyMedium),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Text("Method: ", style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                                            SelectableText(_selectLog!.method, style: theme.textTheme.bodyMedium),
                                            const SizedBox(width: 24),
                                            Text("Status: ", style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                                            SelectableText(_selectLog!.statusCode?.toString() ?? "waiting", style: theme.textTheme.bodyMedium),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_selectLog!.requestHeaders != null && _selectLog!.requestHeaders!.isNotEmpty)
                                  _buildExpanderCard(
                                    theme,
                                    title: "Request Headers",
                                    child: Column(
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
                                if (_selectLog!.requestBody != null && _selectLog!.requestBody.toString().isNotEmpty)
                                  _buildExpanderCard(
                                    theme,
                                    title: "Request Body",
                                    child: SelectableText(
                                      _selectLog!.requestBody.toString(),
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                    ),
                                  ),
                                if (_selectLog!.responseHeaders != null && _selectLog!.responseHeaders!.isNotEmpty)
                                  _buildExpanderCard(
                                    theme,
                                    title: "Response Headers",
                                    child: Column(
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
                                _buildExpanderCard(
                                  theme,
                                  title: "Response Body",
                                  initiallyExpanded: true,
                                  child: SelectableText(
                                    _selectLog!.responseBody ?? "",
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Text(
                                "Select a request to view details",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
        )
      ],
    );
  }

  Widget _buildExpanderCard(ThemeData theme, {required String title, required Widget child, bool initiallyExpanded = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.all(12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [child],
      ),
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

  bool _isLoading = false;

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
    final theme = Theme.of(context);

    if (widget.selectedExtension == null) {
      return Center(
        child: Text(
          "No extension selected, please select an extension first",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (var method in _methods.entries)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(
                      method.key,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(method.value, style: theme.textTheme.bodySmall),
                    onTap: () {
                      setState(() {
                        _controller.text = 'extension.${method.key}';
                      });
                    },
                  ),
                )
            ],
          ),
        ),
        const VerticalDivider(width: 1),
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
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "e.g., extension.latest(1)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : execute,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text("Execute"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text("Execution Result", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFF272822),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CodeTheme(
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
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
