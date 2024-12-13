import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

// initialize a new repo
void initRepository() {
  final bitDir = Directory('.bitvcs');
  if (bitDir.existsSync()) {
    print('Repository already initialized.');
  } else {
    bitDir.createSync();
    //
    Directory('.bitvcs/objects').createSync();
    Directory('.bitvcs/refs').createSync();
    Directory('.bitvcs/refs/heads').createSync();
    // main branch
    File('.bitvcs/HEAD').writeAsStringSync('ref: refs/heads/main');
    File('.bitvcs/index').createSync();
    File('.bitvcs/ignore').createSync();
    print('Initialized empty repository in ${Directory.current.path}/.bitvcs');
  }
}

// add a file(s) to staging area
void addFile(List<String> files) {
  final bitDir = Directory('.bitvcs');

  // Ensure repository is initialized
  if (!bitDir.existsSync()) {
    print('Error: No repository found. Did you forget to initialize one?');
    return;
  }

  final indexFile = File('.bitvcs/index');
  final objectsDir = Directory('.bitvcs/objects');

  // Read ignored patterns from .bitvcs/ignore
  final ignoreFile = File('.bitvcs/ignore');
  final ignorePatterns = ignoreFile.existsSync()
      ? ignoreFile.readAsLinesSync().where((line) => line.trim().isNotEmpty && !line.startsWith('#')).toList()
      : [];

  final ignoredGlobs = ignorePatterns.map((pattern) => Glob(pattern));

  for (final filePath in files) {
    final file = File(filePath);

    // Skip non-existent files
    if (!file.existsSync()) {
      print('Error: File "$filePath" does not exist.');
      continue;
    }

    // Skip ignored files
    final relativePath = file.path.replaceFirst('${Directory.current.path}/', '');
    if (ignoredGlobs.any((glob) => glob.matches(relativePath))) {
      print('Ignoring file: $relativePath');
      continue;
    }

    // Compute hash and stage the file
    final content = file.readAsBytesSync();
    final hash = sha1.convert(content).toString();

    final objectFile = File('${objectsDir.path}/$hash');
    if (!objectFile.existsSync()) {
      objectFile.writeAsBytesSync(content);
    }

    // Update the index
    final indexContent = indexFile.existsSync() ? indexFile.readAsStringSync() : '';
    final updatedIndexContent = _updateIndex(indexContent, filePath, hash);
    indexFile.writeAsStringSync(updatedIndexContent);

    print('Added file: $filePath');
  }
}

