import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/app_config.dart';
import '../../core/models/models.dart';
import '../../services/alert_sound.dart';

class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  late final WebViewController _controller;
  var _loading = true;
  var _sinceId = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'GmsAlerts',
        onMessageReceived: (msg) => _onAlerts(msg.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
            _injectAlertPoller();
          },
        ),
      )
      ..loadRequest(Uri.parse(AppConfig.portalUrl));
  }

  Future<void> _injectAlertPoller() async {
    await _controller.runJavaScript('''
(function(){
  if (window.__gmsAlertPoller) return;
  window.__gmsAlertPoller = true;
  var since = $_sinceId;
  function tick(){
    var urls = [
      '/api/gms/mobile/session_alerts?since_id=' + since,
      '/api/gms/mobile/session_alerts.html?since_id=' + since
    ];
    (function tryUrl(i){
      if (i >= urls.length) return;
      fetch(urls[i], {credentials:'same-origin', headers:{'Accept':'application/json'}})
        .then(function(r){ return r.text(); })
        .then(function(t){
          if (!t || t.charAt(0) === '<') { tryUrl(i+1); return; }
          var j = JSON.parse(t);
          if (j && j.data && j.data.length) {
            for (var k=0;k<j.data.length;k++) {
              var id = parseInt(j.data[k].id, 10);
              if (id > since) since = id;
            }
            if (window.GmsAlerts) GmsAlerts.postMessage(JSON.stringify(j.data));
          }
        })
        .catch(function(){ tryUrl(i+1); });
    })(0);
  }
  setTimeout(tick, 2500);
  setInterval(tick, 12000);
})();
''');
  }

  Future<void> _onAlerts(String raw) async {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        if (item is! Map) continue;
        final alert = GmsAlert.fromJson(Map<String, dynamic>.from(item));
        if (alert.id <= _sinceId) continue;
        _sinceId = alert.id;
        await AlertSound.play(alert);
      }
    } catch (_) {}
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
      ),
    );
  }
}
