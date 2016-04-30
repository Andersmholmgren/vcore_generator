import 'package:analyzer/src/generated/element.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_json_generator/src/source_library.dart';
import 'package:vcore/vcore.dart';

Package convert(LibraryElement library) {
  return convertFromSourceLibrary(
      SourceLibrary.fromLibraryElement(library), library.name);
}

class ConvertFromSourceLibrary {
  final Map<DartType, ClassifierBuilder> _classifierBuilders =
      <DartType, ClassifierBuilder>{};

  final LibraryElement library;
  final PackageBuilder pb = new PackageBuilder();

  ConvertFromSourceLibrary(this.library, String name) {
    pb.name = name;
  }

  Package convert() {
//  new
//  library.sourceClasses.
  }

  ClassifierBuilder _convertSourceClass(ClassElement sourceClass) {
    final classifierBuilder = _classifierBuilders[sourceClass];
    if (classifierBuilder != null) {
      return classifierBuilder;
    }

    // TODO: assuming value class for now

    final vb = new ValueClassBuilder();
    vb.name = sourceClass.name;

    _classifierBuilders[sourceClass] = vb;

//    sourceClass.fields
  }
}

abstract class _ResolvingClassifierHelper<V extends Classifier<V, B>,
    B extends ClassifierBuilder<V, B>> {
  final ClassElement classifierElement;

  V _resolvedClassifier;
  V get resolvedClassifier {
    return _resolvedClassifier ??= resolvingClassifier.build();
  }

  bool get isResolved => _resolvedClassifier != null;

  final B resolvingClassifier;

  String get name => resolvingClassifier.name;

  _ResolvingClassifierHelper._(
      this.classifierElement, this.resolvingClassifier) {
    resolvingClassifier.name = classifierElement.name;
  }

  static _ResolvingClassifierHelper create(ClassElement classifierElement) {
    return new _ResolvingValueClassHelper(classifierElement);
//    final xsiType = _getXsiType(classifierElement);
//    switch (xsiType) {
//      case 'ecore:EClass':
//        return new _ResolvingValueClassHelper(classifierElement);
//
//      case 'ecore:EENumm':
//        return new _ResolvingEnumClassHelper(classifierElement);
//
//      case 'ecore:EDataType':
////        return new _ResolvingExternalClassHelper(classifierElement);
//        return new _ResolvingValueClassHelper(classifierElement);
//
//      default:
//        throw 'oops';
//    }
  }

  void processFlat(_ResolvingClassifierHelper lookup(DartType cls));
  void processGraph(_ResolvingClassifierHelper lookup(DartType cls)) {}
  void resolve() {}
}

class _ResolvingValueClassHelper
    extends _ResolvingClassifierHelper<ValueClass, ValueClassBuilder> {
  SetBuilder<PropertyBuilder> _properties = new SetBuilder<PropertyBuilder>();
  SetBuilder<ValueClassBuilder> _superClasses =
      new SetBuilder<ValueClassBuilder>();

  _ResolvingValueClassHelper(ClassElement classifierElement)
      : super._(classifierElement, new ValueClassBuilder());

  @override
  void processFlat(_ResolvingClassifierHelper lookup(DartType cls)) {
    print('processFlat($name)');
//    resolvingClassifier.isAbstract =
//        (classifierElement.getAttribute('abstract') ?? 'false') == 'true';
  }

  void processGraph(_ResolvingClassifierHelper lookup(DartType cls)) {
    print('processGraph($name)');

    _processSuperTypes(lookup);
    _processProperties(lookup);
  }

  void resolve() {
    print('resolve($name)');
    resolvingClassifier.properties =
        new SetBuilder<Property>(_properties.build().map((pb) => pb.build()));

    resolvingClassifier.superTypes = new SetBuilder<ValueClass>(
        _superClasses.build().map((sc) => sc.build()));

    _resolvedClassifier = resolvingClassifier.build();
  }

  void _processSuperTypes(_ResolvingClassifierHelper lookup(DartType cls)) {
    print('_processSuperTypes($name)');
    final superTypes = classifierElement.allSupertypes;

    superTypes.forEach((t) {
      final superClass = lookup(t as DartType)?.resolvingClassifier;
      if (superClass != null) {
        _superClasses.add(superClass);
      }
    });
  }

  void _processProperties(_ResolvingClassifierHelper lookup(DartType cls)) {
    print('_processProperties($name)');
    final fieldProperties = classifierElement.fields
        .map((sf) => _processField(lookup, sf))
        .where((pb) => pb != null);

    _properties.addAll(fieldProperties);

    final getterProperties = classifierElement.accessors
        .where((a) => a.isGetter)
        .map((sf) => _processField(lookup, sf.variable))
        .where((pb) => pb != null);

    _properties.addAll(getterProperties);

//    resolvingClassifier.addProperty(properties);
  }

  PropertyBuilder _processField(_ResolvingClassifierHelper lookup(DartType cls),
      VariableElement structuralElement) {
    print('_processField: $structuralElement');
    final fieldType = structuralElement.type;
    final classifierBuilder = lookup(fieldType)?.resolvingClassifier;
    if (classifierBuilder == null) {
      print("No type for structuralElement $structuralElement");
      return null;
//      throw new StateError("No type for structuralElement $structuralElement");
    }

    return new PropertyBuilder()
      ..name = structuralElement.name
      ..type = classifierBuilder;
  }

//  PropertyBuilder _processGetter(_ResolvingClassifierHelper lookup(DartType cls),
//      PropertyAccessorElement structuralElement) {
//    print('_processField: $structuralElement');
//    final fieldType = structuralElement.;
//    final classifierBuilder = lookup(fieldType)?.resolvingClassifier;
//    if (classifierBuilder == null) {
//      print("No type for structuralElement $structuralElement");
//      return null;
////      throw new StateError("No type for structuralElement $structuralElement");
//    }
//
//    return new PropertyBuilder()
//      ..name = structuralElement.name
//      ..type = classifierBuilder;
//  }
}

/*
  static SourceClass fromClassElements(
      ClassElement classElement, ClassElement builderClassElement) {
    final result = new SourceClassBuilder();

    result.name = classElement.name;

    // TODO(davidmorgan): better check.
    result.isBuiltValue = classElement.allSupertypes
            .map((type) => type.name)
            .any((name) => name.startsWith('Built')) &&
        !classElement.name.startsWith(r'_$') &&
        classElement.fields.any((field) => field.name == 'serializer');

    // TODO(davidmorgan): better check.
    result.isEnumClass = classElement.allSupertypes
            .map((type) => type.name)
            .any((name) => name == 'EnumClass') &&
        !classElement.name.startsWith(r'_$') &&
        classElement.fields.any((field) => field.name == 'serializer');

    for (final fieldElement in classElement.fields) {
      final builderFieldElement =
          builderClassElement?.getField(fieldElement.displayName);
      final sourceField =
          SourceField.fromFieldElements(fieldElement, builderFieldElement);
      if (sourceField.isSerializable) {
        result.fields.add(sourceField);
      }
    }

    return result.build();
  }

 */