String _updateIndex(String indexContent, String filePath, String hash) {
  final lines = indexContent.split('\n').where((line) => line.trim().isNotEmpty).toList();

  // Replace existing entry for the file if it exists
  final updatedLines = [
    for (final line in lines)
      if (!line.startsWith('$filePath ')) line,
    '$filePath $hash',
  ];

  return updatedLines.join('\n');
}
// commit a file with a message
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
void createBranch(String branchName) {
  final headFile = File('.bitvcs/HEAD');

  // Ensure repository is initialized
  if (!headFile.existsSync()) {
    print('Error: No repository found. Did you forget to initialize one?');
    return;
  }

  // Read the HEAD file to determine the current branch and commit
  final headRef = headFile.readAsStringSync().trim();
  if (!headRef.startsWith('ref: ')) {
    print('Error: HEAD is not pointing to a branch.');
    return;
  }

  final currentBranchFile = File('.bitvcs/${headRef.substring(5)}');
  if (!currentBranchFile.existsSync()) {
    print('Error: Current branch does not have any commits.');
    return;
  }

  final currentCommit = currentBranchFile.readAsStringSync().trim();

  // Create the new branch file
  final newBranchFile = File('.bitvcs/refs/heads/$branchName');
  if (newBranchFile.existsSync()) {
    print('Error: Branch "$branchName" already exists.');
    return;
  }

  newBranchFile.writeAsStringSync(currentCommit);
  print('Branch "$branchName" created at commit $currentCommit.');
}
//
void cloneRepository(String destinationPath) {
  final sourceDir = Directory('.bitvcs');

  // Ensure the repository is initialized
  if (!sourceDir.existsSync()) {
    print('Error: No repository found. Did you forget to initialize one?');
    return;
  }

  // Ensure the destination directory is not inside the source
  if (Directory(destinationPath).absolute.path.startsWith(Directory.current.absolute.path)) {
    print('Error: Cannot clone into a subdirectory of the current repository.');
    return;
  }

  // Create the destination directory
  final destinationDir = Directory(destinationPath);
  if (destinationDir.existsSync()) {
    print('Error: Destination path already exists.');
    return;
  }

  destinationDir.createSync(recursive: true);

  // Recursively copy the repository files to the destination
  void copyDirectory(Directory source, Directory target) {
    for (var entity in source.listSync(recursive: false)) {
      if (entity is File) {
        final targetFile = File('${target.path}/${entity.uri.pathSegments.last}');
        targetFile.createSync(recursive: true);
        targetFile.writeAsBytesSync(entity.readAsBytesSync());
      } else if (entity is Directory) {
        final newDirectory = Directory('${target.path}/${entity.uri.pathSegments.last}');
        newDirectory.createSync();
        copyDirectory(entity, newDirectory);
      }
    }
  }

  copyDirectory(sourceDir, destinationDir);

  print('Repository cloned to $destinationPath');
}
//
void mergeBranch(String sourceBranch) {
  final headFile = File('.bitvcs/HEAD');

  // Ensure repository is initialized
  if (!headFile.existsSync()) {
    print('Error: No repository found. Did you forget to initialize one?');
    return;
  }

  // Read the HEAD file to determine the current branch
  final headRef = headFile.readAsStringSync().trim();
  if (!headRef.startsWith('ref: refs/heads/')) {
    print('Error: HEAD is not pointing to a branch.');
    return;
  }

  final targetBranch = headRef.substring(5); // Extract target branch (e.g., refs/heads/main)
  final targetBranchFile = File('.bitvcs/$targetBranch');
  final sourceBranchFile = File('.bitvcs/refs/heads/$sourceBranch');

  if (!sourceBranchFile.existsSync()) {
    print('Error: Source branch "$sourceBranch" does not exist.');
    return;
  }

  // Get the commit hashes
  final targetCommit = targetBranchFile.readAsStringSync().trim();
  final sourceCommit = sourceBranchFile.readAsStringSync().trim();

  // Find the common ancestor (simplified for linear history)
  final baseCommit = _findCommonAncestor(targetCommit, sourceCommit);
  if (baseCommit == null) {
    print('Error: No common ancestor found. Are these branches related?');
    return;
  }

  print('Merging branch "$sourceBranch" into "${targetBranch.split('/').last}"');
  print('Base commit: $baseCommit');

  // Perform the merge
  final targetFiles = _getFilesInCommit(targetCommit);
  final sourceFiles = _getFilesInCommit(sourceCommit);

  final mergedFiles = <String, String>{};
  bool hasConflicts = false;

  for (final file in {...targetFiles.keys, ...sourceFiles.keys}) {
    final baseContent = _getFileContentInCommit(baseCommit, file);
    final targetContent = targetFiles[file];
    final sourceContent = sourceFiles[file];

    if (targetContent == sourceContent) {
      // No changes or identical changes
      mergedFiles[file] = targetContent!;
    } else if (targetContent == baseContent) {
      // Target branch did not modify the file, take source changes
      mergedFiles[file] = sourceContent!;
    } else if (sourceContent == baseContent) {
      // Source branch did not modify the file, keep target changes
      mergedFiles[file] = targetContent!;
    } else {
      // Conflict: Both branches modified the file differently
      hasConflicts = true;
      final conflictContent = '''
<<<<<<< TARGET
$targetContent
=======
$sourceContent
>>>>>>> SOURCE
''';
      mergedFiles[file] = conflictContent;
      print('Conflict detected in file: $file');
    }
  }

  if (hasConflicts) {
    print('Merge completed with conflicts. Resolve conflicts before committing.');
  } else {
    // Write the merge commit
    final commitHash = _createMergeCommit(mergedFiles, sourceBranch, targetCommit);
    targetBranchFile.writeAsStringSync(commitHash);
    print('Merge completed successfully. New commit: $commitHash');
  }
}

String? _findCommonAncestor(String commit1, String commit2) {
  // Simplified implementation assuming linear history
  final visited = <String>{};
  String? current = commit1;

  while (current != null) {
    visited.add(current);
    current = _getParentCommit(current);
  }

  current = commit2;
  while (current != null) {
    if (visited.contains(current)) {
      return current;
    }
    current = _getParentCommit(current);
  }

  return null;
}

Map<String, String> _getFilesInCommit(String commitHash) {
  final commitFile = File('.bitvcs/objects/$commitHash');
  if (!commitFile.existsSync()) return {};

  final content = commitFile.readAsStringSync();
  final fileLines = content.split('\n').where((line) => line.startsWith('file: '));

  return {
    for (final line in fileLines)
      line.split(' ')[1]: line.split(' ')[2], // file: <filename> <hash>
  };
}

String? _getFileContentInCommit(String commitHash, String fileName) {
  final files = _getFilesInCommit(commitHash);
  final fileHash = files[fileName];
  if (fileHash == null) return null;

  final objectFile = File('.bitvcs/objects/$fileHash');
  return objectFile.existsSync() ? objectFile.readAsStringSync() : null;
}

String? _getParentCommit(String commitHash) {
  final commitFile = File('.bitvcs/objects/$commitHash');
  if (!commitFile.existsSync()) return null;

  final parentLine = commitFile
      .readAsLinesSync()
      .firstWhere((line) => line.startsWith('parent: '), orElse: () => '');
  return parentLine.isNotEmpty ? parentLine.substring(8) : null;
}

String _createMergeCommit(Map<String, String> mergedFiles, String sourceBranch, String parentHash) {
  final commitHash = sha1.convert(utf8.encode(DateTime.now().toIso8601String())).toString();
  final commitFile = File('.bitvcs/objects/$commitHash');

  final content = StringBuffer()
    ..writeln('parent: $parentHash')
    ..writeln('merged: refs/heads/$sourceBranch');

  for (final entry in mergedFiles.entries) {
    final fileHash = sha1.convert(utf8.encode(entry.value)).toString();
    File('.bitvcs/objects/$fileHash').writeAsStringSync(entry.value);
    content.writeln('file: ${entry.key} $fileHash');
  }

  commitFile.writeAsStringSync(content.toString());
  return commitHash;
}
