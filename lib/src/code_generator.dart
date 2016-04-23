import 'dart:io';

import 'package:vcore/vcore.dart';
import 'package:quiver/iterables.dart';

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
      generateClassifier(c, sink);
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
    if (!valueClass.isAbstract) {
      sink.writeln();
      generateBuilder(valueClass, sink);
    }
  }

  void generateClass(ValueClass valueClass, IOSink sink) {
    final className = valueClass.name;
    final classNameLower =
        className.substring(0, 1).toLowerCase() + className.substring(1);
    sink.write('abstract class $className ');
    final buildClassName =
        valueClass.isAbstract ? [] : ['Built<$className, ${className}Builder>'];

//        'implements Built<$className, ${className}Builder>');
    final superNames = valueClass.superTypes.map((c) => c.name);

    final allImplementNames = concat([buildClassName, superNames]);
    if (allImplementNames.isNotEmpty) {
      sink..write('implements ')..write(allImplementNames.join(', '));
    }
    sink.writeln(' {');

    if (!valueClass.isAbstract) {
      sink.writeln('static final Serializer<$className> serializer'
          ' = _\$${classNameLower}Serializer;');
      sink.writeln();
    }

    valueClass.allProperties.forEach((p) {
      if (p.isNullable) {
        sink.writeln('@nullable');
      }
      sink.writeln('${p.type.name} get ${p.name};');
    });
    sink.writeln();

    if (!valueClass.isAbstract) {
      sink..writeln('$className._();')..writeln();

      sink.writeln(
          'factory $className([updates(${className}Builder b)]) = _\$$className;');
      sink.writeln();
    }
    sink.writeln('}');
  }

  void generateBuilder(ValueClass valueClass, IOSink sink) {
    final className = valueClass.name;
    final builderName = '${className}Builder';
//    final classNameLower =
//        className.substring(0, 1).toLowerCase() + className.substring(1);
    sink.write('abstract class $builderName '
        'implements Builder<$className, ${className}Builder>');
    final superNames = valueClass.superTypes.map((c) => c.name);
    if (superNames.isNotEmpty) {
      sink..write(', ')..write(superNames.join(', '));
    }
    sink.writeln(' {');

    valueClass.allProperties.forEach((p) {
      var propertyClassName = _getMaybeMappedClassName(p.type);
      if (p.isNullable) {
        sink.writeln('@nullable');
      }
      sink.writeln('$propertyClassName ${p.name} = new $propertyClassName();');
    });
    sink.writeln();

    sink..writeln('$builderName._();')..writeln();

    sink.writeln('factory $builderName() = _\$$builderName;');
    sink.writeln();
    sink.writeln('}');
  }
}

String _getMaybeMappedClassName(Classifier classifier) {
  if (classifier is GenericType) {
    if (classifier.base == builtSet) {
      return 'SetBuilder<${classifier.genericTypeValues[builtSet.genericTypes.first].name}>';
    }
  }

  return classifier.name;
}
