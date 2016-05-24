import 'package:vcore/vcore.dart';

class VCoreModelAsCodeSerialiser {
  void serialise(Package package, StringSink sink) {
    final name = _uncapitalise(package.name);
    final capName = _capitalise(package.name);
    sink.writeln('''
Package get _\$vCoreModelPackage => _${name}Package ??= _create${capName}Package();
Package _${name}Package;

Package _create${capName}Package() {
  final packageBuilder = new PackageBuilder()..name = '${package.name}';

//  final Map<String, ClassifierBuilder> _builders = new Map<String, ClassifierBuilder>();

//  ClassifierBuilder lookup(String name) => _builders[name];
        ''');

    package.classifiers.forEach((c) {
      _serialiseClassifierBuilder(c, sink);
    });

    // hmmm rather dodgy knowing dartFoo naming scheme
    dartPackage.classifiers.forEach((c) {
      sink.writeln('final ${_uncapitalise(c.name)}Builder = '
          'dart${_capitalise(c.name)}.toBuilder();');
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
      sink.writeln('..add(${_uncapitalise(c.name)}Builder.build())');
    });

    sink.writeln(';');
    sink.writeln('''
    return packageBuilder.build();
  }
    ''');

    sink.writeln();

    package.classifiers.forEach((c) {
      final cType =
          'ValueClass'; // TODO: hack - runtimeType is _$ValueClass :-(
      final cName = c.name;
      sink.writeln('''
      $cType _$cName;
      $cType get $cName => _$cName ??=
    _\$vCoreModelPackage.classifiers.firstWhere((c) => c.name == '$cName');
''');
    });

    sink.writeln('''
    Map<Type, Classifier> __typeMap;
    Map<Type, Classifier> get _typeMap => __typeMap ??= _buildTypeMap();

  Classifier _\$reflectClassifier(Type type) => _typeMap[type];
  ValueClass _\$reflectVClass(Type type) => _\$reflectClassifier(type);

  Map<Type, Classifier> _buildTypeMap() {
    final typeMap = <Type, Classifier>{};
    ''');

    package.classifiers.forEach((c) {
      final cName = c.name;
      sink.writeln('''
        typeMap[source_package.$cName] = $cName;
''');
    });

    sink.writeln('''
    return typeMap;
  }
  ''');
  }

  void _serialiseClassifierBuilder(Classifier c, StringSink sink) {
    if (c is ValueClass) {
      _serialiseClassBuilder(c, sink);
    } else {
      sink.writeln('// TODO: support ${c.runtimeType}');
    }
  }

  void _serialiseClassBuilder(ValueClass vc, StringSink sink) {
    final name = _uncapitalise(vc.name);
    final capName = _capitalise(vc.name);
    sink.writeln('''
    final ValueClassBuilder ${name}Builder = new ValueClassBuilder()
      ..name = '${capName}'
      ..isAbstract = ${vc.isAbstract};
    ''');
  }

  void _serialiseClassProperties(ValueClass vc, StringSink sink) {
    final name = _uncapitalise(vc.name);
    vc.properties.forEach((Property p) {
      sink.writeln('''
    ${name}Builder.properties.add(new PropertyBuilder()
      ..name = '${p.name}'
      ..type = ${_uncapitalise(p.type.name)}Builder
      ..isNullable = ${p.isNullable}
      ..derivedExpression = ${p.derivedExpression}
      ..docComment = ${p.docComment}
      ..defaultValue = ${p.defaultValue}
    );
      ''');
    });
  }

  void _serialiseClassSuperClasses(ValueClass vc, StringSink sink) {
    final name = _uncapitalise(vc.name);
    vc.superTypes.forEach((ValueClass sc) {
      sink.writeln('''
      ${name}Builder.superTypes.add(${_uncapitalise(sc.name)}Builder);
      ''');
    });
  }
}

String _capitalise(String s) =>
    s.substring(0, 1).toUpperCase() + s.substring(1);

String _uncapitalise(String s) =>
    s.substring(0, 1).toLowerCase() + s.substring(1);
