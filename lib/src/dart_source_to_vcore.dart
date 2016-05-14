import 'package:analyzer/src/generated/element.dart';
import 'package:built_collection/built_collection.dart';
import 'package:quiver/iterables.dart';
import 'package:vcore/vcore.dart';
import 'package:vcore_generator/src/library_elements.dart';

Package convert(LibraryElement library) {
  return new ConvertFromSourceLibrary(library).convert();
}

class ConvertFromSourceLibrary {
  Map<DartType, _ResolvingClassifierHelper> _classifierHelpers;

  final LibraryElement library;
  final PackageBuilder pb = new PackageBuilder();

  ConvertFromSourceLibrary(this.library) {
    pb.name = library.name;
  }

  Package convert() {
    final classElements = LibraryElements.getClassElements(library);

    final transitiveClassElements =
        LibraryElements.getTransitiveClassElements(library);

    final allClassElements = concat([classElements, transitiveClassElements])
        .where((ClassElement c) {
//      print(c.name);
      return !c.name.startsWith(r'_$') && !c.name.contains('Builder');
    });

    _classifierHelpers =
        new Map<DartType, _ResolvingClassifierHelper>.fromIterable(
            allClassElements,
            key: (ClassElement c) => c.type,
            value: (c) => _ResolvingClassifierHelper.create(c));

    print("eClassifiers: ${_classifierHelpers.keys.toSet()}");

//    final classifiers =
//        eClassifiers.map(_processClassifier).where((c) => c != null).toList();

    _classifierHelpers.values.forEach((h) => h.processFlat(_resolveHelper));
    _classifierHelpers.values.forEach((h) => h.processGraph(_resolveHelper));
    _classifierHelpers.values.forEach((h) => h.resolve());

    final classifiers =
        _classifierHelpers.values.map((h) => h.resolvedClassifier);

    final package = new Package((b) => b
      ..name = library.name
      ..classifiers.addAll(classifiers));

//    new VCoreCodeGenerator().generatePackage(package, stdout);

//    final boolean = _classifierHelpers['EBoolean'];
//
//    print('-------');
//
//    print('${classifiers.map((c) => c.name).toSet()}');
//    print(boolean.resolvedClassifier);

    return package;
  }

  _ResolvingClassifierHelper _resolveHelper(DartType type) {
    final result = __resolveHelper(type);
    print('resolved to: $result with builder: ${result?.resolvingClassifier}; '
        '${result?.resolvingClassifier?.name}');
    return result;
  }

  _ResolvingClassifierHelper __resolveHelper(DartType type) {
    print('_resolveHelper($type)');
    // TODO: less dodgy way of filtering
    if (type != null &&
        !type.isObject &&
        !type.name.startsWith('Built') &&
        !type.name.startsWith('Serializer')) {
      final _ResolvingClassifierHelper classifierHelper =
          _classifierHelpers[type];
      if (classifierHelper == null) {
        throw new StateError(
            "failed to resolve classifier helper class: $type");
      } else {
        return classifierHelper;
      }
    } else {
      return null;
    }
  }

//  ClassifierBuilder _convertSourceClass(ClassElement sourceClass) {
//    final classifierBuilder = _classifierBuilders[sourceClass];
//    if (classifierBuilder != null) {
//      return classifierBuilder;
//    }
//
//    // TODO: assuming value class for now
//
//    final vb = new ValueClassBuilder();
//    vb.name = sourceClass.name;
//
//    _classifierBuilders[sourceClass] = vb;
//
////    sourceClass.fields
//  }
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
    final p = _properties.build().map((pb) => pb.build());
    final p2 = p.map((x) => x.toBuilder());
    resolvingClassifier.properties = new SetBuilder<PropertyBuilder>(p2);

    final s = _superClasses.build().map((pb) => pb.build());
    final s2 = s.map((x) => x.toBuilder());
    resolvingClassifier.superTypes = new SetBuilder<ValueClassBuilder>(s2);

//    resolvingClassifier.properties = _properties;
//
//    resolvingClassifier.superTypes = _superClasses;

    print('XXX($name): ${_properties.build().map((vc) => vc.type).toList()}');
    print(
        'XXX2($name): ${resolvingClassifier.properties.build().map((vc) => vc.type).toList()}');

    print('YYY($name): ${_superClasses.build().map((vc) => vc).toList()}');
    print(
        'YYY2($name): ${resolvingClassifier.superTypes.build().map((vc) => vc).toList()}');

    _resolvedClassifier = resolvingClassifier.build();
  }

  void _processSuperTypes(_ResolvingClassifierHelper lookup(DartType cls)) {
    print('_processSuperTypes($name)');
    final superTypes = classifierElement.interfaces;

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
