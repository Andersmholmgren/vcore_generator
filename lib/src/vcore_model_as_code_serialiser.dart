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
ValueClass _${name};
ValueClass get ${name} => _${name} ??= _create${capName}();

ValueClass _create${capName}() {
  return new ValueClass((cb) => cb
    ..name = '${capName}'
    ..isAbstract = ${vc.isAbstract}
    ..superTypes.addAll(${[vc.superTypes.map((t) => t.name).join(', ')]})
    ''');

    vc.properties.forEach((p) {
      sink.writeln('''
    ..properties.add(new Property((b) => b
      ..name = '${p.name}'
      ..type = ${p.type.name}
      ..isNullable = ${p.isNullable}
      ..derivedExpression = ${p.derivedExpression}
      ..docComment = ${p.docComment}
      ..defaultValue = ${p.defaultValue})
    )
      ''');
    });

    sink.writeln('''
      );
}
''');
  }
}

String _capitalise(String s) {
  return s.substring(0, 1).toUpperCase() + s.substring(1);
}
