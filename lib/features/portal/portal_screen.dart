import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/app_config.dart';
import '../../core/models/models.dart';
import '../../services/alert_api.dart';
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
    AlertSound.onOpened = (id) async {
      await _controller.runJavaScript(
        "window.__gmsOpenAlert && window.__gmsOpenAlert($id);",
      );
    };
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('GmsAlerts', onMessageReceived: (msg) => _onAlerts(msg.message))
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
    final since = await AlertApi.sinceId();
    _sinceId = since;
    await _controller.runJavaScript('''
(function(){
  if (window.__gmsAlertPoller) return;
  window.__gmsAlertPoller = true;
  var since = $since;
  function setBell(n){
    var el = document.getElementById('gms-alert-count');
    if (!el) return;
    n = parseInt(n, 10) || 0;
    el.textContent = n;
    el.style.display = n > 0 ? '' : 'none';
  }
  window.__gmsOpenAlert = function(id){
    fetch('/api/gms/mobile/mark_read', {
      method:'POST',
      credentials:'same-origin',
      headers:{'Content-Type':'application/json','Accept':'application/json'},
      body: JSON.stringify({ids:[id]})
    }).then(function(r){ return r.json(); }).then(function(j){
      if (j && typeof j.unread_count !== 'undefined') setBell(j.unread_count);
    }).catch(function(){});
  };
  document.addEventListener('click', function(e){
    var t = e.target;
    if (!t) return;
    if (t.id === 'gms-alert-bell' || (t.closest && t.closest('#gms-alert-bell'))) {
      fetch('/api/gms/mobile/mark_read', {
        method:'POST',
        credentials:'same-origin',
        headers:{'Content-Type':'application/json','Accept':'application/json'},
        body: JSON.stringify({ids:[]})
      }).then(function(r){ return r.json(); }).then(function(j){
        if (j && typeof j.unread_count !== 'undefined') setBell(j.unread_count);
      }).catch(function(){});
    }
  }, true);
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
          if (!j) return;
          if (typeof j.unread_count !== 'undefined') setBell(j.unread_count);
          if (window.GmsAlerts) GmsAlerts.postMessage(JSON.stringify(j));
          if (j.data && j.data.length) {
            for (var k=0;k<j.data.length;k++) {
              var id = parseInt(j.data[k].id, 10);
              if (id > since) since = id;
            }
          }
        })
        .catch(function(){ tryUrl(i+1); });
    })(0);
  }
  setTimeout(tick, 2000);
  setInterval(tick, 12000);
})();
''');
  }

  Future<void> _onAlerts(String raw) async {
    try {
      final payload = jsonDecode(raw);
      Map<String, dynamic> map;
      List<dynamic> list;
      if (payload is List) {
        map = {'unread_count': payload.length, 'data': payload, 'push_token': ''};
        list = payload;
      } else if (payload is Map) {
        map = Map<String, dynamic>.from(payload);
        list = map['data'] as List<dynamic>? ?? [];
      } else {
        return;
      }
      final token = '${map['push_token'] ?? ''}';
      if (token.isNotEmpty) await AlertApi.saveToken(token);
      final unread = int.tryParse('${map['unread_count'] ?? 0}') ?? 0;
      await AlertSound.setBadge(unread);
      for (final item in list) {
        if (item is! Map) continue;
        final alert = GmsAlert.fromJson(Map<String, dynamic>.from(item));
        if (alert.id <= _sinceId) continue;
        _sinceId = alert.id;
        await AlertApi.setSinceId(_sinceId);
        final isUnread = '${item['read_at'] ?? ''}'.isEmpty;
        if (isUnread) await AlertSound.play(alert, unread: unread);
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
              if (_loading) const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
      ),
    );
  }
}
