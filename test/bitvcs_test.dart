import 'dart:io';

import 'package:test/test.dart';

void main() {
  //
  test('initialize repository', () async {
    final testDir = Directory('.testvcs');
  if (testDir.existsSync()) {
    // delete any already existing folder
    await testDir.delete().then((x)=>{
      testDir.createSync()
    });
  } else {
    testDir.createSync();
  }
  //check whether folder is created
  final testDirExists = await testDir.exists();
  //
  expect(testDirExists, isTrue ,reason: "A repository could be initialized successfully!");
  });
  //
    
}
