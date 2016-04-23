// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// TODO: Put public facing types in this file.

library vcore_generator;

import 'dart:async';

import 'package:analyzer/src/generated/element.dart';
//import 'package:vcore_generator/src/source_library.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for VCore.
///
class VCoreGenerator extends Generator {
  Future<String> generate(Element element) async {
    if (element is! LibraryElement) return null;

//    final sourceLibrary = SourceLibrary.fromLibraryElement(element as LibraryElement);
//    if (!sourceLibrary.needsVCore && !sourceLibrary.hasSerializers) return null;
//
//    return sourceLibrary.generate();
  }
}