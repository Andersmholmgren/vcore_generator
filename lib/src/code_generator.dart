import 'dart:io';

import 'package:vcore/vcore.dart';

class VCoreCodeGenerator {
  void generatePackage(Package package, IOSink sink) {
    sink..writeln('library ${package.name};')..writeln();
    sink..writeln("""
import 'package:built_collection/built_collection.dart';
import 'package:built_json/built_json.dart';
import 'package:built_value/built_value.dart';
    """)..writeln();

    sink..writeln("part '${package.name}.g.dart;'")..writeln();

    package.classifiers.forEach((c) {
      generateClass(c, sink);
      sink.writeln();
    });
  }

  void generateClassifier(Classifier classifier, IOSink sink) {
    if (classifier is ValueClass) {
      generateClass(classifier, sink);
    } else if (classifier is ExternalClass) {
//      generateExternalClass(classifier, sink);
    } else {
      // oops
    }
  }

  void generateClass(ValueClass valueClass, IOSink sink) {
    sink.write('abstract class ${valueClass.name} '
        'implements Built<${valueClass.name}, ${valueClass.name}Builder>');
    final superNames = valueClass.superTypes.map((c) => c.name);
    if (superNames.isNotEmpty) {
      sink..write(', ')..write(superNames.join(', '));
    }
    sink.writeln(' {');
    sink.writeln('}');
  }
}
