import 'dart:io';

import 'package:vcore/vcore.dart';
import 'package:quiver/iterables.dart';

class VCoreCodeGenerator {
  final bool includeBuildConstructor;

  VCoreCodeGenerator({this.includeBuildConstructor: false});

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
    } else if (classifier is EnumClass) {
      generateEnumClass(classifier, sink);
    } else {
      // oops
    }
  }

  void generateEnumClass(EnumClass enumClass, IOSink sink) {
    sink
      ..writeln('enum ${enumClass.name} { ${enumClass.literals.join(', ')} }')
      ..writeln();
  }

  void generateValueClass(ValueClass valueClass, IOSink sink) {
    generateClass(valueClass, sink);
    if (!valueClass.isAbstract) {
      sink.writeln();
      generateBuilder(valueClass, sink);
    }
  }

  void generateClass(ValueClass valueClass, IOSink sink) {
    if (valueClass.docComment != null) {
      sink.writeln(
          valueClass.docComment.split('\n').map((l) => '/// $l').join('\n'));
    }
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

    final properties = valueClass.isAbstract
        ? valueClass.properties
        : valueClass.allProperties;
    properties.forEach((p) {
      if (p.isNullable) {
        sink.writeln('@nullable');
      }
      sink.write('${p.type.name} get ${p.name}');
      if (p.isDerived && !valueClass.isAbstract) {
        sink.write(' => ${p.derivedExpression}');
      }
      sink.writeln(';');
    });
    sink.writeln();

    if (!valueClass.isAbstract) {
      final builderName = '${className}Builder';
      sink..writeln('$className._();')..writeln();

      sink.writeln(
          'factory $className([updates(${className}Builder b)]) = _\$$className;');
      sink.writeln();

      if (includeBuildConstructor) {
        _generateBuildConstructor(sink, className, valueClass, builderName);
      }
    }

    sink.writeln('}');
  }

  void _generateBuildConstructor(IOSink sink, String className,
      ValueClass valueClass, String builderName) {
    sink.writeln('factory $className.build({');

    final properties = valueClass.allProperties.where((p) => !p.isDerived);
    final namedParams =
        properties.map((p) => '${_getMaybeMappedClassName(p.type)} ${p.name}');

    sink.writeln(namedParams.join(', '));

    sink.writeln('}) {');

    sink.writeln('return (new $builderName()');

    properties.forEach((p) {
      sink.write('..${p.name} = ${p.name}');
      final defaultValue = _getDefaultValue(p);
      if (defaultValue != null) {
        sink.write(' ?? $defaultValue');
      }
      sink.writeln();
    });

    sink..writeln(').build();')..writeln('}');
  }

  void generateBuilder(ValueClass valueClass, IOSink sink) {
    final className = valueClass.name;
    final builderName = '${className}Builder';
//    final classNameLower =
//        className.substring(0, 1).toLowerCase() + className.substring(1);
    sink.write('abstract class $builderName '
        'implements Builder<$className, ${className}Builder>');
    sink.writeln(' {');

    valueClass.allProperties.where((p) => !p.isDerived).forEach((p) {
      final propertyClassName = _getMaybeMappedClassName(p.type);
      if (p.isNullable) {
        sink.writeln('@nullable');
      }
      sink.write('$propertyClassName ${p.name}');
      final defaultValue =
          _getDefaultValue(p, propertyClassName: propertyClassName);
      if (defaultValue != null) {
        sink.write(' = $defaultValue');
      }

      sink.writeln(';');
    });
    sink.writeln();

    sink..writeln('$builderName._();')..writeln();

    sink.writeln('factory $builderName() = _\$$builderName;');
    sink.writeln();
    sink.writeln('}');
  }
}

Object _getDefaultValue(Property p, {String propertyClassName}) {
  final _propertyClassName =
      propertyClassName ?? _getMaybeMappedClassName(p.type);
  if (p.defaultValue != null) {
    return p.defaultValue;
    // TODO: dodgy way to detect it is a builder
  } else if (_propertyClassName.contains('Builder')) {
    return 'new $_propertyClassName()';
  } else
    return null;
}

String _getMaybeMappedClassName(Classifier classifier) {
  if (classifier is GenericType) {
    final genericTypeValues = classifier.genericTypeValues;
    if (classifier.base == builtSet) {
      return 'SetBuilder<${genericTypeValues[builtSet.genericTypes.first].name}>';
    } else if (classifier.base == builtMap) {
      final genericTypes = builtMap.genericTypes;
      return 'MapBuilder<${genericTypeValues[genericTypes.first].name}, '
          '${genericTypeValues[genericTypes.last].name}>';
    }
  } else if (classifier is ValueClass && !classifier.isAbstract) {
    return '${classifier.name}Builder';
  }

  return classifier.name;
}
