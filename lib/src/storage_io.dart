import 'dart:io';

String readFile(String path) => File(path).readAsStringSync();

void writeFile(String path, String content) =>
    File(path).writeAsStringSync(content);
