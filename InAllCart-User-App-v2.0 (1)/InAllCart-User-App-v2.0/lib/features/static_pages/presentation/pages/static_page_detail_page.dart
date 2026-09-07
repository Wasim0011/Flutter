import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../domain/entities/static_page.dart';

class StaticPageDetailPage extends StatefulWidget {
  final StaticPage page;

  const StaticPageDetailPage({super.key, required this.page});

  @override
  State<StaticPageDetailPage> createState() => _StaticPageDetailPageState();
}

class _StaticPageDetailPageState extends State<StaticPageDetailPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
      ))
      ..loadHtmlString(_buildHtml(widget.page.content));
  }

  String _buildHtml(String content) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 15px;
      line-height: 1.7;
      color: #1a1a1a;
      padding: 20px 16px 40px;
      background: #ffffff;
    }
    h1, h2, h3, h4 {
      font-weight: 700;
      margin: 20px 0 10px;
      color: #111;
    }
    h1 { font-size: 22px; }
    h2 { font-size: 18px; }
    h3 { font-size: 16px; }
    p { margin: 10px 0; color: #444; }
    ul, ol { padding-left: 20px; margin: 10px 0; }
    li { margin: 6px 0; color: #444; }
    a { color: #6200EE; text-decoration: none; }
    strong { color: #111; }
    hr { border: none; border-top: 1px solid #eee; margin: 20px 0; }
    blockquote {
      border-left: 3px solid #6200EE;
      padding-left: 12px;
      color: #666;
      margin: 12px 0;
    }
    table { width: 100%; border-collapse: collapse; margin: 12px 0; }
    th, td { border: 1px solid #ddd; padding: 8px 10px; text-align: left; }
    th { background: #f5f5f5; font-weight: 600; }
  </style>
</head>
<body>
$content
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalAppBar(title: widget.page.title),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
