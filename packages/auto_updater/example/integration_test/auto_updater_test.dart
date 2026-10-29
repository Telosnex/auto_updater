import 'dart:async';
import 'dart:io';

import 'package:auto_updater/auto_updater.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// The appcast offers the version the app already has (sparkle:version 1, the
// build number of the example), so Sparkle finds no update and downloads and
// installs nothing.
const _appcast = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>auto_updater integration test</title>
    <item>
      <title>1.0.0</title>
      <sparkle:version>1</sparkle:version>
      <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
      <enclosure url="http://127.0.0.1/unused.zip" length="0" type="application/octet-stream"/>
    </item>
  </channel>
</rss>
''';

class _Listener with UpdaterListener {
  final checked = Completer<Appcast?>();
  final notAvailable = Completer<UpdaterError?>();
  final errors = <UpdaterError>[];

  @override
  void onUpdaterError(UpdaterError? error) {
    if (error != null) errors.add(error);
  }

  @override
  void onUpdaterCheckingForUpdate(Appcast? appcast) {
    if (!checked.isCompleted) checked.complete(appcast);
  }

  @override
  void onUpdaterUpdateAvailable(AppcastItem? appcastItem) {}

  @override
  void onUpdaterUpdateNotAvailable(UpdaterError? error) {
    if (!notAvailable.isCompleted) notAvailable.complete(error);
  }

  @override
  void onUpdaterUpdateDownloaded(AppcastItem? appcastItem) {}

  @override
  void onUpdaterBeforeQuitForUpdate(AppcastItem? appcastItem) {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response
        ..headers.contentType = ContentType('application', 'xml')
        ..write(_appcast)
        ..close();
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  test(
    'checks a local appcast in the background and finds no update',
    () async {
      final listener = _Listener();
      autoUpdater.addListener(listener);
      addTearDown(() => autoUpdater.removeListener(listener));

      await autoUpdater.setFeedURL(
        'http://127.0.0.1:${server.port}/appcast.xml',
      );
      await autoUpdater.checkForUpdates(inBackground: true);

      final appcast = await listener.checked.future.timeout(
        const Duration(seconds: 60),
      );
      expect(appcast?.items, isNotEmpty);

      await listener.notAvailable.future.timeout(const Duration(seconds: 60));
      expect(listener.errors, isEmpty);
    },
  );
}
