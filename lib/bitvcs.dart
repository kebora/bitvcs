import 'dart:io';

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
void addFiles(List<String> files){
    if (files.isEmpty) {
    print('No files specified to add.');
    return;
  }

  final indexFile = File('.bitvcs/index');
  if (!indexFile.existsSync()) {
    print('Error: Repository not initialized. Run "bitvcs init".');
    return;
  }

  final currentIndex = indexFile.readAsStringSync().split('\n').where((line) => line.isNotEmpty).toList();
  currentIndex.addAll(files);
  indexFile.writeAsStringSync('${currentIndex.join('\n')}\n');
  print('Added files: ${files.join(', ')}');
}

//
