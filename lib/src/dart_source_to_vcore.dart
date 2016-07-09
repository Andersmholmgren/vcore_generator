import 'package:built_collection/built_collection.dart';
import 'package:vcore/vcore.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:option/option.dart';

Package convert(LibraryElement library) {
  return new ConvertFromSourceLibrary(library).convert();
}

class ConvertFromSourceLibrary {
  Map<String, _ResolvingClassifierHelper> _classifierHelpers;
  BuiltMap<String, Classifier> _coreTypes;

  final LibraryElement library;
  final PackageBuilder pb = new PackageBuilder();

  ConvertFromSourceLibrary(this.library) {
    pb.name = library.name;

    final builder = new MapBuilder<String, Classifier>();
    dartPackage.classifiers.forEach((c) {
      builder[c.name] = c;
    });

    _coreTypes = builder.build();
  }

  Package convert() {
    final v = new _GetClassesVisitor();
//    sourceLib.definingCompilationUnit.visitChildren(v);
    library.visitChildren(v);
    final classElements = v.nameToBuilderPair.values;
//    final classElements = LibraryElements.getClassElements(library);
    print('classElements: $classElements');

//    final transitiveClassElements =
//        LibraryElements.getTransitiveClassElements(library);
//
//    print('transitiveClassElements: $transitiveClassElements');
//    final allClassElements = concat([classElements, transitiveClassElements])
//        .where((ClassElement c) {
////      print(c.name);
//      return !c.name.startsWith(r'_$') && !c.name.contains('Builder');
//    });

    final allClassElements = classElements;

    _classifierHelpers =
        new Map<String, _ResolvingClassifierHelper>.fromIterable(
            allClassElements,
            key: (ClassElement c) => c.type.name,
            value: (c) => _ResolvingTopLevelClassifierHelper.create(c));

    print("classifiers: ${_classifierHelpers.keys.toSet()}");
    _classifierHelpers.forEach((t, h) {
      print('$t -> ${h.resolvingClassifier.runtimeType}');
    });

//    final classifiers =
//        eClassifiers.map(_processClassifier).where((c) => c != null).toList();

    _classifierHelpers.values.forEach((h) => h.processFlat(_resolveHelper));
    // TODO: hack .toList() as we are modifying the map!!
    _classifierHelpers.values
        .toList()
        .forEach((h) => h.processGraph(_resolveHelper));
    _classifierHelpers.values.forEach((h) => h.resolve());

    final classifiers = _classifierHelpers.values
        // TODO: better not to have put them there in the first place
        .where((h) => h.resolvedClassifier is ValueClass)
        .map((h) => h.resolvedClassifier);

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

  _ResolvingClassifierHolder _resolveHelper(DartType type) {
    final result = __resolveHelper(type);
    print('resolved to: $result with builder: ${result?.resolvingClassifier}; '
        '${result?.resolvingClassifier?.name}');
    return result;
  }

  _ResolvingClassifierHolder __resolveHelper(DartType type) {
    print('_resolveHelper($type)');
    // TODO: less dodgy way of filtering
    if (type != null && !type.isObject) {
      return _resolveHelperByName(type.name, type.displayName);
    } else {
      return null;
    }
  }

  _ResolvingClassifierHolder _resolveHelperByName(
      String typeName, String fullTypeName) {
    print('_resolveHelperByName($typeName, $fullTypeName)');
    // TODO: less dodgy way of filtering
    if (typeName != 'Built' && !typeName.startsWith('Serializer')) {
      final _ResolvingClassifierHelper classifierHelper =
          _classifierHelpers[fullTypeName] ?? _classifierHelpers[typeName];
      if (classifierHelper == null) {
        final coreType = _coreTypes[typeName];
        if (coreType != null) {
          return new _ResolvedExternalClassifier(coreType);
        } else {
          final bool isSet = typeName == 'BuiltSet';
          final bool isList = typeName == 'BuiltList';
          final bool isCollection = isSet || isList;
          final bool isMap = typeName == 'BuiltMap';
          final bool isMultiValued = isCollection || isMap;

          if (isMultiValued) {
            print('found new multivalued type $fullTypeName');
            final typeParamNames = fullTypeName
                .substring(fullTypeName.indexOf('<') + 1,
                    fullTypeName.lastIndexOf('>'))
                .split(',')
                .map((s) => s.trim());
            final typeParamHelpers = typeParamNames.map((typeParamFullName) {
              print('typeParamFullName: $typeParamFullName');

              final i = typeParamFullName.indexOf('<');
              final typeParamName =
                  i < 0 ? typeParamFullName : typeParamFullName.substring(0, i);

              return _resolveHelperByName(typeParamName, typeParamFullName);
            });
            print('*** $typeParamHelpers for $typeParamNames');

            if (isCollection) {
              final typeParamHelper = typeParamHelpers.first;

              final typeBuilder = isSet
                  ? createBuiltSet(typeParamHelper.resolvingClassifier)
                  : createBuiltList(typeParamHelper.resolvingClassifier);
              final helper = new _ResolvingGenericTypeClassifier(typeBuilder);
              _classifierHelpers[fullTypeName] = helper;
              print('added: $fullTypeName -> $helper');
              return helper;
            } else if (isMap) {
              final typeBuilder = createBuiltMap(
                  typeParamHelpers.first.resolvingClassifier,
                  typeParamHelpers.elementAt(1).resolvingClassifier);
              final helper = new _ResolvingGenericTypeClassifier(typeBuilder);
              _classifierHelpers[fullTypeName] = helper;
              print('added: $fullTypeName -> $helper');
              return helper;
            }
          } else {
//          throw new StateError(
//              "failed to resolve classifier helper class: $type");
            print("failed to resolve classifier helper class: $typeName");
            return new _ResolvedExternalClassifier(
                (new ExternalClassBuilder()..name = typeName).build());
          }
        }
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

// OMG shit names
abstract class _ResolvingClassifierHolder<V extends TypedClassifier<V, B>,
    B extends TypedClassifierBuilder<V, B>> {
  B get resolvingClassifier;
  void resolve();
}

abstract class _ResolvedClassifier<V extends TypedClassifier<V, B>,
        B extends TypedClassifierBuilder<V, B>>
    implements _ResolvingClassifierHolder<V, B> {
  final B resolvingClassifier;

  _ResolvedClassifier(V cls) : this.resolvingClassifier = cls.toBuilder();
}

class _ResolvedExternalClassifier
    extends _ResolvedClassifier<ExternalClass, ExternalClassBuilder> {
  _ResolvedExternalClassifier(ExternalClass cls) : super(cls);

  void resolve() {}
}

// TODO: this will be problematic as can't be a super type for a valueclass
// either
class _ResolvingGenericTypeClassifier
    extends _ResolvingClassifierHelper<GenericType, GenericTypeBuilder> {
  _ResolvingGenericTypeClassifier(GenericTypeBuilder resolvingClassifier)
      : super._(resolvingClassifier);

  void resolve() {}

  @override
  void processFlat(_ResolvingClassifierHolder lookup(DartType cls)) {
    // TODO: implement processFlat
  }
}

abstract class _ResolvingClassifierHelper<V extends TypedClassifier<V, B>,
        B extends TypedClassifierBuilder<V, B>>
    implements _ResolvingClassifierHolder<V, B> {
  V _resolvedClassifier;
  V get resolvedClassifier {
    return _resolvedClassifier ??= resolvingClassifier.build();
  }

  bool get isResolved => _resolvedClassifier != null;

  final B resolvingClassifier;

  String get name => resolvingClassifier.name;

  _ResolvingClassifierHelper._(this.resolvingClassifier);

  void processFlat(_ResolvingClassifierHolder lookup(DartType cls));
  void processGraph(_ResolvingClassifierHolder lookup(DartType cls)) {}
  void resolve() {}
}

abstract class _ResolvingTopLevelClassifierHelper<
        V extends TypedClassifier<V, B>, B extends TypedClassifierBuilder<V, B>>
    extends _ResolvingClassifierHelper<V, B> {
  final _ClassBuilderPair classifierElement;

  _ResolvingTopLevelClassifierHelper._(
      this.classifierElement, B resolvingClassifier)
      : super._(resolvingClassifier) {
    resolvingClassifier.name = classifierElement.name;
  }

  static _ResolvingTopLevelClassifierHelper create(
      _ClassBuilderPair classifierElement) {
    return new _ResolvingValueClassHelper(classifierElement);
  }

  void processFlat(_ResolvingClassifierHolder lookup(DartType cls));
  void processGraph(_ResolvingClassifierHolder lookup(DartType cls)) {}
  void resolve() {}
}

class _ResolvingValueClassHelper
    extends _ResolvingTopLevelClassifierHelper<ValueClass, ValueClassBuilder> {
  SetBuilder<PropertyBuilder> _properties = new SetBuilder<PropertyBuilder>();
  SetBuilder<ValueClassBuilder> _superClasses =
      new SetBuilder<ValueClassBuilder>();

  _ResolvingValueClassHelper(_ClassBuilderPair classifierElement)
      : super._(classifierElement, new ValueClassBuilder());

  @override
  void processFlat(_ResolvingClassifierHolder lookup(DartType cls)) {
    print('_ResolvingValueClassHelper.processFlat($name)');
    resolvingClassifier.isAbstract =
        !classifierElement.cls.interfaces.any((it) => it.name == 'Built');

//    classifierElement.accessors.where((p) => p.displayName =='isAbstract')
//    resolvingClassifier.isAbstract = classifierElement.isAbstract;
  }

  void processGraph(_ResolvingClassifierHolder lookup(DartType cls)) {
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
    print('XXX2($name): ${resolvingClassifier.properties.build()
          .map((vc) => vc.type).toList()}');

    print('YYY($name): ${_superClasses.build().map((vc) => vc).toList()}');
    print('YYY2($name): ${resolvingClassifier.superTypes.build()
          .map((vc) => vc).toList()}');

    _resolvedClassifier = resolvingClassifier.build();
  }

  void _processSuperTypes(_ResolvingClassifierHolder lookup(DartType cls)) {
    print('_processSuperTypes($name)');
    final superTypes = classifierElement.cls.interfaces;
    print('superTypes: $superTypes');

    superTypes.forEach((t) {
      final superClass = lookup(t as DartType)?.resolvingClassifier;
      if (superClass != null) {
        if (superClass is! ValueClassBuilder) {
          throw new StateError(
              'attempt to add superclass $superClass (${superClass.name}) to $name');
        }
        _superClasses.add(superClass);
      }
    });
  }

  void _processProperties(_ResolvingClassifierHolder lookup(DartType cls)) {
//    print('_processProperties($name)');
//    final fields = classifierElement.fields.where((fe) => !fe.isStatic);
//    print('fields for $name: ${fields.toList()}');
//
//    final fieldProperties =
//        fields.map((fe) => _processField(lookup, fe)).where((pb) => pb != null);
//
//    _properties.addAll(fieldProperties);

    final getters =
//        classifierElement.accessors.where((a) => a.isGetter && !a.isStatic);
        classifierElement.propertyPairs;

    print('getters for $name: ${getters.toList()}');

    final getterProperties = getters
        .map((sf) => _processField(lookup, sf))
        .where((pb) => pb != null);

    print('getterProperties for $name: ${getterProperties.toList()}');

    _properties.addAll(getterProperties);

//    resolvingClassifier.addProperty(properties);
  }

  PropertyBuilder _processField(_ResolvingClassifierHolder lookup(DartType cls),
      _PropertyPair structuralElement) {
    print('_processField: $structuralElement');
    final fieldType = structuralElement.property.type;
    final classifierBuilder = lookup(fieldType)?.resolvingClassifier;
    if (classifierBuilder == null) {
      print("No type for structuralElement $structuralElement");
      return null;
//      throw new StateError("No type for structuralElement $structuralElement");
    }

    final builderType = structuralElement.builderProperty.map((p) => p.type);
    final builderClassifierBuilder = builderType.expand((t) {
      final b = lookup(t)?.resolvingClassifier;
      if (b == null) {
        print("No type for structuralElement $structuralElement");
        return const None();
//      throw new StateError("No type for structuralElement $structuralElement");
      }
      return new Some(b);
    });

    final pb = new PropertyBuilder()
      ..name = structuralElement.name
      ..type = classifierBuilder;

    if (builderClassifierBuilder is Some) {
      pb.explicitBuilderType = builderClassifierBuilder.get();
    }
  }
}

class _PropertyPair {
  final VariableElement property;
  final Option<VariableElement> builderProperty;

  String get name => property.name;

  _PropertyPair(this.property, this.builderProperty);
}

class _ClassBuilderPair {
  ClassElement cls;
  Option<ClassElement> builder = const None();
  String get name => cls.name;

//  get getters => cls.accessors.where((a) => a.isGetter && !a.isStatic);

  Iterable<_PropertyPair> get propertyPairs {
    final props = cls.accessors.where((a) => a.isGetter && !a.isStatic);
    return props.map((prop) {
      final builderOpt = builder.map((ClassElement bCls) {
        return new Option(bCls.accessors
            .where((a) => a.isGetter && !a.isStatic)
            .firstWhere((a) => a.name == prop.name, orElse: () => null));
      });
      return new _PropertyPair(
          prop.variable, builderOpt.map((p) => p.variable));
    });
  }
}

class _GetClassesVisitor extends RecursiveElementVisitor {
//  final List<ClassElement> classElements = new List<ClassElement>();

  final Map<String, _ClassBuilderPair> nameToBuilderPair =
      <String, _ClassBuilderPair>{};

  @override
  visitClassElement(ClassElement element) {
    print('visitClassElement($element)');
    if (!element.name.startsWith(r'_')) {
      if (element.name.endsWith('Builder')) {
        final valueName = element.name.replaceFirst('Builder', '');
        final pair = nameToBuilderPair.putIfAbsent(
            valueName, () => new _ClassBuilderPair());

        pair.builder = new Some(element);
      } else {
        final valueName = element.name;
        final pair = nameToBuilderPair.putIfAbsent(
            valueName, () => new _ClassBuilderPair());

        pair.cls = element;
      }
    }
    super.visitClassElement(element);
  }

  visitLibraryElement(LibraryElement element) {
    print('visitLibraryElement($element)');
    return super.visitLibraryElement(element);
  }

  visitExportElement(ExportElement element) {
    print('visitExportElement($element)');
    element.exportedLibrary.visitChildren(this);
    return super.visitExportElement(element);
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
