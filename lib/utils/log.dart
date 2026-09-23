import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:miru_app/utils/miru_directory.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:path/path.dart' as path;

final logger = Logger('Miru');

class MiruLog {
  static final logFilePath = path.join(MiruDirectory.getDirectory, 'miru.log');

  static void ensureInitialized() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final log =
          '${record.loggerName} ${record.level.name} ${record.time}: ${record.message} ${record.error ?? ''} ${record.stackTrace ?? ''}';
      // 如果是开发环境则打印到控制台
      if (kReleaseMode) {
        writeLogToFile(log);
        return;
      }

      debugPrint(log);
    });
  }

  // 写入日志到文件
  static void writeLogToFile(String log) async {
    if (!MiruStorage.getSetting(SettingKey.saveLog)) {
      return;
    }
    try {
      final file = File(logFilePath);
      await file.writeAsString('$log\n', mode: FileMode.append);
      if (await file.length() > 1024 * 1024 * 10) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Error writing log to file: $e");
    }
  }
}
