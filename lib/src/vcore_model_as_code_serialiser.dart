import 'package:vcore/vcore.dart';

class VCoreModelAsCodeSerialiser {
  void serialise(Package package, StringSink sink) {
    final name = package.name;
    sink.writeln('''
Package get _\$vCoreModelPackage => _${name}Package ??= _create${name}Package();
Package _${name}Package;

Package _create${name}Package() {
  final packageBuilder = new PackageBuilder()..name = '$name';
  packageBuilder.classifiers
        ''');

    package.classifiers.forEach((c) {
      sink.writeln('..add(${c.name})');
    });
    sink.writeln(';');
    sink.writeln('''
    return packageBuilder.build();
  }
    ''');

    package.classifiers.forEach((c) => _serialiseClassifier(c, sink));
  }

  void _serialiseClassifier(Classifier c, StringSink sink) {
    if (c is ValueClass) {
      _serialiseClass(c, sink);
    } else {
      sink.writeln('// TODO: support ${c.runtimeType}');
    }
  }

  void _serialiseClass(ValueClass vc, StringSink sink) {
    final name = vc.name;
    final capName = _capitalise(name);
    sink.writeln('''
ValueClass _create${capName}() => _${name}Builder.build();
ValueClassBuilder __${name}Builder;
ValueClassBuilder get _${name}Builder => __${name}Builder ??= _create${capName}Builder();

ValueClassBuilder _create${capName}Builder() {
  return new ValueClassBuilder()
    ..name = '_${capName}Builder'
    ..isAbstract = ${vc.isAbstract}
    ..superTypes.addAll(${[vc.superTypes.map((t) => t.name).join(', ')]})
    ''');

    vc.properties.forEach((Property p) {
      final pb = p.toBuilder();
      sink.writeln('''
    ..properties.add(new PropertyBuilder()
      ..name = '${pb.name}'
      ..type = ${pb.type.name}
      ..isNullable = ${pb.isNullable}
      ..derivedExpression = ${pb.derivedExpression}
      ..docComment = ${pb.docComment}
      ..defaultValue = ${pb.defaultValue}
    )
      ''');
    });

    sink.writeln('''
      );
}
''');
  }
  /*
ValueClass _create${capName}() => _${name}Builder.build();
ValueClassBuilder __${name}Builder;
ValueClassBuilder get _${name}Builder => __${name}Builder ??= _create${capName}Builder();

ValueClassBuilder _create${capName}Builder() {
  return new ValueClassBuilder()
    ..name = '_${capName}Builder'
    ..isAbstract = ${vc.isAbstract}
    ..superTypes.addAll(${[vc.superTypes.map((t) => t.name).join(', ')]})
    ..properties.add(new PropertyBuilder()
      ..name = 'iD'
      ..type = EBoolean
      ..isNullable = false
      ..derivedExpression = null
      ..docComment = null
      ..defaultValue = null)
    ..properties.add(new Property((b) => b
      ..name = 'eAttributeType'
      ..type = EDataType
      ..isNullable = false
      ..derivedExpression = null
      ..docComment = null
      ..defaultValue = null));
}


   */
}

String _capitalise(String s) {
  return s.substring(0, 1).toUpperCase() + s.substring(1);
}
