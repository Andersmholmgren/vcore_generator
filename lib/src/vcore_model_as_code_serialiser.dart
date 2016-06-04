import 'package:vcore/vcore.dart';

class VCoreModelAsCodeSerialiser {
  final String vcorePackagePrefix;

  VCoreModelAsCodeSerialiser({this.vcorePackagePrefix: ''});

  void serialise(Package package, StringSink sink) {
    final name = _uncapitalise(package.name);
    final capName = _capitalise(package.name);
    sink.writeln('''
Package get _\$vCoreModelPackage => _${name}Package ??= _create${capName}Package();
Package _${name}Package;

Package _create${capName}Package() {
  final packageBuilder = new ${vcorePackagePrefix}PackageBuilder()..name = '${package.name}';
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
          '${vcorePackagePrefix}ValueClass'; // TODO: hack - runtimeType is _$ValueClass :-(
      final cName = c.name;
      final lowerCaseCName = _uncapitalise(cName);
      sink.writeln('''
      $cType _$lowerCaseCName;
      $cType get $lowerCaseCName => _$lowerCaseCName ??=
    _\$vCoreModelPackage.classifiers.firstWhere((c) => c.name == '$cName');
''');
    });

    sink.writeln('''
    Map<Type, ${vcorePackagePrefix}Classifier> __typeMap;
    Map<Type, ${vcorePackagePrefix}Classifier> get _typeMap => __typeMap ??= _buildTypeMap();

  ${vcorePackagePrefix}Classifier _\$reflectClassifier(Type type) => _typeMap[type];
  ${vcorePackagePrefix}ValueClass _\$reflectVClass(Type type) => _\$reflectClassifier(type);

  Map<Type, ${vcorePackagePrefix}Classifier> _buildTypeMap() {
    final typeMap = <Type, ${vcorePackagePrefix}Classifier>{};
    ''');

    package.classifiers.forEach((c) {
      final cName = c.name;
      final lowerCaseCName = _uncapitalise(cName);
      sink.writeln('''
        typeMap[source_package.$cName] = $lowerCaseCName;
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
    print('_serialiseClassBuilder(${vc.name})');
    final name = _uncapitalise(vc.name);
    final capName = _capitalise(vc.name);
    sink.writeln('''
    final ${vcorePackagePrefix}ValueClassBuilder ${name}Builder = new ${vcorePackagePrefix}ValueClassBuilder()
      ..name = '${capName}'
      ..isAbstract = ${vc.isAbstract};
    ''');
  }

  void _serialiseClassProperties(ValueClass vc, StringSink sink) {
    print('_serialiseClassProperties(${vc.name})');
    final name = _uncapitalise(vc.name);
    vc.properties.forEach((Property p) {
      sink.writeln('''
    ${name}Builder.properties.add(new ${vcorePackagePrefix}PropertyBuilder()
      ..name = r'${p.name}'
      ..type = ${_builderName(p.type)}
      ..isNullable = ${p.isNullable}
      ..derivedExpression = ${p.derivedExpression}
      ..docComment = ${p.docComment}
      ..defaultValue = ${p.defaultValue}
    );
      ''');
    });
  }

  String _builderName(Classifier type) {
    print('_builderName(${type.runtimeType} ${type.name})');

    if (type is GenericType) {
      final typesString =
          type.genericTypeValues.values.map((c) => _builderName(c)).join(', ');
      if (type.base == builtMap) {
        return 'createBuiltMap($typesString)';
      } else if (type.base == builtSet) {
        return 'createBuiltSet($typesString)';
      } else if (type.base == builtList) {
        return 'createBuiltList($typesString)';
      }
    }
    return '${_uncapitalise(type.name)}Builder';
  }

  void _serialiseClassSuperClasses(ValueClass vc, StringSink sink) {
    print('_serialiseClassSuperClasses(${vc.name})');
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
