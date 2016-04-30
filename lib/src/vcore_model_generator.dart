library vcore_model_generator;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/generated/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:vcore_generator/src/dart_source_to_vcore.dart';
import 'package:vcore_generator/vcore_generator.dart';

/// Generator for VCore Models.
///
class VCoreModelGenerator extends Generator {
  Future<String> generate(Element element) async {
    if (element is! LibraryElement) return null;

    // TODO(moi): better way of checking for top level declaration.
    if (!element.definingCompilationUnit.accessors
        .any((element) => element.displayName == 'vCoreModelPackage'))
      return null;

    final package = convert(element);

    new VCoreCodeGenerator().generatePackage(package, stdout);

    return "hi";
  }
}
