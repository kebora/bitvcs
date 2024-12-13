import 'dart:convert';
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
    Directory('.bitvcs/refs/heads').createSync();
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

//
void commit(String message) {
  final indexFile = File('.bitvcs/index');
  final headFile = File('.bitvcs/HEAD');

  // Ensure the repository is initialized
  if (!indexFile.existsSync() || !headFile.existsSync()) {
    print('Error: No repository found. Did you forget to initialize one?');
    return;
  }

  // Check if there are any staged changes
  final indexContent = indexFile.readAsStringSync().trim();
  if (indexContent.isEmpty) {
    print('No changes to commit.');
    return;
  }

  // Determine the current branch
  final headRef = headFile.readAsStringSync().trim();
  if (!headRef.startsWith('ref: ')) {
    print('Error: HEAD is not pointing to a branch.');
    return;
  }
  // Extract "refs/heads/main"
  final branch = headRef.substring(5); 
  final branchFile = File('.bitvcs/$branch');

  // Get parent commit hash (if any)
  final parentHash = branchFile.existsSync() ? branchFile.readAsStringSync().trim() : '';

  // Create commit object
  final commitContent = StringBuffer()
    ..writeln('commit')
    ..writeln('message: $message')
    ..writeln('parent: $parentHash')
    ..writeln('changes:')
    ..writeln(indexContent);

  // Compute hash for the commit
  final commitHash = sha1.convert(utf8.encode(commitContent.toString())).toString();

  // Write commit object to .bitvcs/objects
  final commitFile = File('.bitvcs/objects/$commitHash');
  commitFile.writeAsStringSync(commitContent.toString());

  // Update branch to point to new commit
  branchFile.writeAsStringSync(commitHash);

  // Clear the index (reset staging area)
  indexFile.writeAsStringSync('');

  print('Committed changes with hash: $commitHash');
}

//
void logCommitHistory() {
  final headFile = File('.bitvcs/HEAD');

  // Ensure repository is initialized
  if (!headFile.existsSync()) {
    print('Error: No repository found. Did you forget to initialize one?');
    return;
  }

  // Read the HEAD file to determine the current branch
  final headRef = headFile.readAsStringSync().trim();
  if (!headRef.startsWith('ref: ')) {
    print('Error: HEAD is not pointing to a branch.');
    return;
  }
  // Extract "refs/heads/main"
  final branch = headRef.substring(5);
  final branchFile = File('.bitvcs/$branch');

  // Ensure the branch file exists
  if (!branchFile.existsSync()) {
    print('No commits found in the current branch.');
    return;
  }

  // Start traversing the commit history
  String? currentHash = branchFile.readAsStringSync().trim();
  final commitObjectsDir = Directory('.bitvcs/objects');

  print('Commit history for branch: ${branch.split('/').last}\n');

  while (currentHash!.isNotEmpty) {
    final commitFile = File('${commitObjectsDir.path}/$currentHash');

    // Ensure the commit file exists
    if (!commitFile.existsSync()) {
      print('Error: Commit object $currentHash not found.');
      break;
    }

    // Read and parse the commit object
    final commitContent = commitFile.readAsStringSync();
    final lines = commitContent.split('\n');

    // Extract commit details
    final commitHash = currentHash;
    final message = lines.firstWhere((line) => line.startsWith('message: '), orElse: () => '').substring(9);
    final parentLine = lines.firstWhere((line) => line.startsWith('parent: '), orElse: () => '');
    currentHash = parentLine.isNotEmpty ? parentLine.substring(8) : ''; // Update to parent hash

    // Display commit information
    print('Commit: $commitHash');
    print('Message: $message');
    print('');
  }
}
//