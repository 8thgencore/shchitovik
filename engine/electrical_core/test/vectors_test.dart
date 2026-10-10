import 'dart:convert';
import 'dart:io';

import 'package:electrical_core/electrical_core.dart';
import 'package:test/test.dart';

import '../tool/generate_vectors.dart';

/// The committed reference vectors are checked by the independent Python oracle
/// (verification/oracle). This test guarantees they still describe the current core:
/// after an intended change of results, regenerate them with tool/generate_vectors.dart.
void main() {
  for (final name in ['circuits', 'projects']) {
    test('$name vectors match the current core', () {
      final file = File('../../verification/vectors/$name.json');
      final committed = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      expect(committed['algorithm_version'], algorithmVersion);
      for (final v in committed['vectors']! as List<Object?>) {
        final vector = v! as Map<String, Object?>;
        final input = ProjectInput.fromJson(vector['input']! as Map<String, Object?>);
        expect(
          jsonDecode(jsonEncode(expectedOf(input))),
          vector['expected'],
          reason: 'vector ${vector['id']}',
        );
      }
    });
  }
}
