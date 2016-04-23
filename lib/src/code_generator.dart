import 'dart:async';
import 'dart:io';
import 'package:vcore/vcore.dart';

class VCoreCodeGenerator {
  void generatePackage(Package package, IOSink sink) {
    package.classifiers.forEach((c) {
      generateClass(c, sink);
    });
  }

  void generateClassifier(Classifier classifier, IOSink sink)  {
    if (classifier is ValueClass) {
      generateClass(classifier, sink);
    }
    else if (classifier is ExternalClass) {
//      generateExternalClass(classifier, sink);
    }
    else {
      // oops
    }
  }

  void generateClass(ValueClass valueClass, IOSink sink)  {
    sink.writeln('abstract class ${valueClass.name} {');
    sink.writeln('}');
  }
}
