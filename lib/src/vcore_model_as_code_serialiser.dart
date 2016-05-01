import 'package:vcore/vcore.dart';

class VCoreModelAsCodeSerialiser {
  void serialise(Package package, StringSink sink) {
    final name = package.name;
    sink.writeln('''
Package get _\$vCoreModelPackage => _${name}Package ??= _create${name}Package();
Package _${name}Package;

Package _create${name}Package() {
  final packageBuilder = new PackageBuilder()..name = '$name';

  final Map<String, ClassifierBuilder> _builders = new Map<String, ClassifierBuilder>();

  ClassifierBuilder lookup(String name) => _builders[name];
        ''');

    package.classifiers.forEach((c) {
      _serialiseClassifierBuilder(c, sink);
    });

    sink.writeln();

    package.classifiers.forEach((c) {
      _serialiseClassProperties(c, sink);
    });

    sink.writeln();

    package.classifiers.forEach((c) {
      _serialiseClassSuperClasses(c, sink);
    });

    sink.writeln('packageBuilder.classifiers');

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

  void _serialiseClassifierBuilder(Classifier c, StringSink sink) {
    if (c is ValueClass) {
      _serialiseClassBuilder(c, sink);
    } else {
      sink.writeln('// TODO: support ${c.runtimeType}');
    }
  }

  void _serialiseClassBuilder(ValueClass vc, StringSink sink) {
    final name = vc.name;
    final capName = _capitalise(name);
    sink.writeln('''
ValueClassBuilder ${name}Builder = new ValueClassBuilder()
    ..name = '_${capName}Builder'
    ..isAbstract = ${vc.isAbstract};
    ''');

    sink.writeln('_builders[$name] = ')
  }

  void _serialiseClassProperties(ValueClass vc, StringSink sink) {
    final name = vc.name;
    vc.properties.forEach((Property p) {
      sink.writeln('''
    ${name}Builder.properties.add(new PropertyBuilder()
      ..name = '${p.name}'
      ..type = lookup('${p.type.name}')
      ..isNullable = ${p.isNullable}
      ..derivedExpression = ${p.derivedExpression}
      ..docComment = ${p.docComment}
      ..defaultValue = ${p.defaultValue}
    );
      ''');
    });
  }

  void _serialiseClassSuperClasses(ValueClass vc, StringSink sink) {
    final name = vc.name;
    vc.superTypes.forEach((ValueClass sc) {
      sink.writeln('''
      ${name}Builder.properties.add(lookup('${sc.name}'));
      ''');
    });
  }
}

String _capitalise(String s) {
  return s.substring(0, 1).toUpperCase() + s.substring(1);
}
