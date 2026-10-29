import 'package:auto_updater/auto_updater.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Appcast.fromJson reads the items of a checked appcast', () {
    final appcast = Appcast.fromJson({
      'items': [
        {'versionString': '2.0.0'},
        {'versionString': '1.0.0'},
      ],
    });

    expect(appcast.items.map((item) => item.versionString), ['2.0.0', '1.0.0']);
  });

  test('UpdaterError keeps its message', () {
    expect(UpdaterError('no feed').toString(), 'UpdaterError: no feed');
  });
}
