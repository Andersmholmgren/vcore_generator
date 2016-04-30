import 'package:analyzer/src/generated/element.dart';
import 'package:built_json_generator/src/source_library.dart';
import 'package:vcore/vcore.dart';
import 'package:built_json_generator/src/source_class.dart';

Package convert(LibraryElement library) {
  return convertFromSourceLibrary(
      SourceLibrary.fromLibraryElement(library), library.name);
}

class ConvertFromSourceLibrary {
  final Map<SourceClass, ClassifierBuilder> _classifierBuilders =
      <SourceClass, ClassifierBuilder>{};

  final SourceLibrary library;
  final PackageBuilder pb = new PackageBuilder();

  ConvertFromSourceLibrary(this.library, String name) {
    pb.name = name;
  }

  Package convert() {


//  new
//  library.sourceClasses.

  }

  ClassifierBuilder _convertSourceClass(SourceClass sourceClass) {
    final classifierBuilder = _classifierBuilders[sourceClass];
    if (classifierBuilder != null) {
      return classifierBuilder;
    }


  }
}
