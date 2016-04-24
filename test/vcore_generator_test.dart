// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:vcore_generator/vcore_generator.dart';
import 'package:test/test.dart';
import 'package:vcore/vcore.dart';
import 'dart:io';

void main() {
  group('A group of tests', () {
    test('First Test', () {
      new VCoreCodeGenerator(includeBuildConstructor: false)
          .generatePackage(vcorePackage, stdout);
//      expect(awesome.isAwesome, isTrue);
    });
  });
}
