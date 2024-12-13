import 'dart:io';
import 'package:args/args.dart';
import 'package:bitvcs/bitvcs.dart' as bitvcs;


void main(List<String> arguments) {
  final parser = ArgParser()
  ..addCommand('init')
  ..addCommand('add')
  ..addCommand('commit')
  ..addCommand('log')
  ..addCommand('branch')
  ..addCommand('clone')
  ..addCommand('merge')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Displays help information.');

  final results = parser.parse(arguments);
  //
  if (results['help'] as bool || results.command == null) {
    print('Usage: bitvcs <command> [options]');
    print(parser.usage);
    print("Available commands");
    for (var command in parser.commands.keys) {
    print(' $command');
  }
    exit(0);
  }
  //
  switch (results.command?.name) {
    case 'init':
      bitvcs.initRepository();
      break;
    case 'add':
      bitvcs.addFile(results.command!.arguments);
      break;
    case 'commit':
      bitvcs.commit(results.command!.arguments[0]);
      break;
    case 'log':
      bitvcs.logCommitHistory();
      break;
    case 'branch':
      bitvcs.createBranch(results.command!.arguments[0]);
      break;
    case 'clone':
      bitvcs.cloneRepository(results.command!.arguments[0]);
      break;
    case 'merge':
      bitvcs.mergeBranch(results.command!.arguments[0]);
      break;  
    default:
      print('Unknown command. Use --help for available commands.');
  }
  //
}
