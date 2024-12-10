import 'dart:io';

//
void initRepository() {
  final bitDir = Directory('.bitvcs');
  if (bitDir.existsSync()) {
    print('Repository already initialized.');
  } else {
    bitDir.createSync();
    Directory('.bitvcs/objects').createSync();
    File('.bitvcs/index').createSync();
    File('.bitvcs/commits').createSync();
    print('Initialized empty repository in ${Directory.current.path}/.bitvcs');
  }
}
//
void addFiles(List<String> files){

}
