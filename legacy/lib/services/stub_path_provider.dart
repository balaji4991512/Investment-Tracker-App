// Stub file for path_provider on web
// These functions are never called on web, but need to exist to satisfy imports

import 'dart:async';

class Directory {
  final String path;
  Directory(this.path);
  
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Stream<dynamic> list() => const Stream.empty();
}

class File {
  final String path;
  File(this.path);
  
  Future<bool> exists() async => false;
  Future<String> readAsString() async => '';
  Future<File> writeAsString(String contents) async => this;
  Future<void> delete() async {}
}

Future<Directory> getApplicationDocumentsDirectory() async {
  return Directory('');
}
