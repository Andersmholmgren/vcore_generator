import 'package:vcore/vcore.dart';

class VCoreModelAsCodeSerialiser {
  void serialise(Package package, StringSink sink) {
    final name = package.name;
    sink.writeln('''
Package get _\$vCoreModelPackage => _${name}Package ??= _create${name}Package();
Package _${name}Package;

Package _create${name}Package() {
  final packageBuilder = new PackageBuilder()..name = $name;
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
  }
}
