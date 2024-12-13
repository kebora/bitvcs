import 'dart:io';

import 'package:crypto/crypto.dart';

//
void initRepository() {
  final bitDir = Directory('.bitvcs');
  if (bitDir.existsSync()) {
    print('Repository already initialized.');
  } else {
    bitDir.createSync();
    //
    Directory('.bitvcs/objects').createSync();
    Directory('.bitvcs/refs').createSync();
    // main branch
    File('.bitvcs/HEAD').writeAsStringSync('ref: refs/heads/main');
    File('.bitvcs/index').createSync();
    File('.bitvcs/ignore').createSync();
    print('Initialized empty repository in ${Directory.current.path}/.bitvcs');
  }
}

//
void addFile(List<String> files) {
  final indexFile = File('.bitvcs/index');

  // Ensure the repository exists
  if (!indexFile.existsSync()) {
    print('Error: No repository found. Did you forget to initialize one?');
    return;
  }

  // Read the current index content
  final indexContent = indexFile.readAsStringSync();
  final updatedIndex = StringBuffer(indexContent);

  for (final filePath in files) {
    final file = File(filePath);

    // Check if file exists
    if (!file.existsSync()) {
      print('Warning: File "$filePath" does not exist.');
      continue;
    }

    // Compute the file's hash
    final fileContent = file.readAsBytesSync();
    final fileHash = sha1.convert(fileContent).toString();

    // Write the object to .bitvcs/objects/<hash>
    final objectPath = '.bitvcs/objects/$fileHash';
    final objectFile = File(objectPath);

    if (!objectFile.existsSync()) {
      objectFile.writeAsBytesSync(fileContent);
    }

    // Update the index
    final fileEntry = '$filePath $fileHash\n';
    if (!updatedIndex.toString().contains(fileEntry)) {
      updatedIndex.writeln(fileEntry.trim());
    }
  }

  // Write back the updated index
  indexFile.writeAsStringSync(updatedIndex.toString());

  print('Files added to staging area.');
}