import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:miru_app/models/index.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/utils/request.dart';

class ExtensionRepoPageController extends GetxController {
  List<dynamic> extensions = <dynamic>[].obs;
  List<dynamic> extensionsTemp = <dynamic>[];

  final isLoading = false.obs;
  final isError = false.obs;
  final search = ''.obs;
  final Rx<ExtensionType?> searchType = Rx(null);

  List<dynamic> get displayExtensions {
    final query = search.value.toLowerCase().trim();
    final typeFilter = searchType.value;

    if (query.isEmpty && typeFilter == null) {
      return extensions;
    }

    final typeFilterStr = typeFilter?.toString().split('.').last;

    return extensions.where((e) {
      if (typeFilterStr != null) {
        final itemType = e['type']?.toString();
        if (itemType != typeFilterStr) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final name = (e['name'] ?? '').toString().toLowerCase();
        final package = (e['package'] ?? '').toString().toLowerCase();
        if (!name.contains(query) && !package.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  void onInit() {
    onRefresh();
    super.onInit();
  }

  onRefresh() async {
    isLoading.value = true;
    isError.value = false;

    try {
      final res = await dio.get<String>(
          '${MiruStorage.getSetting(SettingKey.miruRepoUrl)}/index.json');
      extensions = jsonDecode(res.data!);
      if (!MiruStorage.getSetting(SettingKey.enableNSFW)) {
        extensions.removeWhere((element) => element['nsfw'] == "true");
      }
      extensionsTemp.clear();
      extensionsTemp.addAll(extensions);
    } catch (e) {
      isError.value = true;
      debugPrint(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
