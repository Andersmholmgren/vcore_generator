library vcore_model_generator;

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:vcore_generator/src/dart_source_to_vcore.dart';
import 'package:vcore_generator/src/vcore_model_as_code_serialiser.dart';
import 'package:analyzer/dart/element/visitor.dart';

/// Generator for VCore Models.
///
class VCoreModelGenerator extends Generator {
  Future<String> generate(Element element, BuildStep buildStep) async {
    print('VCoreModelGenerator.generate: $element');
    if (element is! LibraryElement) return null;

    final lElement = element as LibraryElement;

    print('** Library: ${lElement.name}');
    print('defining compunit: ${lElement.definingCompilationUnit.name}');
    print(
        'defining compunit imports: ${lElement.definingCompilationUnit.library.imports}');
    print(
        'defining compunit prefixes: ${lElement.definingCompilationUnit.library.imports.where((ie) => ie.prefix != null).map((ie) => ie.importedLibrary)}');
//    print('importedLibraries: ${lelement.importedLibraries.toList()}');
//    print('imports: ${lelement.imports.toList()}');
//    print(lelement.unit.element.accessors.map((p) => p.name).toList());

    final sourceLibraries = lElement.definingCompilationUnit.library.imports
            .where((ie) => ie.prefix?.name?.startsWith('source_package'))
            .map((ie) => ie.importedLibrary)
//            .where((pe) => pe.name.startsWith('source_package'))
//            .map/*<LibraryElement>*/((pe) => pe.enclosingElement)
        as Iterable<LibraryElement>;

    print('** sourceLibraries: ${sourceLibraries.map((l) => l.name).toList()}');

    if (sourceLibraries.isEmpty) {
      print('no libraries imported with prefix starting with source_package '
          'for library ${lElement.name}');
      return null;
    }

    final vcoreImports = lElement.definingCompilationUnit.library.imports
        .where((ie) => ie.importedLibrary.name == 'vcore');

    final prefixedVcoreImport = vcoreImports.where((ie) => ie.prefix != null);
    final vcorePrefix = prefixedVcoreImport.isEmpty
        ? ''
        : '${prefixedVcoreImport.first.prefix.name}.';

    print('*** vcorePrefix: $vcorePrefix');

    // TODO(moi): better way of checking for top level declaration.
    if (!lElement.unit.element.accessors
        .any((element) => element.displayName == 'vCoreModelPackage'))
      return null;

    // TODO: only handling first source lib for now
    final sourceLib = sourceLibraries.first;

    print('sourceLib: ${sourceLib.name}');
    print(sourceLib.definingCompilationUnit.name);
//    final v = new _GetClassesVisitor();
////    sourceLib.definingCompilationUnit.visitChildren(v);
//    sourceLib.visitChildren(v);
//    print('visited classes: ${v.classElements}');

//    sourceLib.accept(())
    print('units: ${sourceLib.units}');
    print('visibleLibraries: ${sourceLib.visibleLibraries}');

    final package = convert(sourceLib);

//    new VCoreCodeGenerator().generatePackage(package, stdout);

//    print('XXXXX');
    print(package);
//    print('YYYYY');
    var _json = new JsonEncoder.withIndent(' ');

//    print(_json.convert(serializers.serialize(package.classifiers.first)));
//
//    print(_json.convert(serializers.serialize(package)));
//
//    return "Package _\$vCoreModelPackage = "
//        "serializers.deserialize(${_json.convert(serializers.serialize(package))});";

    final sb = new StringBuffer();
    new VCoreModelAsCodeSerialiser(vcorePackagePrefix: vcorePrefix)
        .serialise(package, sb);
    print(sb.toString());
    return sb.toString();
  }
}

//class _GetClassesVisitor extends RecursiveElementVisitor {
//  final List<ClassElement> classElements = new List<ClassElement>();
//
//  @override
//  visitClassElement(ClassElement element) {
//    print('visitClassElement($element)');
//    classElements.add(element);
//    super.visitClassElement(element);
//  }
//
//  visitLibraryElement(LibraryElement element) {
//    print('visitLibraryElement($element)');
//    return super.visitLibraryElement(element);
//  }
//
//  visitExportElement(ExportElement element) {
//    print('visitExportElement($element)');
//    element.exportedLibrary.visitChildren(this);
//    return super.visitExportElement(element);
//  }
//}
