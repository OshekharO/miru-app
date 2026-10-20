import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';

class AnilistWebViewPage extends StatefulWidget {
  const AnilistWebViewPage({
    super.key,
    required this.url,
  });
  final String url;

  @override
  State<AnilistWebViewPage> createState() => _AnilistWebViewPageState();
}

class _AnilistWebViewPageState extends State<AnilistWebViewPage> {
  late String url = widget.url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anilist Login"),
      ),
      body: Webview(
        url: url,
      ),
    );
  }
}
