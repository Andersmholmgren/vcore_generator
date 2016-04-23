import 'dart:async';
import 'dart:io';
import 'package:vcore/vcore.dart';

class VCoreCodeGenerator {
  Future generatePackage(Package package, IOSink sink) async {}

  Future generateClass(ValueClass valueClass, IOSink sink) async {
    sink.writeln('abstract class ${valueClass.name} {');
    sink.writeln('}');
  }
}
