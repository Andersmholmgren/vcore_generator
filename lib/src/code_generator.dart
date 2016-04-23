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
      generateValueClass(classifier, sink);
    } else if (classifier is ExternalClass) {
//      generateExternalClass(classifier, sink);
    } else {
      // oops
    }
  }

  void generateValueClass(ValueClass valueClass, IOSink sink) {
    generateClass(valueClass, sink);
  }

  void generateClass(ValueClass valueClass, IOSink sink) {
    final className = valueClass.name;
    final classNameLower =
        className.substring(0, 1).toLowerCase() + className.substring(1);
    sink.write('abstract class $className '
        'implements Built<$className, ${className}Builder>');
    final superNames = valueClass.superTypes.map((c) => c.name);
    if (superNames.isNotEmpty) {
      sink..write(', ')..write(superNames.join(', '));
    }
    sink.writeln(' {');

    sink.writeln('static final Serializer<$className> serializer'
        ' = _\$${classNameLower}Serializer;');
    sink.writeln();

    valueClass.properties.forEach((p) {
      sink.writeln('${p.type.name} get ${p.name};');
    });
    sink.writeln();

    sink..writeln('$className._();')..writeln();

    sink.writeln(
        'factory $className([updates(${className}Builder b)]) = _\$$className;');
    sink.writeln();
    sink.writeln('}');
  }
}
